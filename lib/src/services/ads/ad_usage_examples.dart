import 'package:flutter/material.dart';
import 'ad_manager.dart';
import 'ads_service.dart';

/// 广告使用示例 - 展示如何在实际项目中使用 AdManager
class AdUsageExamples {
  late final AdManager _adManager;

  /// 初始化广告管理器
  void initialize(AdsService adsService) {
    _adManager = AdManager.getInstance(adsService);
  }

  /// 示例1：签到系统中的激励视频广告
  Future<bool> showSignInDailyAd() async {
    debugPrint('=== 示例1：签到系统激励视频广告 ===');

    try {
      final result = await _adManager.showRewardedAd(
        placement: AdPlacements.signinDaily,
        onStart: () {
          debugPrint('签到广告：开始播放');
          // 这里可以显示加载UI
        },
        onCompleted: () {
          debugPrint('签到广告：播放完成，发放奖励');
          // 发放签到奖励
        },
        onSkipped: () {
          debugPrint('签到广告：用户跳过广告');
          // 显示提示信息
        },
        onFailed: (error) {
          debugPrint('签到广告：播放失败 - $error');
          // 显示错误提示
        },
      );

      return result == AdResult.completed;
    } catch (e) {
      debugPrint('签到广告：异常 - $e');
      return false;
    }
  }

  /// 示例2：补签功能
  Future<bool> showSignInMissedAd(int missedDay) async {
    debugPrint('=== 示例2：补签功能 (第$missedDay天) ===');

    final result = await _adManager.showRewardedAd(
      placement: AdPlacements.signinMissed,
      onStart: () => debugPrint('补签广告：开始加载'),
      onCompleted: () {
        debugPrint('补签广告：完成，补签第$missedDay天成功');
        // 执行补签逻辑
      },
      onFailed: (error) => debugPrint('补签广告失败: $error'),
    );

    return result == AdResult.completed;
  }

  /// 示例3：游戏道具获取
  Future<bool> showItemAcquireAd(String itemType) async {
    debugPrint('=== 示例3：道具获取广告 ($itemType) ===');

    // 先检查广告是否可用
    final isReady = await _adManager.isAdReady(
      AdPlacements.itemAcquire(itemType),
      isRewarded: true,
    );

    if (!isReady) {
      debugPrint('道具广告：广告尚未准备好');
      return false;
    }

    final result = await _adManager.showRewardedAd(
      placement: AdPlacements.itemAcquire(itemType),
      maxRetry: 1, // 道具广告只重试1次，提升用户体验
      onCompleted: () {
        debugPrint('道具广告：完成，发放$itemType道具');
        // 发放道具逻辑
      },
      onSkipped: () {
        debugPrint('道具广告：用户跳过，不发放道具');
      },
      onFailed: (error) {
        debugPrint('道具广告：失败 - $error');
        // 可以提供备选方案，比如观看其他广告
      },
    );

    return result == AdResult.completed;
  }

  /// 示例4：应用开屏插屏广告
  Future<void> showAppOpenAd() async {
    debugPrint('=== 示例4：应用开屏插屏广告 ===');

    try {
      final result = await _adManager.showInterstitialAd(
        placement: AdPlacements.appOpen,
        timeout: Duration(seconds: 5), // 开屏广告超时时间短一些
        onCompleted: () => debugPrint('开屏广告：完成'),
        onFailed: (error) => debugPrint('开屏广告：失败 - $error'),
      );

      if (result == AdResult.completed) {
        debugPrint('开屏广告展示成功');
      }
    } catch (e) {
      debugPrint('开屏广告异常：$e');
      // 开屏广告失败不应该影响应用正常启动
    }
  }

  /// 示例5：宝藏卡片广告
  Future<bool> showTreasureCardAd(int cardIndex) async {
    debugPrint('=== 示例5：宝藏卡片广告 (第${cardIndex}张) ===');

    final result = await _adManager.showRewardedAd(
      placement: AdPlacements.treasureCard(cardIndex),
      onStart: () => debugPrint('宝藏卡片${cardIndex}：开始加载'),
      onCompleted: () {
        debugPrint('宝藏卡片${cardIndex}：完成，翻开卡片');
        // 翻开宝藏卡片的逻辑
      },
      onSkipped: () {
        debugPrint('宝藏卡片${cardIndex}：用户跳过');
      },
      onFailed: (error) {
        debugPrint('宝藏卡片${cardIndex}：失败 - $error');
      },
    );

    return result == AdResult.completed;
  }

