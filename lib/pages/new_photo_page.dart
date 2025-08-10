import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/widgets/common_header.dart';

class NewPhotoPage extends StatefulWidget {
  const NewPhotoPage({super.key});

  @override
  State<NewPhotoPage> createState() => _NewPhotoPageState();
}

class _NewPhotoPageState extends State<NewPhotoPage> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.1,
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

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // 启动动画序列
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _scaleController.forward();
      }
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _progressController.forward();
      }
    });

    // 监听进度动画
    _progressController.addListener(() {
      setState(() {
        _progress = _progressAnimation.value;
      });
    });
  }

  void _downloadPhoto() {
    // 这里可以添加下载照片的逻辑
    print('下载新照片');
  }

  void _nextPhoto() {
    // 跳转到下一张照片或返回
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _progressController.dispose();
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
                        // NEW PHOTO 标题
                        Container(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                Assets.newPhotoNewPhotoTitle,
                                height: 130,
                              ),
                            ],
                          ),
                        ),

                        // 照片框架
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 照片框架背景
                              Image.asset(
                                Assets.newPhotoNewPhotoFrame,
                                height: 400,
                              ),
                              // 高亮线效果
                              Positioned(
                                top: 150,
                                child: Image.asset(
                                  Assets.newPhotoNewPhotoHighline,
                                  height: 20,
                                ),
                              ),
                              // NEW 图标
                              Positioned(
                                top: 20,
                                left: 20,
                                child: Image.asset(Assets.newPhotoNewPhotoIconNew,width: 50,),
                              )
                            ],
                          ),
                        ),

                        // 进度条
                        Container(
                          margin: const EdgeInsets.only(bottom: 30),
                          child: Column(
                            children: [
                              // 进度条背景
                              Container(
                                width: 300,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.pink.withOpacity(0.3),
                                ),
                                child: Stack(
                                  children: [
                                    // 进度条填充
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      width: 300 * _progress,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        gradient: const LinearGradient(
                                          colors: [Colors.pink, Colors.pinkAccent],
                                        ),
                                      ),
                                    ),
                                    // 进度文字
                                    Center(
                                      child: Text(
                                        '${(_progress * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              // 进度条图标
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    Assets.newPhotoNewPhotoIconSlider,
                                    width: 20,
                                    height: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // DOWNLOAD 按钮
                        GestureDetector(
                          onTap: _downloadPhoto,
                          child: Container(
                            width: 250,
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
                                  'Download',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
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
                              ],
                            ),
                          ),
                        ),

                        // NEXT 按钮
                        GestureDetector(
                          onTap: _nextPhoto,
                          child: const Text(
                            'NEXT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
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
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
