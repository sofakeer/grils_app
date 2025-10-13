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

          // 设置默认混合时间
          try {
            controller.animationState.getData().setDefaultMix(0.2);
          } catch (e) {
            print('PhotoUnlockEffect: 设置默认混合时间失败: $e');
          }

          // 安全地获取可用动画
          try {
            final skeleton = controller.skeleton;
            final data = skeleton.getData();
            if (data != null) {
              final animations = data.getAnimations();
              if (animations != null && animations.isNotEmpty) {
                print('PhotoUnlockEffect: 找到 ${animations.length} 个动画');

                // 安全地列出所有动画名称
                for (int i = 0; i < animations.length; i++) {
                  try {
                    final animation = animations[i];
                    if (animation != null && animation.getName() != null) {
                      print('PhotoUnlockEffect: 可用动画 $i: ${animation.getName()}');
                    }
                  } catch (e) {
                    print('PhotoUnlockEffect: 获取动画 $i 名称失败: $e');
                  }
                }
              } else {
                print('PhotoUnlockEffect: 动画列表为空');
              }
            } else {
              print('PhotoUnlockEffect: Skeleton 数据为空');
            }
          } catch (e) {
            print('PhotoUnlockEffect: 获取动画列表失败: $e');
          }

          if (mounted) {
            setState(() {
              _isControllerReady = true;
            });
            print('PhotoUnlockEffect: 控制器准备就绪');
          }

          // 如果已经需要显示，立即播放
          if (_isVisible) {
            print('PhotoUnlockEffect: 立即播放等待中的动画');
            _playAnimation();
          }
        } catch (e, stackTrace) {
          print('PhotoUnlockEffect: 初始化失败: $e');
          print('PhotoUnlockEffect: 堆栈跟踪: $stackTrace');
        }
      });
      print('PhotoUnlockEffect: 控制器创建成功');
    } catch (e, stackTrace) {
      print('PhotoUnlockEffect: 控制器创建失败: $e');
      print('PhotoUnlockEffect: 堆栈跟踪: $stackTrace');
    }
  }

  void _playAnimation() {
    if (!_isControllerReady || _spineController == null) {
      print('PhotoUnlockEffect: 控制器未准备就绪');
      return;
    }

    try {
      final skeleton = _spineController!.skeleton;
      if (skeleton.getData() == null) {
        print('PhotoUnlockEffect: Skeleton 数据为空');
        return;
      }

      final data = skeleton.getData()!;
      final animations = data.getAnimations();

      if (animations == null || animations.isEmpty) {
        print('PhotoUnlockEffect: 没有找到动画数据');
        return;
      }

      print('PhotoUnlockEffect: 找到 ${animations.length} 个动画');

      // 安全地获取动画名称
      String? bestAnimation;
      try {
        for (int i = 0; i < animations.length; i++) {
          final animation = animations[i];
          if (animation != null && animation.getName() != null) {
            final name = animation.getName()!;
            print('PhotoUnlockEffect: 可用动画 $i: $name');

            if (name.toLowerCase().contains('born')) {
              bestAnimation = name;
              break;
            }
            if (bestAnimation == null) {
              bestAnimation = name; // 默认使用第一个动画
            }
          }
        }
      } catch (e) {
        print('PhotoUnlockEffect: 遍历动画时出错: $e');
        return;
      }

      if (bestAnimation == null) {
        print('PhotoUnlockEffect: 没有找到可用的动画名称');
        return;
      }

      print('PhotoUnlockEffect: 播放动画: $bestAnimation');

      _spineController!.animationState.clearTracks();
      _spineController!.animationState.setAnimationByName(0, bestAnimation, false);

      final animationData = data.findAnimation(bestAnimation);
      final duration = animationData?.getDuration() ?? 1.0;
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
    } catch (e, stackTrace) {
      print('PhotoUnlockEffect: 动画播放失败: $e');
      print('PhotoUnlockEffect: 堆栈跟踪: $stackTrace');

      // 发生错误时也要隐藏特效
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
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
    // 使用 IgnorePointer 包装整个 SpineWidget 来避免布局问题
    return IgnorePointer(
      ignoring: true,
        child: Transform.translate(
          offset:Offset(70,-120),
        child: SizedBox(

          width: 1080,
          height: 2340,
      child: spine.SpineWidget.fromAsset(
        "assets/spine/PhotoUnlock_Eff.atlas",
        "assets/spine/PhotoUnlock_Eff.skel",
        _spineController!,
        boundsProvider: const spine.SetupPoseBounds(),
        fit: BoxFit.contain,
      ),
        ),
        ),
    );
  }
}