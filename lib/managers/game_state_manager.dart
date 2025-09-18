import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GameStateManager {
  static final GameStateManager _instance = GameStateManager._internal();
  factory GameStateManager() => _instance;
  GameStateManager._internal();

  late SharedPreferences _prefs;
  
  // 游戏状态键值
  static const String _keyHeartCount = 'heart_count';
  static const String _keyShowTakeoffGuide = 'show_takeoff_guide';
  static const String _keyCurrentGirlIndex = 'current_girl_index';
  static const String _keyCurrentIdleIndex = 'current_idle_index';
  static const String _keyUnlockedSkins = 'unlocked_skins';
  static const String _keyCurrentSkins = 'current_skins';
  static const String _keyHasSeenTakeoff = 'has_seen_takeoff';
  // 每个女孩是否看过Takeoff引导的前缀键：has_seen_takeoff_girl_{index}
  static const String _keyHasSeenTakeoffGirlPrefix = 'has_seen_takeoff_girl_';
  static const String _keyCurrentLevel = 'current_level';
  static const String _keyUnlockedGirls = 'unlocked_girls';
  static const String _keyPendingUnlockGirl = 'pending_unlock_girl';
  static const String _keyLastSpecialStageLevel = 'last_special_stage_level';
  static const String _keySpecialStageCompleted = 'special_stage_completed';
  
  // 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // 获取心形货币数量
  int getHeartCount() {
    return _prefs.getInt(_keyHeartCount) ?? 10000; // 初始给10000个心形
  }
  
  // 设置心形货币数量
  Future<void> setHeartCount(int count) async {
    await _prefs.setInt(_keyHeartCount, count);
  }
  
  // 增加心形货币
  Future<void> addHearts(int amount) async {
    int current = getHeartCount();
    await setHeartCount(current + amount);
  }
  
  // 消耗心形货币
  Future<bool> consumeHearts(int amount) async {
    int current = getHeartCount();
    if (current >= amount) {
      await setHeartCount(current - amount);
      return true;
    }
    return false;
  }
  
  // 获取是否已经看过Takeoff引导
  bool hasSeenTakeoffGuide() {
    return _prefs.getBool(_keyHasSeenTakeoff) ?? false;
  }
  
  // 设置已看过Takeoff引导
  Future<void> setHasSeenTakeoffGuide(bool seen) async {
    await _prefs.setBool(_keyHasSeenTakeoff, seen);
  }

  // 获取某个女孩是否已经看过Takeoff引导
  bool hasSeenTakeoffGuideForGirl(int girlIndex) {
    return _prefs.getBool('$_keyHasSeenTakeoffGirlPrefix$girlIndex') ?? false;
  }

  // 设置某个女孩已看过Takeoff引导
  Future<void> setHasSeenTakeoffGuideForGirl(int girlIndex, bool seen) async {
    await _prefs.setBool('$_keyHasSeenTakeoffGirlPrefix$girlIndex', seen);
  }
  
  // 获取当前女孩索引
  int getCurrentGirlIndex() {
    return _prefs.getInt(_keyCurrentGirlIndex) ?? 0;
  }
  
  // 设置当前女孩索引
  Future<void> setCurrentGirlIndex(int index) async {
    await _prefs.setInt(_keyCurrentGirlIndex, index);
  }
  
  // 获取当前idle动画索引
  int getCurrentIdleIndex() {
    return _prefs.getInt(_keyCurrentIdleIndex) ?? 0;
  }
  
  // 设置当前idle动画索引
  Future<void> setCurrentIdleIndex(int index) async {
    await _prefs.setInt(_keyCurrentIdleIndex, index);
  }
  
  // 获取已解锁的皮肤
  Map<String, List<int>> getUnlockedSkins() {
    String? jsonStr = _prefs.getString(_keyUnlockedSkins);
    if (jsonStr == null) {
      // 默认每个女孩的每个部位的第一个皮肤都是解锁的
      return {
        'girl0_bra': [0],
        'girl0_pants': [0],
        'girl0_hands': [0],
        'girl0_socks': [0],
        'girl1_bra': [0],
        'girl1_pants': [0],
        'girl1_head': [0],
        'girl1_socks': [0],
        'girl2_bra': [0],
        'girl2_pants': [0],
        'girl2_head': [0],
        'girl2_socks': [0],
      };
    }
    Map<String, dynamic> decoded = json.decode(jsonStr);
    return decoded.map((key, value) => MapEntry(key, List<int>.from(value)));
  }
  
  // 解锁皮肤
  Future<void> unlockSkin(int girlIndex, String partName, int skinIndex) async {
    Map<String, List<int>> unlocked = getUnlockedSkins();
    String key = 'girl${girlIndex}_$partName';
    
    if (!unlocked.containsKey(key)) {
      unlocked[key] = [0]; // 确保第一个皮肤总是解锁的
    }
    
    if (!unlocked[key]!.contains(skinIndex)) {
      unlocked[key]!.add(skinIndex);
    }
    
    await _prefs.setString(_keyUnlockedSkins, json.encode(unlocked));
  }
  
  // 检查皮肤是否已解锁
  bool isSkinUnlocked(int girlIndex, String partName, int skinIndex) {
    if (skinIndex == 0) return true; // 第一个皮肤总是解锁的
    
    Map<String, List<int>> unlocked = getUnlockedSkins();
    String key = 'girl${girlIndex}_$partName';
    
    if (!unlocked.containsKey(key)) {
      return false;
    }
    
    return unlocked[key]!.contains(skinIndex);
  }
  
  // 获取当前选择的皮肤
  Map<String, int> getCurrentSkins(int girlIndex) {
    String? jsonStr = _prefs.getString('${_keyCurrentSkins}_$girlIndex');
    if (jsonStr == null) {
      // 默认都选择第一个皮肤
      return {
        'bra': 0,
        'pants': 0,
        'hands': 0,
        'head': 0,
        'socks': 0,
      };
    }
    Map<String, dynamic> decoded = json.decode(jsonStr);
    return decoded.map((key, value) => MapEntry(key, value as int));
  }
  
  // 设置当前选择的皮肤
  Future<void> setCurrentSkin(int girlIndex, String partName, int skinIndex) async {
    Map<String, int> current = getCurrentSkins(girlIndex);
    current[partName] = skinIndex;
    await _prefs.setString('${_keyCurrentSkins}_$girlIndex', json.encode(current));
  }
  
  // 获取皮肤价格
  int getSkinPrice(int skinIndex) {
    // 第一个皮肤免费，其他皮肤根据索引递增价格
    if (skinIndex == 0) return 0;
    return skinIndex * 5; // 第2个皮肤5心币，第3个10心币，第4个15心币
  }
  
  // 重置游戏状态
  Future<void> resetGameState() async {
    await _prefs.clear();
    await init(); // 重新初始化
  }
  
  // 获取当前关卡
  int getCurrentLevel() {
    return _prefs.getInt(_keyCurrentLevel) ?? 1;
  }
  
  // 设置当前关卡
  Future<void> setCurrentLevel(int level) async {
    await _prefs.setInt(_keyCurrentLevel, level);
    
    // 检查是否需要解锁新女生
    await _checkAndUnlockGirls(level);
  }
  
  // 增加关卡
  Future<int> passLevel() async {
    int currentLevel = getCurrentLevel();
    int newLevel = currentLevel + 1;
    await setCurrentLevel(newLevel);
    return newLevel;
  }
  
  // 获取已解锁的女生列表
  List<int> getUnlockedGirls() {
    String? jsonStr = _prefs.getString(_keyUnlockedGirls);
    if (jsonStr == null) {
      // 默认只解锁第一个女生
      return [0];
    }
    List<int> unlocked = List<int>.from(json.decode(jsonStr));
    // 确保第一个女生总是解锁的
    if (!unlocked.contains(0)) {
      unlocked.insert(0, 0);
    }
    return unlocked;
  }
  
  // 解锁女生
  Future<void> unlockGirl(int girlIndex) async {
    List<int> unlocked = getUnlockedGirls();
    if (!unlocked.contains(girlIndex)) {
      unlocked.add(girlIndex);
      await _prefs.setString(_keyUnlockedGirls, json.encode(unlocked));
    }
  }
  
  // 检查女生是否已解锁
  bool isGirlUnlocked(int girlIndex) {
    if (girlIndex == 0) return true; // 第一个女生默认解锁
    return getUnlockedGirls().contains(girlIndex);
  }
  
  // 检查并解锁女生
  Future<int?> _checkAndUnlockGirls(int level) async {
    // 100关解锁第二个女生
    if (level >= 100 && !isGirlUnlocked(1)) {
      await unlockGirl(1);
      return 1; // 返回新解锁的女生索引
    }
    // 300关解锁第三个女生
    if (level >= 300 && !isGirlUnlocked(2)) {
      await unlockGirl(2);
      return 2; // 返回新解锁的女生索引
    }
    return null; // 没有新解锁的女生
  }
  
  // 检查是否有足够的心币进行操作
  bool canAffordAction(int requiredHearts) {
    return getHeartCount() >= requiredHearts;
  }
  
  // 检查是否可以脱衣
  bool canTakeoff() {
    // 需要5个心币才能脱衣
    return canAffordAction(5);
  }
  
  // 检查是否有可解锁的皮肤
  Map<String, dynamic>? getAffordableSkin(int girlIndex) {
    int hearts = getHeartCount();
    
    // 检查每个部位的皮肤
    List<String> parts = girlIndex == 0 ? ['bra', 'pants', 'hands', 'socks'] 
                        : ['bra', 'pants', 'head', 'socks'];
    
    for (String part in parts) {
      for (int skinIndex = 1; skinIndex < 4; skinIndex++) {
        if (!isSkinUnlocked(girlIndex, part, skinIndex)) {
          int price = getSkinPrice(skinIndex);
          if (hearts >= price) {
            return {
              'part': part,
              'skinIndex': skinIndex,
              'price': price,
            };
          }
        }
      }
    }
    return null;
  }
  
  // 获取待解锁的女生
  int? getPendingUnlockGirl() {
    return _prefs.getInt(_keyPendingUnlockGirl);
  }
  
  // 设置待解锁的女生
  Future<void> setPendingUnlockGirl(int? girlIndex) async {
    if (girlIndex == null) {
      await _prefs.remove(_keyPendingUnlockGirl);
    } else {
      await _prefs.setInt(_keyPendingUnlockGirl, girlIndex);
    }
  }
  
  // 检查并解锁女生（公开方法）
  Future<int?> checkAndUnlockGirls() async {
    int level = getCurrentLevel();
    return await _checkAndUnlockGirls(level);
  }
  
  // 获取上次触发特殊关卡的关卡
  int getLastSpecialStageLevel() {
    return _prefs.getInt(_keyLastSpecialStageLevel) ?? 0;
  }
  
  // 设置上次触发特殊关卡的关卡
  Future<void> setLastSpecialStageLevel(int level) async {
    await _prefs.setInt(_keyLastSpecialStageLevel, level);
  }
  
  // 检查是否应该触发特殊关卡
  bool shouldTriggerSpecialStage() {
    int currentLevel = getCurrentLevel();
    int lastSpecialLevel = getLastSpecialStageLevel();
    
    // 每5关触发一次特殊关卡，但不超过当前关卡
    return currentLevel > 0 && currentLevel % 5 == 0 && currentLevel > lastSpecialLevel;
  }
  
  // 标记特殊关卡已触发
  Future<void> markSpecialStageTriggered() async {
    await setLastSpecialStageLevel(getCurrentLevel());
  }
  
  // 检查特殊关卡是否已完成
  bool isSpecialStageCompleted() {
    return _prefs.getBool(_keySpecialStageCompleted) ?? false;
  }
  
  // 设置特殊关卡完成状态
  Future<void> setSpecialStageCompleted(bool completed) async {
    await _prefs.setBool(_keySpecialStageCompleted, completed);
  }
  
  // 测试方法：解锁所有女生
  Future<void> unlockAllGirlsForTesting() async {
    List<int> allGirls = [0, 1, 2];
    await _prefs.setString(_keyUnlockedGirls, json.encode(allGirls));
    print("All girls unlocked for testing: $allGirls");
  }
  
  // 测试方法：重置为只解锁第一个女生
  Future<void> resetGirlUnlocksForTesting() async {
    List<int> defaultUnlocked = [0];
    await _prefs.setString(_keyUnlockedGirls, json.encode(defaultUnlocked));
    print("Girl unlocks reset to default: $defaultUnlocked");
  }
}
