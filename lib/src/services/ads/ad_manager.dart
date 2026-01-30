import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ads_service.dart';

/// 广告管理器 - 提供统一的广告加载、播放和错误处理逻辑
class AdManager {
  static const Duration _defaultTimeout = Duration(seconds: 10);
  static const int _maxRetryCount = 2;

  late final AdsService _adsService;
  static AdManager? _instance;

  AdManager._(this._adsService);

  /// 获取单例实例
  factory AdManager.getInstance(AdsService adsService) {
    _instance ??= AdManager._(adsService);
    return _instance!;
  }

  /// 播放激励视频广告（带重试机制）
  ///
  /// [placement] 广告位标识，用于数据分析和区分不同场景
  /// [onStart] 广告开始播放时的回调
  /// [onCompleted] 广告成功完成时的回调
  /// [onSkipped] 用户跳过广告时的回调
  /// [onFailed] 广告播放失败时的回调
  /// [timeout] 广告加载超时时间，默认10秒
  /// [maxRetry] 最大重试次数，默认2次
  ///
  /// 返回 [AdResult] 表示广告播放结果
  ///
  /// 使用示例：
  /// ```dart
  /// final result = await AdManager.getInstance(adsService).showRewardedAd(
  ///   placement: 'signin_daily',
  ///   onStart: () => print('广告开始播放'),
  ///   onCompleted: () => print('广告完成，发放奖励'),
  ///   onFailed: (error) => print('广告失败: $error'),
  /// );
  /// if (result == AdResult.completed) {
  ///   // 发放奖励
  /// }
  /// ```
  Future<AdResult> showRewardedAd({
    required String placement,
    VoidCallback? onStart,
    VoidCallback? onCompleted,
    VoidCallback? onSkipped,
    Function(String)? onFailed,
    Duration timeout = _defaultTimeout,
    int maxRetry = _maxRetryCount,
  }) async {
    return await _executeWithRetry<AdResult>(
      operation: () async => _showRewardedOnce(
        placement: placement,
        onStart: onStart,
        onCompleted: onCompleted,
        onSkipped: onSkipped,
        onFailed: onFailed,
        timeout: timeout,
      ),
      placement: placement,
      adType: '激励视频',
      maxRetry: maxRetry,
    );
  }

  /// 播放插屏广告（带重试机制）
  ///
  /// 参数和返回值与 [showRewardedAd] 类似
  Future<AdResult> showInterstitialAd({
    required String placement,
    VoidCallback? onStart,
    VoidCallback? onCompleted,
    VoidCallback? onSkipped,
    Function(String)? onFailed,
    Duration timeout = _defaultTimeout,
    int maxRetry = _maxRetryCount,
  }) async {
    return await _executeWithRetry<AdResult>(
      operation: () async => _showInterstitialOnce(
        placement: placement,
        onStart: onStart,
        onCompleted: onCompleted,
        onSkipped: onSkipped,
        onFailed: onFailed,
        timeout: timeout,
      ),
      placement: placement,
      adType: '插屏',
      maxRetry: maxRetry,
    );
  }

  /// 预加载激励视频广告（可选实现）
  ///
  /// 部分广告SDK支持预加载功能，可以提前准备好广告以减少用户等待时间
  Future<void> preloadRewardedAd(String placement) async {
    try {
      // 这里可以添加具体的预加载逻辑
      // 当前Dummy实现不支持预加载，所以这里只是占位
      debugPrint('预加载激励视频广告: $placement');
    } catch (e) {
      debugPrint('预加载激励视频广告失败: $placement, 错误: $e');
    }
  }

  /// 预加载插屏广告（可选实现）
  Future<void> preloadInterstitialAd(String placement) async {
    try {
      // 这里可以添加具体的预加载逻辑
      debugPrint('预加载插屏广告: $placement');
    } catch (e) {
      debugPrint('预加载插屏广告失败: $placement, 错误: $e');
    }
  }

