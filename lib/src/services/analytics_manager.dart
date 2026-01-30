// 埋点事件类型枚举
import 'logger.dart';
import '../core/locator.dart';
import 'storage/prefs_service.dart';

enum AnalyticsEvent {
  // 基础事件
  user, // 应用启动
  userVc1, // 应用启动，带版本号
  loading, // 进入loading页面
  home, // 进入主页
  
  // 游戏次数和时长
  playCount, // 累计玩的关卡数量：playcount_1 到 playcount_20
  playTime, // 累计游戏时长：playtime_1 到 playtime_30
  
  // 关卡相关
  start, // 进入关卡-不区分模式
  pass, // 通关关卡-不区分模式
  startLevel, // 启动关卡-普通模式关卡：start_level_1 到 start_level_9, start_level_1x, start_level_2x
  startLevelBase, // 启动普通关卡（无编号）：start_level
  passLevel, // 通关普通关卡
  
  // 特殊关卡
  startSecret, // 进入私密套图关卡
  passSecret, // 通关私密套图关卡
  startTreasure, // 进入通行宝箱关卡
  passTreasure, // 通关通行宝箱关卡
  
  // 广告相关
  adRequest, // 广告请求，不区分广告种类
  adTryShow, // 广告尝试展示，不区分广告种类
  adShow, // 广告展示，不区分广告种类
  
  // 插屏广告
  intRequest, // 插屏广告请求
  intTryShow, // 插屏广告尝试展示
  intShow, // 插屏广告展示
  
  // 激励视频广告
  rewardRequest, // 激励视频广告请求
  rewardTryShow, // 激励视频尝试展示
  rewardShow, // 激励视频展示
  
  // 带版本号的广告事件
  intRequestVc1, // 插屏广告请求，携带版本参数
  intTryShowVc1, // 插屏广告尝试展示，携带版本参数
  intShowVc1, // 插屏广告展示，携带版本参数
  rewardRequestVc1, // 激励视频广告请求，携带版本参数
  rewardTryShowVc1, // 激励视频尝试展示，携带版本参数
  rewardShowVc1, // 激励视频展示，携带版本参数
}

class AnalyticsManager {
  static final AnalyticsManager _instance = AnalyticsManager._internal();

  factory AnalyticsManager() => _instance;

  AnalyticsManager._internal();

  // 记录基础事件
  Future<void> logEvent(AnalyticsEvent event, [Map<String, dynamic>? parameters]) async {
    final eventName = _getEventName(event);
    Log.game('Analytics Event: $eventName');
    if (parameters != null) {
      Log.game('Parameters: $parameters');
    }

    // TODO: 在这里实现具体的埋点发送逻辑
    // 例如发送到Firebase Analytics, 自建后台等
  }

  // 记录应用启动埋点
  Future<void> logUser() async {
    await logEvent(AnalyticsEvent.user);
  }

  // 记录应用启动埋点（带版本号）
  Future<void> logUserVc1() async {
    await logEvent(AnalyticsEvent.userVc1);
  }

  // 记录进入loading页面埋点
  Future<void> logLoading() async {
    await logEvent(AnalyticsEvent.loading);
  }

  // 记录进入主页埋点
  Future<void> logHome() async {
    await logEvent(AnalyticsEvent.home);
  }

  // 记录累计玩的关卡数量埋点：playcount_1 到 playcount_20
  Future<void> logPlayCount(int count) async {
    // 为保持兼容，仍保留该方法，但建议使用 incrementAndLogPlayCount()
    final normalized = count.clamp(1, 20);
    final eventName = "playcount_$normalized";
    Log.game('Analytics Event: $eventName');
    // TODO: 发送埋点
  }

