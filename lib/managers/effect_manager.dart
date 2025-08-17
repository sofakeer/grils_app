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
  Future<void> playCoinEffect(BuildContext context, {int duration = 3}) async {
    return _playSpineEffect(
      context: context,
      atlasAsset: Assets.assetsSpineCoinEff01,
      skeletonAsset: Assets.assetsSpineCoinEff01.replaceAll('.atlas', '.skel'),
      duration: duration,
    );
  }

  /// 播放爱心特效
  /// [context] - 上下文  
  /// [duration] - 播放时长（秒）
  Future<void> playHeartEffect(BuildContext context, {int duration = 3}) async {
    return _playSpineEffect(
      context: context,
      atlasAsset: Assets.assetsSpineHeartEff01,
      skeletonAsset: Assets.assetsSpineHeartEff01.replaceAll('.atlas', '.skel'),
      duration: duration,
    );
  }

  /// 播放Spine特效的通用方法
  Future<void> _playSpineEffect({
    required BuildContext context,
    required String atlasAsset,
    required String skeletonAsset,
    required int duration,
  }) async {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _SpineEffectWidget(
        atlasAsset: atlasAsset,
        skeletonAsset: skeletonAsset,
        duration: duration,
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
  final VoidCallback onComplete;

  const _SpineEffectWidget({
    required this.atlasAsset,
    required this.skeletonAsset,
    required this.duration,
    required this.onComplete,
  });

  @override
  State<_SpineEffectWidget> createState() => _SpineEffectWidgetState();
}

class _SpineEffectWidgetState extends State<_SpineEffectWidget>
    with SingleTickerProviderStateMixin {
  spine.SpineWidgetController? _spineController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: widget.duration * 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

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
    _spineController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
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
            ),
          ),
        );
      },
    );
  }
}