  /// 示例6：批量预加载广告
  Future<void> preloadCommonAds() async {
    debugPrint('=== 示例6：批量预加载常用广告 ===');

    try {
      // 预加载一些常用的广告位
      final futures = <Future>[];

      // 签到相关广告
      futures.add(_adManager.preloadRewardedAd(AdPlacements.signinDaily));
      futures.add(_adManager.preloadRewardedAd(AdPlacements.signinMissed));

      // 游戏内广告
      futures.add(_adManager.preloadRewardedAd(AdPlacements.itemAcquire('coin')));
      futures.add(_adManager.preloadRewardedAd(AdPlacements.itemAcquire('hint')));

      // 其他常用广告
      futures.add(_adManager.preloadRewardedAd(AdPlacements.spin));
      futures.add(_adManager.preloadRewardedAd(AdPlacements.photoDownload));

      await Future.wait(futures);
      debugPrint('广告预加载完成');
    } catch (e) {
      debugPrint('广告预加载失败: $e');
      // 预加载失败不应该影响正常功能
    }
  }

  /// 示例7：高级错误处理和重试策略
  Future<bool> showAdWithAdvancedErrorHandling() async {
    debugPrint('=== 示例7：高级错误处理 ===');

    try {
      final result = await _adManager.showRewardedAd(
        placement: AdPlacements.levelClaimX3,
        maxRetry: 3, // 增加重试次数
        timeout: Duration(seconds: 15), // 增加超时时间
        onStart: () {
          debugPrint('高级广告：开始播放');
          // 显示详细的加载状态
        },
        onCompleted: () {
          debugPrint('高级广告：播放完成');
          // 记录成功事件
        },
        onSkipped: () {
          debugPrint('高级广告：用户跳过');
          // 分析跳过原因
        },
        onFailed: (error) {
          debugPrint('高级广告：播放失败 - $error');
          // 根据错误类型进行不同处理
          _handleAdError(error);
        },
      );

      return result == AdResult.completed;
    } catch (e) {
      debugPrint('高级广告：系统异常 - $e');
      // 系统级异常处理
      _handleSystemException(e);
      return false;
    }
  }

  /// 处理广告错误的私有方法
  void _handleAdError(String error) {
    if (error.contains('网络')) {
      debugPrint('网络相关错误，提示用户检查网络');
    } else if (error.contains('超时')) {
      debugPrint('超时错误，建议稍后重试');
    } else if (error.contains('加载')) {
      debugPrint('加载失败，可能是广告库存不足');
    } else {
      debugPrint('未知错误：$error');
    }
  }

  /// 处理系统异常的私有方法
  void _handleSystemException(dynamic exception) {
    debugPrint('系统异常，需要上报: $exception');
    // 这里可以添加异常上报逻辑
  }
}

/// Flutter Widget 中的广告使用示例
class AdUsageWidgetExample extends StatefulWidget {
  @override
  _AdUsageWidgetExampleState createState() => _AdUsageWidgetExampleState();
}

class _AdUsageWidgetExampleState extends State<AdUsageWidgetExample> {
  final AdUsageExamples _adExamples = AdUsageExamples();
  bool _isLoading = false;
  String _statusMessage = '准备就绪';

  @override
  void initState() {
    super.initState();
    // 初始化广告管理器（这里使用Dummy实现作为示例）
    _adExamples.initialize(DummyAdsService());

    // 预加载一些广告
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adExamples.preloadCommonAds();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('广告使用示例'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态显示
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (_isLoading)
                    Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // 示例按钮
            _buildExampleButton(
              '签到激励视频',
              () => _showAdExample('signin'),
            ),
            _buildExampleButton(
              '道具获取广告',
              () => _showAdExample('item'),
            ),
            _buildExampleButton(
              '宝藏卡片广告',
              () => _showAdExample('treasure'),
            ),
            _buildExampleButton(
              '高级错误处理',
              () => _showAdExample('advanced'),
            ),
            _buildExampleButton(
              '重新预加载广告',
              () => _preloadAds(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleButton(String title, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        child: Text(title),
      ),
    );
  }

  Future<void> _showAdExample(String type) async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在播放广告...';
    });

    bool success = false;

    try {
      switch (type) {
        case 'signin':
          success = await _adExamples.showSignInDailyAd();
          break;
        case 'item':
          success = await _adExamples.showItemAcquireAd('coin');
          break;
        case 'treasure':
          success = await _adExamples.showTreasureCardAd(1);
          break;
        case 'advanced':
          success = await _adExamples.showAdWithAdvancedErrorHandling();
          break;
      }

      setState(() {
        _isLoading = false;
        _statusMessage = success ? '广告播放成功！' : '广告播放失败或被跳过';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '广告播放异常: $e';
      });
    }
  }

  Future<void> _preloadAds() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在预加载广告...';
    });

    try {
      await _adExamples.preloadCommonAds();
      setState(() {
        _isLoading = false;
        _statusMessage = '广告预加载完成';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '广告预加载失败: $e';
      });
    }
  }
}