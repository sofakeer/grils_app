import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/widgets/common_header.dart';
import 'package:grils_app/pages/new_photo_page.dart';
import 'package:grils_app/pages/win_heart_page.dart';
import 'package:spine_flutter/spine_flutter.dart' hide Animation;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/coin_calculator.dart';
import '../managers/audio_manager.dart';
import '../widgets/outlined_text_widget.dart';

class WinPage extends StatefulWidget {
  final int level;
  
  const WinPage({super.key, this.level = 1});

  @override
  State<WinPage> createState() => _WinPageState();
}

class _WinPageState extends State<WinPage> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  // Spine animation controller
  SpineWidgetController? _spineController;
  bool _isSpineReady = false;
  int _coinReward = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSpine();
    _calculateCoinReward();
    
    // 播放结算音效
    AudioManager().playSettlementCoin();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
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

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
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

            // 先播放 CoinWin_Eff_born 动画
            final bornAnim = animations.firstWhere(
              (anim) => anim.getName().contains('born'),
              orElse: () => animations.first,
            );
            
            if (bornAnim != null) {
              final duration = bornAnim.getDuration();
              controller.animationState.setAnimationByName(0, bornAnim.getName(), false);
              
              // born 动画播完后循环播放 idle 动画
              Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
                if (mounted && _spineController != null) {
                  final idleAnim = animations.firstWhere(
                    (anim) => anim.getName().contains('idle'),
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
          print('Spine animation initialization failed: $e');
        }
      });
    } catch (e) {
      print('Spine controller creation failed: $e');
    }
  }

  void _calculateCoinReward() {
    _coinReward = CoinCalculator.calculateCoinsForLevel(widget.level);
    if (mounted) {
      setState(() {});
    }
  }

  void _getReward() async {
    // 播放获得金币特效音效
    await AudioManager().playCoinEffect();
    
    // 检查是否所有80张照片都已解锁
    final prefs = await SharedPreferences.getInstance();
    final allPhotosUnlocked = prefs.getBool('all_photos_unlocked') ?? false;
    
    if (allPhotosUnlocked) {
      // 如果所有照片都解锁了，直接跳转到爱心货币界面
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const WinHeartPage(),
        ),
      );
    } else {
      // 跳转到新照片页面
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NewPhotoPage(level: widget.level),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
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
            // 背景装饰
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.purple.withOpacity(0.3),
                            Colors.blue.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const CommonHeader(showBackButton: false),
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
                        // WIN 标题 with Spine Animation
                        Container(
                          margin: const EdgeInsets.only(bottom: 50),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                Assets.wincoinWinCoinTitle,
                                height: 320,
                              ),
                              // CoinWin_Eff Spine Animation
                              if (_spineController != null && _isSpineReady)
                                Positioned(
                                  child: SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: SpineWidget.fromAsset(
                                      "assets/spine/CoinWin_Eff.atlas",
                                      "assets/spine/CoinWin_Eff.skel",
                                      _spineController!,
                                      boundsProvider: const SetupPoseBounds(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // 奖励信息
                        Container(
                          margin: const EdgeInsets.only(bottom: 80),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                Assets.wincoinWinCoinIconCoin,
                                width: 40,
                                height: 40,
                              ),
                              const SizedBox(width: 10),
                              OutlinedTextWidget(
                                text: '+$_coinReward',
                                fontSize: 42,
                                textColor: Colors.orange,
                                strokeColor: Colors.black,
                                strokeWidth: 3.0,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(
                                    offset: Offset(2, 2),
                                    blurRadius: 4,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // GET 按钮
                        GestureDetector(
                          onTap: _getReward,
                          child: Container(
                            width: 200,
                            height: 70,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(Assets.wincoinWinCoinBtnGreen),
                                fit: BoxFit.fill,
                              ),
                            ),
                            child: const Center(
                              child: OutlinedTextWidget(
                                text: 'GET',
                                fontSize: 28,
                                textColor: Colors.white,
                                strokeColor: Colors.black,
                                strokeWidth: 2.0,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // // 装饰性星星
            // ...List.generate(8, (index) {
            //   return Positioned(
            //     left: (index * 50.0) % MediaQuery.of(context).size.width,
            //     top: (index * 60.0) % MediaQuery.of(context).size.height,
            //     child: AnimatedBuilder(
            //       animation: _fadeAnimation,
            //       builder: (context, child) {
            //         return Opacity(
            //           opacity: _fadeAnimation.value,
            //           child: const Icon(
            //             Icons.star,
            //             color: Colors.yellow,
            //             size: 20,
            //           ),
            //         );
            //       },
            //     ),
            //   );
            // }),
          ],
        ),
      ),
    );
  }
}
