import '../services/storage/prefs_service.dart';
import '../core/locator.dart';
import '../utils/secret_image_utils.dart';

/// 相册数据仓库
/// 专门负责相册解锁状态和收藏状态的持久化存储
class AlbumRepository {
  static const _unlockedKey = 'album_unlocked_v1';
  static const _likedKey = 'album_liked_v1';

  final PrefsService _prefs = ServiceLocator.instance.get<PrefsService>();

  /// 获取所有解锁的图片ID
  Set<String> getUnlockedImageIds() {
    final data = _loadUnlockedState();
    return data.entries
        .where((entry) => entry.value == true || entry.value is int)
        .map((entry) => entry.key)
        .toSet();
  }

  /// 获取带时间戳的解锁记录
  Map<String, int> getUnlockedImageTimestamps() {
    final data = _loadUnlockedState();
    final Map<String, int> result = {};
    data.forEach((key, value) {
      if (value is int) {
        result[key] = value;
      } else if (value == true) {
        // 兼容旧数据，时间戳未知时使用0
        result[key] = 0;
      }
    });
    return result;
  }

  /// 解锁图片
  Future<void> unlockImage(String imageId) async {
    final normalizedId = SecretImageUtils.normalizeImageId(imageId);
    final current = _loadUnlockedState();
    current[normalizedId] = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setJson(_unlockedKey, current);
    print('[AlbumRepository] 图片已解锁: $normalizedId');
    print('[AlbumRepository] 当前解锁状态: $current');
    
    // 验证保存
    final saved = _prefs.getJson(_unlockedKey);
    print('[AlbumRepository] 验证解锁状态: ${saved?[imageId]}');
  }

  /// 批量解锁图片
  Future<void> unlockImages(List<String> imageIds) async {
    final current = _loadUnlockedState();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    for (final id in imageIds) {
      final normalizedId = SecretImageUtils.normalizeImageId(id);
      current[normalizedId] = timestamp;
    }
    await _prefs.setJson(_unlockedKey, current);
    print('[AlbumRepository] 批量解锁${imageIds.length}张图片');
  }

  /// 检查图片是否已解锁
  bool isUnlocked(String imageId) {
    final data = _loadUnlockedState();
    final normalizedId = SecretImageUtils.normalizeImageId(imageId);
    final value = data[normalizedId];
    if (value == null) return false;
    if (value is int) return true;
    return value == true;
  }

  /// 获取所有收藏的图片ID
  Set<String> getLikedImageIds() {
    final data = _loadState(_likedKey);
    return data.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toSet();
  }

  /// 收藏图片
  Future<void> likeImage(String imageId) async {
    final normalizedId = SecretImageUtils.normalizeImageId(imageId);
    final current = _loadState(_likedKey);
    current[normalizedId] = true;
    await _prefs.setJson(_likedKey, current);
    print('[AlbumRepository] 图片已收藏: $normalizedId');
    
    // 验证保存
    final saved = _prefs.getJson(_likedKey);
    print('[AlbumRepository] 验证收藏状态: ${saved?[imageId]}');
  }

  /// 取消收藏
  Future<void> unlikeImage(String imageId) async {
    final normalizedId = SecretImageUtils.normalizeImageId(imageId);
    final current = _loadState(_likedKey);
    current.remove(normalizedId); // 直接删除，而不是设置为 false
    await _prefs.setJson(_likedKey, current);
    print('[AlbumRepository] 取消收藏: $normalizedId');
    
    // 验证保存
    final saved = _prefs.getJson(_likedKey);
    print('[AlbumRepository] 验证取消收藏: ${saved?[imageId]} (应该是null)');
  }

  /// 检查图片是否已收藏
  bool isLiked(String imageId) {
    final data = _loadState(_likedKey);
    final normalizedId = SecretImageUtils.normalizeImageId(imageId);
    final result = data[normalizedId] == true;
    print('[AlbumRepository] 检查收藏状态: $normalizedId = $result');
    return result;
  }

  /// 切换收藏状态
  Future<void> toggleLike(String imageId) async {
    print('[AlbumRepository] toggleLike 开始: $imageId');
    final normalizedId = SecretImageUtils.normalizeImageId(imageId);
    final currentLiked = isLiked(normalizedId);
    print('[AlbumRepository] 当前状态: $currentLiked, 将切换为: ${!currentLiked}');
    
    if (currentLiked) {
      await unlikeImage(normalizedId);
    } else {
      await likeImage(normalizedId);
    }
    
    print('[AlbumRepository] toggleLike 完成');
  }

  /// 从旧版数据迁移
  Future<void> migrateFromLegacy() async {
    // 从旧的 photoState 迁移解锁和收藏数据
    final oldUnlocked = _prefs.getJson('unlocked_images');
    final oldLiked = _prefs.getJson('liked_images');
    
    if (oldUnlocked != null || oldLiked != null) {
      print('[AlbumRepository] 检测到旧版数据，开始迁移');
      
      // 迁移解锁数据
      if (oldUnlocked != null) {
        final current = _loadUnlockedState();
        for (final entry in oldUnlocked.entries) {
          if (entry.value == true) {
            final normalizedId = SecretImageUtils.normalizeImageId(entry.key);
            current.putIfAbsent(normalizedId, () => 0);
          }
        }
        await _prefs.setJson(_unlockedKey, current);
        print('[AlbumRepository] 已迁移${current.length}张解锁图片');
      }
      
      // 迁移收藏数据
      if (oldLiked != null) {
        final current = _loadState(_likedKey);
        for (final entry in oldLiked.entries) {
          if (entry.value == true) {
            final normalizedId = SecretImageUtils.normalizeImageId(entry.key);
            current.putIfAbsent(normalizedId, () => true);
          }
        }
        await _prefs.setJson(_likedKey, current);
        print('[AlbumRepository] 已迁移${current.length}张收藏图片');
      }
      
      print('[AlbumRepository] 数据迁移完成');
    }
  }

  /// 清空所有数据（仅用于测试/重置）
  Future<void> clearAll() async {
    await _prefs.remove(_unlockedKey);
    await _prefs.remove(_likedKey);
    print('[AlbumRepository] 已清空所有数据');
  }

  Map<String, bool> _loadState(String key) {
    final raw = _prefs.getJson(key);
    if (raw == null) return {};
    final source = Map<String, Object?>.from(raw as Map);
    final Map<String, bool> normalized = {};
    source.forEach((rawKey, rawValue) {
      final keyString = SecretImageUtils.normalizeImageId(rawKey);
      final boolValue = rawValue == true;
      normalized[keyString] = boolValue;
    });
    return normalized;
  }

  Map<String, Object?> _loadUnlockedState() {
    final raw = _prefs.getJson(_unlockedKey);
    if (raw == null) return {};
    final source = Map<String, Object?>.from(raw as Map);
    final Map<String, Object?> normalized = {};
    source.forEach((rawKey, rawValue) {
      final keyString = SecretImageUtils.normalizeImageId(rawKey);
      normalized[keyString] = rawValue;
    });
    return normalized;
  }
}
