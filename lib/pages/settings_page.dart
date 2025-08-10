import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../managers/audio_manager.dart';
import '../widgets/animated_popup.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  // 静态方法：显示设置弹窗
  static Future<void> showSettingsDialog(BuildContext context) async {
    return AnimatedPopup.show(
      context: context,
      child: const SettingsPage(),
      barrierDismissible: true,
    );
  }

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
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
        // 同步音频管理器状态
        AudioManager().setMuted(!_soundEnabled);
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

  void _toggleSound() async {
    // 播放切换音效（如果当前是开启状态）
    if (_soundEnabled) {
      await AudioManager().playSwitch();
    }
    
    setState(() {
      _soundEnabled = !_soundEnabled;
    });
    
    // 保存设置并更新音频管理器
    _saveSoundSetting(_soundEnabled);
    AudioManager().setMuted(!_soundEnabled);
    
    // 如果刚刚开启声音，播放一个确认音效
    if (_soundEnabled) {
      await Future.delayed(const Duration(milliseconds: 100));
      await AudioManager().playSwitch();
    }
  }

  void _goToMainMenu() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _closeSettings() async {
    print('关闭按钮被点击'); // 调试信息
    // 播放退出音效
    await AudioManager().playExit();
    // 简化关闭逻辑，直接关闭对话框
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none, // 允许内容超出边界
      children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(Assets.imagesPopBack),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                // 内容
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: Column(
                    children: [
                      // 主要内容区域
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 声音按钮
                              GestureDetector(
                                onTap: _toggleSound,
                                child: Container(
                                  width: 200,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(Assets.settingSettingBtnBlue),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _soundEnabled ? 'SOUND ON' : 'SOUND OFF',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // 主菜单按钮
                              GestureDetector(
                                onTap: _goToMainMenu,
                                child: Container(
                                  width: 200,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(Assets.settingSettingBtnGreen),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'MAIN MENU',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

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
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: _launchTermsOfService,
                                    child: Text(
                                      'Term of service',
                                      style: TextStyle(
                                        color: HexColor("#8B4513"),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.none,
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

                // 右上角关闭按钮 - 改进触摸灵敏度
                Positioned(
                  top: -5,
                  right: -5,
                  child: GestureDetector(
                    onTap: _closeSettings,
                    onTapDown: (_) => print('关闭按钮按下'),
                    onTapCancel: () => print('关闭按钮取消'),
                    behavior: HitTestBehavior.opaque, // 确保整个区域都可以点击
                    child: Container(
                      width: 70,
                      height: 70,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(35),
                        // 添加一个调试边框来看触摸区域（可选）
                        // border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
                      ),
                      child: Center(
                        child: Image.asset(
                          Assets.imagesBtnClose,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 25,
                  right: 0,
                  left: 0,
                  child: Text(
                    "Setting",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none),
                  ),
                ),
        ],
      );
  }
}
