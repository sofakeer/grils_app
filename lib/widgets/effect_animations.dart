import 'package:flutter/material.dart';
import 'package:spine_flutter/spine_flutter.dart';

/// 金币特效动画组件
class CoinEffectAnimation extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback? onAnimationComplete;
  
  const CoinEffectAnimation({
    super.key,
    this.isPlaying = false,
    this.onAnimationComplete,
  });

  @override
  State<CoinEffectAnimation> createState() => _CoinEffectAnimationState();
}

class _CoinEffectAnimationState extends State<CoinEffectAnimation> {
  SpineWidgetController? _spineController;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initializeSpine();
  }

  void _initializeSpine() {
    try {
      _spineController = SpineWidgetController(onInitialized: (controller) {
        if (mounted) {
          setState(() {
            _isReady = true;
          });
          
          if (widget.isPlaying) {
            _playEffect();
          }
        }
      });
    } catch (e) {
      print('Coin effect spine initialization failed: $e');
    }
  }

  void _playEffect() {
    if (_spineController == null || !_isReady) return;
    
    try {
      final animations = _spineController!.skeleton.getData()?.getAnimations();
      if (animations != null && animations.isNotEmpty) {
        final effectAnim = animations.first;
        final duration = effectAnim.getDuration();
        
        _spineController!.animationState.setAnimationByName(0, effectAnim.getName(), false);
        
        // 动画完成后的回调
        Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
          if (mounted && widget.onAnimationComplete != null) {
            widget.onAnimationComplete!();
          }
        });
      }
    } catch (e) {
      print('Coin effect play failed: $e');
    }
  }

  @override
  void didUpdateWidget(CoinEffectAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying && _isReady) {
      _playEffect();
    }
  }

  @override
  void dispose() {
    _spineController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_spineController == null || !_isReady) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: SpineWidget.fromAsset(
        "assets/spine/Coin_Eff01.atlas",
        "assets/spine/Coin_Eff01.skel",
        _spineController!,
        boundsProvider: const SetupPoseBounds(),
      ),
    );
  }
}

/// 爱心特效动画组件
class HeartEffectAnimation extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback? onAnimationComplete;
  
  const HeartEffectAnimation({
    super.key,
    this.isPlaying = false,
    this.onAnimationComplete,
  });

  @override
  State<HeartEffectAnimation> createState() => _HeartEffectAnimationState();
}

class _HeartEffectAnimationState extends State<HeartEffectAnimation> {
  SpineWidgetController? _spineController;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initializeSpine();
  }

  void _initializeSpine() {
    try {
      _spineController = SpineWidgetController(onInitialized: (controller) {
        if (mounted) {
          setState(() {
            _isReady = true;
          });
          
          if (widget.isPlaying) {
            _playEffect();
          }
        }
      });
    } catch (e) {
      print('Heart effect spine initialization failed: $e');
    }
  }

  void _playEffect() {
    if (_spineController == null || !_isReady) return;
    
    try {
      final animations = _spineController!.skeleton.getData()?.getAnimations();
      if (animations != null && animations.isNotEmpty) {
        final effectAnim = animations.first;
        final duration = effectAnim.getDuration();
        
        _spineController!.animationState.setAnimationByName(0, effectAnim.getName(), false);
        
        // 动画完成后的回调
        Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
          if (mounted && widget.onAnimationComplete != null) {
            widget.onAnimationComplete!();
          }
        });
      }
    } catch (e) {
      print('Heart effect play failed: $e');
    }
  }

  @override
  void didUpdateWidget(HeartEffectAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying && _isReady) {
      _playEffect();
    }
  }

  @override
  void dispose() {
    _spineController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_spineController == null || !_isReady) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: SpineWidget.fromAsset(
        "assets/spine/Heart_Eff01.atlas",
        "assets/spine/Heart_Eff01.skel",
        _spineController!,
        boundsProvider: const SetupPoseBounds(),
      ),
    );
  }
}

/// 效果显示管理器 - 用于在指定位置显示特效
class EffectOverlay {
  static OverlayEntry? _currentOverlay;

  /// 显示金币特效
  static void showCoinEffect(BuildContext context, {Offset? position}) {
    _showEffect(
      context,
      CoinEffectAnimation(
        isPlaying: true,
        onAnimationComplete: () {
          _hideCurrentEffect();
        },
      ),
      position: position,
    );
  }

  /// 显示爱心特效
  static void showHeartEffect(BuildContext context, {Offset? position}) {
    _showEffect(
      context,
      HeartEffectAnimation(
        isPlaying: true,
        onAnimationComplete: () {
          _hideCurrentEffect();
        },
      ),
      position: position,
    );
  }

  static void _showEffect(BuildContext context, Widget effect, {Offset? position}) {
    // 隐藏之前的特效
    _hideCurrentEffect();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    
    Offset effectPosition = position ?? const Offset(0, 0);
    if (position == null && renderBox != null) {
      // 默认在屏幕中心显示
      final size = MediaQuery.of(context).size;
      effectPosition = Offset(size.width / 2 - 75, size.height / 2 - 75);
    }

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: effectPosition.dx,
        top: effectPosition.dy,
        child: effect,
      ),
    );

    overlay.insert(_currentOverlay!);
  }

  static void _hideCurrentEffect() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}