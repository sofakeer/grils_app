import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../services/ads/ads_service.dart';
import '../../services/storage/prefs_service.dart';
import '../../utils/game_logger.dart';

enum SignRewardType { coin, undo, reminder, pipe }

class SignReward {
  final SignRewardType type;
  final int amount;
  const SignReward(this.type, this.amount);
}

class SignInState {
  static const Object _noChange = Object();
  final int dayIndex; // 1..7 当前应领取的天数（7天循环）
  final bool claimedToday;
  final bool enabled;
  final int totalSignInDays; // 累计签到天数
  final List<SignReward> dailyRewards; // 7天日常奖励
  final List<CumulativeReward> cumulativeRewards; // 累计奖励
  final DateTime? lastSignDate; // 上一次签到日期（仅日期部分）
  final DateTime? firstSignDate; // 首次签到日期（作为基准时间）
  final bool shouldAutoPopup; // 今日是否需要自动弹窗
  final SignReward? lastClaimedReward; // 最后领取的奖励
  final List<int> cycleClaimedDays; // 当前周期内已自然或补签完成的天数
  const SignInState({
    required this.dayIndex,
    required this.claimedToday,
    required this.enabled,
    required this.totalSignInDays,
    required this.dailyRewards,
    required this.cumulativeRewards,
    required this.lastSignDate,
    required this.firstSignDate,
    required this.shouldAutoPopup,
    required this.cycleClaimedDays,
    this.lastClaimedReward,
  });

  SignInState copyWith({
    int? dayIndex,
    bool? claimedToday,
    bool? enabled,
    int? totalSignInDays,
    List<SignReward>? dailyRewards,
    List<CumulativeReward>? cumulativeRewards,
    Object? lastSignDate = _noChange,
    Object? firstSignDate = _noChange,
    bool? shouldAutoPopup,
    SignReward? lastClaimedReward,
    List<int>? cycleClaimedDays,
  }) =>
      SignInState(
        dayIndex: dayIndex ?? this.dayIndex,
        claimedToday: claimedToday ?? this.claimedToday,
        enabled: enabled ?? this.enabled,
        totalSignInDays: totalSignInDays ?? this.totalSignInDays,
        dailyRewards: dailyRewards ?? this.dailyRewards,
        cumulativeRewards: cumulativeRewards ?? this.cumulativeRewards,
        lastSignDate: identical(lastSignDate, _noChange)
            ? this.lastSignDate
            : lastSignDate as DateTime?,
        firstSignDate: identical(firstSignDate, _noChange)
            ? this.firstSignDate
            : firstSignDate as DateTime?,
        shouldAutoPopup: shouldAutoPopup ?? this.shouldAutoPopup,
        lastClaimedReward: lastClaimedReward ?? this.lastClaimedReward,
        cycleClaimedDays: cycleClaimedDays ?? this.cycleClaimedDays,
      );
}

class CumulativeReward {
  final int requiredDays;
  final SignRewardType type;
  final int amount;
  final bool claimed;

  const CumulativeReward({
    required this.requiredDays,
    required this.type,
    required this.amount,
    required this.claimed,
  });
}

class SignInController extends AsyncNotifier<SignInState> {
  static const _keyLast = 'signin_last_date';
  static const _keyFirst = 'signin_first_date'; // 新增：首次签到日期
  static const _keyIndex = 'signin_cycle_index';
  static const _keyTotalDays = 'signin_total_days';
  static const _keyCumulativeClaimed = 'signin_cumulative_claimed';
  static const _keyCumulativeCompletedDate = 'signin_cum_completed_date';
  static const _keyPopupShown = 'signin_popup_shown_date';
  static const _keyCycleClaimedDays = 'signin_cycle_claimed_days';
  late final PrefsService _prefs;
  late final AdsService _ads;

