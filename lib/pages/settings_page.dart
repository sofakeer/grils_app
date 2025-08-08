import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  // 静态方法：显示设置弹窗
  static Future<void> showSettingsDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const SettingsPage();
      },
    );
  }

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      });
    }
  }

  Future<void> _saveSoundSetting(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
  }

  Future<void> _launchPrivacyPolicy() async {
    const url = 'https://example.com/privacy-policy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchTermsOfService() async {
    const url = 'https://example.com/terms-of-service';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _toggleSound() {
    setState(() {
      _soundEnabled = !_soundEnabled;
    });
    _saveSoundSetting(_soundEnabled);
  }

  void _goToMainMenu() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _closeSettings() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 主对话框背景
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: BoxDecoration(
                    color: HexColor("#FFF5E5"),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: HexColor("#FFD700"),
                      width: 3,
                    ),
                  ),
                ),

                // 内容
                Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: Column(
                    children: [
                      // 紫色标题栏
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: HexColor("#8A2BE2"),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(17),
                            topRight: Radius.circular(17),
                          ),
                        ),
                        child: Stack(
                          children: [
                            // 星星装饰
                            Positioned(
                              top: 5,
                              left: 20,
                              child: Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 60,
                              child: Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                            Positioned(
                              bottom: 5,
                              left: 40,
                              child: Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            // 标题文字
                            Center(
                              child: Text(
                                'Setting',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 主要内容区域
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 声音按钮
                              GestureDetector(
                                onTap: _toggleSound,
                                child: Container(
                                  width: 200,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        HexColor("#4A90E2"),
                                        HexColor("#357ABD"),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(40),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      _soundEnabled ? 'SOUND ON' : 'SOUND OFF',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 20),

                              // 主菜单按钮
                              GestureDetector(
                                onTap: _goToMainMenu,
                                child: Container(
                                  width: 200,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        HexColor("#4CAF50"),
                                        HexColor("#388E3C"),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(40),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'MAIN MENU',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 30),

                              // 政策链接
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: _launchPrivacyPolicy,
                                    child: Text(
                                      'Private policy',
                                      style: TextStyle(
                                        color: HexColor("#8B4513"),
                                        fontSize: 16,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: _launchTermsOfService,
                                    child: Text(
                                      'Term of service',
                                      style: TextStyle(
                                        color: HexColor("#8B4513"),
                                        fontSize: 16,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 右上角关闭按钮
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.2 - 25,
                  right: MediaQuery.of(context).size.width * 0.1 - 25,
                  child: GestureDetector(
                    onTap: _closeSettings,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}