  /// 执行激励视频广告播放（单次，不重试）
  Future<AdResult> _showRewardedOnce({
    required String placement,
    VoidCallback? onStart,
    VoidCallback? onCompleted,
    VoidCallback? onSkipped,
    Function(String)? onFailed,
    required Duration timeout,
  }) async {
    try {
      onStart?.call();

      final result = await _adsService.showRewarded(placement: placement)
          .timeout(timeout);

      switch (result) {
        case AdResult.completed:
          onCompleted?.call();
          break;
        case AdResult.skipped:
          onSkipped?.call();
          break;
        case AdResult.failed:
          onFailed?.call('广告播放失败');
          break;
      }

      return result;
    } catch (e) {
      final errorMessage = '广告播放异常: $e';
      onFailed?.call(errorMessage);
      return AdResult.failed;
    }
  }

  /// 执行插屏广告播放（单次，不重试）
  Future<AdResult> _showInterstitialOnce({
    required String placement,
    VoidCallback? onStart,
    VoidCallback? onCompleted,
    VoidCallback? onSkipped,
    Function(String)? onFailed,
    required Duration timeout,
  }) async {
    try {
      onStart?.call();

      final result = await _adsService.showInterstitial(placement: placement)
          .timeout(timeout);

      switch (result) {
        case AdResult.completed:
          onCompleted?.call();
          break;
        case AdResult.skipped:
          onSkipped?.call();
          break;
        case AdResult.failed:
          onFailed?.call('广告播放失败');
          break;
      }

      return result;
    } catch (e) {
      final errorMessage = '广告播放异常: $e';
      onFailed?.call(errorMessage);
      return AdResult.failed;
    }
  }

  /// 带重试机制的通用执行器
  Future<T> _executeWithRetry<T>({
    required Future<T> Function() operation,
    required String placement,
    required String adType,
    required int maxRetry,
  }) async {
    int attempt = 0;
    String? lastError;

    while (attempt <= maxRetry) {
      try {
        final result = await operation();

        // 如果是成功结果，直接返回
        if (result is AdResult && result != AdResult.failed) {
          return result;
        }

        // 如果是失败结果且还有重试机会，继续重试
        if (result is AdResult && result == AdResult.failed && attempt < maxRetry) {
          lastError = '广告播放失败';
          attempt++;
          await Future.delayed(Duration(milliseconds: 500 * attempt)); // 递增延迟
          continue;
        }

        return result;
      } catch (e) {
        lastError = e.toString();
        attempt++;

        if (attempt <= maxRetry) {
          await Future.delayed(Duration(milliseconds: 500 * attempt)); // 递增延迟
        }
      }
    }

    // 所有重试都失败了
    debugPrint('$adType广告播放失败，已重试$maxRetry次: placement=$placement, 错误=$lastError');
    throw Exception('$adType广告播放失败: $lastError');
  }

  /// 检查广告是否可用（可选实现）
  ///
  /// 返回true表示广告已准备好可以播放，false表示广告不可用
  Future<bool> isAdReady(String placement, {bool isRewarded = true}) async {
    try {
      // 这里可以添加具体的广告可用性检查逻辑
      // 当前Dummy实现总是返回true
      return true;
    } catch (e) {
      debugPrint('检查广告可用性失败: $placement, 错误: $e');
      return false;
    }
  }
}

/// 广告位常量定义
///
/// 为了统一管理所有广告位，避免硬编码和拼写错误
class AdPlacements {
  // 签到系统
  static const String signinDaily = 'signin_daily'; // 日常签到
  static const String signinMissed = 'signin_missed'; // 补签
  static const String signinCumulative = 'signin_cumulative'; // 累计奖励
  static const String signinDouble = 'signin_double'; // 双倍签到

  // 游戏内道具获取
  static String itemAcquire(String itemType) => 'item_acquire_$itemType';

  // 宝藏系统
  static String treasureCard(int index) => 'treasure_card_$index';

  // 图片下载
  static const String photoDownload = 'photo_download';

  // 转盘系统
  static const String spin = 'spin';

  // 分数系统
  static const String levelClaimX3 = 'level_claim_x3'; // 激励视频 x3
  static const String levelClaim = 'level_claim'; // 插屏，奖励不变

  // 通用广告位
  static const String appOpen = 'app_open'; // 应用开屏
  static const String levelComplete = 'level_complete'; // 关卡完成
  static const String dailyBonus = 'daily_bonus'; // 每日奖励
}