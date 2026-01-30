import '../services/storage/prefs_service.dart';
import '../core/locator.dart';
import '../utils/game_logger.dart';

/// 图片顺序轮询服务
/// 负责管理四选一弹窗的图片顺序加载和轮询逻辑
/// 支持按类型（B类、C类）分别管理顺序
class LevelImageSequenceService {
  // B类图片的索引键
  static const String _prefsKeyBCurrentIndex = 'level_image_sequence_b_current_index_v1';
  static const String _prefsKeyBConsumedIds = 'level_image_sequence_b_consumed_ids_v1';
  
  // C类图片的索引键
  static const String _prefsKeyCCurrentIndex = 'level_image_sequence_c_current_index_v1';
  static const String _prefsKeyCConsumedIds = 'level_image_sequence_c_consumed_ids_v1';
  
  final PrefsService _prefs = ServiceLocator.instance.get<PrefsService>();

  /// 只读计算下一组索引（不写 Prefs），用于预加载等场景
  /// 返回 (indices, nextIndex)
  ({List<int> indices, int nextIndex}) _computeNextGroupByType({
    required String levelType,
    required int totalCount,
    required int count,
  }) {
    final currentIndexKey = levelType == 'b' ? _prefsKeyBCurrentIndex : _prefsKeyCCurrentIndex;
    final consumedIdsKey = levelType == 'b' ? _prefsKeyBConsumedIds : _prefsKeyCConsumedIds;

    var consumedIndices = _loadConsumedIndicesByKey(consumedIdsKey);
    int currentIndex = _prefs.getInt(currentIndexKey) ?? 0;

    if (consumedIndices.length >= totalCount) {
      consumedIndices = {};
      currentIndex = 0;
    }

    final availableIndices = <int>[];
    int searchIndex = currentIndex;
    int searchCount = 0;

    while (availableIndices.length < count && searchCount < totalCount) {
      if (!consumedIndices.contains(searchIndex)) {
        availableIndices.add(searchIndex);
      }
      searchIndex = (searchIndex + 1) % totalCount;
      searchCount++;
    }

    if (availableIndices.length < count) {
      searchIndex = 0;
      searchCount = 0;
      while (availableIndices.length < count && searchCount < totalCount) {
        if (!availableIndices.contains(searchIndex)) {
          availableIndices.add(searchIndex);
        }
        searchIndex = (searchIndex + 1) % totalCount;
        searchCount++;
      }
    }

    final nextIndex = availableIndices.isNotEmpty
        ? (availableIndices.last + 1) % totalCount
        : currentIndex;
    return (indices: availableIndices.take(count).toList(), nextIndex: nextIndex);
  }

  /// 获取下一组图片索引（按图片类型分别管理顺序）
  /// [levelType] 图片类型 'b' 或 'c'
  /// [totalCount] 图片总数
  /// [count] 需要获取的图片数量
  /// 返回下一组连续图片的索引列表
  List<int> getNextGroupByType({
    required String levelType,
    required int totalCount,
    required int count,
  }) {
    final currentIndexKey = levelType == 'b' ? _prefsKeyBCurrentIndex : _prefsKeyCCurrentIndex;
    final consumedIdsKey = levelType == 'b' ? _prefsKeyBConsumedIds : _prefsKeyCConsumedIds;

    var consumedIndices = _loadConsumedIndicesByKey(consumedIdsKey);
    int currentIndex = _prefs.getInt(currentIndexKey) ?? 0;

    if (consumedIndices.length >= totalCount) {
      GameLogger.log(GameLogger.tagLevel, '[$levelType类] 所有图片已消费一轮，重置轮询状态');
      consumedIndices.clear();
      currentIndex = 0;
      _saveConsumedIndicesByKey(consumedIdsKey, consumedIndices);
      _prefs.setInt(currentIndexKey, currentIndex);
    }

    final result = _computeNextGroupByType(levelType: levelType, totalCount: totalCount, count: count);
    _prefs.setInt(currentIndexKey, result.nextIndex);

    GameLogger.log(
      GameLogger.tagLevel,
      '[$levelType类] 获取下一组图片: count=$count, currentIndex=$currentIndex, nextIndex=${result.nextIndex}, consumedCount=${consumedIndices.length}, availableIndices=${result.indices}',
    );

    return result.indices;
  }