  // 自增并上报累计关卡次数（跨模式累计）
  Future<int> incrementAndLogPlayCount() async {
    const String key = 'analytics.play_count_total';
    final prefs = ServiceLocator.instance.get<PrefsService>();
    final current = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, current);
    // 事件名按上限20进行分桶
    final bucket = current.clamp(1, 20);
    final eventName = "playcount_$bucket";
    Log.game('Analytics Event: $eventName (total=$current)');
    // TODO: 发送埋点
    return current;
  }

  // 记录累计游戏时长埋点：playtime_1 到 playtime_30
  Future<void> logPlayTime(int minutes) async {
    if (minutes < 1 || minutes > 30) {
      Log.game('Play time out of range: $minutes, should be 1-30');
      return;
    }
    
    final eventName = "playtime_$minutes";
    Log.game('Analytics Event: $eventName');
    // TODO: 发送埋点
  }

  // 记录进入关卡埋点（不区分模式）
  Future<void> logStart() async {
    await logEvent(AnalyticsEvent.start);
  }

  // 记录通关关卡埋点（不区分模式）
  Future<void> logPass() async {
    await logEvent(AnalyticsEvent.pass);
  }

  // 记录启动普通模式关卡埋点：start_level_1 到 start_level_9, start_level_1x, start_level_2x
  Future<void> logStartLevel(int level) async {
    if (level > 30) {
      Log.game('Level out of range: $level, should be <= 30');
      return;
    }

    final levelSuffix = _formatLevelNumber(level);
    final eventName = "start_level_$levelSuffix";

    Log.game('Analytics Event: $eventName (level: $level)');
    // TODO: 发送埋点
  }

  // 记录启动普通关卡（无编号）埋点：start_level
  Future<void> logStartLevelBase() async {
    await logEvent(AnalyticsEvent.startLevelBase);
  }

  // 记录通关普通关卡埋点
  Future<void> logPassLevel() async {
    await logEvent(AnalyticsEvent.passLevel);
  }

  // 记录进入私密套图关卡埋点
  Future<void> logStartSecret() async {
    await logEvent(AnalyticsEvent.startSecret);
  }

  // 记录通关私密套图关卡埋点
  Future<void> logPassSecret() async {
    await logEvent(AnalyticsEvent.passSecret);
  }

  // 记录进入通行宝箱关卡埋点
  Future<void> logStartTreasure() async {
    await logEvent(AnalyticsEvent.startTreasure);
  }

  // 记录通关通行宝箱关卡埋点
  Future<void> logPassTreasure() async {
    await logEvent(AnalyticsEvent.passTreasure);
  }

  // ========== 广告相关埋点 ==========
  
  // 记录广告请求埋点（不区分广告种类）
  Future<void> logAdRequest() async {
    await logEvent(AnalyticsEvent.adRequest);
  }

  // 记录广告尝试展示埋点（不区分广告种类）
  Future<void> logAdTryShow() async {
    await logEvent(AnalyticsEvent.adTryShow);
  }

  // 记录广告展示埋点（不区分广告种类）
  Future<void> logAdShow() async {
    await logEvent(AnalyticsEvent.adShow);
  }

  // 记录插屏广告请求埋点
  Future<void> logIntRequest() async {
    await logEvent(AnalyticsEvent.intRequest);
  }

  // 记录插屏广告尝试展示埋点
  Future<void> logIntTryShow() async {
    await logEvent(AnalyticsEvent.intTryShow);
  }

  // 记录插屏广告展示埋点
  Future<void> logIntShow() async {
    await logEvent(AnalyticsEvent.intShow);
  }

  // 记录激励视频广告请求埋点
  Future<void> logRewardRequest() async {
    await logEvent(AnalyticsEvent.rewardRequest);
  }

  // 记录激励视频尝试展示埋点
  Future<void> logRewardTryShow() async {
    await logEvent(AnalyticsEvent.rewardTryShow);
  }

  // 记录激励视频展示埋点
  Future<void> logRewardShow() async {
    await logEvent(AnalyticsEvent.rewardShow);
  }

  // ========== 带版本号的广告埋点 ==========
  
  // 记录插屏广告请求埋点（携带版本参数）
  Future<void> logIntRequestVc1() async {
    await logEvent(AnalyticsEvent.intRequestVc1);
  }

  // 记录插屏广告尝试展示埋点（携带版本参数）
  Future<void> logIntTryShowVc1() async {
    await logEvent(AnalyticsEvent.intTryShowVc1);
  }

  // 记录插屏广告展示埋点（携带版本参数）
  Future<void> logIntShowVc1() async {
    await logEvent(AnalyticsEvent.intShowVc1);
  }

  // 记录激励视频广告请求埋点（携带版本参数）
  Future<void> logRewardRequestVc1() async {
    await logEvent(AnalyticsEvent.rewardRequestVc1);
  }

  // 记录激励视频尝试展示埋点（携带版本参数）
  Future<void> logRewardTryShowVc1() async {
    await logEvent(AnalyticsEvent.rewardTryShowVc1);
  }

  // 记录激励视频展示埋点（携带版本参数）
  Future<void> logRewardShowVc1() async {
    await logEvent(AnalyticsEvent.rewardShowVc1);
  }

  // 获取基础事件名称
  String _getEventName(AnalyticsEvent event) {
    switch (event) {
      // 基础事件
      case AnalyticsEvent.user:
        return 'user';
      case AnalyticsEvent.userVc1:
        return 'user_vc1';
      case AnalyticsEvent.loading:
        return 'loading';
      case AnalyticsEvent.home:
        return 'home';
      
      // 游戏次数和时长
      case AnalyticsEvent.playCount:
        return 'playcount_';
      case AnalyticsEvent.playTime:
        return 'playtime_';
      
      // 关卡相关
      case AnalyticsEvent.start:
        return 'start';
      case AnalyticsEvent.pass:
        return 'pass';
      case AnalyticsEvent.startLevel:
        return 'start_level_';
      case AnalyticsEvent.startLevelBase:
        return 'start_level';
      case AnalyticsEvent.passLevel:
        return 'pass_level';
      
      // 特殊关卡
      case AnalyticsEvent.startSecret:
        return 'start_secret';
      case AnalyticsEvent.passSecret:
        return 'pass_secret';
      case AnalyticsEvent.startTreasure:
        return 'start_trsasure';
      case AnalyticsEvent.passTreasure:
        return 'pass_trsasure';
      
      // 广告相关
      case AnalyticsEvent.adRequest:
        return 'ad_request';
      case AnalyticsEvent.adTryShow:
        return 'ad_try_show';
      case AnalyticsEvent.adShow:
        return 'ad_show';
      
      // 插屏广告
      case AnalyticsEvent.intRequest:
        return 'int_request';
      case AnalyticsEvent.intTryShow:
        return 'int_try_show';
      case AnalyticsEvent.intShow:
        return 'int_show';
      
      // 激励视频广告
      case AnalyticsEvent.rewardRequest:
        return 'reward_request';
      case AnalyticsEvent.rewardTryShow:
        return 'reward_try_show';
      case AnalyticsEvent.rewardShow:
        return 'reward_show';
      
      // 带版本号的广告事件
      case AnalyticsEvent.intRequestVc1:
        return 'int_request_vc1';
      case AnalyticsEvent.intTryShowVc1:
        return 'int_try_show_vc1';
      case AnalyticsEvent.intShowVc1:
        return 'int_show_vc1';
      case AnalyticsEvent.rewardRequestVc1:
        return 'reward_request_vc1';
      case AnalyticsEvent.rewardTryShowVc1:
        return 'reward_try_show_vc1';
      case AnalyticsEvent.rewardShowVc1:
        return 'reward_show_vc1';
    }
  }

  // 格式化关卡编号：1~9, 1x, 2x
  String _formatLevelNumber(int level) {
    if (level <= 9) {
      return level.toString();
    } else if (level >= 10 && level <= 19) {
      return '1x';
    } else if (level >= 20 && level <= 29) {
      return '2x';
    } else {
      return '2x'; // 超过29也使用2x，但实际上超过30不会调用
    }
  }

  // ========== 便捷方法 ==========
  
  // 便捷方法：记录页面进入
  Future<void> logPageEnter(String pageName) async {
    switch (pageName) {
      case 'loading':
        await logLoading();
        break;
      case 'user':
        await logUser();
        break;
      case 'user_vc1':
        await logUserVc1();
        break;
    }
  }

  // 便捷方法：记录游戏开始
  Future<void> logGameStart({
    required int level,
    bool isSecret = false,
    bool isTreasure = false,
  }) async {
    // 记录总的开始埋点
    await logStart();

    // 根据关卡类型记录对应的埋点
    if (isSecret) {
      await logStartSecret();
    } else if (isTreasure) {
      await logStartTreasure();
    } else {
      // 普通关卡 - 同时记录 start_level 和 start_level_X
      await logStartLevelBase(); // start_level
      await logStartLevel(level); // start_level_1, start_level_2, etc.
    }
  }

  // 便捷方法：记录游戏结束
  Future<void> logGameEnd({
    required int level,
    required bool isSuccess,
    bool isSecret = false,
    bool isTreasure = false,
  }) async {
    if (isSuccess) {
      // 记录总的通关埋点
      await logPass();
      
      // 根据关卡类型记录对应的通关埋点
      if (isSecret) {
        await logPassSecret();
      } else if (isTreasure) {
        await logPassTreasure();
      } else {
        // 普通关卡
        await logPassLevel();
      }
    }
  }

  // 便捷方法：记录广告事件
  Future<void> logAdEvent({
    required String adType, // 'int', 'reward', 'general'
    required String action, // 'request', 'try_show', 'show'
    bool withVersion = false,
  }) async {
    final methodName = 'log${adType.toUpperCase()}${action.toUpperCase()}${withVersion ? 'Vc1' : ''}';
    
    switch (methodName) {
      case 'logINTREQUEST':
        await logIntRequest();
        break;
      case 'logINTTRY_SHOW':
        await logIntTryShow();
        break;
      case 'logINTSHOW':
        await logIntShow();
        break;
      case 'logREWARDREQUEST':
        await logRewardRequest();
        break;
      case 'logREWARDTRY_SHOW':
        await logRewardTryShow();
        break;
      case 'logREWARDSHOW':
        await logRewardShow();
        break;
      case 'logINTREQUESTVC1':
        await logIntRequestVc1();
        break;
      case 'logINTTRY_SHOWVC1':
        await logIntTryShowVc1();
        break;
      case 'logINTSHOWVC1':
        await logIntShowVc1();
        break;
      case 'logREWARDREQUESTVC1':
        await logRewardRequestVc1();
        break;
      case 'logREWARDTRY_SHOWVC1':
        await logRewardTryShowVc1();
        break;
      case 'logREWARDSHOWVC1':
        await logRewardShowVc1();
        break;
      case 'logGENERALREQUEST':
        await logAdRequest();
        break;
      case 'logGENERALTRY_SHOW':
        await logAdTryShow();
        break;
      case 'logGENERALSHOW':
        await logAdShow();
        break;
      default:
        Log.game('Unknown ad event: $methodName');
    }
  }
}