  @override
  Future<SignInState> build() async {
    _prefs = ref.read(prefsServiceProvider);
    _ads = ref.read(adsServiceProvider);
    final rc = ref.read(remoteConfigProvider);
    final enabled = rc.getBool('signin.enabled', defaultValue: true);

    final today = _onlyDate(DateTime.now());
    final todayStr = _dateStr(today);
    final last = _prefs.getString(_keyLast);
    final lastDate = _parseDate(last);
    final first = _prefs.getString(_keyFirst);
    DateTime? firstDate = _parseDate(first);
    var idx = _prefs.getInt(_keyIndex) ?? 1;
    var totalDays = _prefs.getInt(_keyTotalDays) ?? 0; // 改为 var 以便在重置时更新
    final claimedToday = last == todayStr;
    final popupShownStr = _prefs.getString(_keyPopupShown);
    final popupShownToday = popupShownStr == todayStr;
    var cycleClaimedDays = _readCycleClaimedDays();

    // 若距离上次签到已超过或等于7天，则重置7天签到周期
    if (!claimedToday && lastDate != null) {
      final gapDays = today.difference(lastDate).inDays;
      if (gapDays >= 7) {
        idx = 1;
        firstDate = today; // 重置基准为今天
        await _prefs.setInt(_keyIndex, idx);
        await _prefs.setString(_keyFirst, todayStr);
        // 清除今日弹窗已展示标记，允许重新弹窗
        await _prefs.remove(_keyPopupShown);
        // 超过7天未签到视为开启新周期，清空补签记录
        await _prefs.setString('signin_missed_claimed', '');
        await _clearCycleClaimedDays();
        cycleClaimedDays = [];
        GameLogger.log(GameLogger.tagSignIn, '超过7天未签到，重置周循环: gap=$gapDays, dayIndex=1, firstDate=$today');
      }
    }

    // 如果有首次签到日期，根据首次签到日期计算当前应该是第几天
    if (firstDate != null && !claimedToday) {
      // 计算从首次签到到今天经过了多少天
      final daysFromFirstToToday = today.difference(firstDate).inDays;
      
      // 今天应该是第几天（基于首次签到日期）
      // 首次签到当天是第1天，第二天是第2天，以此类推
      // 例如：1月1日首次签到（第1天），1月2日是第2天，1月3日是第3天
      final calculatedIdx = ((daysFromFirstToToday) % 7) + 1;
      
      GameLogger.log(GameLogger.tagSignIn, '时间计算: firstDate=$firstDate, lastDate=$lastDate, today=$today');
      GameLogger.log(GameLogger.tagSignIn, 'daysFromFirstToToday=$daysFromFirstToToday');
      GameLogger.log(GameLogger.tagSignIn, '存储的dayIndex=$idx, 计算的dayIndex=$calculatedIdx, totalSignInDays=$totalDays');
      
      // 如果计算出的索引与存储的不一致，使用计算出的索引
      // 这样可以防止时间被修改后出现不一致
      if (calculatedIdx != idx) {
        GameLogger.log(GameLogger.tagSignIn, '检测到时间变化，更新dayIndex: $idx -> $calculatedIdx');
        idx = calculatedIdx;
        // 更新存储的索引
        await _prefs.setInt(_keyIndex, idx);
      }
    }

    // 新的重置逻辑：如果累计签到天数超过28天，立即重置整个签到系统
    if (totalDays > 28) {
      GameLogger.log(GameLogger.tagSignIn, '累计天数超过28天，立即重置签到系统: totalDays=$totalDays');
      GameLogger.log(GameLogger.tagSignIn, '重置前: idx=$idx, firstDate=$firstDate, lastDate=$lastDate');

      // 清空累计宝箱领取标记
      await _prefs.setString(_keyCumulativeClaimed, '');
      await _prefs.remove(_keyCumulativeCompletedDate);

      // 重置累计签到天数为0
      totalDays = 0;
      await _prefs.setInt(_keyTotalDays, totalDays);

      // 将 7 天循环重置为第 1 天，并将首次签到基准改为今天
      idx = 1;
      firstDate = today;
      await _prefs.setInt(_keyIndex, idx);
      await _prefs.setString(_keyFirst, todayStr);

      // 清除补签记录
      await _prefs.setString('signin_missed_claimed', '');
      await _clearCycleClaimedDays();
      cycleClaimedDays = [];

      // 清除今日签到记录，让今天变为未签到状态
      await _prefs.remove(_keyLast);

      // 允许今日重新弹窗
      await _prefs.remove(_keyPopupShown);

      GameLogger.log(GameLogger.tagSignIn, '重置完成: dayIndex=1, totalDays=0, reset firstDate=$today, 所有记录已清除');
    }

    // 若进入新的一天，且累计宝箱三档都已领取，则在次日重置累计宝箱领取记录
    // 并将 7 天循环从 1 重新开始，满足"全部领取后，第二天重新开始"的需求
    GameLogger.log(GameLogger.tagSignIn, '重置检查: claimedToday=$claimedToday, lastDate=$lastDate, today=$today');

    // 检查累计宝箱状态
    final claimedStr = _prefs.getString(_keyCumulativeClaimed) ?? '';
    final claimedList = claimedStr.isEmpty ? <String>[] : claimedStr.split(',');
    final allClaimed = claimedList.contains('14') &&
        claimedList.contains('21') &&
        claimedList.contains('28');
    final completedStr = _prefs.getString(_keyCumulativeCompletedDate);
    final completedDate = _parseDate(completedStr);
    GameLogger.log(GameLogger.tagSignIn, '累计宝箱状态: claimedList=$claimedList, allClaimed=$allClaimed, completedDate=$completedDate');

    if (!claimedToday && lastDate != null && today.isAfter(lastDate)) {
      GameLogger.log(GameLogger.tagSignIn, '重置条件检查: 新的一天且未签到，检查累计宝箱领取状态');
      // 仅当已完成且"严格跨天"后才重置，防止在完成当天立刻清理
      if (allClaimed && completedDate != null && today.isAfter(completedDate)) {
        GameLogger.log(GameLogger.tagSignIn, '次日检测到累计宝箱全部已领，开始重置累计与周循环');
        GameLogger.log(GameLogger.tagSignIn, '重置前: totalDays=$totalDays, idx=$idx, firstDate=$firstDate');

        // 清空累计宝箱领取标记（必须在重置 totalDays 之前执行）
        await _prefs.setString(_keyCumulativeClaimed, '');
        await _prefs.remove(_keyCumulativeCompletedDate);

        // 重置累计签到天数为0（重要：清空进度条和累计奖励状态）
        totalDays = 0;
        await _prefs.setInt(_keyTotalDays, totalDays);

        // 将 7 天循环重置为第 1 天，并将首次签到基准改为今天
        idx = 1;
        firstDate = today;
        await _prefs.setInt(_keyIndex, idx);
        await _prefs.setString(_keyFirst, todayStr);

        // 清除补签记录
        await _prefs.setString('signin_missed_claimed', '');
        await _clearCycleClaimedDays();
        cycleClaimedDays = [];

        // 清除今日签到记录，让今天变为未签到状态（与resetSignIn保持一致）
        await _prefs.remove(_keyLast);

        // 允许今日重新弹窗
        await _prefs.remove(_keyPopupShown);

        GameLogger.log(GameLogger.tagSignIn, '重置完成: dayIndex=1, totalDays=0, reset firstDate=$today, 补签记录已清除, lastSignDate已清除, claimed标记已清除');
      } else {
        GameLogger.log(GameLogger.tagSignIn, '重置条件不满足: allClaimed=$allClaimed, completedDate=$completedDate, today.isAfter(completedDate)=${completedDate != null ? today.isAfter(completedDate) : false}');
      }
    } else {
      GameLogger.log(GameLogger.tagSignIn, '重置条件不满足: claimedToday=$claimedToday, lastDate=$lastDate, today.isAfter(lastDate)=${lastDate != null ? today.isAfter(lastDate) : false}');
    }

    // 新开一周前清理补签缓存，避免旧周期的数据干扰
    if (!claimedToday && totalDays > 0 && totalDays % 7 == 0) {
      await _prefs.setString('signin_missed_claimed', '');
      await _clearCycleClaimedDays();
      cycleClaimedDays = [];
      GameLogger.log(GameLogger.tagSignIn, '检测到新周期开始，清理补签记录: totalDays=$totalDays');
    }

    final dailyRewards = _getDailyRewards();
    final cumulativeRewards = _getCumulativeRewards(totalDays);

    return SignInState(
      dayIndex: idx,
      claimedToday: claimedToday,
      enabled: enabled,
      totalSignInDays: totalDays,
      dailyRewards: dailyRewards,
      cumulativeRewards: cumulativeRewards,
      lastSignDate: lastDate,
      firstSignDate: firstDate,
      shouldAutoPopup: enabled && !claimedToday && !popupShownToday,
      lastClaimedReward: null,
      cycleClaimedDays: List.unmodifiable(cycleClaimedDays),
    );
  }

