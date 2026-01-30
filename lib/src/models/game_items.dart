/// 游戏道具类型枚举
enum GameItemType {
  undo,      // 撤销
  clear,     // 清除
  hint,      // 提示
  bottle,       // 添加
}

/// 游戏道具数据模型
class GameItem {
  final GameItemType type;
  final String name;
  final String description;
  final String iconPath;
  final int maxQuantity;
  final bool isUnlimited;
  final int unlockLevel;

  const GameItem({
    required this.type,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.maxQuantity,
    this.isUnlimited = false,
    this.unlockLevel = 1,
  });

  GameItem copyWith({
    GameItemType? type,
    String? name,
    String? description,
    String? iconPath,
    int? maxQuantity,
    bool? isUnlimited,
    int? unlockLevel,
  }) {
    return GameItem(
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      isUnlimited: isUnlimited ?? this.isUnlimited,
      unlockLevel: unlockLevel ?? this.unlockLevel,
    );
  }
}

/// 用户道具库存
class UserItemInventory {
  final Map<GameItemType, int> items;
  final Map<GameItemType, int> totalUsed; // 总使用次数
  final Map<GameItemType, DateTime> lastUsed; // 最后使用时间
  final DateTime lastUpdated;

  const UserItemInventory({
    required this.items,
    required this.totalUsed,
    required this.lastUsed,
    required this.lastUpdated,
  });

  UserItemInventory copyWith({
    Map<GameItemType, int>? items,
    Map<GameItemType, int>? totalUsed,
    Map<GameItemType, DateTime>? lastUsed,
    DateTime? lastUpdated,
  }) {
    return UserItemInventory(
      items: items ?? this.items,
      totalUsed: totalUsed ?? this.totalUsed,
      lastUsed: lastUsed ?? this.lastUsed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// 获取道具数量
  int getItemCount(GameItemType type) {
    return items[type] ?? 0;
  }

  /// 获取总使用次数
  int getTotalUsed(GameItemType type) {
    return totalUsed[type] ?? 0;
  }

  /// 获取最后使用时间
  DateTime? getLastUsed(GameItemType type) {
    return lastUsed[type];
  }

  /// 是否有道具
  bool hasItem(GameItemType type) {
    return getItemCount(type) > 0;
  }

  /// 是否可以解锁
  bool canUnlock(GameItemType type, int currentLevel) {
    final item = GameItemData.getItem(type);
    return currentLevel >= item.unlockLevel;
  }
}

/// 道具使用记录
class ItemUsageRecord {
  final GameItemType type;
  final DateTime usedAt;
  final int level;
  final bool success;
  final Map<String, dynamic> metadata;

  const ItemUsageRecord({
    required this.type,
    required this.usedAt,
    required this.level,
    required this.success,
    this.metadata = const {},
  });
}

/// 预定义道具数据
class GameItemData {
  static const List<GameItem> allItems = [
    GameItem(
      type: GameItemType.undo,
      name: '撤销',
      description: '撤销上一步操作',
      iconPath: 'assets/items/undo.png',
      maxQuantity: 99,
      unlockLevel: 1,
    ),
    GameItem(
      type: GameItemType.clear,
      name: '清除',
      description: '清除所有操作',
      iconPath: 'assets/items/clear.png',
      maxQuantity: 99,
      unlockLevel: 1,
    ),
    GameItem(
      type: GameItemType.hint,
      name: '提示',
      description: '获得游戏提示',
      iconPath: 'assets/items/hint.png',
      maxQuantity: 99,
      unlockLevel: 1,
    ),
    GameItem(
      type: GameItemType.bottle,
      name: '添加',
      description: '添加额外道具',
      iconPath: 'assets/items/add.png',
      maxQuantity: 99,
      unlockLevel: 1,
    ),
  ];

  /// 根据类型获取道具
  static GameItem getItem(GameItemType type) {
    return allItems.firstWhere((item) => item.type == type);
  }

  /// 获取所有道具
  static List<GameItem> getAllItems() {
    return allItems;
  }

  /// 根据关卡获取可用道具
  static List<GameItem> getAvailableItems(int level) {
    return allItems.where((item) => level >= item.unlockLevel).toList();
  }
}
