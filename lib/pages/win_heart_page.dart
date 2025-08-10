import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/widgets/common_header.dart';
import 'package:grils_app/pages/special_page.dart';

class WinHeartPage extends StatefulWidget {
  const WinHeartPage({super.key});

  @override
  State<WinHeartPage> createState() => _WinHeartPageState();
}

class _WinHeartPageState extends State<WinHeartPage> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.3,
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
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _scaleController.forward();
      }
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _heartController.forward();
      }
    });
  }

  void _getReward() {
    // 跳转到特殊页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SpecialPage(),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _heartController.dispose();
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
            image: AssetImage(Assets.winHeartWinHeartBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // 头部
            const CommonHeader(
              showBackButton: false,
            ),

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
                        // VICTORY 标题
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Image.asset(
                            Assets.winHeartWinHeartTitle,
                            height: 150,
                          ),
                        ),

                        // 中间背景和女孩动画
                        Container(
                          margin: const EdgeInsets.only(bottom: 40),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 中间背景
                              Image.asset(
                                Assets.winHeartWinHeartMiddleBg,
                                height: 300,
                              ),
                              // 女孩动画
                              Image.asset(
                                Assets.winHeartWinHeartMiddleGirlAni,
                                height: 280,
                              ),
                            ],
                          ),
                        ),

                        GestureDetector(
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
                                const Text(
                                  '+100',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 爱心奖励

                        // GET 按钮
                        GestureDetector(
                          onTap: _getReward,
                          child: const Center(
                            child: Text(
                              'GET',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                shadows: [
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

            // 装饰性光效
            ...List.generate(6, (index) {
              return Positioned(
                left: (index * 80.0) % MediaQuery.of(context).size.width,
                top: (index * 100.0) % MediaQuery.of(context).size.height,
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value * 0.6,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.yellow.withOpacity(0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.yellow.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
