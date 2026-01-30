import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/firebase_config.dart';
import '../models/image_item.dart';
import '../services/storage/prefs_service.dart';
import 'app_providers.dart';
import '../providers/user_type_provider.dart';
import '../services/firebase_config_service.dart';
import '../services/image_loader_service.dart';
import '../utils/secret_image_utils.dart';

/// 图片状态管理Provide但是是事实上 okok22222222323323323323拉屎肯定放假啦睡大觉看
class PhotoStateNotifier extends StateNotifier<Map<String, bool>> {
  PhotoStateNotifier(this._prefsService) : super({}) {
    _loadState();
  }

  final PrefsService _prefsService;
  static const String _likedImagesKey = 'liked_images';
  static const String _downloadedImagesKey = 'downloaded_images';
  static const String _unlockedImagesKey = 'unlocked_images';
  static const String _displayedLevelImagesKey = 'displayed_level_images';

  /// 加载保存的状态
  Future<void> _loadState() async {
    final likedImages = _prefsService.getJson(_likedImagesKey) ?? {};
    final downloadedImages = _prefsService.getJson(_downloadedImagesKey) ?? {};
    final unlockedImages = _prefsService.getJson(_unlockedImagesKey) ?? {};

    // 合并收藏、下载和解锁状态
    state = {
      ...likedImages.map((key, value) => MapEntry('${key}_liked', value as bool)),
      ...downloadedImages.map((key, value) => MapEntry('${key}_downloaded', value as bool)),
      ...unlockedImages.map((key, value) => MapEntry('${key}_unlocked', value as bool)),
    };
  }

  /// 切换收藏状态
  Future<void> toggleLike(String imageId) async {
    final currentLiked = _prefsService.getJson(_likedImagesKey)?[imageId] as bool? ?? false;
    final newLiked = !currentLiked;
    
    // 更新本地存储
    final likedImages = Map<String, Object?>.from(_prefsService.getJson(_likedImagesKey) ?? {});
    likedImages[imageId] = newLiked;
    await _prefsService.setJson(_likedImagesKey, likedImages);
    
    // 更新状态
    state = {...state, '${imageId}_liked': newLiked};
  }

  /// 检查是否已收藏
  bool isLiked(String imageId) {
    return _prefsService.getJson(_likedImagesKey)?[imageId] as bool? ?? false;
  }

  /// 检查是否已下载
  bool isDownloaded(String imageId) {
    return _prefsService.getJson(_downloadedImagesKey)?[imageId] as bool? ?? false;
  }

  /// 标记为已下载
  Future<void> markAsDownloaded(String imageId) async {
    final downloadedImages = Map<String, Object?>.from(_prefsService.getJson(_downloadedImagesKey) ?? {});
    downloadedImages[imageId] = true;
    await _prefsService.setJson(_downloadedImagesKey, downloadedImages);
    
    state = {...state, '${imageId}_downloaded': true};
  }