  /// 领取日常签到奖励
  Future<bool> claimDaily() async {
    final s = state.value;
    if (s == null || s.claimedToday) return false;

    GameLogger.log(GameLogger.tagSignIn, '领取日常签到: dayIndex=${s.dayIndex}, totalDays=${s.totalSignInDays}');

    // 观看激励视频
    final res = await _ads.showRewarded(placement: 'signin_daily');
    if (res != AdResult.completed) return false;

    final rewardIndex = (s.dayIndex - 1).clamp(0, s.dailyRewards.length - 1);
    final reward = s.dailyRewards[rewardIndex];
    GameLogger.log(GameLogger.tagSignIn, '领取奖励: day=${s.dayIndex}, rewardIndex=$rewardIndex, type=${reward.type.name}, amount=${reward.amount}');
    await _applyReward(reward);

    // 更新索引与日期
    final nextIdx = s.dayIndex >= 7 ? 1 : s.dayIndex + 1;
    final newTotalDays = s.totalSignInDays + 1;
    final now = _onlyDate(DateTime.now());
    final todayStr = _dateStr(now);
    
    // 如果是首次签到，记录首次签到日期
    if (s.firstSignDate == null) {
      await _prefs.setString(_keyFirst, todayStr);
    }
    
    await _prefs.setString(_keyLast, todayStr);
    await _prefs.setInt(_keyIndex, nextIdx);
    await _prefs.setInt(_keyTotalDays, newTotalDays);
    await _prefs.setString(_keyPopupShown, todayStr);

    final updatedCycleClaimedSet = {...s.cycleClaimedDays, s.dayIndex};
    final updatedCycleClaimed = await _saveCycleClaimedDays(updatedCycleClaimedSet);

    final newCumulativeRewards = _getCumulativeRewards(newTotalDays);
    state = AsyncData(s.copyWith(
      dayIndex: nextIdx,
      claimedToday: true,
      totalSignInDays: newTotalDays,
      cumulativeRewards: newCumulativeRewards,
      lastSignDate: now,
      firstSignDate: s.firstSignDate ?? now, // 保存首次签到日期
      shouldAutoPopup: false,
      lastClaimedReward: reward, // 添加最后领取的奖励
      cycleClaimedDays: List<int>.unmodifiable(updatedCycleClaimed),
    ));
    return true;
  }

