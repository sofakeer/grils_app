import '../analytics_manager.dart';

enum AdResult { completed, skipped, failed }

abstract class AdsService {
  /// 展示激励视频。
  Future<AdResult> showRewarded({required String placement});

  /// 展示插屏。
  Future<AdResult> showInterstitial({required String placement});
}

/// 占位实现（全局通用）：
/// - 不依赖任何第三方 SDK；
/// - 通过延时模拟加载与播放；
/// - 恒定返回 completed（成功）。
class DummyAdsService implements AdsService {
  final Duration latency;
  const DummyAdsService({this.latency = const Duration(milliseconds: 800)});

  @override
  Future<AdResult> showRewarded({required String placement}) async {
    // 记录激励视频广告请求埋点
    final analytics = AnalyticsManager();
    await analytics.logRewardRequest();
    await analytics.logRewardTryShow();
    
    await Future.delayed(latency);
    
    // 记录激励视频广告展示埋点
    await analytics.logRewardShow();
    
    return AdResult.completed;
  }

  @override
  Future<AdResult> showInterstitial({required String placement}) async {
    // 记录插屏广告请求埋点
    final analytics = AnalyticsManager();
    await analytics.logIntRequest();
    await analytics.logIntTryShow();
    
    await Future.delayed(latency);
    
    // 记录插屏广告展示埋点
    await analytics.logIntShow();
    
    return AdResult.completed;
  }
}
