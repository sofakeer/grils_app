class CoinCalculator {
  static int calculateCoinsForLevel(int level) {
    if (level <= 10) {
      return 10; // 0-10关，每关10硬币
    } else if (level <= 30) {
      return 15; // 11-30关，每关15硬币
    } else if (level <= 60) {
      return 20; // 31-60关，每关20硬币
    } else if (level <= 100) {
      return 25; // 61-100关，每关25硬币
    } else if (level <= 200) {
      return 30; // 101-200关，每关30硬币
    } else if (level <= 300) {
      return 35; // 201-300关，每关35硬币
    } else if (level <= 400) {
      return 40; // 301-400关，每关40硬币
    } else if (level <= 500) {
      return 45; // 401-500关，每关45硬币
    } else {
      return 50; // 500关之后，每关50硬币
    }
  }

  /// 计算从起始关卡到结束关卡的总金币数
  static int calculateTotalCoins(int startLevel, int endLevel) {
    int totalCoins = 0;
    for (int level = startLevel; level <= endLevel; level++) {
      totalCoins += calculateCoinsForLevel(level);
    }
    return totalCoins;
  }

  /// 获取关卡对应的金币奖励描述
  static String getCoinRewardDescription(int level) {
    int coins = calculateCoinsForLevel(level);
    String range = _getLevelRange(level);
    return '$range: $coins coins per level';
  }

  static String _getLevelRange(int level) {
    if (level <= 10) return 'Level 0-10';
    if (level <= 30) return 'Level 11-30';
    if (level <= 60) return 'Level 31-60';
    if (level <= 100) return 'Level 61-100';
    if (level <= 200) return 'Level 101-200';
    if (level <= 300) return 'Level 201-300';
    if (level <= 400) return 'Level 301-400';
    if (level <= 500) return 'Level 401-500';
    return 'Level 500+';
  }

  /// 获取所有奖励等级的完整列表
  static List<Map<String, dynamic>> getAllCoinRewards() {
    return [
      {'range': 'Level 0-10', 'coins': 10},
      {'range': 'Level 11-30', 'coins': 15},
      {'range': 'Level 31-60', 'coins': 20},
      {'range': 'Level 61-100', 'coins': 25},
      {'range': 'Level 101-200', 'coins': 30},
      {'range': 'Level 201-300', 'coins': 35},
      {'range': 'Level 301-400', 'coins': 40},
      {'range': 'Level 401-500', 'coins': 45},
      {'range': 'Level 500+', 'coins': 50},
    ];
  }
}