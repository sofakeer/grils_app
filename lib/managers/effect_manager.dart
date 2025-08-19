import 'package:flutter/material.dart';
import 'package:spine_flutter/spine_flutter.dart' as spine;
import 'package:grils_app/generated/assets.dart';

/// 特效管理器
/// 负责播放各种游戏特效
class EffectManager {
  static EffectManager? _instance;
  static EffectManager get instance => _instance ??= EffectManager._();
  
  EffectManager._();

  /// 播放金币特效
  /// [context] - 上下文
  /// [duration] - 播放时长（秒）
  /// [targetPosition] - 特效目标位置（从中心飘到目标位置）
  Future<void> playCoinEffect(BuildContext context, {int duration = 3, Offset? targetPosition}) async {
    return _playSpineEffect(
      context: context,
      atlasAsset: Assets.assetsSpineCoinEff01,
      skeletonAsset: Assets.assetsSpineCoinEff01.replaceAll('.atlas', '.skel'),
      duration: duration,
      targetPosition: targetPosition,
    );
  }

  /// 播放爱心特效
  /// [context] - 上下文  
  /// [duration] - 播放时长（秒）
  /// [targetPosition] - 特效目标位置（从中心飘到目标位置）
  Future<void> playHeartEffect(BuildContext context, {int duration = 3, Offset? targetPosition}) async {
    return _playSpineEffect(
      context: context,
      atlasAsset: Assets.assetsSpineHeartEff01,
      skeletonAsset: Assets.assetsSpineHeartEff01.replaceAll('.atlas', '.skel'),
      duration: duration,
      targetPosition: targetPosition,
    );
  }

  /// 播放Spine特效的通用方法
  Future<void> _playSpineEffect({
    required BuildContext context,
    required String atlasAsset,
    required String skeletonAsset,
    required int duration,
    Offset? targetPosition,
  }) async {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _SpineEffectWidget(
        atlasAsset: atlasAsset,
        skeletonAsset: skeletonAsset,
        duration: duration,
        targetPosition: targetPosition,
        onComplete: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

/// Spine特效播放组件
class _SpineEffectWidget extends StatefulWidget {
  final String atlasAsset;
  final String skeletonAsset;
  final int duration;
  final Offset? targetPosition;
  final VoidCallback onComplete;

  const _SpineEffectWidget({
    required this.atlasAsset,
    required this.skeletonAsset,
    required this.duration,
    this.targetPosition,
    required this.onComplete,
  });

  @override
  State<_SpineEffectWidget> createState() => _SpineEffectWidgetState();
}

class _SpineEffectWidgetState extends State<_SpineEffectWidget>
    with TickerProviderStateMixin {
  spine.SpineWidgetController? _spineController;
  late AnimationController _fadeController;
  late AnimationController _positionController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: widget.duration * 1000),
      vsync: this,
    );
    
    _positionController = AnimationController(
      duration: const Duration(milliseconds: 2000), // 2秒位置动画
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    // 先创建一个默认的位置动画
    _positionAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, 0),
    ).animate(_positionController);

    _initializeSpine();
    _startEffect();
  }

  void _initializeSpine() {
    _spineController = spine.SpineWidgetController(
      onInitialized: (controller) {
        try {
          final animations = controller.skeleton.getData()?.getAnimations();
          if (animations != null && animations.isNotEmpty) {
            // 播放第一个动画
            final animationName = animations.first.getName();
            controller.animationState.setAnimationByName(0, animationName, true);
            print("特效动画播放: $animationName");
          }
        } catch (e) {
          print("特效动画初始化失败: $e");
        }
      },
    );
  }

  void _startEffect() async {
    // 同时启动位置动画和淡出动画
    _positionController.forward();
    _fadeController.forward();
    
    // 等待动画完成
    await Future.delayed(Duration(seconds: widget.duration));
    
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _positionController.dispose();
    _spineController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _positionController]),
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;
        
        // 计算当前位置
        Offset currentPosition;
        if (widget.targetPosition != null) {
          // 从屏幕中心开始，动画到目标位置
          final startPosition = Offset(screenSize.width / 2, screenSize.height / 2);
          final endPosition = widget.targetPosition!;
          currentPosition = Offset.lerp(startPosition, endPosition, _positionController.value)!;
        } else {
          // 无目标位置，保持在屏幕中心
          currentPosition = Offset(screenSize.width / 2, screenSize.height / 2);
        }
        
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned(
                  left: currentPosition.dx - 100, // 特效宽度的一半
                  top: currentPosition.dy - 100,  // 特效高度的一半
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: _spineController != null
                        ? spine.SpineWidget.fromAsset(
                            widget.atlasAsset,
                            widget.skeletonAsset,
                            _spineController!,
                            boundsProvider: const spine.SetupPoseBounds(),
                          )
                        : const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}