  /// 获取收藏的图片ID列表
  List<String> getLikedImageIds() {
    final likedImages = _prefsService.getJson(_likedImagesKey) ?? {};
    return likedImages.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  /// 检查图片是否已解锁
  bool isUnlocked(String imageId) {
    return _prefsService.getJson(_unlockedImagesKey)?[imageId] as bool? ?? false;
  }

  /// 标记图片为已解锁
  Future<void> markAsUnlocked(String imageId) async {
    final unlockedImages = Map<String, Object?>.from(_prefsService.getJson(_unlockedImagesKey) ?? {});
    unlockedImages[imageId] = true;
    await _prefsService.setJson(_unlockedImagesKey, unlockedImages);

    state = {...state, '${imageId}_unlocked': true};
  }

  /// 批量标记图片为已解锁
  Future<void> markMultipleAsUnlocked(List<String> imageIds) async {
    final unlockedImages = Map<String, Object?>.from(_prefsService.getJson(_unlockedImagesKey) ?? {});
    for (final imageId in imageIds) {
      unlockedImages[imageId] = true;
    }
    await _prefsService.setJson(_unlockedImagesKey, unlockedImages);

    final newState = Map<String, bool>.from(state);
    for (final imageId in imageIds) {
      newState['${imageId}_unlocked'] = true;
    }
    state = newState;
  }

  /// 获取已在关卡选择弹窗中展示过的图片ID集合
  /// 返回格式: {'b': [0, 3, 5], 'c': [1, 2]}
  Map<String, List<int>> getDisplayedLevelImages() {
    final data = _prefsService.getJson(_displayedLevelImagesKey) ?? {};
    final result = <String, List<int>>{};
    data.forEach((levelType, indices) {
      if (indices is List) {
        result[levelType] = List<int>.from(indices);
      }
    });
    return result;
  }

  /// 标记图片已在关卡选择弹窗中展示
  Future<void> markLevelImageAsDisplayed(String levelType, int levelIndex) async {
    final displayed = Map<String, Object?>.from(_prefsService.getJson(_displayedLevelImagesKey) ?? {});
    final typeList = (displayed[levelType] as List?)?.cast<int>() ?? <int>[];
    
    if (!typeList.contains(levelIndex)) {
      typeList.add(levelIndex);
      displayed[levelType] = typeList;
      await _prefsService.setJson(_displayedLevelImagesKey, displayed);
    }
  }

  /// 批量标记图片已展示
  Future<void> markMultipleLevelImagesAsDisplayed(String levelType, List<int> indices) async {
    final displayed = Map<String, Object?>.from(_prefsService.getJson(_displayedLevelImagesKey) ?? {});
    final typeList = (displayed[levelType] as List?)?.cast<int>() ?? <int>[];
    
    for (final index in indices) {
      if (!typeList.contains(index)) {
        typeList.add(index);
      }
    }
    
    displayed[levelType] = typeList;
    await _prefsService.setJson(_displayedLevelImagesKey, displayed);
  }

  /// 重置某个关卡类型的展示记录（当所有图片都展示完后）
  Future<void> resetDisplayedLevelImages(String levelType) async {
    final displayed = Map<String, Object?>.from(_prefsService.getJson(_displayedLevelImagesKey) ?? {});
    displayed[levelType] = <int>[];
    await _prefsService.setJson(_displayedLevelImagesKey, displayed);
  }

  /// 清空所有展示记录（用于测试或重置）
  Future<void> clearAllDisplayedLevelImages() async {
    await _prefsService.setJson(_displayedLevelImagesKey, {});
  }
}

final photoStateProvider = StateNotifierProvider<PhotoStateNotifier, Map<String, bool>>((ref) {
  final prefsService = ref.read(prefsServiceProvider);
  return PhotoStateNotifier(prefsService);
});

/// 图片列表Provider - 支持无限滚动
class PhotoListNotifier extends StateNotifier<AsyncValue<List<ImageItem>>> {
  PhotoListNotifier(this._ref, this._photoStateNotifier)
      : super(const AsyncValue.loading()) {
    loadMore();
    // 移除测试数据，确保正常持久化逻辑
  }

  final Ref _ref;
  final PhotoStateNotifier _photoStateNotifier;
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  List<ImageItem>? _catalogCache;

