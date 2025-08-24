import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/widgets/common_header.dart';
import 'package:grils_app/pages/settings_page.dart';
import 'package:grils_app/pages/signin_page.dart';
import 'package:grils_app/pages/gallery_page.dart';
import 'package:grils_app/pages/shop_page.dart';
import 'package:grils_app/pages/game_page.dart';
import 'package:grils_app/pages/special_page.dart';
import 'package:grils_app/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spine_flutter/spine_flutter.dart' as spine;

import '../main_old.dart';
import '../managers/audio_manager.dart';
import '../managers/game_state_manager.dart';
import '../utils/audio_assets.dart';
import '../widgets/outlined_text_widget.dart';
import '../services/user_service.dart';
import 'spine_preview_page.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> with TickerProviderStateMixin {
  late AnimationController _takeoffController;
  late Animation<double> _takeoffAnimation;

  // 背景女孩Spine控制器
  spine.SpineWidgetController? _backgroundSpineController;
  bool _isBackgroundSpineReady = false;

  // 使用UserService管理金币和爱心
  late UserService _userService;
  int _currentLevel = 1;
  
  // 最新解锁的图片索引
  int _latestUnlockedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _userService = UserService.instance;
    _initializeAnimations();
    _loadUserData();
    _initializeBackgroundSpine();
    
    // 初始化音频系统并播放主界面BGM
    _initializeAudio();
  }
  
  void _initializeAudio() async {
    await AudioManager().initialize();
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

  void _initializeBackgroundSpine() {
    // 销毁旧的控制器
    if (_backgroundSpineController != null) {
      _backgroundSpineController = null;
    }

    try {
      _backgroundSpineController = spine.SpineWidgetController(onInitialized: (controller) {
        try {
          // 设置默认过渡时间
          controller.animationState.getData().setDefaultMix(0.2);

          // 获取可用动画
          final animations = controller.skeleton.getData()?.getAnimations();
          print("=== 背景女孩 可用动画 ===");
          if (animations != null && animations.isNotEmpty) {
            for (var anim in animations) {
              print("动画名称: ${anim.getName()}");
            }

            if (mounted) {
              setState(() {
                _isBackgroundSpineReady = true;
              });
            }

            // 播放第一个idle动画（循环播放）
            String defaultAnimation = "idle_01";
            final foundAnimation = animations.firstWhere(
              (anim) => anim.getName() == defaultAnimation,
              orElse: () => animations.first,
            );
            
            final animationName = foundAnimation.getName();
            print("开始播放背景动画: $animationName");
            if (animationName.isNotEmpty) {
              controller.animationState.setAnimationByName(0, animationName, true);
              print("背景女孩动画播放成功");
            }

            // 设置默认皮肤
            _setBackgroundDefaultSkin(controller);
          } else {
            print("背景女孩没有找到动画");
          }
          print("========================");
        } catch (e) {
          print("背景女孩动画初始化失败: $e");
        }
      });
    } catch (e) {
      print("背景女孩控制器创建失败: $e");
    }
  }

  void _setBackgroundDefaultSkin(spine.SpineWidgetController controller) {
    try {
      final data = controller.skeletonData;
      final skeleton = controller.skeleton;

      // 创建自定义皮肤 - 默认为Girl01的默认皮肤状态
      final customSkin = spine.Skin("background-default-skin");

      // 添加默认皮肤状态（全部隐藏）
      final braSkin = data.findSkin("bra/bra_none");
      final handsSkin = data.findSkin("hands/hands_none");
      final pantsSkin = data.findSkin("pants/pants_none");
      final socksSkin = data.findSkin("socks/socks_none");

      if (braSkin != null) customSkin.addSkin(braSkin);
      if (handsSkin != null) customSkin.addSkin(handsSkin);
      if (pantsSkin != null) customSkin.addSkin(pantsSkin);
      if (socksSkin != null) customSkin.addSkin(socksSkin);

      // 应用自定义皮肤
      skeleton.setSkin(customSkin);
      skeleton.setSlotsToSetupPose();

      print("背景女孩默认皮肤应用成功");
    } catch (e) {
      print("背景女孩皮肤设置失败: $e");
    }
  }

  Future<void> _loadUserData() async {
    // 初始化UserService
    await _userService.initialize();
    
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentLevel = prefs.getInt('current_level') ?? 1;
        
        // 加载最新解锁的图片
        _latestUnlockedImageIndex = _getLatestUnlockedImageIndex(prefs);
      });
    }
    print("MainPage: UserService初始化完成，金币: ${_userService.coinCount}, 爱心: ${_userService.heartCount}");
    
    // 检查是否应该触发特殊关卡
    await _checkForSpecialStage();
  }
  
  // 检查是否应该触发特殊关卡
  Future<void> _checkForSpecialStage() async {
    await GameStateManager().init();
    
    if (GameStateManager().shouldTriggerSpecialStage()) {
      // 延迟一下，等页面完全加载后再显示弹窗
      await Future.delayed(Duration(milliseconds: 500));
      
      if (mounted) {
        // 标记特殊关卡已触发
        await GameStateManager().markSpecialStageTriggered();
        
        // 显示特殊关卡弹窗
        await AudioManager().playPopupOpen();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const SpecialPage(),
        );
      }
    }
  }
  
  // 获取最新解锁的图片索引
  int _getLatestUnlockedImageIndex(SharedPreferences prefs) {
    // 总共75张图片，从后往前查找最新解锁的
    for (int i = 74; i >= 0; i--) {
      // 前5张图片默认解锁
      if (i < 5) {
        print("使用默认解锁图片: Bg_${(i + 1).toString().padLeft(2, '0')}.png");
        return i;
      }
      if (prefs.getBool('photo_unlocked_$i') ?? false) {
        print("找到最新解锁图片: Bg_${(i + 1).toString().padLeft(2, '0')}.png");
        return i;
      }
    }
    // 如果没有找到，返回第一张图片
    print("没有找到解锁图片，使用默认第一张");
    return 0;
  }
  
  // 获取图片路径
  String _getImagePath(int index) {
    // 图片索引从0开始，但文件名从01开始
    final imageNumber = (index + 1).toString().padLeft(2, '0');
    return 'assets/images/grils_list/Bg_$imageNumber.png';
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    // 金币和爱心通过UserService自动保存，这里只保存其他数据
    await prefs.setInt('current_level', _currentLevel);
  }

  void _showSettingsDialog() async {
    await AudioManager().playPopupOpen();
    SettingsPage.showSettingsDialog(context);
  }

  void _navigateToSignIn() async {
    await AudioManager().playPopupOpen();
    SignInPage.showSignInDialog(context).then((_) {
      // 从签到页面返回时重新加载数据
      _loadUserData();
    });
  }


  void _navigateToShop() async {
    await AudioManager().playPopupOpen();
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
  
  void _navigateToGallery() async {
    await AudioManager().playPopupOpen();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GalleryPage(),
      ),
    ).then((_) {
      // 从图鉴页面返回时重新加载数据，可能有新图片解锁
      _loadUserData();
    });
  }

  void _navigateToGame() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GamePage(),
      ),
    ).then((_) {
      // 从游戏页面返回时重新加载数据，可能有新图片解锁
      _loadUserData();
    });
  }

  void _switchToNextGirl() async {
    await AudioManager().playSwitch();
    final currentIndex = ref.read(currentGirlIndexProvider);
    final spineAssets = ref.read(spineAssetsProvider);
    final nextIndex = (currentIndex + 1) % spineAssets.length;
    ref.read(currentGirlIndexProvider.notifier).state = nextIndex;
    
    // 重新初始化背景Spine动画
    _initializeBackgroundSpine();
  }

  void _startTakeOff() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SpinePreviewPage(),
      ),
    ).then((_) {
      // 从预览页面返回时重新加载数据，可能有新图片解锁
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _takeoffController.dispose();
    _backgroundSpineController = null;
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
            // 背景显示当前选择的女孩 currentGirlAsset spine 动画默认的
            if (_backgroundSpineController != null)
              Positioned.fill(
                child: spine.SpineWidget.fromAsset(
                  currentGirlAsset.atlasFile,
                  currentGirlAsset.skeletonFile,
                  _backgroundSpineController!,
                  boundsProvider: const spine.SetupPoseBounds(),
                ),
              ),

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
              bottom: 30,
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
                          _getImagePath(_latestUnlockedImageIndex),
                          fit: BoxFit.cover, // 使用cover填充整个容器
                          alignment: Alignment.topCenter, // 确保头部优先显示
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
              bottom: 150,
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

                  // 换按钮 (动画)
                  GestureDetector(
                    onTap: () {
                      _startTakeOff();
                    },
                    child: const SizedBox(
                      width: 100,
                      height: 120,
                      child: TakeoffButtonAnimation(),
                    ),
                  ),
                ],
              ),
            ),

            // 底部开始游戏按钮,
            Positioned(
              bottom: 30,
              right: 20,
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
                        child: OutlinedTextWidget(
                          text: 'Level ${_currentLevel.toString().padLeft(3, '0')}',
                          fontSize: 11,
                          textColor: Colors.white,
                          strokeColor: Colors.black,
                          strokeWidth: 4.0, // 为小字体增加描边宽度
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.6),
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
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
    if (_spineController == null) {
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
          child: OutlinedTextWidget(
            text: 'SPINE\n加载失败',
            fontSize: 12,
            textColor: Colors.white,
            strokeColor: Colors.red,
            strokeWidth: 1.0,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }
}
