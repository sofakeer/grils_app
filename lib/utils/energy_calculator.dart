class EnergyCalculator {
  /// 根据关卡计算每关获得的能量值 (测试版本 - 增加数值以便快速看效果)
  static double calculateEnergyForLevel(int level) {
    if (level <= 10) {
      return 25.0; // 1-10关，每关增加能量值为25 (测试用，原值为1.0)
    } else if (level <= 20) {
      return 20.0; // 11-20关，每关增加能量值为20 (测试用，原值为0.5)
    } else if (level <= 40) {
      return 15.0; // 21-40关，每关增加能量值为15 (测试用，原值为0.3)
    } else if (level <= 100) {
      return 10.0; // 41-100关，每关增加能量值为10 (测试用，原值为0.15)
    } else if (level <= 200) {
      return 8.0; // 101-200关，每关增加能量值为8 (测试用，原值为0.1)
    } else {
      return 5.0; // 200关之后，每关增加能量值为5 (测试用，原值为0.05)
    }
  }

  /// 计算进度百分比（0.0 到 1.0）
  static double calculateProgress(double currentEnergy) {
    // 能量上限为100，返回0.0到1.0的进度
    return (currentEnergy / 100.0).clamp(0.0, 1.0);
  }

  /// 添加能量值，确保不超过上限100
  static double addEnergy(double currentEnergy, double addedEnergy) {
    return (currentEnergy + addedEnergy).clamp(0.0, 100.0);
  }

  /// 检查是否达到100%完成度
  static bool isCompleted(double currentEnergy) {
    return currentEnergy >= 100.0;
  }

  /// 获取关卡对应的能量奖励描述
  static String getEnergyRewardDescription(int level) {
    double energy = calculateEnergyForLevel(level);
    String range = _getLevelRange(level);
    return '$range: $energy energy per level';
  }

  static String _getLevelRange(int level) {
    if (level <= 10) return 'Level 1-10';
    if (level <= 20) return 'Level 11-20';
    if (level <= 40) return 'Level 21-40';
    if (level <= 100) return 'Level 41-100';
    if (level <= 200) return 'Level 101-200';
    return 'Level 200+';
  }

  /// 获取所有能量奖励等级的完整列表 (测试版本)
  static List<Map<String, dynamic>> getAllEnergyRewards() {
    return [
      {'range': 'Level 1-10', 'energy': 25.0},
      {'range': 'Level 11-20', 'energy': 20.0},
      {'range': 'Level 21-40', 'energy': 15.0},
      {'range': 'Level 41-100', 'energy': 10.0},
      {'range': 'Level 101-200', 'energy': 8.0},
      {'range': 'Level 200+', 'energy': 5.0},
    ];
  }
}