// 女孩状态管理
enum GirlMode {
  normal,    // 普通模式 (idle_01 到 idle_04)
  underwear, // 换装模式 (idle_underwear)
}

enum AnimationType {
  idle,     // 待机动画 (idle_01, idle_02, etc.)
  special,  // 特殊待机动画 (idlesp_01, idlesp_02, etc.)
  takeoff,  // 脱衣动画 (take_off_01, take_off_02, etc.)
  underwear, // 换装模式动画
}

class GirlState {
  final int girlIndex;           // 女孩索引 (0, 1, 2)
  final int skinLevel;           // 当前皮肤等级 (1-4 或 1-5 for Girl03)
  final GirlMode mode;           // 当前模式
  final AnimationType currentAnimationType; // 当前动画类型
  final bool isPlayingSpecial;   // 是否正在播放特殊动画
  final int maxSkinLevels;       // 最大皮肤等级

  const GirlState({
    required this.girlIndex,
    this.skinLevel = 1,
    this.mode = GirlMode.normal,
    this.currentAnimationType = AnimationType.idle,
    this.isPlayingSpecial = false,
    required this.maxSkinLevels,
  });

  // Girl01, Girl02: 4次换肤
  // Girl03: 5次换肤
  static int getMaxSkinLevels(int girlIndex) {
    return girlIndex == 2 ? 5 : 4; // Girl03 (index 2) 有 5 次换肤
  }

  GirlState copyWith({
    int? girlIndex,
    int? skinLevel,
    GirlMode? mode,
    AnimationType? currentAnimationType,
    bool? isPlayingSpecial,
    int? maxSkinLevels,
  }) {
    return GirlState(
      girlIndex: girlIndex ?? this.girlIndex,
      skinLevel: skinLevel ?? this.skinLevel,
      mode: mode ?? this.mode,
      currentAnimationType: currentAnimationType ?? this.currentAnimationType,
      isPlayingSpecial: isPlayingSpecial ?? this.isPlayingSpecial,
      maxSkinLevels: maxSkinLevels ?? this.maxSkinLevels,
    );
  }

  // 获取当前应该播放的动画名称
  String getCurrentAnimationName() {
    switch (mode) {
      case GirlMode.normal:
        if (isPlayingSpecial) {
          return 'idlesp_${skinLevel.toString().padLeft(2, '0')}';
        } else {
          return 'idle_${skinLevel.toString().padLeft(2, '0')}';
        }
      case GirlMode.underwear:
        if (isPlayingSpecial) {
          return 'idlesp_underwear';
        } else {
          return 'idle_underwear';
        }
    }
  }

  // 获取脱衣动画名称
  String getTakeoffAnimationName() {
    return 'take_off_${skinLevel.toString().padLeft(2, '0')}';
  }

  // 是否已经到达最后一个皮肤等级
  bool isMaxSkinLevel() {
    return skinLevel >= maxSkinLevels;
  }

  // 是否可以进行下一次换肤
  bool canTakeoff() {
    return mode == GirlMode.normal && skinLevel < maxSkinLevels;
  }

  // 获取下一个皮肤等级
  int getNextSkinLevel() {
    if (skinLevel < maxSkinLevels) {
      return skinLevel + 1;
    }
    return skinLevel;
  }

  // 获取音效文件名
  String getAudioFileName() {
    final girlNumber = girlIndex + 1; // Girl01, Girl02, Girl03
    if (mode == GirlMode.underwear) {
      return 'girl${girlNumber}_underwear.mp3';
    } else {
      return 'girl${girlNumber}_special.mp3';
    }
  }
}

// 音频资源管理
class AudioAssets {
  // 每个女孩的特殊动画音效
  static const String girl1Special = 'audio/girl1_special.mp3';
  static const String girl2Special = 'audio/girl2_special.mp3';
  static const String girl3Special = 'audio/girl3_special.mp3';
  
  // 每个女孩的换装模式音效
  static const String girl1Underwear = 'audio/girl1_underwear.mp3';
  static const String girl2Underwear = 'audio/girl2_underwear.mp3';
  static const String girl3Underwear = 'audio/girl3_underwear.mp3';

  static String getSpecialAudio(int girlIndex) {
    switch (girlIndex) {
      case 0: return girl1Special;
      case 1: return girl2Special;
      case 2: return girl3Special;
      default: return girl1Special;
    }
  }

  static String getUnderwearAudio(int girlIndex) {
    switch (girlIndex) {
      case 0: return girl1Underwear;
      case 1: return girl2Underwear;
      case 2: return girl3Underwear;
      default: return girl1Underwear;
    }
  }
}