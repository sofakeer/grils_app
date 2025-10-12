import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:spine_flutter/spine_flutter.dart' as spine;
import '../managers/audio_manager.dart';

class PhotoUnlockEffectWidget extends StatefulWidget {
  const PhotoUnlockEffectWidget({super.key});

  @override
  PhotoUnlockEffectWidgetState createState() => PhotoUnlockEffectWidgetState();
}

class PhotoUnlockEffectWidgetState extends State<PhotoUnlockEffectWidget> {
  spine.SpineWidgetController? _spineController;
  bool _isControllerReady = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    try {
      _spineController = spine.SpineWidgetController(onInitialized: (controller) {
        try {
          print('PhotoUnlockEffect: 控制器初始化开始');
          controller.animationState.getData().setDefaultMix(0.2);

          // 获取可用动画
          final animations = controller.skeleton.getData()?.getAnimations() ?? [];
          print('PhotoUnlockEffect: 可用动画: ${animations.map((a) => a.getName()).toList()}');

          if (mounted) {
            setState(() {
              _isControllerReady = true;
            });
            print('PhotoUnlockEffect: 控制器准备就绪');
          }

          // 如果已经需要显示，立即播放
          if (_isVisible) {
            _playAnimation();
          }
        } catch (e) {
          print('PhotoUnlockEffect: 初始化失败: $e');
        }
      });
      print('PhotoUnlockEffect: 控制器创建成功');
    } catch (e) {
      print('PhotoUnlockEffect: 控制器创建失败: $e');
    }
  }

  void _playAnimation() {
    if (!_isControllerReady || _spineController == null) {
      print('PhotoUnlockEffect: 控制器未准备就绪');
      return;
    }

    try {
      final data = _spineController!.skeleton.getData();
      final animations = data?.getAnimations() ?? [];

      if (animations.isEmpty) {
        print('PhotoUnlockEffect: 没有找到动画');
        return;
      }

      // 查找最佳动画
      String? bestAnimation = animations
              .map((a) => a.getName())
              .firstWhere((n) => n.toLowerCase().contains('born'), orElse: () => '')
              .isNotEmpty
          ? animations.firstWhere((n) => n.getName().toLowerCase().contains('born')).getName()
          : animations.first.getName();

      print('PhotoUnlockEffect: 播放动画: $bestAnimation');

      _spineController!.animationState.clearTracks();
      _spineController!.animationState.setAnimationByName(0, bestAnimation, false);

      final duration = data?.findAnimation(bestAnimation)?.getDuration() ?? 1.0;
      print('PhotoUnlockEffect: 动画时长: ${duration}s');

      // 播放音效
      AudioManager().playSettlementCoin();

      // 动画完成后隐藏
      Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
          print('PhotoUnlockEffect: 动画播放完成，隐藏特效');
        }
      });
    } catch (e) {
      print('PhotoUnlockEffect: 动画播放失败: $e');
    }
  }

  void showEffect() {
    print('PhotoUnlockEffect: 显示特效 - _isControllerReady=$_isControllerReady, _isVisible=$_isVisible');
    if (mounted) {
      setState(() {
        _isVisible = true;
      });
      print('PhotoUnlockEffect: setState 完成，_isVisible 设置为 true');

      if (_isControllerReady) {
        print('PhotoUnlockEffect: 控制器已准备就绪，开始播放动画');
        _playAnimation();
      } else {
        print('PhotoUnlockEffect: 控制器未准备就绪，等待初始化完成');
      }
    } else {
      print('PhotoUnlockEffect: Widget 已销毁，无法显示特效');
    }
  }

  @override
  void dispose() {
    _spineController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('PhotoUnlockEffect: build() 被调用 - _isVisible=$_isVisible, _spineController=${_spineController != null}');

    if (!_isVisible || _spineController == null) {
      print('PhotoUnlockEffect: 返回空 Widget - _isVisible=$_isVisible, _spineController=${_spineController != null}');
      return const SizedBox.shrink();
    }

    print('PhotoUnlockEffect: 构建 Spine 动画 Widget');
    return Stack(
      children: [
        // 添加一个半透明背景用于调试
        Positioned.fill(
          child: Container(
            color: Colors.red.withOpacity(0.3), // 调试用红色背景
            child: const Center(
              child: Text(
                'PhotoUnlock Effect Playing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        // 解锁特效覆盖在顶层
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: spine.SpineWidget.fromAsset(
              "assets/spine/PhotoUnlock_Eff.atlas",
              "assets/spine/PhotoUnlock_Eff.skel",
              _spineController!,
              boundsProvider: const spine.SetupPoseBounds(),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}