class EnergyCalculator {
  /// 【关键代码】按照关卡顺序解锁的new photo增长值 - 根据关卡调整照片解锁进度
  static double calculateEnergyForLevel(int level) {
    if (level <= 10) {
      return 1.0; // 1-10关，每关增加能量值为1.0
    } else if (level <= 20) {
      return 0.5; // 11-20关，每关增加能量值为0.5
    } else if (level <= 40) {
      return 0.3; // 21-40关，每关增加能量值为0.3
    } else if (level <= 100) {
      return 0.15; // 41-100关，每关增加能量值为0.15
    } else if (level <= 200) {
      return 0.1; // 101-200关，每关增加能量值为0.1
    } else {
      return 0.05; // 200关之后，每关增加能量值为0.05
    }
  }

  /// 归一化能量值，兼容旧版(0-100)和新版(0-1)存储
  static double normalizeEnergy(double energy) {
    if (energy.isNaN || energy <= 0.0) {
      return 0.0;
    }
    if (energy > 1.0) {
      // 旧版本使用0-100区间，转换为0-1
      return (energy / 100.0).clamp(0.0, 1.0);
    }
    return energy.clamp(0.0, 1.0);
  }

  /// 计算进度百分比（0.0 到 1.0）
  static double calculateProgress(double currentEnergy) {
    return normalizeEnergy(currentEnergy).clamp(0.0, 1.0);
  }

  /// 添加能量值，确保不超过 1.0
  static double addEnergy(double currentEnergy, double addedEnergy) {
    final normalizedCurrent = normalizeEnergy(currentEnergy);
    final safeAdded = addedEnergy.isNaN ? 0.0 : addedEnergy;
    return (normalizedCurrent + safeAdded).clamp(0.0, 1.0);
  }

  /// 检查是否达到100%完成度
  static bool isCompleted(double currentEnergy) {
    return normalizeEnergy(currentEnergy) >= 1.0;
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

  /// 获取所有能量奖励等级的完整列表
  static List<Map<String, dynamic>> getAllEnergyRewards() {
    return [
      {'range': 'Level 1-10', 'energy': 1.0},
      {'range': 'Level 11-20', 'energy': 0.5},
      {'range': 'Level 21-40', 'energy': 0.3},
      {'range': 'Level 41-100', 'energy': 0.15},
      {'range': 'Level 101-200', 'energy': 0.1},
      {'range': 'Level 200+', 'energy': 0.05},
    ];
  }
}