  /// 只读窥探下一组 4 张图索引（不写 Prefs），用于预加载
  /// 返回 [b0, b1, c0, c1]，与弹窗 allIndices 顺序一致
  List<int> peekNextGroup(int bTotal, int cTotal) {
    final bIndices = _computeNextGroupByType(levelType: 'b', totalCount: bTotal, count: 2).indices;
    final cIndices = _computeNextGroupByType(levelType: 'c', totalCount: cTotal, count: 2).indices;
    return [...bIndices.take(2), ...cIndices.take(2)];
  }

  /// 标记图片为已消费（按类型）
  /// [levelType] 图片类型 'b' 或 'c'
  /// [indices] 要标记的图片索引列表
  void markAsConsumedByType(String levelType, List<int> indices) {
    final consumedIdsKey = levelType == 'b' ? _prefsKeyBConsumedIds : _prefsKeyCConsumedIds;
    final consumedIndices = _loadConsumedIndicesByKey(consumedIdsKey);
    consumedIndices.addAll(indices);
    _saveConsumedIndicesByKey(consumedIdsKey, consumedIndices);
    
    GameLogger.log(
      GameLogger.tagLevel,
      '[$levelType类] 标记图片已消费: indices=$indices, totalConsumed=${consumedIndices.length}',
    );
  }

  /// 重置轮询状态（所有图片重新可用）
  void reset() {
    // 重置B类
    _prefs.setInt(_prefsKeyBCurrentIndex, 0);
    _prefs.setString(_prefsKeyBConsumedIds, '');
    // 重置C类
    _prefs.setInt(_prefsKeyCCurrentIndex, 0);
    _prefs.setString(_prefsKeyCConsumedIds, '');
    GameLogger.log(GameLogger.tagLevel, '重置所有图片轮询状态');
  }

  /// 重置特定类型的轮询状态
  void resetByType(String levelType) {
    if (levelType == 'b') {
      _prefs.setInt(_prefsKeyBCurrentIndex, 0);
      _prefs.setString(_prefsKeyBConsumedIds, '');
    } else {
      _prefs.setInt(_prefsKeyCCurrentIndex, 0);
      _prefs.setString(_prefsKeyCConsumedIds, '');
    }
    GameLogger.log(GameLogger.tagLevel, '[$levelType类] 重置图片轮询状态');
  }

  Set<int> _loadConsumedIndicesByKey(String key) {
    final consumedStr = _prefs.getString(key) ?? '';
    if (consumedStr.isEmpty) return <int>{};
    
    return consumedStr
        .split(',')
        .map((s) => int.tryParse(s.trim()) ?? -1)
        .where((idx) => idx >= 0)
        .toSet();
  }

  void _saveConsumedIndicesByKey(String key, Set<int> indices) {
    if (indices.isEmpty) {
      _prefs.setString(key, '');
    } else {
      final indicesList = indices.toList()..sort();
      _prefs.setString(key, indicesList.join(','));
    }
  }

  // ============ 兼容旧版本的方法（已废弃，保留以防其他地方调用）============
  
  @Deprecated('Use getNextGroupByType instead')
  List<int> getNextGroup({
    required int totalCount,
    required int count,
    Set<int>? consumedIndices,
  }) {
    // 默认使用B类
    return getNextGroupByType(levelType: 'b', totalCount: totalCount, count: count);
  }

  @Deprecated('Use markAsConsumedByType instead')
  void markAsConsumed(List<int> indices) {
    // 默认使用B类
    markAsConsumedByType('b', indices);
  }
}
