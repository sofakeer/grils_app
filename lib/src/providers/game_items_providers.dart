import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_items.dart';
import '../services/storage/prefs_service.dart';
import 'app_providers.dart';

/// 游戏道具状态管理器
class GameItemsNotifier extends StateNotifier<UserItemInventory> {
  final PrefsService _prefsService;

  GameItemsNotifier(this._prefsService) : super(UserItemInventory(
    items: {},
    totalUsed: {},
    lastUsed: {},
    lastUpdated: DateTime.now(),
  )) {
    _loadInventory();
  }

  /// 加载道具库存
  Future<void> _loadInventory() async {
    final items = <GameItemType, int>{};
    final totalUsed = <GameItemType, int>{};
    final lastUsed = <GameItemType, DateTime>{};

    // 加载每种道具的数量
    for (final itemType in GameItemType.values) {
      final count = await _prefsService.getInt('item_${itemType.name}_count') ?? 0;
      final used = await _prefsService.getInt('item_${itemType.name}_used') ?? 0;
      final lastUsedStr = await _prefsService.getString('item_${itemType.name}_last_used');
      
      items[itemType] = count;
      totalUsed[itemType] = used;
      
      if (lastUsedStr != null) {
        lastUsed[itemType] = DateTime.parse(lastUsedStr);
      }
    }

    state = state.copyWith(
      items: items,
      totalUsed: totalUsed,
      lastUsed: lastUsed,
      lastUpdated: DateTime.now(),
    );
  }

  /// 添加道具
  Future<void> addItem(GameItemType type, int quantity) async {
    final currentCount = state.getItemCount(type);
    final newCount = currentCount + quantity;
    
    await _prefsService.setInt('item_${type.name}_count', newCount);
    
    final newItems = Map<GameItemType, int>.from(state.items);
    newItems[type] = newCount;
    
    state = state.copyWith(
      items: newItems,
      lastUpdated: DateTime.now(),
    );
  }

  /// 使用道具
  Future<bool> useItem(GameItemType type, {int level = 1, Map<String, dynamic> metadata = const {}}) async {
    if (!state.hasItem(type)) {
      return false;
    }

    final currentCount = state.getItemCount(type);
    final newCount = currentCount - 1;
    
    // 更新道具数量
    await _prefsService.setInt('item_${type.name}_count', newCount);
    
    // 更新总使用次数
    final currentUsed = state.getTotalUsed(type);
    await _prefsService.setInt('item_${type.name}_used', currentUsed + 1);
    
    // 更新最后使用时间
    final now = DateTime.now();
    await _prefsService.setString('item_${type.name}_last_used', now.toIso8601String());
    
    // 更新状态
    final newItems = Map<GameItemType, int>.from(state.items);
    final newTotalUsed = Map<GameItemType, int>.from(state.totalUsed);
    final newLastUsed = Map<GameItemType, DateTime>.from(state.lastUsed);
    
    newItems[type] = newCount;
    newTotalUsed[type] = currentUsed + 1;
    newLastUsed[type] = now;
    
    state = state.copyWith(
      items: newItems,
      totalUsed: newTotalUsed,
      lastUsed: newLastUsed,
      lastUpdated: now,
    );

    // 记录使用记录
    await _recordItemUsage(type, level, true, metadata);
    
    return true;
  }

  /// 记录道具使用
  Future<void> _recordItemUsage(GameItemType type, int level, bool success, Map<String, dynamic> metadata) async {
    final record = ItemUsageRecord(
      type: type,
      usedAt: DateTime.now(),
      level: level,
      success: success,
      metadata: metadata,
    );
    
    // 这里可以保存到数据库或发送到服务器
    // 暂时保存到本地存储
    final usageKey = 'item_usage_${type.name}_${DateTime.now().millisecondsSinceEpoch}';
    await _prefsService.setString(usageKey, record.usedAt.toIso8601String());
  }

  /// 获取道具数量
  int getItemCount(GameItemType type) {
    return state.getItemCount(type);
  }

  /// 获取总使用次数
  int getTotalUsed(GameItemType type) {
    return state.getTotalUsed(type);
  }

  /// 获取最后使用时间
  DateTime? getLastUsed(GameItemType type) {
    return state.getLastUsed(type);
  }

  /// 检查是否有道具
  bool hasItem(GameItemType type) {
    return state.hasItem(type);
  }

  /// 检查是否可以解锁
  bool canUnlock(GameItemType type, int currentLevel) {
    return state.canUnlock(type, currentLevel);
  }

  /// 获取道具使用统计
  Map<GameItemType, int> getUsageStats() {
    return state.totalUsed;
  }

  /// 获取道具库存统计
  Map<GameItemType, int> getInventoryStats() {
    return state.items;
  }

  /// 重置道具库存
  Future<void> resetInventory() async {
    for (final itemType in GameItemType.values) {
      await _prefsService.remove('item_${itemType.name}_count');
      await _prefsService.remove('item_${itemType.name}_used');
      await _prefsService.remove('item_${itemType.name}_last_used');
    }
    
    state = UserItemInventory(
      items: {},
      totalUsed: {},
      lastUsed: {},
      lastUpdated: DateTime.now(),
    );
  }

  /// 初始化默认道具（新用户）
  Future<void> initializeDefaultItems() async {
    // 给新用户一些初始道具
    await addItem(GameItemType.undo, 5);
    await addItem(GameItemType.clear, 3);
    await addItem(GameItemType.hint, 2);
    await addItem(GameItemType.bottle, 1);
  }

  /// 根据关卡解锁道具
  Future<void> unlockItemsForLevel(int level) async {
    for (final item in GameItemData.getAllItems()) {
      if (level >= item.unlockLevel && !state.hasItem(item.type)) {
        await addItem(item.type, 1);
      }
    }
  }
}

/// 游戏道具状态提供者
final gameItemsProvider = StateNotifierProvider<GameItemsNotifier, UserItemInventory>((ref) {
  final prefsService = ref.read(prefsServiceProvider);
  return GameItemsNotifier(prefsService);
});

/// 道具使用记录提供者
final itemUsageProvider = Provider<List<ItemUsageRecord>>((ref) {
  // 这里可以从数据库或本地存储加载使用记录
  return [];
});

/// 道具统计提供者
final itemStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final itemsState = ref.watch(gameItemsProvider);
  
  return {
    'totalItems': itemsState.items.values.fold(0, (sum, count) => sum + count),
    'totalUsed': itemsState.totalUsed.values.fold(0, (sum, count) => sum + count),
    'mostUsedItem': _getMostUsedItem(itemsState.totalUsed),
    'lastUsedItem': _getLastUsedItem(itemsState.lastUsed),
  };
});

/// 获取使用最多的道具
String _getMostUsedItem(Map<GameItemType, int> totalUsed) {
  if (totalUsed.isEmpty) return '无';
  
  final mostUsed = totalUsed.entries.reduce((a, b) => a.value > b.value ? a : b);
  return mostUsed.key.name;
}

/// 获取最后使用的道具
String _getLastUsedItem(Map<GameItemType, DateTime> lastUsed) {
  if (lastUsed.isEmpty) return '无';
  
  final lastUsedEntry = lastUsed.entries.reduce((a, b) => a.value.isAfter(b.value) ? a : b);
  return lastUsedEntry.key.name;
}
