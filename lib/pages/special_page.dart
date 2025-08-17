import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/widgets/common_header.dart';
import 'package:grils_app/pages/new_photo_page.dart';
import '../widgets/outlined_text_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

  void _playSpecial() {
    // 跳转到新照片页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NewPhotoPage(),
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
                                    strokeColor: Color(0xffF306FF),
                                    strokeWidth: 2.0,
                                    fontWeight: FontWeight.bold,
                                    textAlign: TextAlign.center,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(2, 2),
                                        blurRadius: 2,
                                        color: Color(0xffF306FF),
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
                          onTap: _playSpecial,
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

                        // SKIP 按钮
                        GestureDetector(
                          onTap: _skipSpecial,
                          child: const OutlinedTextWidget(
                            text: 'SKIP',
                            fontSize: 18,
                            textColor: Colors.white,
                            strokeColor: Colors.black,
                            strokeWidth: 1.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // // 装饰性爱心
            // ...List.generate(3, (index) {
            //   return Positioned(
            //     top: 100 + (index * 30),
            //     left: 20 + (index * 40),
            //     child: AnimatedBuilder(
            //       animation: _heartAnimation,
            //       builder: (context, child) {
            //         return Opacity(
            //           opacity: _heartAnimation.value * 0.8,
            //           child: Transform.scale(
            //             scale: 0.8 + (0.2 * _heartAnimation.value),
            //             child: Container(
            //               width: 30,
            //               height: 30,
            //               decoration: BoxDecoration(
            //                 color: index == 0
            //                     ? Colors.pink
            //                     : index == 1
            //                         ? Colors.blue
            //                         : Colors.blue,
            //                 shape: BoxShape.circle,
            //                 boxShadow: [
            //                   BoxShadow(
            //                     color: Colors.lightBlue.withOpacity(0.6),
            //                     blurRadius: 15,
            //                     spreadRadius: 2,
            //                   ),
            //                 ],
            //               ),
            //               child: const Icon(
            //                 Icons.favorite,
            //                 color: Colors.white,
            //                 size: 20,
            //               ),
            //             ),
            //           ),
            //         );
            //       },
            //     ),
            //   );
            // }),

            // // 右侧装饰性爱心
            // ...List.generate(2, (index) {
            //   return Positioned(
            //     top: 150 + (index * 50),
            //     right: 30 + (index * 20),
            //     child: AnimatedBuilder(
            //       animation: _heartAnimation,
            //       builder: (context, child) {
            //         return Opacity(
            //           opacity: _heartAnimation.value * 0.6,
            //           child: Transform.scale(
            //             scale: 0.6 + (0.4 * _heartAnimation.value),
            //             child: Container(
            //               width: 25,
            //               height: 25,
            //               decoration: BoxDecoration(
            //                 color: Colors.pink.withOpacity(0.8),
            //                 shape: BoxShape.circle,
            //                 boxShadow: [
            //                   BoxShadow(
            //                     color: Colors.pink.withOpacity(0.5),
            //                     blurRadius: 10,
            //                     spreadRadius: 1,
            //                   ),
            //                 ],
            //               ),
            //               child: const Icon(
            //                 Icons.favorite,
            //                 color: Colors.white,
            //                 size: 15,
            //               ),
            //             ),
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
