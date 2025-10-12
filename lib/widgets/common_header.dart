import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:grils_app/services/user_service.dart';
import 'package:grils_app/managers/effect_manager.dart';
import 'package:grils_app/managers/audio_manager.dart';
import 'package:spine_flutter/spine_flutter.dart' as spine;

import 'outlined_text_widget.dart';

/// 公共头部组件
///
/// 使用示例:
/// ```dart
/// CommonHeader(
///   title: '相册',
///   onBackPressed: () => Navigator.pop(context),
/// )
/// ```
///
/// 参数说明:
/// - title: 页面标题（可选）
/// - onBackPressed: 返回按钮回调（可选，默认调用Navigator.pop）
/// - showBackButton: 是否显示返回按钮（默认为true）
class CommonHeader extends StatefulWidget {
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final bool settingsButton;

  const CommonHeader({
    super.key,
    this.onBackPressed,
    this.showBackButton = true,
    this.settingsButton = false,
  });

  /// 播放签到奖励特效
  static Future<void> playSignInEffects(BuildContext context, int coins, int hearts) async {
    if (coins > 0) {
      // 播放金币获得特效
      await playCoinGainEffect(context);
    }
    if (hearts > 0) {
      // 延迟0.5秒后播放爱心获得特效
      Future.delayed(const Duration(milliseconds: 500), () {
        playHeartGainEffect(context);
      });
    }
  }

  /// 播放获得金币动画特效
  static Future<void> playCoinGainEffect(BuildContext context) async {
    await AudioManager().playCoinEffect();

    // 使用Overlay直接在金币图标位置显示动画
    _showCoinGainOverlay(context);
  }

  /// 播放获得爱心动画特效
  static Future<void> playHeartGainEffect(BuildContext context) async {
    await AudioManager().playHeartEffect();

    // 使用Overlay直接在爱心图标位置显示动画
    _showHeartGainOverlay(context);
  }

