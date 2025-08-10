import 'dart:math';

class AudioAssets {
  // Background Music
  static const String bgmMain = 'audio/bgm02.mp3';  // 主界面和其他界面背景音乐
  static const String bgmPreview = 'audio/bgm01.mp3';  // Gril换装界面背景音乐

  // UI Sound Effects
  static const String popupOpen = 'audio/tanchuang01.mp3';  // 弹窗打开音效
  static const String exit = 'audio/tuichu01.mp3';  // 退出界面音效
  static const String switchButton = 'audio/qiehuan01.mp3';  // 切换按键音效
  static const String checkIn = 'audio/qiandao01.mp3';  // 签到音效
  static const String buySuccess = 'audio/goumai01.mp3';  // 购买成功音效
  static const String buyFailed = 'audio/goumai02.mp3';  // 购买失败音效
  static const String clothingButton = 'audio/yigui01.mp3';  // 部位按键音效

  // Game Sound Effects
  static const String bottlePour = 'audio/pingzi01.mp3';  // 瓶子倒小球音效
  static const String bottleCap = 'audio/pingzi02.mp3';  // 瓶子加盖子音效
  static const String itemUse = 'audio/daoju01.mp3';  // 道具使用音效

  // Settlement Sound Effects
  static const String settlementCoin = 'audio/jiesuan01.mp3';  // 结算获得金币音效
  static const String progressBar = 'audio/jindutiao01.mp3';  // 进度条音效
  static const String newPhoto = 'audio/xinzhaopian01.mp3';  // 解锁新照片音效
  static const String settlementHeart = 'audio/jiesuan02.mp3';  // 获取桃心币音效

  // Special Effects
  static const String heartEffect = 'audio/taoxin01.mp3';  // 获得桃心币特效音效
  static const String coinEffect = 'audio/jinbi01.mp3';  // 获得金币特效音效

  // Girl Takeoff Sounds
  static String getTakeoffSound(int girlIndex, int takeoffIndex) {
    final girlNumber = girlIndex + 1;
    final soundNumber = takeoffIndex + 1;
    return 'audio/Gril0${girlNumber}_takeoff_sound0$soundNumber.wav';
  }

  // Girl Special Idle Sounds (随机播放)
  static String getRandomIdlespSound(int girlIndex) {
    final girlNumber = girlIndex + 1;
    final soundNumber = Random().nextInt(5) + 1;  // 1-5随机
    return 'audio/Gril0${girlNumber}_idlesp_sound0$soundNumber.mp3';
  }

  // Get all idle special sounds for a girl
  static List<String> getAllIdlespSounds(int girlIndex) {
    final girlNumber = girlIndex + 1;
    return List.generate(5, (index) => 
        'audio/Gril0${girlNumber}_idlesp_sound0${index + 1}.mp3');
  }

  // Get maximum takeoff sounds count for each girl
  static int getMaxTakeoffSounds(int girlIndex) {
    if (girlIndex == 0 || girlIndex == 1) {
      return 4;  // Girl01 and Girl02 have 4 takeoff sounds
    } else if (girlIndex == 2) {
      return 5;  // Girl03 has 5 takeoff sounds
    }
    return 4;  // Default
  }

  // Legacy methods for backward compatibility
  static String getSpecialAudio(int girlIndex) {
    final girlNumber = girlIndex + 1;
    return 'audio/girl${girlNumber}_special.mp3';
  }

  static String getUnderwearAudio(int girlIndex) {
    final girlNumber = girlIndex + 1;
    return 'audio/girl${girlNumber}_underwear.mp3';
  }
}