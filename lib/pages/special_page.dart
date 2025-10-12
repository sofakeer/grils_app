import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/pages/special_game_page.dart';
import 'package:grils_app/pages/win_heart_page.dart';
import 'package:spine_flutter/spine_flutter.dart' hide Animation;
import 'dart:ui' as ui;
import '../widgets/outlined_text_widget.dart';
import '../managers/audio_manager.dart';
import '../managers/ad_manager.dart';

class SpecialPage extends StatefulWidget {
  const SpecialPage({super.key});

  @override
  State<SpecialPage> createState() => _SpecialPageState();
}

class _SpecialPageState extends State<SpecialPage> with TickerProviderStateMixin {
  late AnimationController _scaleController;

  late Animation<double> _scaleAnimation;

  // Spine动画控制器
  SpineWidgetController? _spineController;
  // 全屏特效 Overlay
  OverlayEntry? _spineOverlayEntry;

  // 视频广告状态
  bool _isShowingAd = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSpine();

    // 播放特殊关卡音效
    AudioManager().playSpecialEffect();

    // 在首帧后插入全屏 Overlay，不参与排版
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insertSpineOverlay();
    });
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // 启动动画序列
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _scaleController.forward();
      }
    });
  }

  void _initializeSpine() {
    try {
      _spineController = SpineWidgetController(onInitialized: (controller) {
        try {
          controller.animationState.getData().setDefaultMix(0.2);
          final animations = controller.skeleton.getData()?.getAnimations() ?? [];
          print("Special_Eff animations: ${animations.map((a) => a.getName()).toList()}");

          // 延迟播放动画，确保控件已渲染
          Future.delayed(const Duration(milliseconds: 200), () async {
            if (!mounted) return;

            final data = controller.skeleton.getData();
            String? bornName = animations
                    .map((a) => a.getName())
                    .firstWhere((n) => n == 'Special_Eff_born', orElse: () => '')
                    .isNotEmpty
                ? 'Special_Eff_born'
                : null;
            bornName ??= animations
                .map((a) => a.getName())
                .firstWhere((n) => n.toLowerCase().contains('born'), orElse: () => '');
            if (bornName.isEmpty) bornName = null;

            String? idleName = animations
                    .map((a) => a.getName())
                    .firstWhere((n) => n == 'Special_Eff_idle', orElse: () => '')
                    .isNotEmpty
                ? 'Special_Eff_idle'
                : null;
            idleName ??= animations
                .map((a) => a.getName())
                .firstWhere((n) => n.toLowerCase().contains('idle'), orElse: () => '');
            if (idleName.isEmpty) idleName = null;

            try {
              controller.animationState.clearTracks();
              if (bornName != null && data?.findAnimation(bornName) != null) {
                controller.animationState.setAnimationByName(0, bornName, false);
                final duration = (data?.findAnimation(bornName)?.getDuration() ?? 1.0);
                print('✓ Special_Eff born once: $bornName, duration: $duration s');
                await Future.delayed(Duration(milliseconds: (duration * 1000).toInt()));
                if (!mounted) return;
                final next = idleName ?? animations.first.getName();
                if (next.isNotEmpty && data?.findAnimation(next) != null) {
                  controller.animationState.setAnimationByName(0, next, true);
                  print('→ Special_Eff idle loop: $next');
                } else {
                  print('✗ Special_Eff idle not found');
                }
              } else {
                final next = idleName ?? animations.first.getName();
                if (next.isNotEmpty && data?.findAnimation(next) != null) {
                  controller.animationState.setAnimationByName(0, next, true);
                  print('✓ Special_Eff idle directly: $next');
                } else {
                  print('✗ Special_Eff no playable animation');
                }
              }
            } catch (e) {
              print('Special_Eff animations play failed: $e');
            }
          });
        } catch (e) {
          print('Special_Eff spine animation initialization failed: $e');
        }
      });
    } catch (e) {
      print('Special_Eff spine controller creation failed: $e');
    }
  }

  void _insertSpineOverlay() {
    if (!mounted || _spineOverlayEntry != null) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _spineOverlayEntry = OverlayEntry(
      builder: (context) {
        return IgnorePointer(
          ignoring: true, // 仅展示特效，点击穿透
            child: Transform.translate(
              offset:Offset(-80,-300),
          child: Positioned.fill(
            child: _spineController == null
                ? const SizedBox.shrink()
                : Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: SpineWidget.fromAsset(
                        "assets/spine/Special_Eff.atlas",
                        "assets/spine/Special_Eff.skel",
                        _spineController!,
                        boundsProvider: const SetupPoseBounds(),
                      ),
                    ),
                  ),
          ),
            ),
        );
      },
    );

    overlay.insert(_spineOverlayEntry!);
  }

  void _removeSpineOverlay() {
    try {
      _spineOverlayEntry?.remove();
      _spineOverlayEntry = null;
    } catch (_) {}
  }

  void _playSpecial() async {
    if (_isShowingAd) return; // 防止重复点击

    setState(() {
      _isShowingAd = true;
    });

    // 播放按钮音效
    await AudioManager().playPopupOpen();

    final bool adCompleted = await AdManager.instance.showRewardedAd(
      context: context,
      onAdFailed: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad failed to play. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
    );

    if (!mounted) return;

    setState(() {
      _isShowingAd = false;
    });

    if (!adCompleted) {
      return;
    }

    // 广告播放完成，进入特殊关卡
    Navigator.of(context).pop();

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const WinHeartPage(),
      ),
    )
        .then((_) {
      if (mounted) {
        _showHeartRewardDialog();
      }
    });
  }

  // 显示爱心货币奖励弹窗
  void _showHeartRewardDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Special Stage Complete!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Congratulations! You completed the special stage!\n\nYou earned double heart rewards!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 跳转到爱心货币界面
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WinHeartPage(),
                ),
              );
            },
            child: const Text('Claim Rewards'),
          ),
        ],
      ),
    );
  }

  void _skipSpecial() {
    // 跳过特殊关卡
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _removeSpineOverlay();
    _spineController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Assets.wincoinWinCoinBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // 主要内容
            Center(
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // SPECIAL 标题特效改为 Overlay，全屏渲染且不参与排版
                        const SizedBox(height: 50),

                        // 女孩图片
                        Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 30),
                              child: Image.asset(
                                Assets.specialSpecialImgMiddle,
                                height: 350,
                              ),
                            ),
                            // 说明文字
                            Positioned(
                              left: 0,
                              right: 0,
                              child: Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const OutlinedTextWidget(
                                  text: 'Play special levels to win extra hearts!',
                                  fontSize: 20,
                                  textColor: Colors.white,
                                  strokeColor: ui.Color(0xffF306FF),
                                  strokeWidth: 2.0,
                                  fontWeight: FontWeight.bold,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.visible,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(2, 2),
                                      blurRadius: 2,
                                      color: ui.Color(0xffF306FF),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // PLAY 按钮
                        GestureDetector(
                          onTap: _isShowingAd ? null : _playSpecial,
                          child: Opacity(
                            opacity: _isShowingAd ? 0.5 : 1.0,
                            child: Container(
                              width: 200,
                              height: 60,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(Assets.newPhotoNewPhotoBtnBlueBig),
                                  fit: BoxFit.fill,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 相机图标
                                  Image.asset(
                                    Assets.newPhotoNewPhotoIconAd,
                                    height: 30,
                                  ),
                                  const SizedBox(width: 10),
                                  const OutlinedTextWidget(
                                    text: 'Play',
                                    fontSize: 20,
                                    textColor: Colors.white,
                                    strokeColor: Colors.black,
                                    strokeWidth: 1.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // SKIP 按钮
                        GestureDetector(
                          onTap: _isShowingAd ? null : _skipSpecial,
                          child: Opacity(
                            opacity: _isShowingAd ? 0.5 : 1.0,
                            child: const OutlinedTextWidget(
                              text: 'SKIP',
                              fontSize: 18,
                              textColor: Colors.white,
                              strokeColor: Colors.black,
                              strokeWidth: 1.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Spine特效动画已移至顶部标题位置
          ],
        ),
      ),
    );
  }
}
