import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:grils_app/main.dart';
import 'package:grils_app/pages/settings_page.dart';
import 'package:grils_app/pages/signin_page.dart';
import 'package:grils_app/pages/gallery_page.dart';
import 'package:grils_app/pages/shop_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  late AnimationController _takeoffController;
  late Animation<double> _takeoffAnimation;
  
  int _coinCount = 1000;
  int _heartCount = 50;
  int _currentLevel = 1;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _takeoffController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _takeoffAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _takeoffController,
      curve: Curves.easeInOut,
    ));

    // 开始循环播放takeoff动画
    _takeoffController.repeat();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _coinCount = prefs.getInt('coin_count') ?? 1000;
        _heartCount = prefs.getInt('heart_count') ?? 50;
        _currentLevel = prefs.getInt('current_level') ?? 1;
      });
    }
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coin_count', _coinCount);
    await prefs.setInt('heart_count', _heartCount);
    await prefs.setInt('current_level', _currentLevel);
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  void _navigateToSignIn() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SignInPage(),
      ),
    ).then((_) {
      // 从签到页面返回时重新加载数据
      _loadUserData();
    });
  }

  void _navigateToGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GalleryPage(),
      ),
    );
  }

  void _navigateToShop() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ShopPage(),
      ),
    ).then((_) {
      // 从商店页面返回时重新加载数据
      _loadUserData();
    });
  }

  void _startGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const SpinePreviewPage(),
      ),
    );
  }

  @override
  void dispose() {
    _takeoffController.dispose();
    _saveUserData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              HexColor("#FF69B4"),
              HexColor("#FF1493"),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 顶部货币显示区域
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 金币显示
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: HexColor("#FFD700"),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          Assets.imagesMainMainIconCoin,
                          height: 30,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '$_coinCount',
                          style: TextStyle(
                            color: HexColor("#8B4513"),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 爱心货币显示
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: HexColor("#FFB6C1"),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.pink, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          Assets.imagesIconHeart2x,
                          height: 30,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '$_heartCount',
                          style: TextStyle(
                            color: HexColor("#8B0000"),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 左侧功能按钮
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height * 0.25,
              child: Column(
                children: [
                  // 签到按钮
                  GestureDetector(
                    onTap: _navigateToSignIn,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 20),
                      child: Image.asset(
                        Assets.imagesMainMainBtnSign,
                        height: 80,
                      ),
                    ),
                  ),
                  
                  // 皮肤商店按钮
                  GestureDetector(
                    onTap: _navigateToShop,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 20),
                      child: Image.asset(
                        Assets.imagesMainMainBtnGameskin,
                        height: 80,
                      ),
                    ),
                  ),
                  
                  // 图鉴按钮
                  GestureDetector(
                    onTap: _navigateToGallery,
                    child: Stack(
                      children: [
                        Image.asset(
                          Assets.imagesMainMainFrameGallary,
                          height: 120,
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          right: 10,
                          bottom: 30,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/grils_list/Bg_01.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _navigateToGallery,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 右侧功能按钮
            Positioned(
              right: 20,
              top: MediaQuery.of(context).size.height * 0.25,
              child: Column(
                children: [
                  // 设置按钮
                  GestureDetector(
                    onTap: _navigateToSettings,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 40),
                      child: Image.asset(
                        Assets.imagesMainMainBtnSetting,
                        height: 80,
                      ),
                    ),
                  ),
                  
                  // 脱衣按钮 (动画)
                  Container(
                    margin: EdgeInsets.only(bottom: 40),
                    child: AnimatedBuilder(
                      animation: _takeoffAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + 0.1 * _takeoffAnimation.value,
                          child: Image.asset(
                            Assets.imagesBtnTakeoff,
                            height: 100,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 底部开始游戏按钮
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _startGame,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        Assets.imagesMainMainBtnGamestart,
                        height: 100,
                      ),
                      Positioned(
                        bottom: 15,
                        child: Text(
                          'Level $_currentLevel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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