  /// 领取日常签到奖励（不包含广告播放）
  /// 供UI层使用AdManager播放广告后调用
  /// [multiplier] 奖励倍数，默认为1（普通领取），2为双倍领取
  Future<bool> claimDailyWithoutAd({int multiplier = 1}) async {
    final s = state.value;
    if (s == null || s.claimedToday) return false;

    GameLogger.log(GameLogger.tagSignIn, '领取日常签到(无广告): dayIndex=${s.dayIndex}, totalDays=${s.totalSignInDays}, multiplier=$multiplier');

    final rewardIndex = (s.dayIndex - 1).clamp(0, s.dailyRewards.length - 1);
    final reward = s.dailyRewards[rewardIndex];
    GameLogger.log(GameLogger.tagSignIn, '领取奖励: day=${s.dayIndex}, rewardIndex=$rewardIndex, type=${reward.type.name}, amount=${reward.amount}, multiplier=$multiplier');
    await _applyReward(reward, multiplier: multiplier);

    // 更新索引与日期
    final nextIdx = s.dayIndex >= 7 ? 1 : s.dayIndex + 1;
    final newTotalDays = s.totalSignInDays + 1;
    final now = _onlyDate(DateTime.now());
    final todayStr = _dateStr(now);

    // 如果是首次签到，记录首次签到日期
    if (s.firstSignDate == null) {
      await _prefs.setString(_keyFirst, todayStr);
    }

    await _prefs.setString(_keyLast, todayStr);
    await _prefs.setInt(_keyIndex, nextIdx);
    await _prefs.setInt(_keyTotalDays, newTotalDays);
    await _prefs.setString(_keyPopupShown, todayStr);

    final updatedCycleClaimedSet = {...s.cycleClaimedDays, s.dayIndex};
    final updatedCycleClaimed = await _saveCycleClaimedDays(updatedCycleClaimedSet);

    final newCumulativeRewards = _getCumulativeRewards(newTotalDays);
    
    // 创建带倍数的奖励对象用于显示
    final displayedReward = SignReward(reward.type, reward.amount * multiplier);
    
    state = AsyncData(s.copyWith(
      dayIndex: nextIdx,
      claimedToday: true,
      totalSignInDays: newTotalDays,
      cumulativeRewards: newCumulativeRewards,
      lastSignDate: now,
      firstSignDate: s.firstSignDate ?? now, // 保存首次签到日期
      shouldAutoPopup: false,
      lastClaimedReward: displayedReward, // 添加最后领取的奖励（带倍数）
      cycleClaimedDays: List<int>.unmodifiable(updatedCycleClaimed),
    ));
    return true;
  }

  /// 补签功能
  /// 补签不会将今天标记为已签到，用户可以连续补签多天
  /// 用户可以自由选择任意一个漏签天进行补签
  Future<bool> claimMissed(int day) async {
    // 先检查是否已补签过
    final claimedMissedStr = _prefs.getString('signin_missed_claimed') ?? '';
    final claimedMissedList = claimedMissedStr.isEmpty ? <String>[] : claimedMissedStr.split(',');
    if (claimedMissedList.contains(day.toString())) {
      GameLogger.log(GameLogger.tagSignIn, '补签失败: day=$day 已经补签过了');
      return false;
    }
    final s = state.value;
    if (s == null) return false;

    // 验证要补签的天数是否有效（必须在1-7范围内）
    if (day < 1 || day > 7) {
      GameLogger.log(GameLogger.tagSignIn, '补签失败: day=$day 超出有效范围');
      return false;
    }

    // 检查该天是否是今天（今天应该使用 claimDaily，而不是 claimMissed）
    if (day == s.dayIndex) {
      GameLogger.log(GameLogger.tagSignIn, '补签失败: day=$day 是今天，应使用 claimDaily');
      return false;
    }

    // 计算漏签天集合
    final missedDays = _getMissedDays(s);

    // 检查该天是否在漏签天集合中
    if (!missedDays.contains(day)) {
      GameLogger.log(GameLogger.tagSignIn, '补签失败: day=$day 不在可补签范围, dayIndex=${s.dayIndex}, missedDays=$missedDays');
      return false;
    }

    GameLogger.log(GameLogger.tagSignIn, '补签: day=$day, dayIndex=${s.dayIndex}, totalDays=${s.totalSignInDays}');

    // 观看激励视频
    GameLogger.log(GameLogger.tagSignIn, '准备播放广告补签');
    final res = await _ads.showRewarded(placement: 'signin_missed');
    GameLogger.log(GameLogger.tagSignIn, '广告播放完成, 结果: res=$res');
    if (res != AdResult.completed) {
      GameLogger.log(GameLogger.tagSignIn, '广告未完成，补签失败');
      return false;
    }

    // 补签指定天的奖励
    GameLogger.log(GameLogger.tagSignIn, '准备获取奖励: day=$day, dailyRewards长度=${s.dailyRewards.length}');
    GameLogger.log(GameLogger.tagSignIn, 'dailyRewards数组: ${s.dailyRewards.asMap().entries.map((e) => 'day${e.key + 1}=${e.value.type.name}*${e.value.amount}').join(', ')}');
    final reward = s.dailyRewards[(day - 1).clamp(0, s.dailyRewards.length - 1)];
    GameLogger.log(GameLogger.tagSignIn, '补签奖励: day=$day, 索引=${day - 1}, type=${reward.type.name}, amount=${reward.amount}');
    await _applyReward(reward);

    // 更新累计天数，但不更新 dayIndex
    // dayIndex 由日期决定，补签不应该改变"今天是第几天"
    final newTotalDays = s.totalSignInDays + 1;

    // 补签时不更新 lastSignDate、claimedToday 和 dayIndex
    // dayIndex 保持不变，因为"今天是第几天"不会因为补签而改变
    await _prefs.setInt(_keyTotalDays, newTotalDays);

    // 记录补签的天数
    claimedMissedList.add(day.toString());
    await _prefs.setString('signin_missed_claimed', claimedMissedList.join(','));

    final updatedCycleClaimedSet = {...s.cycleClaimedDays, day};
    final updatedCycleClaimed = await _saveCycleClaimedDays(updatedCycleClaimedSet);

    final newCumulativeRewards = _getCumulativeRewards(newTotalDays);

    // 重要：补签后不改变 dayIndex、claimedToday、lastSignDate
    // 只更新 totalSignInDays，这样用户可以继续补签或签今天
    state = AsyncData(s.copyWith(
      totalSignInDays: newTotalDays,
      cumulativeRewards: newCumulativeRewards,
      lastClaimedReward: reward,
      cycleClaimedDays: List<int>.unmodifiable(updatedCycleClaimed),
      // dayIndex 保持不变
      // claimedToday 保持不变
      // lastSignDate 保持不变
    ));

    GameLogger.log(GameLogger.tagSignIn, '补签完成: day=$day, dayIndex保持=${s.dayIndex}, 新totalDays=$newTotalDays');
    return true;
  }

