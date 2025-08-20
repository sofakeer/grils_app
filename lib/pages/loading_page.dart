import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'dart:async';
import 'package:grils_app/pages/main_page.dart';
import 'package:grils_app/widgets/privacy_dialog.dart';
import 'package:grils_app/widgets/outlined_text_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  Timer? _progressTimer;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLoading();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  void _startLoading() {
    _progressController.forward();

    _progressTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isCompleted = true;
        });
        _checkFirstLaunch();
      }
    });
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
    // _showPrivacyDialog();
    if (isFirstLaunch && mounted) {
      // 首次启动，显示隐私协议弹窗
      _showPrivacyDialog();
    } else {
      // 非首次启动，直接进入主页面
      _navigateToMainPage();
    }
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PrivacyDialog(
        onAccept: () async {
          // 标记已接受隐私协议
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_first_launch', false);
          
          if (mounted) {
            Navigator.of(context).pop();
            _navigateToMainPage();
          }
        },
        onDecline: () {
          // 用户拒绝隐私协议，关闭应用
          Navigator.of(context).pop();
          // 这里可以添加关闭应用的逻辑
        },
      ),
    );
  }

  void _navigateToMainPage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainPage(),
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Assets.loadingLoadingBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Logo
            // Positioned(
            //   top: MediaQuery.of(context).size.height * 0.2,
            //   left: 0,
            //   right: 0,
            //   child: Center(
            //     child: Image.asset(
            //       Assets.loadingLoadingBg,
            //       height: 200,
            //     ),
            //   ),
            // ),

            // Loading text
            Positioned(
              top: MediaQuery.of(context).size.height * 0.5,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  Assets.loadingLoadingText,
                  height: 50,
                ),
              ),
            ),

            // Progress bar
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.2,
              left: 50,
              right: 50,
              child: Column(
                children: [
                  // Progress bar background
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        // Background image
                        Container(
                          width: double.infinity,
                          height: 20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: AssetImage(Assets.loadingLoadingSliderbarBg),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Progress fill
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Container(
                              width: MediaQuery.of(context).size.width * 0.8 * _progressAnimation.value,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: AssetImage(Assets.loadingLoadingSliderbarTop),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Progress percentage
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return OutlinedTextWidget(
                        text: '${(_progressAnimation.value * 100).toInt()}%',
                        fontSize: 18,
                        textColor: Colors.white,
                        strokeColor: Colors.black,
                        strokeWidth: 1.5,
                        fontWeight: FontWeight.bold,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}