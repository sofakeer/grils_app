import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'audio_service.dart';

/// 默认音频服务实现
class DefaultAudioService implements AudioService {
  late final AudioPlayer _soundPlayer;
  late final AudioPlayer _musicPlayer;

  BackgroundMusicType? _currentBackgroundMusic;
  bool _isSoundMuted = false;
  bool _isMusicMuted = false;
  double _soundVolume = 1.0;
  double _musicVolume = 0.5; // 背景音乐默认音量稍低

  DefaultAudioService() {
    _initializePlayers();
  }

  void _initializePlayers() {
    _soundPlayer = AudioPlayer();
    _musicPlayer = AudioPlayer();

    // 设置音量
    _soundPlayer.setVolume(_soundVolume);
    _musicPlayer.setVolume(_musicVolume);

    // 设置背景音乐循环
    _musicPlayer.setReleaseMode(ReleaseMode.loop);

    // 监听背景音乐播放完成事件
    _musicPlayer.onPlayerComplete.listen((_) {
      // 如果设置了循环，这里不会触发
    });
  }

  @override
  Future<void> playSound(SoundType soundType) async {
    if (_isSoundMuted) return;

    try {
      final path = AudioPaths.getSoundPath(soundType);
      if (path.isEmpty) return;

      await _soundPlayer.play(AssetSource(path));
    } catch (e) {
      print('播放音效失败: $e');
    }
  }

  @override
  Future<void> playBackgroundMusic(BackgroundMusicType musicType) async {
    if (_isMusicMuted) return;

    try {
      final path = AudioPaths.getMusicPath(musicType);
      if (path.isEmpty) {
        print('背景音乐文件不存在: $musicType');
        return;
      }

      // 检查当前音乐播放状态
      final currentState = _musicPlayer.state;
      final isPlaying = currentState == PlayerState.playing;
      final isPaused = currentState == PlayerState.paused;

      print('当前播放状态: $currentState, 当前音乐: $_currentBackgroundMusic, 目标音乐: $musicType');

      // 如果已经在播放相同的音乐，不需要重新播放
      if (_currentBackgroundMusic == musicType && isPlaying) {
        print('已在播放相同的背景音乐: $musicType，跳过');
        return;
      }

      // 如果是相同的音乐但暂停了，恢复播放
      if (_currentBackgroundMusic == musicType && isPaused) {
        print('恢复播放相同的背景音乐: $musicType');
        await _musicPlayer.resume();
        return;
      }

      // 如果正在播放其他音乐，先停止
      if (isPlaying && _currentBackgroundMusic != null && _currentBackgroundMusic != musicType) {
        print('停止当前背景音乐: $_currentBackgroundMusic');
        await _musicPlayer.stop();
      }

      // 播放新的背景音乐
      await _musicPlayer.play(AssetSource(path));
      _currentBackgroundMusic = musicType;
      print('开始播放背景音乐: $musicType');
    } catch (e) {
      print('播放背景音乐失败: $e');
    }
  }

  @override
  Future<void> stopBackgroundMusic() async {
    try {
      await _musicPlayer.stop();
      _currentBackgroundMusic = null;
    } catch (e) {
      print('停止背景音乐失败: $e');
    }
  }

  @override
  Future<void> pauseBackgroundMusic() async {
    try {
      await _musicPlayer.pause();
    } catch (e) {
      print('暂停背景音乐失败: $e');
    }
  }

  @override
  Future<void> resumeBackgroundMusic() async {
    if (_isMusicMuted) return;

    try {
      final currentState = _musicPlayer.state;
      print('尝试恢复背景音乐，当前状态: $currentState');

      if (currentState == PlayerState.paused) {
        await _musicPlayer.resume();
        print('背景音乐已恢复');
      } else if (currentState == PlayerState.stopped && _currentBackgroundMusic != null) {
        // 如果音乐被停止了，重新播放
        print('背景音乐被停止，重新播放: $_currentBackgroundMusic');
        await playBackgroundMusic(_currentBackgroundMusic!);
      } else if (currentState == PlayerState.playing) {
        print('背景音乐已在播放中');
      }
    } catch (e) {
      print('恢复背景音乐失败: $e');
      // 尝试重新播放
      if (_currentBackgroundMusic != null) {
        try {
          await playBackgroundMusic(_currentBackgroundMusic!);
        } catch (retryError) {
          print('重新播放背景音乐也失败: $retryError');
        }
      }
    }
  }

  @override
  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume.clamp(0.0, 1.0);
    try {
      await _soundPlayer.setVolume(_soundVolume);
    } catch (e) {
      print('设置音效音量失败: $e');
    }
  }

  @override
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    try {
      await _musicPlayer.setVolume(_musicVolume);
    } catch (e) {
      print('设置背景音乐音量失败: $e');
    }
  }

  @override
  Future<void> setSoundMuted(bool muted) async {
    _isSoundMuted = muted;
    if (muted) {
      try {
        await _soundPlayer.stop();
      } catch (e) {
        print('静音音效失败: $e');
      }
    }
  }

  @override
  Future<void> setMusicMuted(bool muted) async {
    _isMusicMuted = muted;
    if (muted) {
      try {
        await _musicPlayer.pause();
      } catch (e) {
        print('静音背景音乐失败: $e');
      }
    } else if (_currentBackgroundMusic != null) {
      // 取消静音时恢复播放
      await resumeBackgroundMusic();
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _soundPlayer.dispose();
      await _musicPlayer.dispose();
    } catch (e) {
      print('释放音频资源失败: $e');
    }
  }

  @override
  BackgroundMusicType? get currentBackgroundMusic => _currentBackgroundMusic;

  @override
  bool get isSoundMuted => _isSoundMuted;

  @override
  bool get isMusicMuted => _isMusicMuted;
}

/// 空音频服务实现（用于测试或静音模式）
class SilentAudioService implements AudioService {
  @override
  Future<void> playSound(SoundType soundType) async {
    // 不播放任何声音
  }

  @override
  Future<void> playBackgroundMusic(BackgroundMusicType musicType) async {
    // 不播放任何声音
  }

  @override
  Future<void> stopBackgroundMusic() async {}

  @override
  Future<void> pauseBackgroundMusic() async {}

  @override
  Future<void> resumeBackgroundMusic() async {}

  @override
  Future<void> setSoundVolume(double volume) async {}

  @override
  Future<void> setMusicVolume(double volume) async {}

  @override
  Future<void> setSoundMuted(bool muted) async {}

  @override
  Future<void> setMusicMuted(bool muted) async {}

  @override
  Future<void> dispose() async {}

  @override
  BackgroundMusicType? get currentBackgroundMusic => null;

  @override
  bool get isSoundMuted => true;

  @override
  bool get isMusicMuted => true;
}