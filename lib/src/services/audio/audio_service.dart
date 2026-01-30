/// 音频服务接口
abstract class AudioService {
  /// 播放音效
  Future<void> playSound(SoundType soundType);

  /// 播放背景音乐
  Future<void> playBackgroundMusic(BackgroundMusicType musicType);

  /// 停止背景音乐
  Future<void> stopBackgroundMusic();

  /// 暂停背景音乐
  Future<void> pauseBackgroundMusic();

  /// 恢复背景音乐
  Future<void> resumeBackgroundMusic();

  /// 设置音效音量 (0.0 - 1.0)
  Future<void> setSoundVolume(double volume);

  /// 设置背景音乐音量 (0.0 - 1.0)
  Future<void> setMusicVolume(double volume);

  /// 静音/取消静音音效
  Future<void> setSoundMuted(bool muted);

  /// 静音/取消静音背景音乐
  Future<void> setMusicMuted(bool muted);

  /// 释放资源
  Future<void> dispose();

  /// 获取当前背景音乐类型
  BackgroundMusicType? get currentBackgroundMusic;

  /// 获取音效是否静音
  bool get isSoundMuted;

  /// 获取背景音乐是否静音
  bool get isMusicMuted;
}

/// 音效类型
enum SoundType {
  click,     // 点击音效 (click.mp3)
  clickBoll, // 点击球音效 (click_boll.mp3)
  success,   // 成功音效 (success.mp3)
  fail,      // 失败音效 (使用success.mp3，因为只有这一个文件)
}

/// 背景音乐类型
enum BackgroundMusicType {
  home,    // 主页背景音乐 (home.mp3)
  gaming2, // 游戏音乐2 (gaming2.mp3)
  gaming3, // 游戏音乐3 (gaming3.mp3)
}

/// 音频文件路径映射
class AudioPaths {
  static const Map<SoundType, String> soundPaths = {
    SoundType.click: 'voice/click.mp3',
    SoundType.clickBoll: 'voice/click_boll.mp3',
    SoundType.success: 'voice/success.mp3',
    SoundType.fail: 'voice/success.mp3', // 失败音效也使用success.mp3
  };

  static const Map<BackgroundMusicType, String> musicPaths = {
    BackgroundMusicType.home: 'voice/home.mp3',
    BackgroundMusicType.gaming2: 'voice/gaming2.mp3',
    BackgroundMusicType.gaming3: 'voice/gaming3.mp3',
  };

  static String getSoundPath(SoundType type) {
    return soundPaths[type] ?? '';
  }

  static String getMusicPath(BackgroundMusicType type) {
    return musicPaths[type] ?? '';
  }

  /// 获取随机游戏音乐
  static BackgroundMusicType getRandomGamingMusic() {
    final gamingMusics = [
      BackgroundMusicType.gaming2,
      BackgroundMusicType.gaming3,
    ];
    gamingMusics.shuffle();
    return gamingMusics.first;
  }
}