import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/widgets/common_header.dart';
import 'package:grils_app/pages/special_game_page.dart';
import 'package:grils_app/pages/win_heart_page.dart';
import 'package:spine_flutter/spine_flutter.dart' hide Animation;
import 'package:audioplayers/audioplayers.dart';
import 'dart:ui' as ui;
import '../widgets/outlined_text_widget.dart';
import '../managers/audio_manager.dart';
import '../managers/game_state_manager.dart';

class SpecialPage extends StatefulWidget {
  const SpecialPage({super.key});

  @override
  State<SpecialPage> createState() => _SpecialPageState();
}

class _SpecialPageState extends State<SpecialPage> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _heartAnimation;

  // Spine动画控制器
  SpineWidgetController? _spineController;
  bool _isSpineReady = false;
  bool _isPlayingBornAnimation = true;

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

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _heartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeInOut,
    ));

    // 启动动画序列
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _scaleController.forward();
      }
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _heartController.forward();
      }
    });
  }

  void _initializeSpine() {
    try {
      _spineController = SpineWidgetController(onInitialized: (controller) {
        try {
          final animations = controller.skeleton.getData()?.getAnimations();
          if (animations != null && animations.isNotEmpty) {
            if (mounted) {
              setState(() {
                _isSpineReady = true;
              });
            }

            // 先播放 Special_Eff_born 动画
            final bornAnim = animations.firstWhere(
              (anim) => anim.getName().toLowerCase().contains('born'),
              orElse: () => animations.first,
            );
            
            if (bornAnim != null) {
              final duration = bornAnim.getDuration();
              controller.animationState.setAnimationByName(0, bornAnim.getName(), false);
              
              // born 动画播完后循环播放 idle 动画
              Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
                if (mounted && _spineController != null) {
                  setState(() {
                    _isPlayingBornAnimation = false;
                  });
                  
                  final idleAnim = animations.firstWhere(
                    (anim) => anim.getName().toLowerCase().contains('idle'),
                    orElse: () => animations.last,
                  );
                  
                  if (idleAnim != null) {
                    controller.animationState.setAnimationByName(0, idleAnim.getName(), true);
                  }
                }
              });
            }
          }
        } catch (e) {
          print('Special effect spine animation initialization failed: $e');
        }
      });
    } catch (e) {
      print('Special effect spine controller creation failed: $e');
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
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SpecialGamePage(),
        ),
      ).then((_) {
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
    _fadeController.dispose();
    _heartController.dispose();
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
                        // SPECIAL 标题
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Image.asset(
                            Assets.specialSpecialTitle,
                            height: 140,
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
                              right:0,
                              child: SizedBox(
                                width: 300,
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
                                  Image.asset(Assets.newPhotoNewPhotoIconAd,height: 30,),
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

            // Spine特效动画
            if (_isSpineReady)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 300,
                    height: 200,
                    child: SpineWidget.fromAsset(
                      "assets/spine/Special_Eff.atlas",
                      "assets/spine/Special_Eff.skel",
                      _spineController!,
                      boundsProvider: const SetupPoseBounds(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