  /// 补签功能（不包含广告播放）
  /// 供UI层使用AdManager播放广告后调用
  Future<bool> claimMissedWithoutAd(int day) async {
    // 先检查是否已补签过
    final claimedMissedStr = _prefs.getString('signin_missed_claimed') ?? '';
    final claimedMissedList = claimedMissedStr.isEmpty ? <String>[] : claimedMissedStr.split(',');
    if (claimedMissedList.contains(day.toString())) {
      GameLogger.log(GameLogger.tagSignIn, '补签失败(无广告): day=$day 已经补签过了');
      return false;
    }
    final s = state.value;
    if (s == null) return false;

    // 验证要补签的天数是否有效（必须在1-7范围内）
    if (day < 1 || day > 7) {
      GameLogger.log(GameLogger.tagSignIn, '补签失败(无广告): day=$day 超出有效范围');
      return false;
    }

    // 检查该天是否是今天（今天应该使用 claimDaily，而不是 claimMissed）
    if (day == s.dayIndex) {
      GameLogger.log(GameLogger.tagSignIn, '补签失败(无广告): day=$day 是今天，应使用 claimDaily');
      return false;
    }

    // 计算漏签天集合
    final missedDays = _getMissedDays(s);

    // 检查该天是否在漏签天集合中
    if (!missedDays.contains(day)) {
      GameLogger.log(GameLogger.tagSignIn, '补签失败(无广告): day=$day 不在可补签范围, dayIndex=${s.dayIndex}, missedDays=$missedDays');
      return false;
    }

    GameLogger.log(GameLogger.tagSignIn, '补签(无广告): day=$day, dayIndex=${s.dayIndex}, totalDays=${s.totalSignInDays}');

    // 补签指定天的奖励
    GameLogger.log(GameLogger.tagSignIn, '准备获取奖励: day=$day, dailyRewards长度=${s.dailyRewards.length}');
    GameLogger.log(GameLogger.tagSignIn, 'dailyRewards数组: ${s.dailyRewards.asMap().entries.map((e) => 'day${e.key + 1}=${e.value.type.name}*${e.value.amount}').join(', ')}');
    final reward = s.dailyRewards[(day - 1).clamp(0, s.dailyRewards.length - 1)];
    GameLogger.log(GameLogger.tagSignIn, '补签奖励: day=$day, 索引=${day - 1}, type=${reward.type.name}, amount=${reward.amount}');
    await _applyReward(reward);

    // 更新累计天数，但不更新 dayIndex
    // dayIndex 由日期决定，补签不应该改变"今天是第几天"
    final newTotalDays = s.totalSignInDays + 1;

    // 补签时不更新 lastSignDate、claimedToday 和 dayIndex
    // dayIndex 保持不变，因为"今天是第几天"不会因为补签而改变
    await _prefs.setInt(_keyTotalDays, newTotalDays);

    // 记录补签的天数
    claimedMissedList.add(day.toString());
    await _prefs.setString('signin_missed_claimed', claimedMissedList.join(','));

    final updatedCycleClaimedSet = {...s.cycleClaimedDays, day};
    final updatedCycleClaimed = await _saveCycleClaimedDays(updatedCycleClaimedSet);

    final newCumulativeRewards = _getCumulativeRewards(newTotalDays);

    // 重要：补签后不改变 dayIndex、claimedToday、lastSignDate
    // 只更新 totalSignInDays，这样用户可以继续补签或签今天
    state = AsyncData(s.copyWith(
      totalSignInDays: newTotalDays,
      cumulativeRewards: newCumulativeRewards,
      lastClaimedReward: reward,
      cycleClaimedDays: List<int>.unmodifiable(updatedCycleClaimed),
      // dayIndex 保持不变
      // claimedToday 保持不变
      // lastSignDate 保持不变
    ));

    GameLogger.log(GameLogger.tagSignIn, '补签完成(无广告): day=$day, dayIndex保持=${s.dayIndex}, 新totalDays=$newTotalDays');
    return true;
  }

  /// 领取累计奖励
  Future<bool> claimCumulative(int requiredDays) async {
    final s = state.value;
    if (s == null) return false;

    // 观看激励视频
    final res = await _ads.showRewarded(placement: 'signin_cumulative');
    if (res != AdResult.completed) return false;

    // 找到对应的累计奖励
    final cumulativeReward = s.cumulativeRewards.firstWhere(
      (r) => r.requiredDays == requiredDays,
      orElse: () => throw Exception('Cumulative reward not found'),
    );

    final reward = SignReward(cumulativeReward.type, cumulativeReward.amount);
    await _applyReward(reward);

    // 标记为已领取
    final claimedStr = _prefs.getString(_keyCumulativeClaimed) ?? '';
    final claimedList = claimedStr.isEmpty ? <String>[] : claimedStr.split(',');
    claimedList.add(requiredDays.toString());
    await _prefs.setString(_keyCumulativeClaimed, claimedList.join(','));

    // 计算更新后的累计领取状态
    final updatedClaimedStr = _prefs.getString(_keyCumulativeClaimed) ?? '';
    final updatedClaimedList =
        updatedClaimedStr.isEmpty ? <String>[] : updatedClaimedStr.split(',');
    // 如果在本次领取后达成“三档全部已领”，记录完成日期为今天
    final now = _onlyDate(DateTime.now());
    final nowStr = _dateStr(now);
    final nowAllClaimed = updatedClaimedList.contains('14') &&
        updatedClaimedList.contains('21') &&
        updatedClaimedList.contains('28');
    if (nowAllClaimed) {
      await _prefs.setString(_keyCumulativeCompletedDate, nowStr);
    }

    final newCumulativeRewards = _getCumulativeRewards(s.totalSignInDays);
    state = AsyncData(s.copyWith(cumulativeRewards: newCumulativeRewards));
    return true;
  }