  /// 在金币图标位置显示获得动画
  static void _showCoinGainOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: -100, // 金币图标左边距
        top: topPadding -75, // 金币图标顶部位置
        child: CoinGainAnimationWidget(
          onComplete: () {
            overlayEntry.remove();
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  /// 在爱心图标位置显示获得动画
  static void _showHeartGainOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 50, // 爱心图标左边距
        top: topPadding - 65, // 爱心图标顶部位置
        child: HeartGainAnimationWidget(
          onComplete: () {
            overlayEntry.remove();
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  /// 调试用：显示目标位置红点
  static void _showDebugDot(BuildContext context, Offset position, Color color) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 5,
        top: position.dy - 5,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // 3秒后移除调试点
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  State<CommonHeader> createState() => _CommonHeaderState();
}

class _CommonHeaderState extends State<CommonHeader> with TickerProviderStateMixin {
  late UserService _userService;
  late AnimationController _coinAnimationController;
  late Animation<double> _coinScaleAnimation;
  int _previousCoinCount = 0;

  @override
  void initState() {
    super.initState();
    _userService = UserService.instance;
    _initializeUserService();

    // 初始化金币动画
    _coinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _coinScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _coinAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  void _initializeUserService() async {
    print("CommonHeader: 初始化UserService");
    await _userService.initialize();
    _previousCoinCount = _userService.coinCount;
    _userService.addListener(_onUserDataChanged);
    print("CommonHeader: 初始金币数量: $_previousCoinCount");
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _userService.removeListener(_onUserDataChanged);
    _coinAnimationController.dispose();
    super.dispose();
  }

  void _onUserDataChanged() {
    print("CommonHeader: _onUserDataChanged called");
    if (mounted) {
      final currentCoinCount = _userService.coinCount;
      print("CommonHeader: 当前金币: $currentCoinCount, 之前金币: $_previousCoinCount");

      // 如果金币数量变化，触发动画
      if (currentCoinCount != _previousCoinCount) {
        print("CommonHeader: 金币数量变化: $_previousCoinCount -> $currentCoinCount");
        _coinAnimationController.forward().then((_) {
          _coinAnimationController.reverse();
        });
        _previousCoinCount = currentCoinCount;
      }

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 10,
      ),
      child: Stack(
        children: [
          // 内容层 - 调整位置让图标盖住顶部横条
          Positioned(
            top: 0, // 让内容稍微向上，盖住顶部横条
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // 金币显示 - 添加动画
                    AnimatedBuilder(
                      animation: _coinScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _coinScaleAnimation.value,
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 15,top: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: HexColor("#FFF5E5"),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(width: 30,),
                                      OutlinedTextWidget(
                                        text: '${_userService.coinCount}',
                                        textColor: HexColor("#95756A"),
                                        strokeWidth: 0,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Image.asset(
                                Assets.mainMainIconCoin,
                                height: 50,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 10),

                    // 爱心显示
                    Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10, top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 2),
                            decoration: BoxDecoration(
                              color: HexColor("#FFF5E5"),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 30,),
                                OutlinedTextWidget(
                                  text:'${_userService.heartCount}',
                                  textColor: HexColor("#95756A"),
                                  fontSize: 18,
                                  strokeWidth: 0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Image.asset(
                          Assets.imagesIconHeart2x,
                          height: 45,
                        ),
                      ],
                    ),
                  ],
                ),
                // 按钮区域
                Row(
                  children: [
                    // // 特效测试按钮
                    // GestureDetector(
                    //   onTap: () {
                    //     // 测试特效
                    //     CommonHeader.playSignInEffects(context, 100, 10);
                    //   },
                    //   child: Container(
                    //     width: 30,
                    //     height: 30,
                    //     decoration: BoxDecoration(
                    //       color: Colors.green,
                    //       borderRadius: BorderRadius.circular(15),
                    //     ),
                    //     child: const Icon(
                    //       Icons.star,
                    //       color: Colors.white,
                    //       size: 16,
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(width: 5),
                    //
                    // // 调试按钮（临时添加）
                    // GestureDetector(
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => const UserServiceTestPage(),
                    //       ),
                    //     );
                    //   },
                    //   child: Container(
                    //     width: 30,
                    //     height: 30,
                    //     decoration: BoxDecoration(
                    //       color: Colors.blue,
                    //       borderRadius: BorderRadius.circular(15),
                    //     ),
                    //     child: const Icon(
                    //       Icons.bug_report,
                    //       color: Colors.white,
                    //       size: 16,
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(width: 10),

                    // 返回按钮 - 使用指定图片
                    if (widget.showBackButton)
                      GestureDetector(
                        onTap: widget.onBackPressed ?? () => Navigator.of(context).pop(),
                        child: Image.asset(
                          widget.settingsButton ? Assets.mainMainBtnSetting : Assets.imagesBtnHeartBack,
                          height: 50,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 金币获得动画组件 - 使用Spine动画
class CoinGainAnimationWidget extends StatefulWidget {
  final VoidCallback onComplete;

  const CoinGainAnimationWidget({super.key, required this.onComplete});

  @override
  State<CoinGainAnimationWidget> createState() => _CoinGainAnimationWidgetState();
}

class _CoinGainAnimationWidgetState extends State<CoinGainAnimationWidget> {
  spine.SpineWidgetController? _spineController;

  @override
  void initState() {
    super.initState();
    _initializeSpine();
  }

  void _initializeSpine() {
    try {
      _spineController = spine.SpineWidgetController(onInitialized: (controller) {
        try {
          final data = controller.skeleton.getData();
          final animations = data?.getAnimations() ?? [];

          // 设置默认混合
          try {
            controller.animationState.getData().setDefaultMix(0.2);
          } catch (_) {}

          print('Coin_Eff01可用动画: ${animations.map((a) => a.getName()).toList()}');

          if (animations.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 200), () async {
              if (!mounted) return;

              // 查找Coin_Eff01动画
              String? coinEffName = animations
                  .map((a) => a.getName())
                  .firstWhere((n) => n == 'Coin_Eff01', orElse: () => '')
                  .isNotEmpty
                  ? 'Coin_Eff01'
                  : null;
              coinEffName ??= animations
                  .map((a) => a.getName())
                  .firstWhere((n) => n.toLowerCase().contains('coin'), orElse: () => '');
              if (coinEffName.isEmpty) coinEffName = null;

              try {
                controller.animationState.clearTracks();

                if (coinEffName != null && data?.findAnimation(coinEffName) != null) {
                  controller.animationState.setAnimationByName(0, coinEffName, false);
                  final duration = (data?.findAnimation(coinEffName)?.getDuration() ?? 1.0);
                  print('✓ 播放金币Spine动画: $coinEffName, 时长: $duration s');

                  // 动画播放完成后调用回调
                  Future.delayed(Duration(milliseconds: (duration * 1000).toInt() + 500), () {
                    if (mounted) {
                      widget.onComplete();
                    }
                  });
                } else {
                  // 播放第一个可用动画
                  final firstAnimation = animations.first.getName();
                  if (firstAnimation.isNotEmpty && data?.findAnimation(firstAnimation) != null) {
                    controller.animationState.setAnimationByName(0, firstAnimation, false);

                    print('✓ 播放金币默认动画: $firstAnimation');

                    // 2秒后完成
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) {
                        widget.onComplete();
                      }
                    });
                  }
                }
              } catch (e) {
                print('金币Spine动画播放失败: $e');
                // 出错时也要调用回调
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    widget.onComplete();
                  }
                });
              }
            });
          } else {
            print('Coin_Eff01没有找到动画');
            // 没有动画时也要调用回调
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                widget.onComplete();
              }
            });
          }
        } catch (e) {
          print('金币Spine动画初始化失败: $e');
          // 出错时也要调用回调
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              widget.onComplete();
            }
          });
        }
      });
    } catch (e) {
      print('金币Spine控制器创建失败: $e');
      // 出错时也要调用回调
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          widget.onComplete();
        }
      });
    }
  }

  @override
  void dispose() {
    _spineController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 343,
      height: 246,
      child: _spineController != null
          ? spine.SpineWidget.fromAsset(
        "assets/spine/Coin_Eff01.atlas",
        "assets/spine/Coin_Eff01.skel",
        _spineController!,
        boundsProvider: const spine.SetupPoseBounds(),
        fit: BoxFit.contain,
      )
          : const Center(
        child: CircularProgressIndicator(color: Colors.yellow),
      ),
    );
  }
}

