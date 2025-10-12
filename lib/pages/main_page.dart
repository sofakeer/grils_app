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
import '../widgets/unlock_new_gril_dialog.dart';
import '../widgets/gril_waiting_dialog.dart';
import 'spine_preview_page.dart';
import '../tilt_test_page.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage>
    with TickerProviderStateMixin {
  late AnimationController _takeoffController;
  late Animation<double> _takeoffAnimation;

  // 页面加载状态
  bool _isPageReady = false;

  // 背景女孩Spine控制器
  spine.SpineWidgetController? _backgroundSpineController;
  bool _isBackgroundSpineReady = false;
  int _backgroundIdleIndex = 0;
  Map<String, int> _backgroundSkinSelections = {};

  // 使用UserService管理金币和爱心
  late UserService _userService;
  int _currentLevel = 1;

  // 最新解锁的图片索引
  int _latestUnlockedImageIndex = 0;

  // 标记是否已经弹过 GrilWaitingDialog
  bool _hasShownGrilWaitingDialog = false;
  static const String _kHasShownGrilWaitingDialogKey =
      'has_shown_gril_waiting_dialog';

  Future<void> _loadHasShownGrilWaitingDialogFlag() async {
    final prefs = await SharedPreferences.getInstance();
    _hasShownGrilWaitingDialog =
        prefs.getBool(_kHasShownGrilWaitingDialogKey) ?? false;
  }

  Future<void> _setHasShownGrilWaitingDialogFlag(bool value) async {
    _hasShownGrilWaitingDialog = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasShownGrilWaitingDialogKey, value);
  }

  Future<void> _restoreBackgroundState() async {
    await GameStateManager().init();

    // 优先尝试恢复上次保存的女孩状态
    final lastState = GameStateManager().getLastGirlState();
    int targetGirlIndex;
    int idleOverride;
    Map<String, int>? skinsOverride;

    if (lastState != null) {
      // 如果有上次保存的状态，使用它
      targetGirlIndex = (lastState['girlIndex'] as int?) ?? 0;
      idleOverride = (lastState['idleIndex'] as int?) ?? 0;

      // 解析皮肤状态
      final dynamic skins = lastState['skins'];
      if (skins is Map) {
        final map = <String, int>{};
        skins.forEach((key, value) {
          if (key is String) {
            if (value is int) {
              map[key] = value;
            } else if (value is num) {
              map[key] = value.toInt();
            }
          }
        });
        if (map.isNotEmpty) {
          skinsOverride = map;
        }
      }
      print("恢复上次保存的女孩状态: girl=$targetGirlIndex, idle=$idleOverride, skins=$skinsOverride");
    } else {
      // 如果没有保存的状态，使用当前StateManager的状态
      targetGirlIndex = GameStateManager().getCurrentGirlIndex();
      idleOverride = GameStateManager().getCurrentIdleIndex();
      skinsOverride = GameStateManager().getCurrentSkins(targetGirlIndex);
      print("使用StateManager当前状态: girl=$targetGirlIndex, idle=$idleOverride, skins=$skinsOverride");
    }

    await _loadGirlStateForBackground(
      targetGirlIndex,
      idleIndexOverride: idleOverride,
      skinsOverride: skinsOverride,
      ensureInit: false,
    );

    // 更新StateManager状态
    await GameStateManager().setCurrentGirlIndex(targetGirlIndex);
    await GameStateManager().setCurrentIdleIndex(idleOverride);

    // 标记页面准备就绪
    if (mounted) {
      setState(() {
        _isPageReady = true;
      });
    }
  }

  Future<void> _loadGirlStateForBackground(
    int girlIndex, {
    int? idleIndexOverride,
    Map<String, int>? skinsOverride,
    bool ensureInit = true,
  }) async {
    if (ensureInit) {
      await GameStateManager().init();
    }

    final assets = ref.read(spineAssetsProvider);
    if (assets.isEmpty) {
      return;
    }

    final int normalizedGirlIndex =
        girlIndex.clamp(0, assets.length - 1) as int;
    final int storedIdle = idleIndexOverride ??
        GameStateManager().getGirlIdleIndex(normalizedGirlIndex);
    final Map<String, int> storedSkins =
        GameStateManager().getCurrentSkins(normalizedGirlIndex);
    final Map<String, int> mergedSkins = {...storedSkins};
    if (skinsOverride != null) {
      mergedSkins.addAll(skinsOverride);
    }

    if (!mounted) {
      return;
    }

    ref.read(currentGirlIndexProvider.notifier).state = normalizedGirlIndex;

    setState(() {
      _backgroundIdleIndex =
          _normalizeIdleIndex(normalizedGirlIndex, storedIdle);
      _backgroundSkinSelections =
          _normalizeSkinSelections(normalizedGirlIndex, mergedSkins);
      _isBackgroundSpineReady = false;
    });

    await GameStateManager().setCurrentGirlIndex(normalizedGirlIndex);
    await GameStateManager().setCurrentIdleIndex(_backgroundIdleIndex);

    if (!mounted) {
      return;
    }

    _initializeBackgroundSpine();
  }

  Map<String, int> _normalizeSkinSelections(
      int girlIndex, Map<String, int> skins) {
    if (girlIndex == 0) {
      return {
        'bra': skins['bra'] ?? 0,
        'pants': skins['pants'] ?? 0,
        'hands': skins['hands'] ?? 0,
        'socks': skins['socks'] ?? 0,
      };
    } else if (girlIndex == 1) {
      return {
        'head': skins['head'] ?? 0,
        'bra': skins['bra'] ?? 0,
        'hands': skins['hands'] ?? 0,
        'socks': skins['socks'] ?? 0,
      };
    } else {
      return {
        'head': skins['head'] ?? 0,
        'bra': skins['bra'] ?? 0,
        'pants': skins['pants'] ?? 0,
        'socks': skins['socks'] ?? 0,
      };
    }
  }

  int _normalizeIdleIndex(int girlIndex, int idleIndex) {
    final int maxIndex = girlIndex == 2 ? 5 : 4;
    if (idleIndex < 0) {
      return 0;
    }
    if (idleIndex > maxIndex) {
      return maxIndex;
    }
    return idleIndex;
  }

  bool _isUnderwearMode(int girlIndex, int idleIndex) {
    return girlIndex == 2 ? idleIndex == 5 : idleIndex == 4;
  }

  String _resolveIdleAnimationName(int girlIndex, int idleIndex) {
    if (_isUnderwearMode(girlIndex, idleIndex)) {
      return 'idle_underwear';
    }
    final int safeIndex = idleIndex < 0 ? 0 : idleIndex;
    final String formatted = (safeIndex + 1).toString().padLeft(2, '0');
    return 'idle_$formatted';
  }

  List<String> _buildDefaultSkinNames(int girlIndex) {
    if (girlIndex == 0) {
      return [
        'bra/bra_none',
        'pants/pants_none',
        'hands/hands_none',
        'socks/socks_none',
      ];
    } else if (girlIndex == 1) {
      return [
        'bra/bra_none',
        'hands/hands_none',
        'head/head_none',
        'socks/socks_none',
      ];
    } else {
      return [
        'bra/bra_none',
        'head/head_none',
        'pants/pants_none',
        'socks/socks_none',
      ];
    }
  }

  List<String> _buildUnderwearSkinNames(int girlIndex, Map<String, int> skins) {
    if (girlIndex == 0) {
      return [
        'bra/bra${(skins['bra'] ?? 0) + 1}',
        'pants/pants${(skins['pants'] ?? 0) + 1}',
        'hands/hands${(skins['hands'] ?? 0) + 1}',
        'socks/socks${(skins['socks'] ?? 0) + 1}',
      ];
    } else if (girlIndex == 1) {
      return [
        'bra/bra${(skins['bra'] ?? 0) + 1}',
        'hands/hands${(skins['hands'] ?? 0) + 1}',
        'head/head${(skins['head'] ?? 0) + 1}',
        'socks/socks${(skins['socks'] ?? 0) + 1}',
      ];
    } else {
      return [
        'bra/bra${(skins['bra'] ?? 0) + 1}',
        'head/head${(skins['head'] ?? 0) + 1}',
        'pants/pants${(skins['pants'] ?? 0) + 1}',
        'socks/socks${(skins['socks'] ?? 0) + 1}',
      ];
    }
  }

  void _applySkinSet(
      spine.SpineWidgetController controller, List<String> skinNames) {
    try {
      final data = controller.skeletonData;
      final skeleton = controller.skeleton;
      if (data == null || skeleton == null) {
        return;
      }

      final customSkin = spine.Skin('background-custom-skin');
      bool hasAnySkin = false;
      for (final name in skinNames) {
        final skin = data.findSkin(name);
        if (skin != null) {
          customSkin.addSkin(skin);
          hasAnySkin = true;
        } else {
          print('背景女孩皮肤缺失: $name');
        }
      }

      if (hasAnySkin) {
        skeleton.setSkin(customSkin);
        skeleton.setSlotsToSetupPose();
      } else {
        final defaultSkin = data.findSkin('default');
        if (defaultSkin != null) {
          skeleton.setSkin(defaultSkin);
          skeleton.setSlotsToSetupPose();
        } else {
          skeleton.setToSetupPose();
        }
      }
    } catch (e) {
      print('背景女孩皮肤设置失败: $e');
    }
  }

  void _applyBackgroundSkin(
      spine.SpineWidgetController controller, int girlIndex, bool isUnderwear) {
    final skinNames = isUnderwear
        ? _buildUnderwearSkinNames(girlIndex, _backgroundSkinSelections)
        : _buildDefaultSkinNames(girlIndex);
    _applySkinSet(controller, skinNames);
  }

  void _applyBackgroundState(spine.SpineWidgetController controller) {
    final animationState = controller.animationState;
    final stateData = animationState?.getData();
    final skeleton = controller.skeleton;
    final skeletonData = skeleton?.getData();

    if (animationState == null ||
        stateData == null ||
        skeleton == null ||
        skeletonData == null) {
      // 控制器尚未准备就绪，等待下一帧再试
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller == _backgroundSpineController) {
          _applyBackgroundState(controller);
        }
      });
      return;
    }

    try {
      stateData.setDefaultMix(0.2);
    } catch (e) {
      print('背景女孩动画过渡设置失败: $e');
    }

    final girlIndex = ref.read(currentGirlIndexProvider);
    final idleIndex = _backgroundIdleIndex;
    final isUnderwear = _isUnderwearMode(girlIndex, idleIndex);
    final desiredAnimation = _resolveIdleAnimationName(girlIndex, idleIndex);

    String? animationToPlay;
    try {
      if (skeletonData.findAnimation(desiredAnimation) != null) {
        animationToPlay = desiredAnimation;
      } else if (skeletonData.findAnimation('idle_01') != null) {
        animationToPlay = 'idle_01';
      } else {
        final animations = skeletonData.getAnimations();
        if (animations != null && animations.isNotEmpty) {
          animationToPlay = animations.first.getName();
        }
      }
    } catch (e) {
      print('背景女孩查询动画失败: $e');
    }

    if (animationToPlay != null && animationToPlay.isNotEmpty) {
      try {
        animationState.setAnimationByName(0, animationToPlay, true);
      } catch (e) {
        print('背景女孩动画播放失败: $e');
      }
    }

    _applyBackgroundSkin(controller, girlIndex, isUnderwear);

    if (mounted) {
      setState(() {
        _isBackgroundSpineReady = true;
        _isPageReady = true; // 确保页面标记为就绪
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _userService = UserService.instance;
    _initializeAnimations();
    _loadUserData();
    _restoreBackgroundState();

    // 初始化音频系统并播放主界面BGM
    _initializeAudio();

    // 读取是否已经弹过GrilWaitingDialog的持久化标记
    _loadHasShownGrilWaitingDialogFlag();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当从其它页面返回到主界面时再次检查特殊关卡和刷新状态
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      // 延迟到当前帧结束，确保上下文稳定
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // 检查特殊关卡
          _checkForSpecialStage();

          // 刷新背景女孩状态以确保同步
          _refreshBackgroundState();

          // 检查并播放待播放的爱心动画
          _checkAndPlayPendingHeartAnimation();
        }
      });
    }
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
      _backgroundSpineController =
          spine.SpineWidgetController(onInitialized: (controller) {
        _applyBackgroundState(controller);
      });
    } catch (e) {
      print("背景女孩控制器创建失败: $e");
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
    print(
        "MainPage: UserService初始化完成，金币: ${_userService.coinCount}, 爱心: ${_userService.heartCount}");

    // 检查是否应该触发特殊关卡
    await _checkForSpecialStage();

    // 检查是否有待解锁的女孩
    await _checkForUnlockGirl();

    // 检查是否有可进行的操作
    await _checkForAvailableActions();
  }

  // 检查是否应该触发特殊关卡
  Future<void> _checkForSpecialStage() async {
    await GameStateManager().init();
    // 仅当标记要求在返回后触发时，才检查并弹出
    if (GameStateManager().shouldTriggerSpecialOnReturn() && GameStateManager().shouldTriggerSpecialStage()) {
      // 延迟一下，等页面完全加载后再显示弹窗
      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        // 显示特殊关卡弹窗
        await AudioManager().playPopupOpen();
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const SpecialPage(),
        );

        await GameStateManager().markSpecialStageTriggered();
      }
    }
  }

  // 检查是否有待解锁的女孩
  Future<void> _checkForUnlockGirl() async {
    await GameStateManager().init();

    // 获取待解锁的女孩索引
    int? pendingUnlockGirl = GameStateManager().getPendingUnlockGirl();

    if (pendingUnlockGirl != null && mounted) {
      // 延迟一下，等页面完全加载后再显示弹窗
      await Future.delayed(Duration(milliseconds: 800));

      if (mounted) {
        // 清除待解锁女孩标记
        await GameStateManager().setPendingUnlockGirl(null);

        // 显示解锁新女孩弹窗
        await AudioManager().playPopupOpen();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => UnlockNewGrilDialog(
            girlIndex: pendingUnlockGirl,
            onAccept: () {
              Navigator.of(context).pop();
              // 用户同意解锁，可以在这里添加额外的逻辑
              print("用户同意解锁女孩: $pendingUnlockGirl");
            },
            onDecline: () {
              Navigator.of(context).pop();
              // 用户拒绝解锁，可以在这里添加额外的逻辑
              print("用户拒绝解锁女孩: $pendingUnlockGirl");
            },
          ),
        );
      }
    }
  }

  // 检查是否有可进行的操作
  Future<void> _checkForAvailableActions() async {
    await GameStateManager().init();

    // 如果已经弹过这个弹窗，就不再弹了
    if (_hasShownGrilWaitingDialog) {
      return;
    }

    // 获取当前女孩索引
    int currentGirlIndex = GameStateManager().getCurrentGirlIndex();

    // 检查是否可以脱衣或解锁新皮肤
    bool canTakeoff = GameStateManager().canTakeoff();
    var affordableSkin = GameStateManager().getAffordableSkin(currentGirlIndex);

    if (canTakeoff || affordableSkin != null) {
      // 延迟一下，等页面完全加载后再显示弹窗
      await Future.delayed(Duration(milliseconds: 1200));

      if (mounted) {
        // 标记已经弹过弹窗（持久化）
        await _setHasShownGrilWaitingDialogFlag(true);

        // 显示提醒弹窗
        await AudioManager().playPopupOpen();
        // await GrilWaitingDialog.show(
        //   context: context,
        //   onAccept: () {
        //     Navigator.of(context).pop();
        //     // 用户选择去使用心币，导航到预览页面
        //     _startTakeOff();
        //   },
        //   onDecline: () {
        //     Navigator.of(context).pop();
        //     // 用户拒绝，不做任何操作
        //   },
        // );
      }
    }
  }

  // 检查并播放待播放的爱心动画
  Future<void> _checkAndPlayPendingHeartAnimation() async {
    try {
      await GameStateManager().init();

      final pendingAnimation = GameStateManager().getPendingHeartAnimation();
      if (pendingAnimation != null && mounted) {
        final int heartAmount = pendingAnimation['heartAmount'] ?? 0;

        if (heartAmount > 0) {
          print("MainPage: 播放待播放的爱心动画，数量: $heartAmount");

          // 播放爱心动画，金币数量设为0
          CommonHeader.playSignInEffects(context, 0, heartAmount);

          // 清除待播放的动画标记
          await GameStateManager().clearPendingHeartAnimation();
        }
      }
    } catch (e) {
      print("检查并播放爱心动画失败: $e");
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
      // 从签到页面返回时重新加载数据，可能有新图片解锁或新女孩解锁
      _loadUserData();
      // 不再重置已弹标记
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
      // 从商店页面返回时重新加载数据，可能有新图片解锁或新女孩解锁
      _loadUserData();
      // 刷新背景女孩状态（商店中可能有皮肤变更）
      _refreshBackgroundState();
    });
  }

  void _navigateToGallery() async {
    await AudioManager().playPopupOpen();
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const GalleryPage(),
      ),
    )
        .then((_) {
      // 从图鉴页面返回时重新加载数据，可能有新图片解锁或新女孩解锁
      _loadUserData();
      // 不再重置已弹标记
    });
  }

  void _navigateToGame() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const GamePage(),
      ),
    )
        .then((_) {
      // 从游戏页面返回时重新加载数据，可能有新图片解锁或新女孩解锁
      _loadUserData();
      // 不再重置已弹标记
    });
  }

  void _switchToNextGirl() async {
    await AudioManager().playSwitch();
    final currentIndex = ref.read(currentGirlIndexProvider);
    final spineAssets = ref.read(spineAssetsProvider);
    final nextIndex = (currentIndex + 1) % spineAssets.length;
    await _loadGirlStateForBackground(nextIndex);
  }

  void _startTakeOff() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const SpinePreviewPage(),
      ),
    )
        .then((_) {
      // 从预览页面返回时重新加载数据，可能有新图片解锁或新女孩解锁
      _loadUserData();
      // 立即刷新背景女孩状态以同步SpinePreviewPage中的变更
      _refreshBackgroundState();
      // 不再重置已弹标记，确保跨页面也只弹一次
    });
  }

  // 新增方法：专门用于刷新背景女孩状态
  Future<void> _refreshBackgroundState() async {
    if (!mounted) return;

    print("MainPage: 刷新背景女孩状态");

    // 重新初始化游戏状态管理器
    await GameStateManager().init();

    // 获取最新的女孩状态
    final lastState = GameStateManager().getLastGirlState();
    if (lastState != null) {
      final int girlIndex = (lastState['girlIndex'] as int?) ?? 0;
      final int idleIndex = (lastState['idleIndex'] as int?) ?? 0;

      // 解析皮肤状态
      final dynamic skins = lastState['skins'];
      Map<String, int>? skinsOverride;
      if (skins is Map) {
        final map = <String, int>{};
        skins.forEach((key, value) {
          if (key is String) {
            if (value is int) {
              map[key] = value;
            } else if (value is num) {
              map[key] = value.toInt();
            }
          }
        });
        if (map.isNotEmpty) {
          skinsOverride = map;
        }
      }

      print("MainPage: 应用最新状态 - girl=$girlIndex, idle=$idleIndex, skins=$skinsOverride");

      // 应用最新状态到背景女孩
      await _loadGirlStateForBackground(
        girlIndex,
        idleIndexOverride: idleIndex,
        skinsOverride: skinsOverride,
        ensureInit: false,
      );
    } else {
      print("MainPage: 没有找到保存的状态，使用默认状态");
      // 如果没有保存的状态，重新初始化默认状态
      await _restoreBackgroundState();
    }
  }

  // 临时测试方法 - 播放金币和心特效
  void _playCoinAndHeartEffects() async {
    await AudioManager().playPopupOpen();

    // 播放签到奖励特效（金币和爱心）
    CommonHeader.playSignInEffects(context, 10, 5);
  }

  // 导航到倾斜测试页面
  void _navigateToTiltTest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TiltTestPage(),
      ),
    );
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

    // 如果页面还没准备好，显示加载界面
    if (!_isPageReady || _backgroundSpineController == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(Assets.loadingLoadingBg), // 使用加载页背景
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  '正在初始化...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
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
                  // 临时测试按钮 - 播放金币和心特效
                  GestureDetector(
                    onTap: _playCoinAndHeartEffects,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const OutlinedTextWidget(
                        text: '测试特效',
                        fontSize: 14,
                        textColor: Colors.white,
                        strokeColor: Colors.black,
                        strokeWidth: 2.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 倾斜测试按钮
                  // GestureDetector(
                  //   onTap: _navigateToTiltTest,
                  //   child: Container(
                  //     margin: const EdgeInsets.only(bottom: 20),
                  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  //     decoration: BoxDecoration(
                  //       color: Colors.blue.withOpacity(0.8),
                  //       borderRadius: BorderRadius.circular(20),
                  //       border: Border.all(color: Colors.white, width: 2),
                  //     ),
                  //     child: const OutlinedTextWidget(
                  //       text: '倾斜测试',
                  //       fontSize: 14,
                  //       textColor: Colors.white,
                  //       strokeColor: Colors.black,
                  //       strokeWidth: 2.0,
                  //       fontWeight: FontWeight.bold,
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
                          text:
                              'Level ${_currentLevel.toString().padLeft(3, '0')}',
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
      _spineController =
          spine.SpineWidgetController(onInitialized: (controller) {
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
                controller.animationState
                    .setAnimationByName(0, firstAnimationName, true);
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