  /// 领取累计奖励（不包含广告播放）
  /// 供UI层使用AdManager播放广告后调用
  Future<bool> claimCumulativeWithoutAd(int requiredDays) async {
    final s = state.value;
    if (s == null) return false;

    // 找到对应的累计奖励
    final cumulativeReward = s.cumulativeRewards.firstWhere(
      (r) => r.requiredDays == requiredDays,
      orElse: () => throw Exception('Cumulative reward not found'),
    );

    final reward = SignReward(cumulativeReward.type, cumulativeReward.amount);
    await _applyReward(reward);

    // 标记为已领取
    final claimedStr = _prefs.getString(_keyCumulativeClaimed) ?? '';
    final claimedList = claimedStr.isEmpty ? <String>[] : claimedStr.split(',');
    claimedList.add(requiredDays.toString());
    await _prefs.setString(_keyCumulativeClaimed, claimedList.join(','));

    // 计算更新后的累计领取状态
    final updatedClaimedStr = _prefs.getString(_keyCumulativeClaimed) ?? '';
    final updatedClaimedList =
        updatedClaimedStr.isEmpty ? <String>[] : updatedClaimedStr.split(',');
    // 如果在本次领取后达成"三档全部已领"，记录完成日期为今天
    final now = _onlyDate(DateTime.now());
    final nowStr = _dateStr(now);
    final nowAllClaimed = updatedClaimedList.contains('14') &&
        updatedClaimedList.contains('21') &&
        updatedClaimedList.contains('28');
    if (nowAllClaimed) {
      await _prefs.setString(_keyCumulativeCompletedDate, nowStr);
    }

    final newCumulativeRewards = _getCumulativeRewards(s.totalSignInDays);
    state = AsyncData(s.copyWith(cumulativeRewards: newCumulativeRewards));
    return true;
  }

  Future<void> markPopupShown() async {
    final todayStr = _dateStr(_onlyDate(DateTime.now()));
    await _prefs.setString(_keyPopupShown, todayStr);
    final current = state.value;
    if (current != null && current.shouldAutoPopup) {
      state = AsyncData(current.copyWith(shouldAutoPopup: false));
    }
  }

  Future<void> _applyReward(SignReward reward, {int multiplier = 1}) async {
    GameLogger.log(GameLogger.tagSignIn, '_applyReward 开始: type=${reward.type.name}, amount=${reward.amount}, multiplier=$multiplier');
    final up = ref.read(userProgressProvider.notifier);
    final amt = reward.amount * multiplier;
    GameLogger.log(GameLogger.tagSignIn, '准备增加道具: type=${reward.type.name}, amount=$amt');
    switch (reward.type) {
      case SignRewardType.coin:
        await up.addCoins(amt);
        GameLogger.log(GameLogger.tagSignIn, '已增加金币: $amt');
        break;
      case SignRewardType.undo:
        await up.addUndo(amt);
        GameLogger.log(GameLogger.tagSignIn, '已增加撤销: $amt');
        break;
      case SignRewardType.reminder:
        await up.addReminder(amt);
        GameLogger.log(GameLogger.tagSignIn, '已增加提醒: $amt');
        break;
      case SignRewardType.pipe:
        await up.addPipe(amt);
        GameLogger.log(GameLogger.tagSignIn, '已增加管子: $amt');
        break;
    }
    GameLogger.log(GameLogger.tagSignIn, '_applyReward 完成');
  }

  List<SignReward> _getDailyRewards() {
    // 7天循环的日常奖励
    return [
      const SignReward(SignRewardType.coin, 10), // 第1天：金币 x10
      const SignReward(SignRewardType.coin, 20), // 第2天：金币 x20
      const SignReward(SignRewardType.undo, 3), // 第3天：撤销道具 x3
      const SignReward(SignRewardType.reminder, 3), // 第4天：提醒道具 x3
      const SignReward(SignRewardType.coin, 30), // 第5天：金币 x30
      const SignReward(SignRewardType.pipe, 1), // 第6天：增加管子 x1
      const SignReward(SignRewardType.coin, 50), // 第7天：金币 x50
    ];
  }

