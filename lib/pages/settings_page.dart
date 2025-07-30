import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

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
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 背景
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.6,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(Assets.imagesPopPopFrameMiddle),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),

                  // 内容
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Column(
                      children: [
                        // 标题
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            '设置',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: HexColor("#8B4513"),
                            ),
                          ),
                        ),

                        // 设置项列表
                        Expanded(
                          child: Column(
                            children: [
                              // 声音开关
                              _buildSettingItem(
                                icon: Icons.volume_up,
                                title: '声音',
                                subtitle: _soundEnabled ? 'ON' : 'OFF',
                                onTap: _toggleSound,
                                trailing: Switch(
                                  value: _soundEnabled,
                                  onChanged: (value) {
                                    _toggleSound();
                                  },
                                  activeColor: Colors.green,
                                  inactiveThumbColor: Colors.grey,
                                ),
                              ),

                              SizedBox(height: 20),

                              // 隐私政策
                              _buildSettingItem(
                                icon: Icons.privacy_tip,
                                title: '隐私政策',
                                subtitle: '查看我们的隐私政策',
                                onTap: _launchPrivacyPolicy,
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: HexColor("#8B4513"),
                                  size: 16,
                                ),
                              ),

                              SizedBox(height: 20),

                              // 服务条款
                              _buildSettingItem(
                                icon: Icons.description,
                                title: '服务条款',
                                subtitle: '查看服务条款',
                                onTap: _launchTermsOfService,
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: HexColor("#8B4513"),
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 关闭按钮
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: GestureDetector(
                            onTap: _closeSettings,
                            child: Container(
                              width: 120,
                              height: 50,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(Assets.imagesSettingSettingBtnBlue),
                                  fit: BoxFit.fill,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '关闭',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 右上角关闭按钮
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.2 - 20,
                    right: MediaQuery.of(context).size.width * 0.1 - 20,
                    child: GestureDetector(
                      onTap: _closeSettings,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
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
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: HexColor("#FF69B4").withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: HexColor("#FF69B4"),
                size: 24,
              ),
            ),
            
            SizedBox(width: 15),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: HexColor("#4A4A4A"),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: HexColor("#888888"),
                    ),
                  ),
                ],
              ),
            ),
            
            // Trailing widget
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}