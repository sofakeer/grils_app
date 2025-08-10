import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/widgets/common_header.dart';
import 'package:grils_app/main.dart';
import 'package:grils_app/pages/settings_page.dart';
import 'package:grils_app/pages/signin_page.dart';
import 'package:grils_app/pages/gallery_page.dart';
import 'package:grils_app/pages/shop_page.dart';
import 'package:grils_app/pages/game_page.dart';
import 'package:grils_app/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spine_flutter/spine_flutter.dart' as spine;

import '../main_old.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> with TickerProviderStateMixin {
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

  void _showSettingsDialog() {
    SettingsPage.showSettingsDialog(context);
  }

  void _navigateToSignIn() {
    SignInPage.showSignInDialog(context).then((_) {
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
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const ShopPage(),
      ),
    )
        .then((_) {
      // 从商店页面返回时重新加载数据
      _loadUserData();
    });
  }

  void _navigateToGame() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GamePage(),
      ),
    );
  }

  void _switchToNextGirl() {
    final currentIndex = ref.read(currentGirlIndexProvider);
    final spineAssets = ref.read(spineAssetsProvider);
    final nextIndex = (currentIndex + 1) % spineAssets.length;
    ref.read(currentGirlIndexProvider.notifier).state = nextIndex;
  }

  void _startTakeOff() {
    Navigator.of(context).push(
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
    final currentGirlAsset = ref.watch(currentGirlAssetProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        child: Stack(
          children: [
            // 顶部货币显示区域
            CommonHeader(
              settingsButton: true,
              onBackPressed: () {
                _showSettingsDialog();
              },
            ),

            // 左侧功能按钮
            Positioned(
              left: 20,
              top: 130,
              child: Column(
                children: [
                  // 签到按钮
                  GestureDetector(
                    onTap: _navigateToSignIn,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Image.asset(
                        Assets.mainMainBtnSign,
                        height: 60,
                      ),
                    ),
                  ),

                  // 皮肤商店按钮
                  GestureDetector(
                    onTap: _navigateToShop,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Image.asset(
                        Assets.mainMainBtnGameskin,
                        height: 60,
                      ),
                    ),
                  ),

                  // 图鉴按钮 - 显示最新选择的女孩

                  // 游戏按钮
                  // GestureDetector(
                  //   onTap: _navigateToGame,
                  //   child: Container(
                  //     margin: const EdgeInsets.only(top: 20),
                  //     child: Image.asset(
                  //       Assets.mainMainBtnGamestart,
                  //       height: 80,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),

            Positioned(
              left: 20,
              bottom: 50,
              child: GestureDetector(
                onTap: _navigateToGallery,
                child: Stack(
                  children: [
                    Image.asset(
                      Assets.mainMainFrameGallary,
                      height: 120,
                    ),
                    Positioned(
                      top: 5,
                      left: 6,
                      right: 6,
                      bottom: 30,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          Assets.grilsListBg01,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 75,
                      left: 6,
                      right: 6,
                      bottom: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          Assets.mainMainBtnGallary,
                          fit: BoxFit.fitWidth,
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
            ),
            // 右侧功能按钮
            Positioned(
              right: 20,
              bottom: 180,
              child: Column(
                children: [
                  // // 设置按钮
                  // GestureDetector(
                  //   onTap: _navigateToSettings,
                  //   child: Container(
                  //     margin: EdgeInsets.only(bottom: 40),
                  //     child: Image.asset(
                  //       Assets.mainMainBtnSetting,
                  //       height: 80,
                  //     ),
                  //   ),
                  // ),

                  // 脱衣按钮 (动画)
                  GestureDetector(
                    onTap: () {
                      _startTakeOff();
                    },
                    child: const SizedBox(
                      width: 120,
                      height: 120,
                      child: TakeoffButtonAnimation(),
                    ),
                  ),
                ],
              ),
            ),

            // 中央显示当前选择的女孩
            // Positioned(
            //   top: MediaQuery.of(context).size.height * 0.3,
            //   left: MediaQuery.of(context).size.width * 0.2,
            //   right: MediaQuery.of(context).size.width * 0.2,
            //   bottom: MediaQuery.of(context).size.height * 0.35,
            //   child: GestureDetector(
            //     onTap: _switchToNextGirl,
            //     child: Container(
            //       decoration: BoxDecoration(
            //         borderRadius: BorderRadius.circular(20),
            //         border: Border.all(
            //           color: Colors.white.withOpacity(0.3),
            //           width: 2,
            //         ),
            //       ),
            //       child: ClipRRect(
            //         borderRadius: BorderRadius.circular(18),
            //         child: Container(
            //           color: Colors.black.withOpacity(0.1),
            //           child: Center(
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Container(
            //                   width: 150,
            //                   height: 150,
            //                   decoration: BoxDecoration(
            //                     shape: BoxShape.circle,
            //                     border: Border.all(
            //                       color: Colors.white.withOpacity(0.5),
            //                       width: 3,
            //                     ),
            //                   ),
            //                   child: ClipOval(
            //                     child: Image.asset(
            //                       currentGirlAsset.imagePath,
            //                       fit: BoxFit.cover,
            //                     ),
            //                   ),
            //                 ),
            //                 const SizedBox(height: 10),
            //                 Text(
            //                   currentGirlAsset.name,
            //                   style: TextStyle(
            //                     color: Colors.white,
            //                     fontSize: 20,
            //                     fontWeight: FontWeight.bold,
            //                     shadows: [
            //                       Shadow(
            //                         color: Colors.black.withOpacity(0.7),
            //                         offset: const Offset(1, 1),
            //                         blurRadius: 3,
            //                       ),
            //                     ],
            //                   ),
            //                 ),
            //                 const SizedBox(height: 5),
            //                 Text(
            //                   'Tap to switch',
            //                   style: TextStyle(
            //                     color: Colors.white.withOpacity(0.7),
            //                     fontSize: 12,
            //                     shadows: [
            //                       Shadow(
            //                         color: Colors.black.withOpacity(0.7),
            //                         offset: const Offset(1, 1),
            //                         blurRadius: 2,
            //                       ),
            //                     ],
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),

            // 底部开始游戏按钮,
            Positioned(
              bottom: 30,
              right: 30,
              child: Center(
                child: GestureDetector(
                  onTap: _navigateToGame,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        Assets.mainMainBtnGamestart,
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
                                offset: const Offset(1, 1),
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

// 脱衣按钮动画组件 - 使用 btn_takeoff spine 动画
class TakeoffButtonAnimation extends StatefulWidget {
  const TakeoffButtonAnimation({super.key});

  @override
  _TakeoffButtonAnimationState createState() => _TakeoffButtonAnimationState();
}

class _TakeoffButtonAnimationState extends State<TakeoffButtonAnimation> {
  spine.SpineWidgetController? _spineController;
  bool _isControllerReady = false;

  @override
  void initState() {
    super.initState();
    _initializeBtnTakeoffController();
  }

  void _initializeBtnTakeoffController() {
    // 先销毁旧的控制器
    if (_spineController != null) {
      _spineController = null;
    }

    try {
      _spineController = spine.SpineWidgetController(onInitialized: (controller) {
        try {
          // 设置默认过渡时间
          controller.animationState.getData().setDefaultMix(0.2);

          // 获取可用动画
          final animations = controller.skeleton.getData()?.getAnimations();
          print("=== btn_takeoff 可用动画 ===");
          if (animations != null && animations.isNotEmpty) {
            for (var anim in animations) {
              print("动画名称: ${anim.getName()}");
            }

            if (mounted) {
              setState(() {
                _isControllerReady = true;
              });
            }

            // 播放第一个可用的动画（循环播放）
            if (animations.isNotEmpty) {
              final firstAnimationName = animations.first.getName();
              print("开始播放动画: $firstAnimationName");
              if (firstAnimationName.isNotEmpty) {
                controller.animationState.setAnimationByName(0, firstAnimationName, true);
                print("btn_takeoff 动画播放成功");
              } else {
                print("动画名称为空");
              }
            }
          } else {
            print("btn_takeoff 没有找到动画");
          }
          print("========================");
        } catch (e) {
          print("btn_takeoff 动画初始化失败: $e");
        }
      });
    } catch (e) {
      print("btn_takeoff 控制器创建失败: $e");
    }
  }

  @override
  void dispose() {
    _spineController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_spineController == null || !_isControllerReady) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.pink.withOpacity(0.3),
          borderRadius: BorderRadius.circular(60),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.pink,
          ),
        ),
      );
    }

    try {
      return SizedBox(
        width: 120,
        height: 120,
        child: spine.SpineWidget.fromAsset(
          "assets/spine/btn_takeoff.atlas",
          "assets/spine/btn_takeoff.skel",
          _spineController!,
          boundsProvider: const spine.SetupPoseBounds(),
        ),
      );
    } catch (e) {
      print("btn_takeoff SpineWidget 创建失败: $e");
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.3),
          borderRadius: BorderRadius.circular(60),
        ),
        child: const Center(
          child: Text(
            'SPINE\n加载失败',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }
}
