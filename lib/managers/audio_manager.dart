import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../utils/audio_assets.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  late AudioPlayer _bgmPlayer;
  late AudioPlayer _sfxPlayer;
  
  String? _currentBgm;
  bool _isMuted = false;
  double _bgmVolume = 0.7;
  double _sfxVolume = 1.0;

  Future<void> initialize() async {
    _bgmPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();
    
    // Set player modes
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    
    // Start with main background music
    await playBackgroundMusic(AudioAssets.bgmMain);
  }

  // Background Music Methods
  Future<void> playBackgroundMusic(String audioPath) async {
    if (_isMuted || _currentBgm == audioPath) return;
    
    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.play(AssetSource(audioPath));
      _currentBgm = audioPath;
      if (kDebugMode) {
        print('Playing BGM: $audioPath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing BGM: $e');
      }
    }
  }

  Future<void> stopBackgroundMusic() async {
    await _bgmPlayer.stop();
    _currentBgm = null;
  }

  Future<void> pauseBackgroundMusic() async {
    await _bgmPlayer.pause();
  }

  Future<void> resumeBackgroundMusic() async {
    await _bgmPlayer.resume();
  }

  // Sound Effects Methods
  Future<void> playSoundEffect(String audioPath) async {
    if (_isMuted) return;
    
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource(audioPath));
      if (kDebugMode) {
        print('Playing SFX: $audioPath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing SFX: $e');
      }
    }
  }

  // Convenience methods for common UI sounds
  Future<void> playPopupOpen() async {
    await playSoundEffect(AudioAssets.popupOpen);
  }

  Future<void> playExit() async {
    await playSoundEffect(AudioAssets.exit);
  }

  Future<void> playSwitch() async {
    await playSoundEffect(AudioAssets.switchButton);
  }

  Future<void> playCheckIn() async {
    await playSoundEffect(AudioAssets.checkIn);
  }

  Future<void> playBuySuccess() async {
    await playSoundEffect(AudioAssets.buySuccess);
  }

  Future<void> playBuyFailed() async {
    await playSoundEffect(AudioAssets.buyFailed);
  }

  Future<void> playClothingButton() async {
    await playSoundEffect(AudioAssets.clothingButton);
  }

  // Girl-specific sounds
  Future<void> playTakeoffSound(int girlIndex, int takeoffIndex) async {
    final maxSounds = AudioAssets.getMaxTakeoffSounds(girlIndex);
    if (takeoffIndex < maxSounds) {
      final soundPath = AudioAssets.getTakeoffSound(girlIndex, takeoffIndex);
      await playSoundEffect(soundPath);
    }
  }

  Future<void> playRandomIdlespSound(int girlIndex) async {
    final soundPath = AudioAssets.getRandomIdlespSound(girlIndex);
    await playSoundEffect(soundPath);
  }

  // Game sounds
  Future<void> playBottlePour() async {
    await playSoundEffect(AudioAssets.bottlePour);
  }

  Future<void> playBottleCap() async {
    await playSoundEffect(AudioAssets.bottleCap);
  }

  Future<void> playItemUse() async {
    await playSoundEffect(AudioAssets.itemUse);
  }

  // Settlement sounds
  Future<void> playSettlementCoin() async {
    await playSoundEffect(AudioAssets.settlementCoin);
  }

  Future<void> playProgressBar() async {
    await playSoundEffect(AudioAssets.progressBar);
  }

  Future<void> playNewPhoto() async {
    await playSoundEffect(AudioAssets.newPhoto);
  }

  Future<void> playSettlementHeart() async {
    await playSoundEffect(AudioAssets.settlementHeart);
  }

  // Special effect sounds
  Future<void> playHeartEffect() async {
    await playSoundEffect(AudioAssets.heartEffect);
  }

  Future<void> playCoinEffect() async {
    await playSoundEffect(AudioAssets.coinEffect);
  }

  Future<void> playSpecialEffect() async {
    await playSoundEffect(AudioAssets.specialEffect);
  }

  // Volume and Settings
  void setBgmVolume(double volume) {
    _bgmVolume = volume.clamp(0.0, 1.0);
    _bgmPlayer.setVolume(_bgmVolume);
  }

  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      _bgmPlayer.setVolume(0.0);
    } else {
      _bgmPlayer.setVolume(_bgmVolume);
    }
  }

  bool get isMuted => _isMuted;
  double get bgmVolume => _bgmVolume;
  double get sfxVolume => _sfxVolume;
  String? get currentBgm => _currentBgm;

  // Switch to Preview BGM
  Future<void> switchToPreviewMode() async {
    await playBackgroundMusic(AudioAssets.bgmPreview);
  }

  // Switch back to Main BGM
  Future<void> switchToMainMode() async {
    await playBackgroundMusic(AudioAssets.bgmMain);
  }

  // Cleanup
  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
  }
}