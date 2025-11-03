import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GameStateManager {
  static final GameStateManager _instance = GameStateManager._internal();
  factory GameStateManager() => _instance;
  GameStateManager._internal();

  late SharedPreferences _prefs;
  Map<String, dynamic>? _lastGirlStateCache;

  // 游戏状态键值
  static const String _keyHeartCount = 'heart_count';
  static const String _keyShowTakeoffGuide = 'show_takeoff_guide';
  static const String _keyCurrentGirlIndex = 'current_girl_index';
  static const String _keyCurrentIdleIndex = 'current_idle_index';
  static const String _keyGirlIdleIndexPrefix = 'girl_idle_index_';
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
  static const String _keyPendingSpecialStageLevel =
      'pending_special_stage_level';
  static const String _keySpecialStageReady = 'special_stage_ready';
  static const String _keyLastGirlState = 'last_girl_state';
  static const String _keyTriggerSpecialOnReturn = 'trigger_special_on_return';
  static const String _keyPendingHeartAnimation = 'pending_heart_animation';
  static const String _keyPendingHeartAmount = 'pending_heart_amount';

  // 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (_lastGirlStateCache == null) {
      final stored = getLastGirlState(preferCache: false);
      if (stored == null) {
        final currentGirl = getCurrentGirlIndex();
        cacheLastGirlState(
          girlIndex: currentGirl,
          idleIndex: getGirlIdleIndex(currentGirl),
          skins: getCurrentSkins(currentGirl),
        );
      }
    }
  }

  // 获取心形货币数量
  int getHeartCount() {
    return _prefs.getInt(_keyHeartCount) ?? 0;
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

  void cacheLastGirlState({
    required int girlIndex,
    required int idleIndex,
    required Map<String, int> skins,
  }) {
    _lastGirlStateCache = {
      'girlIndex': girlIndex,
      'idleIndex': idleIndex,
      'skins': Map<String, int>.from(skins),
    };
  }

  Map<String, dynamic>? _cloneCachedGirlState() {
    if (_lastGirlStateCache == null) {
      return null;
    }
    return {
      'girlIndex': _lastGirlStateCache!['girlIndex'] ?? 0,
      'idleIndex': _lastGirlStateCache!['idleIndex'] ?? 0,
      'skins': Map<String, int>.from(
        (_lastGirlStateCache!['skins'] as Map<String, int>? ?? const {}),
      ),
    };
  }

  void _updateCacheFromStored(Map<String, dynamic> source) {
    final skins = <String, int>{};
    final rawSkins = source['skins'];
    if (rawSkins is Map) {
      rawSkins.forEach((key, value) {
        if (key is String) {
          if (value is int) {
            skins[key] = value;
          } else if (value is num) {
            skins[key] = value.toInt();
          }
        }
      });
    }
    cacheLastGirlState(
      girlIndex: (source['girlIndex'] as num?)?.toInt() ?? 0,
      idleIndex: (source['idleIndex'] as num?)?.toInt() ?? 0,
      skins: skins,
    );
  }

  /// Persist idle index for a specific girl.
  Future<void> setGirlIdleIndex(int girlIndex, int idleIndex) async {
    await _prefs.setInt('$_keyGirlIdleIndexPrefix$girlIndex', idleIndex);
  }

  /// Read the stored idle index for a specific girl.
  int getGirlIdleIndex(int girlIndex) {
    return _prefs.getInt('$_keyGirlIdleIndexPrefix$girlIndex') ?? 0;
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
  Future<void> setCurrentSkin(
      int girlIndex, String partName, int skinIndex) async {
    Map<String, int> current = getCurrentSkins(girlIndex);
    current[partName] = skinIndex;
    await _prefs.setString(
        '${_keyCurrentSkins}_$girlIndex', json.encode(current));
  }

  Future<void> setLastGirlState({
    required int girlIndex,
    required int idleIndex,
    required Map<String, int> skins,
  }) async {
    cacheLastGirlState(
        girlIndex: girlIndex, idleIndex: idleIndex, skins: skins);

    final payload = <String, dynamic>{
      'girlIndex': girlIndex,
      'idleIndex': idleIndex,
      'skins': skins,
    };
    await _prefs.setString(_keyLastGirlState, json.encode(payload));
  }

  Map<String, dynamic>? getLastGirlState({bool preferCache = true}) {
    if (preferCache) {
      final cached = _cloneCachedGirlState();
      if (cached != null) {
        return cached;
      }
    }

    final jsonStr = _prefs.getString(_keyLastGirlState);
    if (jsonStr == null) {
      return null;
    }
    try {
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      _updateCacheFromStored(decoded);
      return _cloneCachedGirlState();
    } catch (_) {
      return null;
    }
  }

  // 获取皮肤价格
  int getSkinPrice(int skinIndex) {
    // 【关键代码】三个美女不同换装所需爱心货币值 - 调整此处数值改变换装消耗
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
    int completedLevel = currentLevel;
    int newLevel = currentLevel + 1;
    await setCurrentLevel(newLevel);

    if (completedLevel > 0 && completedLevel % 5 == 0) {
      int lastTriggered = getLastSpecialStageLevel();
      if (completedLevel > lastTriggered) {
        await setPendingSpecialStageLevel(completedLevel);
        await setSpecialStageReady(false);
      }
    }

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
    // 【关键代码】三个美女解锁关卡设置 - 调整此处数值改变解锁条件
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

  // 【关键代码】每个角色脱每件衣服所需爱心货币值配置
  // 格式: Map<角色索引, List<每个脱衣阶段的消耗>>
  // Girl01和Girl02有4次脱衣（0-3索引），Girl03有5次脱衣（0-4索引）
  static const Map<int, List<int>> _takeoffCosts = {
    0: [5, 5, 5, 5], // Girl0 每个脱衣阶段的消耗
    1: [5, 5, 5, 5], // Girl1 每个脱衣阶段的消耗
    2: [5, 5, 5, 5, 5], // Girl2 每个脱衣阶段的消耗（5次脱衣）
  };

  // 获取指定角色在指定脱衣阶段的消耗
  int getTakeoffCost(int girlIndex, int idleIndex) {
    // idleIndex 是当前阶段，脱衣后会变成 idleIndex + 1
    // 所以消耗应该对应下一个阶段的成本
    if (!_takeoffCosts.containsKey(girlIndex)) {
      return 5; // 默认值
    }
    final costs = _takeoffCosts[girlIndex]!;
    // idleIndex 范围是 0 到 max-1，消耗对应的是从当前阶段到下一阶段的成本
    if (idleIndex >= 0 && idleIndex < costs.length) {
      return costs[idleIndex];
    }
    return 5; // 默认值，超出范围时返回默认值
  }

  // 检查是否可以脱衣（使用当前女孩和当前idle索引）
  bool canTakeoff({int? girlIndex, int? idleIndex}) {
    final currentGirl = girlIndex ?? getCurrentGirlIndex();
    final currentIdle = idleIndex ?? getGirlIdleIndex(currentGirl);
    final cost = getTakeoffCost(currentGirl, currentIdle);
    return canAffordAction(cost);
  }

  // 获取当前脱衣阶段的消耗（用于显示和检查）
  int getCurrentTakeoffCost({int? girlIndex, int? idleIndex}) {
    final currentGirl = girlIndex ?? getCurrentGirlIndex();
    final currentIdle = idleIndex ?? getGirlIdleIndex(currentGirl);
    return getTakeoffCost(currentGirl, currentIdle);
  }

  // 检查是否有可解锁的皮肤
  Map<String, dynamic>? getAffordableSkin(int girlIndex) {
    int hearts = getHeartCount();

    // 检查每个部位的皮肤
    List<String> parts = girlIndex == 0
        ? ['bra', 'pants', 'hands', 'socks']
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

  // 获取待触发的特殊关卡关卡数
  int getPendingSpecialStageLevel() {
    return _prefs.getInt(_keyPendingSpecialStageLevel) ?? 0;
  }

  // 设置待触发的特殊关卡关卡数
  Future<void> setPendingSpecialStageLevel(int level) async {
    if (level <= 0) {
      await _prefs.remove(_keyPendingSpecialStageLevel);
    } else {
      await _prefs.setInt(_keyPendingSpecialStageLevel, level);
    }
  }

  // 检查特殊关卡是否可以弹出
  bool isSpecialStageReady() {
    return _prefs.getBool(_keySpecialStageReady) ?? false;
  }

  // 标记特殊关卡是否可以弹出
  Future<void> setSpecialStageReady(bool ready) async {
    await _prefs.setBool(_keySpecialStageReady, ready);
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
    int pendingLevel = getPendingSpecialStageLevel();
    if (pendingLevel <= 0) {
      return false;
    }

    if (!isSpecialStageReady()) {
      return false;
    }

    int lastSpecialLevel = getLastSpecialStageLevel();
    return pendingLevel > lastSpecialLevel;
  }

  // 标记特殊关卡已触发
  Future<void> markSpecialStageTriggered({int? level}) async {
    int targetLevel = level ?? getPendingSpecialStageLevel();
    if (targetLevel <= 0) {
      // 若没有待触发关卡，默认使用当前已完成的关卡
      targetLevel = getCurrentLevel() - 1;
    }

    if (targetLevel > 0) {
      await setLastSpecialStageLevel(targetLevel);
    }

    await setPendingSpecialStageLevel(0);
    await setSpecialStageReady(false);
    await setTriggerSpecialOnReturn(false);
  }

  // 检查特殊关卡是否已完成
  bool isSpecialStageCompleted() {
    return _prefs.getBool(_keySpecialStageCompleted) ?? false;
  }

  // 设置特殊关卡完成状态
  Future<void> setSpecialStageCompleted(bool completed) async {
    await _prefs.setBool(_keySpecialStageCompleted, completed);
  }

  // 是否仅在从结果流返回主界面时检查特殊关卡
  bool shouldTriggerSpecialOnReturn() {
    return _prefs.getBool(_keyTriggerSpecialOnReturn) ?? false;
  }

  Future<void> setTriggerSpecialOnReturn(bool value) async {
    await _prefs.setBool(_keyTriggerSpecialOnReturn, value);
  }

  // 设置待播放的爱心动画
  Future<void> setPendingHeartAnimation(int heartAmount) async {
    await _prefs.setBool(_keyPendingHeartAnimation, true);
    await _prefs.setInt(_keyPendingHeartAmount, heartAmount);
  }

  // 获取待播放的爱心动画信息
  Map<String, dynamic>? getPendingHeartAnimation() {
    final hasAnimation = _prefs.getBool(_keyPendingHeartAnimation) ?? false;
    if (!hasAnimation) return null;

    final amount = _prefs.getInt(_keyPendingHeartAmount) ?? 0;
    return {
      'playHeartAnimation': true,
      'heartAmount': amount,
    };
  }

  // 清除待播放的爱心动画信息
  Future<void> clearPendingHeartAnimation() async {
    await _prefs.remove(_keyPendingHeartAnimation);
    await _prefs.remove(_keyPendingHeartAmount);
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