  List<CumulativeReward> _getCumulativeRewards(int totalDays) {
    final claimedStr = _prefs.getString(_keyCumulativeClaimed) ?? '';
    final claimedList = claimedStr.isEmpty ? <String>[] : claimedStr.split(',');

    // 如果 totalDays 已经被重置为 0，说明进入了新周期，累计宝箱应该全部重置
    // 此时即使存储中还有 claimedList，也应该忽略，因为这是上一个周期的数据
    final shouldIgnoreClaimed = totalDays == 0;

    final rewards = [
      CumulativeReward(
        requiredDays: 14,
        type: SignRewardType.pipe,
        amount: 5,
        claimed: shouldIgnoreClaimed ? false : claimedList.contains('14'),
      ),
      CumulativeReward(
        requiredDays: 21,
        type: SignRewardType.undo,
        amount: 5,
        claimed: shouldIgnoreClaimed ? false : claimedList.contains('21'),
      ),
      CumulativeReward(
        requiredDays: 28,
        type: SignRewardType.reminder,
        amount: 5,
        claimed: shouldIgnoreClaimed ? false : claimedList.contains('28'),
      ),
    ];

    if (shouldIgnoreClaimed) {
      GameLogger.log(GameLogger.tagSignIn, '累计宝箱重置: totalDays=0，强制重置所有宝箱的 claimed 状态为 false');
      GameLogger.log(GameLogger.tagSignIn, '存储的 claimedStr=$claimedStr，但会被忽略');
    } else {
      GameLogger.log(GameLogger.tagSignIn, '累计宝箱状态: totalDays=$totalDays, claimed=$claimedStr');
    }

    return rewards;
  }

