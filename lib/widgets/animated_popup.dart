import 'package:flutter/material.dart';
import '../managers/audio_manager.dart';

class AnimatedPopup extends StatefulWidget {
  final Widget child;
  final bool showPopup;
  final VoidCallback? onClose;
  final Duration animationDuration;
  final bool barrierDismissible;
  final Color? barrierColor;

  const AnimatedPopup({
    super.key,
    required this.child,
    required this.showPopup,
    this.onClose,
    this.animationDuration = const Duration(milliseconds: 300),
    this.barrierDismissible = true,
    this.barrierColor,
  });

  @override
  State<AnimatedPopup> createState() => _AnimatedPopupState();

  /// 显示弹窗的静态方法
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    Duration animationDuration = const Duration(milliseconds: 300), // 更快的动画
    bool barrierDismissible = true,
    Color? barrierColor,
  }) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      builder: (BuildContext context) {
        return AnimatedPopupDialog(
          animationDuration: animationDuration,
          child: child,
        );
      },
    );
  }
}

class _AnimatedPopupState extends State<AnimatedPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic, // 平滑的打开动画，无回弹
      reverseCurve: Curves.easeInCubic, // 快速平滑的关闭动画
    ));

    if (widget.showPopup) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showPopup != oldWidget.showPopup) {
      if (widget.showPopup) {
        _controller.forward();
      } else {
        _closeWithAnimation();
      }
    }
  }

  void _closeWithAnimation() async {
    await AudioManager().playExit();
    // 关闭动画更快，只需要原来时间的一半
    await _controller.reverse();
    if (widget.onClose != null) {
      widget.onClose!();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// 用于Dialog的动画弹窗组件
class AnimatedPopupDialog extends StatefulWidget {
  final Widget child;
  final Duration animationDuration;

  const AnimatedPopupDialog({
    super.key,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedPopupDialog> createState() => _AnimatedPopupDialogState();
}

class _AnimatedPopupDialogState extends State<AnimatedPopupDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic, // 平滑的打开动画，无回弹
      reverseCurve: Curves.easeInCubic, // 快速平滑的关闭动画
    ));

    // 播放弹窗打开音效并开始动画
    _playOpenSoundAndStartAnimation();
  }

  void _playOpenSoundAndStartAnimation() async {
    // 立即播放音效，不等待
    AudioManager().playPopupOpen();
    // 开始动画
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void closeWithAnimation() async {
    // 立即播放关闭音效，不等待
    AudioManager().playExit();
    // 关闭动画使用更快的时长
    _controller.duration = const Duration(milliseconds: 150);
    await _controller.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 点击外部关闭时也使用快速动画
        _controller.duration = const Duration(milliseconds: 150);
        await _controller.reverse();
        return true;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}