  /// 加载更多图片
  Future<void> loadMore() async {
    if (!_hasMore) return;

    try {
      // 模拟网络请求延迟
      await Future.delayed(const Duration(milliseconds: 500));
      
      final catalog = _ensureCatalog();
      final start = _currentPage * _pageSize;
      final end = math.min(start + _pageSize, catalog.length);
      final newImages = start >= catalog.length ? <ImageItem>[] : catalog.sublist(start, end);

      if (newImages.isEmpty) {
        _hasMore = false;
        return;
      }

      final currentImages = state.valueOrNull ?? [];
      
      // 检查是否有重复数据，避免重复添加
      final existingIds = currentImages.map((img) => img.id).toSet();
      final uniqueNewImages = newImages.where((img) => !existingIds.contains(img.id)).toList();
      
      if (uniqueNewImages.isEmpty) {
        _hasMore = false;
        return;
      }
      
      final updatedImages = [...currentImages, ...uniqueNewImages];
      
      // 更新图片状态（收藏、下载、解锁状态）
      final updatedImagesWithState = updatedImages.map((image) {
        return image.copyWith(
          liked: _photoStateNotifier.isLiked(image.id),
          downloaded: _photoStateNotifier.isDownloaded(image.id),
          unlocked: _photoStateNotifier.isUnlocked(image.id),
        );
      }).toList();

      state = AsyncValue.data(updatedImagesWithState);
      _currentPage++;
      
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 刷新列表
  Future<void> refresh() async {
    print('[PhotoList] 刷新相册列表，清除目录缓存');
    _catalogCache = null;  // ✅ 清除目录缓存，强制重新构建
    _currentPage = 0;
    _hasMore = true;
    state = const AsyncValue.loading();  // 重置状态
    await loadMore();
  }

  /// 根据来源类型过滤图片
  List<ImageItem> getImagesBySource(ImageSourceType sourceType) {
    final allImages = state.valueOrNull ?? [];
    return allImages.where((image) => image.source == sourceType).toList();
  }

  /// 获取收藏的图片
  List<ImageItem> getLikedImages() {
    final allImages = state.valueOrNull ?? [];
    return allImages.where((image) => image.liked).toList();
  }

  /// 刷新图片状态（收藏、下载状态）
  void refreshImageStates() {
    final currentImages = state.valueOrNull ?? [];
    if (currentImages.isEmpty) return;

    // 去重处理，避免重复数据
    final uniqueImages = <String, ImageItem>{};
    for (final image in currentImages) {
      if (!uniqueImages.containsKey(image.id)) {
        uniqueImages[image.id] = image.copyWith(
          liked: _photoStateNotifier.isLiked(image.id),
          downloaded: _photoStateNotifier.isDownloaded(image.id),
          unlocked: _photoStateNotifier.isUnlocked(image.id),
        );
      }
    }

    state = AsyncValue.data(uniqueImages.values.toList());
  }

  /// 解锁图片
  Future<void> unlockImage(String imageId) async {
    print('[PhotoList] 开始解锁图片: $imageId');
    
    // 先持久化保存解锁状态
    await _photoStateNotifier.markAsUnlocked(imageId);
    print('[PhotoList] 图片解锁状态已持久化: $imageId');

    // 如果图片列表还没加载，等待加载完成
    var currentImages = state.valueOrNull ?? [];
    if (currentImages.isEmpty) {
      print('[PhotoList] 图片列表为空，等待加载...');
      // 等待一段时间让loadMore完成
      int retryCount = 0;
      while (currentImages.isEmpty && retryCount < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        currentImages = state.valueOrNull ?? [];
        retryCount++;
        print('[PhotoList] 重试 $retryCount/10, 当前图片数量: ${currentImages.length}');
      }
      
      if (currentImages.isEmpty) {
        print('[PhotoList] 警告: 图片列表加载失败，但解锁状态已持久化');
        return;
      }
    }
    
    print('[PhotoList] 当前图片数量: ${currentImages.length}');

    // 检查图片是否存在
    final targetImage = currentImages.firstWhere(
      (image) => image.id == imageId,
      orElse: () {
        print('[PhotoList] 警告: 图片不存在于目录中: $imageId，但解锁状态已持久化');
        return ImageItem(
          id: imageId,
          type: ImageType.B,
          src: '',
          unlocked: false,
          source: ImageSourceType.secret,
          liked: false,
          downloaded: false,
          ts: 0,
        );
      },
    );
    
    if (targetImage.src.isEmpty) {
      print('[PhotoList] 图片不在目录中，跳过状态更新');
      return;
    }
    
    print('[PhotoList] 找到目标图片: ${targetImage.id}, 当前状态: unlocked=${targetImage.unlocked}');

    final updatedImages = currentImages.map((image) {
      if (image.id == imageId) {
        print('[PhotoList] 更新图片状态: ${image.id} -> unlocked=true');
        return image.copyWith(
          unlocked: true,
          ts: DateTime.now().millisecondsSinceEpoch, // 更新解锁时间
        );
      }
      return image;
    }).toList();

    state = AsyncValue.data(updatedImages);
    print('[PhotoList] 图片已解锁并更新状态: $imageId');
  }

  /// 根据图片ID解锁多个图片
  Future<void> unlockImages(List<String> imageIds) async {
    if (imageIds.isEmpty) return;

    final currentImages = state.valueOrNull ?? [];
    if (currentImages.isEmpty) return;

    // 持久化保存解锁状态
    await _photoStateNotifier.markMultipleAsUnlocked(imageIds);

    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedImages = currentImages.map((image) {
      if (imageIds.contains(image.id)) {
        return image.copyWith(
          unlocked: true,
          ts: now + imageIds.indexOf(image.id), // 按顺序设置解锁时间
        );
      }
      return image;
    }).toList();

    state = AsyncValue.data(updatedImages);
  }

  List<ImageItem> _ensureCatalog() {
    return _catalogCache ??= _buildCatalog();
  }

  
  FirebaseConfig? _resolveConfig() {
    final asyncConfig = _ref.read(firebaseConfigProvider);
    final firebaseConfig = asyncConfig.valueOrNull;
    if (firebaseConfig != null) {
      return firebaseConfig;
    }
    final userType = _ref.read(userTypeProvider);
    return _ref.read(firebaseConfigServiceProvider).getDefaultConfig(userType);
  }

  List<ImageItem> _buildCatalog() {
    final items = <ImageItem>[];
    final now = DateTime.now().millisecondsSinceEpoch;
    var counter = 0;
    final config = _resolveConfig();
    final imageLoader = _ref.read(imageLoaderServiceProvider);

    void addItem({
      required String id,
      required ImageType type,
      required String path,
      required ImageSourceType source,
      required bool unlocked,
    }) {
      // 从持久化存储中读取实际解锁状态
      final actualUnlocked = _photoStateNotifier.isUnlocked(id) || unlocked;

      items.add(ImageItem(
        id: id,
        type: type,
        src: path,
        unlocked: actualUnlocked,
        source: source,
        liked: _photoStateNotifier.isLiked(id),
        downloaded: _photoStateNotifier.isDownloaded(id),
        ts: now - counter * 1000,
      ));
      counter++;
    }

    const levelFolders = [
      {'folder': 'a', 'type': ImageType.A},
      {'folder': 'b', 'type': ImageType.B},
      {'folder': 'c', 'type': ImageType.C},
    ];

    for (final entry in levelFolders) {
      final folder = entry['folder'] as String;
      final type = entry['type'] as ImageType;
      for (var i = 1; i <= 10; i++) {
        final id = 'level_${folder}_$i';
        final path = 'assets/pic_level/$folder/level_${folder}_$i.png';
        addItem(
          id: id,
          type: type,
          path: path,
          source: ImageSourceType.general,
          unlocked: false, // 修复：普通关卡图片默认不解锁
        );
      }
    }

    final secretSets = config?.secrets.sets;
    if (secretSets != null && secretSets.isNotEmpty) {
      for (final secretSet in secretSets) {
        final slotCount = secretSet.slotCount > 0 ? secretSet.slotCount : 9;
        for (var slotIdx = 1; slotIdx <= slotCount; slotIdx++) {
          final id = 'secret_${secretSet.setId}_$slotIdx';
          final path = imageLoader.getLocalImagePath(id, config);
          final type = SecretImageUtils.imageType(slotIdx);
          addItem(
            id: id,
            type: type,
            path: path,
            source: ImageSourceType.secret,
            unlocked: false,
          );
        }
      }
    } else {
      const secretFolders = ['a', 'b', 'c', 'd', 'e', 'f', 'j', 'h', 'i'];
      for (var setIdx = 0; setIdx < secretFolders.length; setIdx++) {
        final folder = secretFolders[setIdx];
        final setId = setIdx + 1;
        for (var slotIdx = 1; slotIdx <= 9; slotIdx++) {
          final id = 'secret_${setId}_$slotIdx';
          final prefix = SecretImageUtils.typeLetter(slotIdx);
          final path =
              'assets/pic_secret/$folder/secret_${setId}_${prefix}_$slotIdx.png';
          final type = SecretImageUtils.imageType(slotIdx);
          addItem(
            id: id,
            type: type,
            path: path,
            source: ImageSourceType.secret,
            unlocked: false,
          );
        }
      }
    }

    final treasureTotal = config?.treasure.totalCount ?? 18;
    final treasureCount = treasureTotal > 0 ? treasureTotal : 18;
    for (var i = 1; i <= treasureCount; i++) {
      final id = 'pass_c_$i';
      final path = imageLoader.getLocalImagePath(id, config);
      addItem(
        id: id,
        type: ImageType.C,
        path: path,
        source: ImageSourceType.treasure,
        unlocked: false, // 修复：宝藏图片默认也不解锁
      );
    }

    return items;
  }
}

final photoListProvider = StateNotifierProvider<PhotoListNotifier, AsyncValue<List<ImageItem>>>((ref) {
  final photoStateNotifier = ref.read(photoStateProvider.notifier);
  return PhotoListNotifier(ref, photoStateNotifier);
});
