import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import '../core/locator.dart';
import '../services/audio/audio_service.dart';
import '../services/storage/prefs_service.dart';
import 'vibration_providers.dart';
import 'app_providers.dart';

/// 音频服务 Provider
final audioServiceProvider = Provider<AudioService>((ref) {
  return ServiceLocator.instance.get<AudioService>();
});

const _soundMutedPrefsKey = 'audio.sound_muted';
const _musicMutedPrefsKey = 'audio.music_muted';

/// 音频状态管理器
class AudioNotifier extends StateNotifier<AudioState> {
  final AudioService _audioService;
  final PrefsService _prefs;

  AudioNotifier(this._audioService, this._prefs) : super(const AudioState()) {
    _restorePersistedSettings();
  }

  void _restorePersistedSettings() {
    final soundMuted = _prefs.getBool(_soundMutedPrefsKey) ?? false;
    final musicMuted = _prefs.getBool(_musicMutedPrefsKey) ?? false;

    state = state.copyWith(
      isSoundMuted: soundMuted,
      isMusicMuted: musicMuted,
    );

    Future.microtask(() async {
      await _audioService.setSoundMuted(soundMuted);
      await _audioService.setMusicMuted(musicMuted);
    });
  }

  /// 播放音效
  Future<void> playSound(SoundType soundType) async {
    await _audioService.playSound(soundType);
  }

  /// 播放背景音乐
  Future<void> playBackgroundMusic(BackgroundMusicType musicType) async {
    await _audioService.playBackgroundMusic(musicType);
    state = state.copyWith(currentBackgroundMusic: musicType);
  }

  /// 播放随机游戏背景音乐
  Future<void> playRandomGamingMusic() async {
    final musicType = AudioPaths.getRandomGamingMusic();
    await playBackgroundMusic(musicType);
  }

  /// 停止背景音乐
  Future<void> stopBackgroundMusic() async {
    await _audioService.stopBackgroundMusic();
    state = state.copyWith(currentBackgroundMusic: null);
  }

  /// 暂停背景音乐
  Future<void> pauseBackgroundMusic() async {
    await _audioService.pauseBackgroundMusic();
  }

  /// 恢复背景音乐
  Future<void> resumeBackgroundMusic() async {
    await _audioService.resumeBackgroundMusic();
  }

  /// 设置音效音量
  Future<void> setSoundVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    await _audioService.setSoundVolume(clampedVolume);
    state = state.copyWith(soundVolume: clampedVolume);
  }

  /// 设置背景音乐音量
  Future<void> setMusicVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    await _audioService.setMusicVolume(clampedVolume);
    state = state.copyWith(musicVolume: clampedVolume);
  }

  /// 静音/取消静音音效
  Future<void> setSoundMuted(bool muted) async {
    await _audioService.setSoundMuted(muted);
    state = state.copyWith(isSoundMuted: muted);
    await _prefs.setBool(_soundMutedPrefsKey, muted);
  }

  /// 静音/取消静音背景音乐
  Future<void> setMusicMuted(bool muted) async {
    await _audioService.setMusicMuted(muted);
    state = state.copyWith(isMusicMuted: muted);
    await _prefs.setBool(_musicMutedPrefsKey, muted);
  }

  /// 切换音效静音状态
  Future<void> toggleSoundMuted() async {
    await setSoundMuted(!state.isSoundMuted);
  }

  /// 切换背景音乐静音状态
  Future<void> toggleMusicMuted() async {
    await setMusicMuted(!state.isMusicMuted);
  }

  /// 更新音频状态（从服务同步）
  void updateState() {
    state = AudioState(
      currentBackgroundMusic: _audioService.currentBackgroundMusic,
      isSoundMuted: _audioService.isSoundMuted,
      isMusicMuted: _audioService.isMusicMuted,
      soundVolume: state.soundVolume, // 保持当前音量设置
      musicVolume: state.musicVolume, // 保持当前音量设置
    );
  }
}

/// 音频状态 Provider
final audioStateProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  final prefs = ref.watch(prefsServiceProvider);
  return AudioNotifier(audioService, prefs);
});

/// 音频状态数据类
class AudioState {
  final BackgroundMusicType? currentBackgroundMusic;
  final bool isSoundMuted;
  final bool isMusicMuted;
  final double soundVolume;
  final double musicVolume;

  const AudioState({
    this.currentBackgroundMusic,
    this.isSoundMuted = false,
    this.isMusicMuted = false,
    this.soundVolume = 1.0,
    this.musicVolume = 0.5,
  });

  AudioState copyWith({
    BackgroundMusicType? currentBackgroundMusic,
    bool? isSoundMuted,
    bool? isMusicMuted,
    double? soundVolume,
    double? musicVolume,
  }) {
    return AudioState(
      currentBackgroundMusic: currentBackgroundMusic ?? this.currentBackgroundMusic,
      isSoundMuted: isSoundMuted ?? this.isSoundMuted,
      isMusicMuted: isMusicMuted ?? this.isMusicMuted,
      soundVolume: soundVolume ?? this.soundVolume,
      musicVolume: musicVolume ?? this.musicVolume,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioState &&
          runtimeType == other.runtimeType &&
          currentBackgroundMusic == other.currentBackgroundMusic &&
          isSoundMuted == other.isSoundMuted &&
          isMusicMuted == other.isMusicMuted &&
          soundVolume == other.soundVolume &&
          musicVolume == other.musicVolume;

  @override
  int get hashCode =>
      currentBackgroundMusic.hashCode ^
      isSoundMuted.hashCode ^
      isMusicMuted.hashCode ^
      soundVolume.hashCode ^
      musicVolume.hashCode;
}

/// 便捷方法 Provider
class AudioActions {
  static Future<void> playClickSound(WidgetRef ref) async {
    await ref.read(audioStateProvider.notifier).playSound(SoundType.click);
    // 添加点击震动（如果启用）
    await VibrationActions.vibrate(ref);
  }

  static Future<void> playClickBollSound(WidgetRef ref) async {
    await ref.read(audioStateProvider.notifier).playSound(SoundType.clickBoll);
    await VibrationActions.vibrate(ref);
  }

  static Future<void> playSuccessSound(WidgetRef ref) async {
    await ref.read(audioStateProvider.notifier).playSound(SoundType.success);
    await VibrationActions.vibrateSuccess(ref);
  }

  static Future<void> playFailSound(WidgetRef ref) async {
    await ref.read(audioStateProvider.notifier).playSound(SoundType.fail);
    await VibrationActions.vibrateFail(ref);
  }

  static Future<void> playHomeMusic(WidgetRef ref) async {
    // await ref.read(audioStateProvider.notifier).playBackgroundMusic(BackgroundMusicType.home);
  }

  static Future<void> playGamingMusic(WidgetRef ref) async {
    await ref.read(audioStateProvider.notifier).playRandomGamingMusic();
  }

  static Future<void> stopMusic(WidgetRef ref) async {
    await ref.read(audioStateProvider.notifier).stopBackgroundMusic();
  }

  static Future<void> toggleSoundMuted(WidgetRef ref) async {
    await ref.read(audioStateProvider.notifier).toggleSoundMuted();
    await VibrationActions.vibrate(ref);
  }

  static Future<void> toggleMusicMuted(WidgetRef ref) async {
    await ref.read(audioStateProvider.notifier).toggleMusicMuted();
    await VibrationActions.vibrate(ref);
  }
}
