import 'package:flutter/material.dart';

/// 广告管理器
/// 提供统一的广告调用接口
class AdManager {
  static AdManager? _instance;
  static AdManager get instance => _instance ??= AdManager._();
  
  AdManager._();

  /// 显示激励视频广告
  /// [context] - 上下文
  /// [onAdCompleted] - 广告完成回调
  /// [onAdFailed] - 广告失败回调
  Future<bool> showRewardedAd({
    required BuildContext context,
    VoidCallback? onAdCompleted,
    VoidCallback? onAdFailed,
  }) async {
    // 这里模拟广告播放过程
    return await _showMockAd(context, onAdCompleted, onAdFailed);
  }

  /// 模拟广告播放
  Future<bool> _showMockAd(
    BuildContext context,
    VoidCallback? onAdCompleted,
    VoidCallback? onAdFailed,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _MockAdDialog(
          onAdCompleted: onAdCompleted,
          onAdFailed: onAdFailed,
        );
      },
    ) ?? false;
  }
}

/// 模拟广告弹窗
class _MockAdDialog extends StatefulWidget {
  final VoidCallback? onAdCompleted;
  final VoidCallback? onAdFailed;

  const _MockAdDialog({
    this.onAdCompleted,
    this.onAdFailed,
  });

  @override
  State<_MockAdDialog> createState() => _MockAdDialogState();
}

class _MockAdDialogState extends State<_MockAdDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  int _countdown = 5; // 5秒广告时间

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _startCountdown();
    _controller.forward();
  }

  void _startCountdown() async {
    for (int i = 5; i > 0; i--) {
      if (mounted) {
        setState(() {
          _countdown = i;
        });
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    
    if (mounted) {
      // 广告播放完成
      widget.onAdCompleted?.call();
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Container(
        width: 300,
        height: 200,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎬 模拟广告播放中...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            // 进度条
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Colors.grey[700],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '倒计时: $_countdown 秒',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              '广告结束后获得双倍奖励',
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}