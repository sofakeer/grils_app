import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/pages/special_game_page.dart';
import 'package:grils_app/pages/win_heart_page.dart';
import 'package:spine_flutter/spine_flutter.dart' hide Animation;
import 'dart:ui' as ui;
import '../widgets/outlined_text_widget.dart';
import '../managers/audio_manager.dart';

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

  // 视频广告状态
  bool _isShowingAd = false;
  bool _isAdCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSpine();

    // 播放特殊关卡音效
    AudioManager().playSpecialEffect();
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

  void _playSpecial() async {
    if (_isShowingAd) return; // 防止重复点击

    setState(() {
      _isShowingAd = true;
    });

    // 播放按钮音效
    await AudioManager().playPopupOpen();

    // 模拟视频广告播放
    await _showVideoAd();

    if (_isAdCompleted) {
      // 广告播放完成，进入特殊关卡
      Navigator.of(context).pop(); // 关闭特殊关卡弹窗

      // 跳转到特殊关卡游戏页面（这里使用新照片页面作为示例）
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => const SpecialGamePage(),
        ),
      )
          .then((_) {
        // 特殊关卡完成后，显示翻倍领取爱心货币界面
        _showHeartRewardDialog();
      });
    } else {
      // 广告未完成，恢复状态
      setState(() {
        _isShowingAd = false;
      });
    }
  }

  // 模拟视频广告播放
  Future<void> _showVideoAd() async {
    // 显示广告加载提示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Loading Ad...'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Please wait while the video ad loads...'),
          ],
        ),
      ),
    );

    // 模拟广告加载时间
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop(); // 关闭加载提示

      // 模拟广告播放
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Video Ad'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle, size: 64, color: Colors.blue),
              SizedBox(height: 16),
              Text('Video ad is playing...\nPlease watch the full ad.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isAdCompleted = false;
                });
              },
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isAdCompleted = true;
                });
              },
              child: const Text('Complete'),
            ),
          ],
        ),
      );
    }
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
                        // SPECIAL 标题 - 使用Spine动画
                        Container(
                          margin: const EdgeInsets.only(bottom: 20,right: 90),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Special_Eff Spine动画 - 仅判断控制器存在即可渲染
                              if (_spineController != null)
                                SizedBox(
                                  width: 300,
                                  height: 140,
                                  child: Center(
                                    child: SpineWidget.fromAsset(
                                      "assets/spine/Special_Eff.atlas",
                                      "assets/spine/Special_Eff.skel",
                                      _spineController!,
                                      boundsProvider: const SetupPoseBounds(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

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