// 爱心获得动画组件 - 使用Spine动画
class HeartGainAnimationWidget extends StatefulWidget {
  final VoidCallback onComplete;

  const HeartGainAnimationWidget({super.key, required this.onComplete});

  @override
  State<HeartGainAnimationWidget> createState() => _HeartGainAnimationWidgetState();
}

class _HeartGainAnimationWidgetState extends State<HeartGainAnimationWidget> {
  spine.SpineWidgetController? _spineController;

  @override
  void initState() {
    super.initState();
    _initializeSpine();
  }

  void _initializeSpine() {
    try {
      _spineController = spine.SpineWidgetController(onInitialized: (controller) {
        try {
          final data = controller.skeleton.getData();
          final animations = data?.getAnimations() ?? [];

          // 设置默认混合
          try {
            controller.animationState.getData().setDefaultMix(0.2);
          } catch (_) {}

          print('Heart_Eff01可用动画: ${animations.map((a) => a.getName()).toList()}');

          if (animations.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 200), () async {
              if (!mounted) return;

              // 查找Heart_Eff01动画
              String? heartEffName = animations
                  .map((a) => a.getName())
                  .firstWhere((n) => n == 'Heart_Eff01', orElse: () => '')
                  .isNotEmpty
                  ? 'Heart_Eff01'
                  : null;
              heartEffName ??= animations
                  .map((a) => a.getName())
                  .firstWhere((n) => n.toLowerCase().contains('heart'), orElse: () => '');
              if (heartEffName.isEmpty) heartEffName = null;

              try {
                controller.animationState.clearTracks();

                if (heartEffName != null && data?.findAnimation(heartEffName) != null) {
                  controller.animationState.setAnimationByName(0, heartEffName, false);
                  final duration = (data?.findAnimation(heartEffName)?.getDuration() ?? 1.0);
                  print('✓ 播放爱心Spine动画: $heartEffName, 时长: $duration s');

                  // 动画播放完成后调用回调
                  Future.delayed(Duration(milliseconds: (duration * 1000).toInt() + 500), () {
                    if (mounted) {
                      widget.onComplete();
                    }
                  });
                } else {
                  // 播放第一个可用动画
                  final firstAnimation = animations.first.getName();
                  if (firstAnimation.isNotEmpty && data?.findAnimation(firstAnimation) != null) {
                    controller.animationState.setAnimationByName(0, firstAnimation, false);
                    print('✓ 播放爱心默认动画: $firstAnimation');

                    // 2秒后完成
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) {
                        widget.onComplete();
                      }
                    });
                  }
                }
              } catch (e) {
                print('爱心Spine动画播放失败: $e');
                // 出错时也要调用回调
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    widget.onComplete();
                  }
                });
              }
            });
          } else {
            print('Heart_Eff01没有找到动画');
            // 没有动画时也要调用回调
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                widget.onComplete();
              }
            });
          }
        } catch (e) {
          print('爱心Spine动画初始化失败: $e');
          // 出错时也要调用回调
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              widget.onComplete();
            }
          });
        }
      });
    } catch (e) {
      print('爱心Spine控制器创建失败: $e');
      // 出错时也要调用回调
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          widget.onComplete();
        }
      });
    }
  }

  @override
  void dispose() {
    _spineController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 343,
      height: 246,
      child: _spineController != null
          ? spine.SpineWidget.fromAsset(
        "assets/spine/Heart_Eff01.atlas",
        "assets/spine/Heart_Eff01.skel",
        _spineController!,
        boundsProvider: const spine.SetupPoseBounds(),
        fit: BoxFit.contain,
      )
          : const Center(
        child: CircularProgressIndicator(color: Colors.pink),
      ),
    );
  }
} 