  String _dateStr(DateTime d) => '${d.year}-${d.month}-${d.day}';

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    return parsed == null ? null : _onlyDate(parsed);
  }

  /// 检查指定天数是否为自然签到（基于当前周期的完成天数）
  bool _isNaturalSigned(int day, SignInState s) {
    return s.cycleClaimedDays.contains(day);
  }

  /// 获取所有漏签的天数（需要补签的天数）
  Set<int> _getMissedDays(SignInState s) {
    final missedDays = <int>{};

    // 获取已补签的天数
    final claimedMissedStr = _prefs.getString('signin_missed_claimed') ?? '';
    final claimedMissedList = claimedMissedStr.isEmpty ? <int>[] : claimedMissedStr.split(',').map((e) => int.tryParse(e) ?? 0).toList();
    GameLogger.log(GameLogger.tagSignIn, '已补签的天数: $claimedMissedList');

    final logicalToday = _logicalTodayIndex(s);
    final hasSignedToday = s.claimedToday;
    // 遍历1-7天，判断哪些是漏签天
    for (int day = 1; day <= 7; day++) {
      // 如果已经补签了，不算漏签
      if (claimedMissedList.contains(day)) {
        continue;
      }

      // 如果是自然签到，不算漏签
      if (_isNaturalSigned(day, s)) {
        continue;
      }

      final bool isToday = !hasSignedToday && day == logicalToday;
      final bool isPastDay = hasSignedToday
          ? day < logicalToday
          : day < logicalToday;
      if (!isToday && isPastDay) {
        missedDays.add(day);
      }
    }

    GameLogger.log(
      GameLogger.tagSignIn,
      'claimMissed漏签分析: dayIndex=${s.dayIndex}, totalDays=${s.totalSignInDays}, logicalToday=$logicalToday, hasSignedToday=$hasSignedToday, 漏签天数=$missedDays',
    );

    return missedDays;
  }

  int _logicalTodayIndex(SignInState s) {
    if (s.claimedToday) {
      return s.dayIndex == 1 ? 7 : s.dayIndex - 1;
    }
    return s.dayIndex;
  }

  List<int> _readCycleClaimedDays() {
    final stored = _prefs.getString(_keyCycleClaimedDays) ?? '';
    if (stored.isEmpty) return [];
    final parsed = stored
        .split(',')
        .map((e) => int.tryParse(e) ?? 0);
    return _sanitizeCycleClaimed(parsed);
  }

  Future<List<int>> _saveCycleClaimedDays(Iterable<int> days) async {
    final sanitized = _sanitizeCycleClaimed(days);
    await _prefs.setString(_keyCycleClaimedDays, sanitized.join(','));
    return sanitized;
  }

  Future<void> _clearCycleClaimedDays() async {
    await _prefs.setString(_keyCycleClaimedDays, '');
  }

  List<int> _sanitizeCycleClaimed(Iterable<int> days) {
    final sanitized = days
        .where((d) => d >= 1 && d <= 7)
        .toSet()
        .toList()
      ..sort();
    return sanitized;
  }

  // 测试方法
  void resetSignIn() {
    _prefs.setString(_keyLast, '');
    _prefs.setString(_keyFirst, '');
    _prefs.setInt(_keyIndex, 1);
    _prefs.setInt(_keyTotalDays, 0);
    _prefs.setString(_keyCumulativeClaimed, '');
    _prefs.setString(_keyPopupShown, '');
    _prefs.setString('signin_missed_claimed', ''); // 清除补签记录
    _prefs.setString(_keyCycleClaimedDays, '');
    GameLogger.log(GameLogger.tagSignIn, '手动重置签到系统: 清除所有签到数据包括补签记录');
    state = AsyncData(SignInState(
      dayIndex: 1,
      claimedToday: false,
      enabled: true,
      totalSignInDays: 0,
      dailyRewards: _getDailyRewards(),
      cumulativeRewards: _getCumulativeRewards(0),
      lastSignDate: null,
      firstSignDate: null,
      shouldAutoPopup: true,
      lastClaimedReward: null,
      cycleClaimedDays: const [],
    ));
  }

  void addSignInDay() {
    final s = state.value;
    if (s == null) return;

    final newTotalDays = s.totalSignInDays + 1;
    final newCumulativeRewards = _getCumulativeRewards(newTotalDays);

    state = AsyncData(s.copyWith(
      totalSignInDays: newTotalDays,
      cumulativeRewards: newCumulativeRewards,
    ));
  }

  void addSignInWeek() {
    final s = state.value;
    if (s == null) return;

    final newTotalDays = s.totalSignInDays + 7;
    final newCumulativeRewards = _getCumulativeRewards(newTotalDays);

    state = AsyncData(s.copyWith(
      totalSignInDays: newTotalDays,
      cumulativeRewards: newCumulativeRewards,
    ));
  }

  void setSignInDay(int day) {
    final s = state.value;
    if (s == null) return;

    final newTotalDays = day;
    final newCumulativeRewards = _getCumulativeRewards(newTotalDays);

    state = AsyncData(s.copyWith(
      totalSignInDays: newTotalDays,
      cumulativeRewards: newCumulativeRewards,
    ));
  }

  void markTodayClaimed() {
    final s = state.value;
    if (s == null) return;

    state = AsyncData(s.copyWith(claimedToday: true));
  }

  // 便捷调试：设置今日是第几天（1..7），并将今日置为未签
  Future<void> debugSetTodayIndex(int idx) async {
    final s = state.value;
    if (s == null) return;
    final next = idx.clamp(1, 7);
    await _prefs.setInt(_keyIndex, next);
    await _prefs.remove(_keyLast); // 标记今日未签
    await _prefs.remove(_keyPopupShown);
    
    // 如果没有首次签到日期，设置一个基准日期（当前日期减去已签到天数）
    if (s.firstSignDate == null && s.totalSignInDays > 0) {
      final baseDate = _onlyDate(DateTime.now()).subtract(Duration(days: s.totalSignInDays));
      await _prefs.setString(_keyFirst, _dateStr(baseDate));
      state = AsyncData(s.copyWith(
        dayIndex: next,
        claimedToday: false,
        lastSignDate: null,
        firstSignDate: baseDate,
        shouldAutoPopup: true,
      ));
    } else {
      state = AsyncData(s.copyWith(
        dayIndex: next,
        claimedToday: false,
        lastSignDate: null,
        shouldAutoPopup: true,
      ));
    }
  }

  // 便捷调试：设置"今日是否已签"
  Future<void> debugSetClaimedToday(bool claimed) async {
    final s = state.value;
    if (s == null) return;
    if (claimed) {
      final now = _onlyDate(DateTime.now());
      final todayStr = _dateStr(now);
      
      // 如果是首次签到，记录首次签到日期
      if (s.firstSignDate == null) {
        await _prefs.setString(_keyFirst, todayStr);
      }
      
      await _prefs.setString(_keyLast, todayStr);
      await _prefs.setString(_keyPopupShown, todayStr);
      state = AsyncData(s.copyWith(
        claimedToday: true,
        lastSignDate: now,
        firstSignDate: s.firstSignDate ?? now,
        shouldAutoPopup: false,
      ));
    } else {
      await _prefs.remove(_keyLast);
      await _prefs.remove(_keyPopupShown);
      state = AsyncData(s.copyWith(
        claimedToday: false,
        lastSignDate: null,
        shouldAutoPopup: true,
      ));
    }
  }

  // 便捷调试：设置累计签到天数（影响累计奖励解锁）
  Future<void> debugSetTotalDays(int days) async {
    final s = state.value;
    if (s == null) return;
    final d = days.clamp(0, 9999);
    await _prefs.setInt(_keyTotalDays, d);
    final newTable = _getCumulativeRewards(d);
    state =
        AsyncData(s.copyWith(totalSignInDays: d, cumulativeRewards: newTable));
  }

  /// 一键模拟"已连续签到满一周"。
  Future<void> debugSimulateFullWeek() async {
    final s = state.value;
    if (s == null) return;
    final total = s.totalSignInDays;
    final toAdd = (7 - (total % 7)) % 7; // 补齐至7的倍数
    final newTotal = (total >= 7) ? (total + toAdd) : 7; // 至少达到7天
    await _prefs.setInt(_keyTotalDays, newTotal);
    await _prefs.setInt(_keyIndex, 1); // 下一周期从第1天开始
    final now = _onlyDate(DateTime.now());
    final todayStr = _dateStr(now);
    
    // 如果是首次签到，记录首次签到日期（回推7天）
    if (s.firstSignDate == null) {
      final firstDate = now.subtract(const Duration(days: 6));
      await _prefs.setString(_keyFirst, _dateStr(firstDate));
    }
    
    await _prefs.setString(_keyLast, todayStr); // 今日视为已签
    await _prefs.setString(_keyPopupShown, todayStr);
    state = AsyncData(s.copyWith(
      totalSignInDays: newTotal,
      cumulativeRewards: _getCumulativeRewards(newTotal),
      dayIndex: 1,
      claimedToday: true,
      lastSignDate: now,
      firstSignDate: s.firstSignDate ?? now.subtract(const Duration(days: 6)),
      shouldAutoPopup: false,
    ));
  }

  /// 增加累计签到天数（用于调试）。
  Future<void> debugAddTotalDays(int delta) async {
    final s = state.value;
    if (s == null) return;
    final next = (s.totalSignInDays + delta).clamp(0, 999999);
    await _prefs.setInt(_keyTotalDays, next);
    state = AsyncData(s.copyWith(
        totalSignInDays: next, cumulativeRewards: _getCumulativeRewards(next)));
  }
}

final signInProvider = AsyncNotifierProvider<SignInController, SignInState>(
    () => SignInController());
