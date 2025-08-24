import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:spine_flutter/spine_flutter.dart' hide Animation;
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:ui' as ui;

import '../models/girl_state.dart';
import '../managers/audio_manager.dart';
import '../managers/game_state_manager.dart';
import '../utils/audio_assets.dart';
import '../widgets/outlined_text_widget.dart';
import '../widgets/insufficient_coins_dialog.dart';
import '../widgets/gril_waiting_dialog.dart';
import '../widgets/unlock_new_gril_dialog.dart';


class SpinePreviewPage extends StatefulWidget {
  const SpinePreviewPage({super.key});

  @override
  State<SpinePreviewPage> createState() => _SpinePreviewPageState();
}

class _SpinePreviewPageState extends State<SpinePreviewPage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _showSecondImage = false;
  bool _isLoading = false;
  bool _isAnimating = false;
  String? _errorMessage;
  Map<String, dynamic>? _atlasInfo;
  SpineWidgetController? _spineController;
  bool _isControllerReady = false;
  List<String> _availableAnimations = [];
  int _currentAnimationIndex = 0;

  // Takeoff 覆盖动画控制器
  SpineWidgetController? _takeoffController;
  bool _isTakeoffReady = false;
  bool _showTakeoffOverlay = true;

  // 心形数量
  int _heartCount = 20;

  // 弹窗状态
  int _pendingUnlockSkinIndex = -1; // 待解锁的皮肤索引
  int _pendingUnlockButtonType = -1; // 待解锁的部位类型

  // 页面切换动画控制器
  late PageController _pageController;

  // 女孩状态管理
  late List<GirlState> _girlStates;

  // 音频播放器
  late AudioPlayer _audioPlayer;

  // 动画计时器
  Timer? _animationTimer;

  // 当前idle动画索引
  int _currentIdleIndex = 0;

  // 当前选中的underwear按钮索引 (-1表示未选中)
  int _selectedUnderwearButton = -1;
  int _previousUnderwearButton = -1; // 记录上一个选中的按钮
  
  // 皮肤选择列表动画控制器
  late AnimationController _skinListAnimationController;
  late Animation<Offset> _skinListSlideAnimation;
  bool _isAnimatingList = false;

  // 每个部位的当前皮肤索引 (0-3, 对应1-4号皮肤)
  Map<int, int> _currentSkinIndices = {
    0: 0, // bra: 默认1号皮肤
    1: 0, // pants: 默认1号皮肤
    2: 0, // hands: 默认1号皮肤
    3: 0, // socks: 默认1号皮肤
  };

  // 定义所有spine文件的信息
  final List<SpineAsset> _spineAssets = [
    SpineAsset(
      name: "Girl 01",
      imagePath: "assets/grils/Icon_girl_01_head_unlock.png", // Girl01只有解锁状态
      image2Path: "assets/spine/girl01_2.png",
      atlasFile: "assets/spine/girl01.atlas",
      skeletonFile: "assets/spine/girl01.skel",
    ),
    SpineAsset(
      name: "Girl 02",
      imagePath: "assets/grils/Icon_girl_02_head_unlock.png", // 使用unlock版本，lock版本通过代码控制
      image2Path: "assets/spine/girl02_2.png",
      atlasFile: "assets/spine/girl02.atlas",
      skeletonFile: "assets/spine/girl02.skel",
    ),
    SpineAsset(
      name: "Girl 03",
      imagePath: "assets/grils/Icon_girl_03_head_unlock.png", // 使用unlock版本，lock版本通过代码控制
      image2Path: "assets/spine/girl03_2.png",
      atlasFile: "assets/spine/girl03.atlas",
      skeletonFile: "assets/spine/girl03.skel",
    ),
  ];

  @override
  void initState() {
    super.initState();
    // // 设置全屏模式，隐藏状态栏和导航栏
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // // 设置状态栏透明
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    //   statusBarColor: Colors.transparent,
    //   systemNavigationBarColor: Colors.transparent,
    // ));

    // 初始化游戏状态
    _initGameState();

    // 初始化页面控制器
    _pageController = PageController(initialPage: _currentIndex);

    // 初始化女孩状态
    _girlStates = [
      GirlState(girlIndex: 0, maxSkinLevels: GirlState.getMaxSkinLevels(0)),
      GirlState(girlIndex: 1, maxSkinLevels: GirlState.getMaxSkinLevels(1)),
      GirlState(girlIndex: 2, maxSkinLevels: GirlState.getMaxSkinLevels(2)),
    ];

    // 初始化音频播放器
    _audioPlayer = AudioPlayer();
    
    // 初始化皮肤列表动画控制器
    _skinListAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _skinListSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _skinListAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _loadSpineInfo();
    _initializeSpineController();
    _initializeTakeoffController();

    // 启动idle动画循环
    _startIdleAnimationCycle();
    
    // 切换到预览模式BGM
    AudioManager().switchToPreviewMode();
    
    // 检查是否有足够的心币进行操作
    _checkForAvailableActions();
  }

  // 初始化游戏状态
  void _initGameState() async {
    await GameStateManager().init();
    
    // 恢复上次的状态
    setState(() {
      _heartCount = GameStateManager().getHeartCount();
      _currentIndex = GameStateManager().getCurrentGirlIndex();
      _currentIdleIndex = GameStateManager().getCurrentIdleIndex();
      _showTakeoffOverlay = !GameStateManager().hasSeenTakeoffGuide();
      
      // 恢复每个女孩的皮肤选择
      for (int i = 0; i < 3; i++) {
        Map<String, int> skins = GameStateManager().getCurrentSkins(i);
        if (i == _currentIndex) {
          _currentSkinIndices[0] = skins['bra'] ?? 0;
          _currentSkinIndices[1] = skins['pants'] ?? 0;
          _currentSkinIndices[2] = skins[i == 0 ? 'hands' : 'head'] ?? 0;
          _currentSkinIndices[3] = skins['socks'] ?? 0;
        }
      }
    });
  }
  
  // 检查是否有可进行的操作
  void _checkForAvailableActions() async {
    // 延迟一下，等页面加载完成
    await Future.delayed(Duration(seconds: 1));
    
    if (!mounted) return;
    
    // 检查是否可以脱衣或解锁新皮肤
    bool canTakeoff = GameStateManager().canTakeoff();
    var affordableSkin = GameStateManager().getAffordableSkin(_currentIndex);
    
    if (canTakeoff || affordableSkin != null) {
      // 显示提醒弹窗
      await AudioManager().playPopupOpen();
      await GrilWaitingDialog.show(
        context: context,
        onAccept: () {
          Navigator.of(context).pop();
          // 用户选择去使用心币
          if (canTakeoff && _currentIdleIndex < 4) {
            // 可以脱衣，自动触发脱衣
            _nextIdleAnimation();
          } else if (affordableSkin != null && _currentIdleIndex == 4) {
            // 可以解锁皮肤，引导用户点击对应部位
            _highlightAffordableSkin(affordableSkin);
          }
        },
        onDecline: () {
          Navigator.of(context).pop();
        },
      );
    }
  }
  
  // 高亮可解锁的皮肤部位
  void _highlightAffordableSkin(Map<String, dynamic> affordableSkin) {
    // 可以添加一些视觉提示，比如闪烁效果
    print("可解锁皮肤: ${affordableSkin['part']}, 价格: ${affordableSkin['price']}心币");
  }

  void _initializeTakeoffController() {
    // 先销毁旧的Takeoff控制器，防止内存泄漏
    if (_takeoffController != null) {
      // _takeoffController!.dispose();
      _takeoffController = null;
    }

    try {
      _takeoffController = SpineWidgetController(onInitialized: (controller) {
        try {
          controller.animationState.getData().setDefaultMix(0.2);
          final animations = controller.skeleton.getData()?.getAnimations();
          if (animations != null && animations.isNotEmpty) {
            if (mounted) {
              setState(() {
                _isTakeoffReady = true;
              });
            }
            // 播放第一个动画循环
            final firstAnimationName = animations.first.getName();
            if (firstAnimationName != null && firstAnimationName.isNotEmpty) {
              controller.animationState.setAnimationByName(0, firstAnimationName, true);
            } else {
              print("First animation name is null or empty");
            }
          }
        } catch (e) {
          print("Takeoff animation initialization failed: $e");
        }
      });
    } catch (e) {
      print("Takeoff controller creation failed: $e");
    }
  }

  void _initializeSpineController() {
    // 先销毁旧的控制器，防止内存泄漏
    if (_spineController != null) {
      // _spineController!.dispose();
      _spineController = null;
    }

    try {
      _spineController = SpineWidgetController(onInitialized: (controller) {
        try {
          // 设置默认过渡时间
          controller.animationState.getData().setDefaultMix(0.2);

          // 获取可用动画
          final animations = controller.skeleton.getData()?.getAnimations();
          if (animations != null && animations.isNotEmpty) {
            _availableAnimations = animations.map((a) => a.getName()).toList();
            print("Available animations: $_availableAnimations");

            // 设置默认皮肤状态
            _setDefaultSkinForCurrentGirl(controller);

            // 调试：列出所有可用皮肤
            _listAvailableSkins(controller);

            if (mounted) {
              setState(() {
                _isLoading = false;
                _isControllerReady = true; // 标记控制器已准备好
              });
            }

            // 播放当前女孩的idle动画
            if (_availableAnimations.isNotEmpty) {
              _playCurrentIdleAnimation();

              // 重新启动动画循环
              _startIdleAnimationCycle();
            }
          } else {
            print("No animations found in spine file");
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = "未找到动画";
              });
            }
          }
        } catch (e) {
          print("Animation initialization failed: $e");
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = "动画初始化失败: $e";
            });
          }
        }
      });
    } catch (e) {
      print("Controller creation failed: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "控制器创建失败: $e";
        });
      }
    }
  }

  // 根据当前女孩设置默认皮肤状态
  void _setDefaultSkinForCurrentGirl(SpineWidgetController controller) {
    print(
        "Setting default skin for current girl: ${_spineAssets[_currentIndex].name} (index: $_currentIndex, underwear mode: ${_currentIdleIndex == 4})");
    
    try {
      // Girl03的underwear模式是index 5，其他是index 4
      bool isUnderwearMode = (_currentIndex == 2 && _currentIdleIndex == 5) || 
                            (_currentIndex != 2 && _currentIdleIndex == 4);

      if (_currentIndex == 0 && _spineAssets[_currentIndex].name == "Girl 01") {
        if (isUnderwearMode) {
          // underwear模式，设置内衣皮肤
          _setGirl01UnderwearSkin(controller);
        } else {
          // 普通模式，设置默认皮肤
          _setGirl01DefaultSkin(controller);
        }
      } else if (_currentIndex == 1 && _spineAssets[_currentIndex].name == "Girl 02") {
        if (isUnderwearMode) {
          // underwear模式，设置内衣皮肤
          _setGirl02UnderwearSkin(controller);
        } else {
          // 普通模式，设置默认皮肤
          _setGirl02DefaultSkin(controller);
        }
      } else if (_currentIndex == 2 && _spineAssets[_currentIndex].name == "Girl 03") {
        if (isUnderwearMode) {
          // underwear模式，设置内衣皮肤
          _setGirl03UnderwearSkin(controller);
        } else {
          // 普通模式，设置默认皮肤
          _setGirl03DefaultSkin(controller);
        }
      } else {
        print("No default skin configuration for: ${_spineAssets[_currentIndex].name}");
      }
    } catch (e) {
      print("Error setting skin: $e");
      // 如果设置皮肤失败，尝试使用默认皮肤或跳过
      try {
        // 尝试查找并使用默认皮肤
        final defaultSkin = controller.skeletonData.findSkin("default");
        if (defaultSkin != null) {
          controller.skeleton.setSkin(defaultSkin);
          controller.skeleton.setSlotsToSetupPose();
          print("Reset to default skin");
        } else {
          // 如果没有默认皮肤，只重置槽位
          controller.skeleton.setSlotsToSetupPose();
          print("Reset slots to setup pose without changing skin");
        }
      } catch (e2) {
        print("Failed to reset skin: $e2");
      }
    }
  }

  // 设置Girl01的默认皮肤状态
  void _setGirl01DefaultSkin(SpineWidgetController controller) {
    try {
      final data = controller.skeletonData;
      final skeleton = controller.skeleton;

      // 创建自定义皮肤
      final customSkin = Skin("girl01-default-skin");
      
      // 用于跟踪是否添加了任何皮肤
      bool hasAnySkin = false;

      // 添加默认皮肤状态
      final braSkin = data.findSkin("bra/bra_none");
      final handsSkin = data.findSkin("hands/hands_none");
      final pantsSkin = data.findSkin("pants/pants_none");
      final socksSkin = data.findSkin("socks/socks_none");

      if (braSkin != null) {
        customSkin.addSkin(braSkin);
        hasAnySkin = true;
        print("Added bra/bra_none skin");
      } else {
        print("bra/bra_none skin not found");
      }

      if (handsSkin != null) {
        customSkin.addSkin(handsSkin);
        hasAnySkin = true;
        print("Added hands/hands_none skin");
      } else {
        print("hands/hands_none skin not found");
      }

      if (pantsSkin != null) {
        customSkin.addSkin(pantsSkin);
        hasAnySkin = true;
        print("Added pants/pants_none skin");
      } else {
        print("pants/pants_none skin not found");
      }

      if (socksSkin != null) {
        customSkin.addSkin(socksSkin);
        hasAnySkin = true;
        print("Added socks/socks_none skin");
      } else {
        print("socks/socks_none skin not found");
      }

      // 只有在至少添加了一个皮肤时才应用
      if (hasAnySkin) {
        skeleton.setSkin(customSkin);
        skeleton.setSlotsToSetupPose();
        print("Girl01 default skin applied successfully");
      } else {
        print("No skins found, skipping skin application");
        // 尝试使用默认皮肤
        final defaultSkin = data.findSkin("default");
        if (defaultSkin != null) {
          skeleton.setSkin(defaultSkin);
          skeleton.setSlotsToSetupPose();
          print("Applied default skin instead");
        }
      }
    } catch (e) {
      print("Failed to set Girl01 default skin: $e");
    }
  }

  // 设置Girl01的underwear皮肤状态
  void _setGirl01UnderwearSkin(SpineWidgetController controller) {
    try {
      final data = controller.skeletonData;
      final skeleton = controller.skeleton;

      // 创建自定义内衣皮肤
      final customSkin = Skin("girl01-underwear-skin");

      // 根据当前选择的皮肤索引应用皮肤
      final skinNames = [
        "bra/bra${_currentSkinIndices[0]! + 1}",
        "pants/pants${_currentSkinIndices[1]! + 1}",
        "hands/hands${_currentSkinIndices[2]! + 1}",
        "socks/socks${_currentSkinIndices[3]! + 1}",
      ];

      print("=== Applying Girl01 underwear skins ===");
      for (String skinName in skinNames) {
        final skin = data.findSkin(skinName);
        if (skin != null) {
          customSkin.addSkin(skin);
          print("✓ Added skin: $skinName");
        } else {
          print("✗ Skin not found: $skinName");
        }
      }

      // 应用自定义皮肤
      skeleton.setSkin(customSkin);
      skeleton.setSlotsToSetupPose();

      print("Girl01 underwear skin applied successfully");
    } catch (e) {
      print("Failed to set Girl01 underwear skin: $e");
    }
  }

  // 应用当前选择的皮肤
  void _applyCurrentSkins() {
    if (_spineController != null && _isControllerReady) {
      // Girl03的underwear模式是index 5，其他是index 4
      bool isUnderwearMode = (_currentIndex == 2 && _currentIdleIndex == 5) || 
                            (_currentIndex != 2 && _currentIdleIndex == 4);
      
      if (isUnderwearMode) {
        _setDefaultSkinForCurrentGirl(_spineController!);
      }
    }
  }

  // 重新开始游戏
  void _restartGame() {
    setState(() {
      // 重置所有状态
      _currentIdleIndex = 0; // 回到第一个idle动画
      _selectedUnderwearButton = -1; // 重置选中状态
      _heartCount = 10; // 重置心形数量

      // 重置所有皮肤为默认状态
      _currentSkinIndices = {
        0: 0, // bra: 默认皮肤
        1: 0, // pants: 默认皮肤
        2: 0, // hands/head: 默认皮肤
        3: 0, // socks: 默认皮肤
      };

      // 重置女孩状态
      for (int i = 0; i < _girlStates.length; i++) {
        _girlStates[i] = _girlStates[i].copyWith(
          isPlayingSpecial: false,
          mode: GirlMode.normal,
        );
      }
    });

    // 重新播放默认动画
    _playCurrentIdleAnimation();

    print("Game restarted - all states reset to default");
  }

  // 调试方法：列出所有可用的皮肤
  void _listAvailableSkins(SpineWidgetController controller) {
    try {
      final data = controller.skeletonData;
      final skins = data.getSkins();

      print("=== Available Skins ===");
      for (var skin in skins) {
        print("Skin: ${skin.getName()}");
      }
      print("======================");
    } catch (e) {
      print("Failed to list skins: $e");
    }
  }

  // 设置Girl02的默认皮肤状态
  void _setGirl02DefaultSkin(SpineWidgetController controller) {
    try {
      final data = controller.skeletonData;
      final skeleton = controller.skeleton;

      // 创建自定义皮肤
      final customSkin = Skin("girl02-default-skin");
      
      // 用于跟踪是否添加了任何皮肤
      bool hasAnySkin = false;

      // 添加默认皮肤状态
      final braSkin = data.findSkin("bra/bra_none");
      final handsSkin = data.findSkin("hands/hands_none");
      final headSkin = data.findSkin("head/head_none");
      final socksSkin = data.findSkin("socks/socks_none");

      if (braSkin != null) {
        customSkin.addSkin(braSkin);
        hasAnySkin = true;
        print("Added bra/bra_none skin");
      } else {
        print("bra/bra_none skin not found");
      }

      if (handsSkin != null) {
        customSkin.addSkin(handsSkin);
        hasAnySkin = true;
        print("Added hands/hands_none skin");
      } else {
        print("hands/hands_none skin not found");
      }

      if (headSkin != null) {
        customSkin.addSkin(headSkin);
        hasAnySkin = true;
        print("Added head/head_none skin");
      } else {
        print("head/head_none skin not found");
      }

      if (socksSkin != null) {
        customSkin.addSkin(socksSkin);
        hasAnySkin = true;
        print("Added socks/socks_none skin");
      } else {
        print("socks/socks_none skin not found");
      }

      // 只有在至少添加了一个皮肤时才应用
      if (hasAnySkin) {
        skeleton.setSkin(customSkin);
        skeleton.setSlotsToSetupPose();
        print("Girl02 default skin applied successfully");
      } else {
        print("No skins found, skipping skin application");
        // 尝试使用默认皮肤
        final defaultSkin = data.findSkin("default");
        if (defaultSkin != null) {
          skeleton.setSkin(defaultSkin);
          skeleton.setSlotsToSetupPose();
          print("Applied default skin instead");
        }
      }
    } catch (e) {
      print("Failed to set Girl02 default skin: $e");
    }
  }

  // 设置Girl03的默认皮肤状态
  void _setGirl03DefaultSkin(SpineWidgetController controller) {
    try {
      final data = controller.skeletonData;
      final skeleton = controller.skeleton;

      // 创建自定义皮肤
      final customSkin = Skin("girl03-default-skin");
      
      // 用于跟踪是否添加了任何皮肤
      bool hasAnySkin = false;

      // 添加默认皮肤状态
      final braSkin = data.findSkin("bra/bra_none");
      final headSkin = data.findSkin("head/head_none");
      final pantsSkin = data.findSkin("pants/pants_none");
      final socksSkin = data.findSkin("socks/socks_none");

      if (braSkin != null) {
        customSkin.addSkin(braSkin);
        hasAnySkin = true;
        print("Added bra/bra_none skin");
      } else {
        print("bra/bra_none skin not found");
      }

      if (headSkin != null) {
        customSkin.addSkin(headSkin);
        hasAnySkin = true;
        print("Added head/head_none skin");
      } else {
        print("head/head_none skin not found");
      }

      if (pantsSkin != null) {
        customSkin.addSkin(pantsSkin);
        hasAnySkin = true;
        print("Added pants/pants_none skin");
      } else {
        print("pants/pants_none skin not found");
      }

      if (socksSkin != null) {
        customSkin.addSkin(socksSkin);
        hasAnySkin = true;
        print("Added socks/socks_none skin");
      } else {
        print("socks/socks_none skin not found");
      }

      // 只有在至少添加了一个皮肤时才应用
      if (hasAnySkin) {
        skeleton.setSkin(customSkin);
        skeleton.setSlotsToSetupPose();
        print("Girl03 default skin applied successfully");
      } else {
        print("No skins found, skipping skin application");
        // 尝试使用默认皮肤
        final defaultSkin = data.findSkin("default");
        if (defaultSkin != null) {
          skeleton.setSkin(defaultSkin);
          skeleton.setSlotsToSetupPose();
          print("Applied default skin instead");
        }
      }
    } catch (e) {
      print("Failed to set Girl03 default skin: $e");
    }
  }

  // 设置Girl02的underwear皮肤状态
  void _setGirl02UnderwearSkin(SpineWidgetController controller) {
    try {
      final data = controller.skeletonData;
      final skeleton = controller.skeleton;

      // 创建自定义内衣皮肤
      final customSkin = Skin("girl02-underwear-skin");

      // Girl02在underwear模式下需要: bra, pants(内裤), head, socks
      // 注意：虽然按钮位置2显示head，但实际皮肤还需要pants
      final skinNames = [
        "bra/bra${_currentSkinIndices[0]! + 1}",
        "pants/pants${_currentSkinIndices[1]! + 1}", // 添加pants皮肤
        "head/head${_currentSkinIndices[2]! + 1}",   // head皮肤
        "socks/socks${_currentSkinIndices[3]! + 1}",
      ];

      print("=== Applying Girl02 underwear skins ===");
      for (String skinName in skinNames) {
        final skin = data.findSkin(skinName);
        if (skin != null) {
          customSkin.addSkin(skin);
          print("✓ Added skin: $skinName");
        } else {
          print("✗ Skin not found: $skinName");
        }
      }

      // 应用自定义皮肤
      skeleton.setSkin(customSkin);
      skeleton.setSlotsToSetupPose();

      print("Girl02 underwear skin applied successfully");
    } catch (e) {
      print("Failed to set Girl02 underwear skin: $e");
    }
  }

  // 设置Girl03的underwear皮肤状态
  void _setGirl03UnderwearSkin(SpineWidgetController controller) {
    try {
      final data = controller.skeletonData;
      final skeleton = controller.skeleton;

      // 创建自定义内衣皮肤
      final customSkin = Skin("girl03-underwear-skin");

      // Girl03在underwear模式下需要: bra, pants, head, socks
      final skinNames = [
        "bra/bra${_currentSkinIndices[0]! + 1}",
        "pants/pants${_currentSkinIndices[1]! + 1}",
        "head/head${_currentSkinIndices[2]! + 1}",
        "socks/socks${_currentSkinIndices[3]! + 1}",
      ];

      print("=== Applying Girl03 underwear skins ===");
      for (String skinName in skinNames) {
        final skin = data.findSkin(skinName);
        if (skin != null) {
          customSkin.addSkin(skin);
          print("✓ Added skin: $skinName");
        } else {
          print("✗ Skin not found: $skinName");
        }
      }

      // 应用自定义皮肤
      skeleton.setSkin(customSkin);
      skeleton.setSlotsToSetupPose();

      print("Girl03 underwear skin applied successfully");
    } catch (e) {
      print("Failed to set Girl03 underwear skin: $e");
    }
  }

  // 验证动画是否存在
  bool _isAnimationAvailable(String animationName) {
    if (_spineController == null || !_isControllerReady) return false;

    try {
      final animation = _spineController!.skeleton.getData()?.findAnimation(animationName);
      return animation != null;
    } catch (e) {
      print("Failed to check animation availability: $e");
      return false;
    }
  }

  void _playAnimation(String animationName, bool loop) {
    if (_spineController != null && _isControllerReady) {
      if (!_isAnimationAvailable(animationName)) {
        print("Animation '$animationName' not found, using first available animation");
        if (_availableAnimations.isNotEmpty) {
          animationName = _availableAnimations.first;
        } else {
          print("No animations available");
          return;
        }
      }

      _spineController!.animationState.setAnimationByName(0, animationName, loop);
      setState(() {
        _isAnimating = true;
      });

      // 皮肤只在控制器初始化时设置一次即可，不需要每次播放动画都重新设置
    }
  }

  void _pauseAnimation() {
    if (_spineController != null && _isControllerReady) {
      _spineController!.animationState.setTimeScale(0.0);
      setState(() {
        _isAnimating = false;
      });
    }
  }

  void _resumeAnimation() {
    if (_spineController != null && _isControllerReady) {
      _spineController!.animationState.setTimeScale(1.0);
      setState(() {
        _isAnimating = true;
      });
    }
  }

  void _stopAnimation() {
    if (_spineController != null && _isControllerReady) {
      _spineController!.animationState.clearTracks();
      setState(() {
        _isAnimating = false;
      });
    }
  }

  void _nextAnimation() {
    if (_availableAnimations.isNotEmpty && _isControllerReady) {
      _currentAnimationIndex = (_currentAnimationIndex + 1) % _availableAnimations.length;
      _playAnimation(_availableAnimations[_currentAnimationIndex], true);
    }
  }

  // 启动idle动画循环
  void _startIdleAnimationCycle() {
    _animationTimer?.cancel();

    // 不需要定时器，Spine动画会自己循环播放
    // 只在初始化时播放一次即可
  }

  // 播放当前iddle动画
  void _playCurrentIdleAnimation() {
    // 使用用户选择的动画索引
    String animationName;
    
    // Girl03的underwear模式是index 5，其他是index 4
    bool isUnderwearMode = (_currentIndex == 2 && _currentIdleIndex == 5) || 
                          (_currentIndex != 2 && _currentIdleIndex == 4);
    
    if (!isUnderwearMode) {
      // 非underwear模式: idle_01 到 idle_04 (Girl03有idle_05)
      if (_girlStates[_currentIndex].isPlayingSpecial) {
        // 播放特殊动画
        animationName = 'idlesp_0${_currentIdleIndex + 1}';
      } else {
        // 播放普通idle动画
        animationName = 'idle_0${_currentIdleIndex + 1}';
      }
    } else {
      // underwear模式
      if (_girlStates[_currentIndex].isPlayingSpecial) {
        // 播放underwear特殊动画
        animationName = 'idlesp_underwear';
      } else {
        // 播放underwear普通动画
        animationName = 'idle_underwear';
      }
    }

    if (_spineController != null && _isControllerReady) {
      print(
          "Playing current idle animation: $animationName (index: $_currentIdleIndex, special: ${_girlStates[0].isPlayingSpecial})");

      // 验证动画是否存在
      if (!_isAnimationAvailable(animationName)) {
        print("Animation '$animationName' not found, using fallback");
        if (_availableAnimations.isNotEmpty) {
          animationName = _availableAnimations.first;
          print("Using fallback animation: $animationName");
        } else {
          print("No animations available");
          return;
        }
      }

      // 清除所有动画轨道，确保没有残留动画
      _spineController!.animationState.clearTracks();

      // 播放新动画
      _spineController!.animationState.setAnimationByName(0, animationName, true);

      // 注意：皮肤已经在控制器初始化时设置好了，这里不需要再次设置
      // 移除延迟设置皮肤的逻辑，避免重复设置导致的问题
    }
  }

  // 播放特殊动画
  void _playSpecialAnimation() async {
    // 所有女孩都支持特殊动画
    setState(() {
      _girlStates[_currentIndex] = _girlStates[_currentIndex].copyWith(isPlayingSpecial: true);
    });

    // 播放随机idlesp音效
    await AudioManager().playRandomIdlespSound(_currentIndex);

    // 播放特殊动画
    _playCurrentIdleAnimation();

    // 3秒后恢复到用户当前选择的idle动画
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _girlStates[_currentIndex] = _girlStates[_currentIndex].copyWith(isPlayingSpecial: false);
        });
        // 恢复到用户当前选择的idle动画，而不是默认动画
        _playCurrentIdleAnimation();
      }
    });
  }

  @override
  void dispose() {
    // 恢复系统UI显示
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    
    // 销毁动画控制器
    _skinListAnimationController.dispose();

    // 停止动画计时器
    _animationTimer?.cancel();

    // 销毁音频播放器
    _audioPlayer.dispose();

    // 正确销毁Spine控制器
    if (_spineController != null) {
      // _spineController!.dispose();
      _spineController = null;
    }

    if (_takeoffController != null) {
      // _takeoffController!.dispose();
      _takeoffController = null;
    }

    // 恢复主界面BGM
    AudioManager().switchToMainMode();

    super.dispose();
  }

  Future<void> _loadSpineInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final atlasContent = await rootBundle.loadString(_spineAssets[_currentIndex].atlasFile);
      _atlasInfo = _parseAtlasFile(atlasContent);
    } catch (e) {
      _errorMessage = '加载atlas文件失败: $e';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Map<String, dynamic> _parseAtlasFile(String content) {
    final lines = content.split('\n');
    final info = <String, dynamic>{};
    final regions = <Map<String, dynamic>>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.endsWith('.png')) {
        info['texture'] = line;
      } else if (line.startsWith('size:')) {
        info['size'] = line.substring(5).trim();
      } else if (line.startsWith('format:')) {
        info['format'] = line.substring(7).trim();
      } else if (line.startsWith('filter:')) {
        info['filter'] = line.substring(7).trim();
      } else if (!line.contains(':') && line.isNotEmpty) {
        final region = <String, dynamic>{'name': line};
        regions.add(region);
      }
    }

    info['regions'] = regions;
    info['regionCount'] = regions.length;

    return info;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.transparent,
        child: Stack(
          children: [
            // Spine动画预览区域 - 全屏显示，禁用左右滑动
            PageView.builder(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              // 禁用滚动
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _loadSpineAsset(index);

                // 重新启动动画循环
                _startIdleAnimationCycle();
              },
              itemCount: _spineAssets.length,
              itemBuilder: (context, index) {
                return _buildSpineWidgetForIndex(index);
              },
            ),

            // Takeoff 手势覆盖动画
            // 只在非underwear模式下且未看过引导时显示
            if (_currentIdleIndex != 4 && _showTakeoffOverlay)
              GestureDetector(
                onTap: () async {
                  // 点击后隐藏引导
                  setState(() {
                    _showTakeoffOverlay = false;
                  });
                  await GameStateManager().setHasSeenTakeoffGuide(true);
                },
                child: Center(
                  child: SizedBox(
                    height: 200,
                    child: SpineWidget.fromAsset(
                      "assets/spine/Takeoff.atlas",
                      "assets/spine/Takeoff.skel",
                      _takeoffController!,
                      boundsProvider: SetupPoseBounds(),
                    ),
                  ),
                ),
              ),

            // 顶部控制区域浮动
            Positioned(
              top: MediaQuery.of(context).padding.top, // 避开状态栏
              left: 0,
              right: 0,
              child: Container(
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      left: 0,
                      // 确保从左边开始
                      right: 0,
                      // 确保宽度扩展到父容器右边
                      height: 40,
                      child: Image.asset(
                        Assets.imagesFrameHeartUp,
                        fit: BoxFit.fitWidth,
                        repeat: ImageRepeat.repeat,
                      ),
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              //imag
                              Stack(
                                children: [
                                  // score
                                  Padding(
                                    padding: const EdgeInsets.only(left: 20, top: 10),
                                    child: Container(
                                      padding: EdgeInsets.only(right: 30),
                                      decoration: BoxDecoration(
                                        color: HexColor("#FFF5E5"),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 50),
                                        child: OutlinedTextWidget(
                                          text: '$_heartCount',
                                          fontSize: 18,
                                          textColor: HexColor("#95756A"),
                                          strokeColor: Colors.white,
                                          strokeWidth: 1.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Image.asset(Assets.imagesIconHeart2x, height: 50),
                                ],
                              ),

                              GestureDetector(
                                onTap: () async {
                                  await AudioManager().playExit();
                                  
                                  // 检查是否有新解锁的女生
                                  await _checkForNewUnlockOnExit();
                                  
                                  Navigator.of(context).pop();
                                },
                                child: Image.asset(Assets.imagesBtnHeartBack, height: 50),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (index) {
                            bool isUnlocked = index < 3 ? GameStateManager().isGirlUnlocked(index) : false;
                            return GestureDetector(
                              onTap: () {
                                if (index < 3) {
                                  if (isUnlocked) {
                                    // 切换到该女生
                                    _switchToGirl(index);
                                  } else {
                                    // 提示未解锁
                                    _showLockedGirlMessage(index);
                                  }
                                }
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    child: ClipOval(
                                      child: ColorFiltered(
                                        colorFilter: isUnlocked || index >= 3
                                            ? ColorFilter.mode(Colors.transparent, ui.BlendMode.multiply)
                                            : ColorFilter.mode(Colors.grey, ui.BlendMode.saturation),
                                        child: Image.asset(
                                          _getGirlIconPath(index, isUnlocked),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // 锁定图标
                                  // if (index < 3 && !isUnlocked)
                                    // Positioned(
                                    //   bottom: 0,
                                    //   right: 0,
                                    //   child: Container(
                                    //     width: 25,
                                    //     height: 25,
                                    //     decoration: BoxDecoration(
                                    //       color: Colors.black54,
                                    //       shape: BoxShape.circle,
                                    //     ),
                                    //     child: Icon(
                                    //       Icons.lock,
                                    //       color: Colors.white,
                                    //       size: 15,
                                    //     ),
                                    //   ),
                                    // ),
                                  // 当前选中指示器
                                  // if (index == _currentIndex && index < 3)
                                  //   Positioned(
                                  //     bottom: -5,
                                  //     left: 0,
                                  //     right: 0,
                                  //     child: Container(
                                  //       height: 3,
                                  //       color: Colors.yellow,
                                  //     ),
                                  //   ),
                                ],
                              ),
                            );
                          }),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Girl03的underwear模式是index 5，其他是index 4
            if (!((_currentIndex == 2 && _currentIdleIndex == 5) || 
                  (_currentIndex != 2 && _currentIdleIndex == 4)))
              Positioned(
                left: 0,
                right: 0,
                bottom: 100,
                child: Column(
                  children: [
                    // 爱心图标和数量显示
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(Assets.imagesIconHeart2x, height: 50),
                        SizedBox(width: 8), // 间距
                        // x 字符 - 使用自定义发光效果
                        OutlinedTextWidget.glow(
                          text: 'x',
                          fontSize: 48,
                          textColor: Colors.white,
                          glowColor: Colors.red,
                          glowRadius: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(width: 4), // 小间距
                        // 数字 - 使用自定义发光效果
                        OutlinedTextWidget.glow(
                          text: '$_heartCount',
                          fontSize: 48,
                          textColor: Colors.white,
                          glowColor: Colors.red,
                          glowRadius: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    SizedBox(height: 10), // 间距
                    // 脱衣按钮 - 只在非underwear状态显示

                    GestureDetector(
                      onTap: _nextIdleAnimation,
                      child: Image.asset(Assets.imagesBtnTakeoff, height: 80),
                    ),
                  ],
                ),
              ),
            // 只有在underwear模式且选中了某个按钮时才显示底部皮肤选择区域
            // Girl03的underwear模式是index 5，其他是index 4
            if (((_currentIndex == 2 && _currentIdleIndex == 5) || 
                 (_currentIndex != 2 && _currentIdleIndex == 4)) && 
                _selectedUnderwearButton != -1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: SlideTransition(
                  position: _skinListSlideAnimation,
                  child: Container(
                    height: 150,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/Frame_heart_bottom.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 30),
                      child: _buildSkinSelectionList(),
                    ),
                  ),
                ),
              ),
            // Underwear状态下的四周按钮
            // Girl03的underwear模式是index 5，其他是index 4
            if ((_currentIndex == 2 && _currentIdleIndex == 5) || 
                (_currentIndex != 2 && _currentIdleIndex == 4)) 
              _buildUnderwearButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpineWidget() {
    if (_spineController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载Spine动画...'),
          ],
        ),
      );
    }

    try {
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: SpineWidget.fromAsset(
          _spineAssets[_currentIndex].atlasFile,
          _spineAssets[_currentIndex].skeletonFile,
          _spineController!,
          boundsProvider: SetupPoseBounds(),
        ),
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load Spine animation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $e',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _isControllerReady = false;
                  _availableAnimations = [];
                  _currentAnimationIndex = 0;
                });
                _initializeSpineController();
                _loadSpineInfo();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
  }

  String _getCurrentImagePath() {
    final asset = _spineAssets[_currentIndex];
    if (_showSecondImage && asset.image2Path != null) {
      return asset.image2Path!;
    }
    return asset.imagePath;
  }

  void _loadSpineAsset(int index) {
    // 检查是否解锁
    if (!GameStateManager().isGirlUnlocked(index)) {
      _showLockedGirlMessage(index);
      return;
    }
    
    setState(() {
      _currentIndex = index;
      _showSecondImage = false;
      _atlasInfo = null;
      _isAnimating = false;
      _isLoading = true;
      _isControllerReady = false; // 重置控制器状态
      _availableAnimations = [];
      _currentAnimationIndex = 0;
      // 切换女孩时重置idle状态为0
      _currentIdleIndex = 0;
      // 重置underwear按钮选择
      _selectedUnderwearButton = -1;
      _previousUnderwearButton = -1;
      // 重置皮肤选择
      _currentSkinIndices = {
        0: 0,
        1: 0,
        2: 0,
        3: 0,
      };
    });
    
    // 保存当前女孩索引
    GameStateManager().setCurrentGirlIndex(index);
    GameStateManager().setCurrentIdleIndex(0);

    // 停止之前的动画循环
    _animationTimer?.cancel();

    // 重新初始化Spine控制器
    _initializeSpineController();
    _loadSpineInfo();
  }


  // 显示心形不足弹窗
  Future<bool?> _showInsufficientHeartsDialog(int needMore) async {
    // 调用通用弹窗
    bool? result = await InsufficientCoinsDialog.show(
      context: context,
      title:  'Get More', // needMore <= 3 ? 'Almost There!' :
      requiredCoins: needMore,
      onGetPressed: () async {
        // 这里是点击GET按钮后的回调
        // 实际已经在弹窗内部处理了增加心币
        // 此处只需更新本地显示
        await GameStateManager().addHearts(10); // 看广告获得10个心币
        setState(() {
          _heartCount = GameStateManager().getHeartCount();
        });
      },
    );
    
    return result;
  }

  // 切换到指定女孩
  void _switchToGirl(int index) {
    if (index != _currentIndex && GameStateManager().isGirlUnlocked(index)) {
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  // 显示女生未解锁提示
  void _showLockedGirlMessage(int girlIndex) {
    String message = '';
    if (girlIndex == 1) {
      message = 'Girl 02 will be unlocked at Level 100';
    } else if (girlIndex == 2) {
      message = 'Girl 03 will be unlocked at Level 300';
    }
    
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  // 检查退出时是否有新解锁的女生
  Future<void> _checkForNewUnlockOnExit() async {
    // 检查当前关卡是否满足解锁条件
    int? unlockedGirl = await GameStateManager().checkAndUnlockGirls();
    
    if (unlockedGirl != null && mounted) {
      // 设置待解锁女生，让主页面显示弹窗
      await GameStateManager().setPendingUnlockGirl(unlockedGirl);
    }
  }

  // 处理手势点击 - 触发特殊动画
  void _handleGirlTap() {
    // 所有女孩都支持点击事件
    _playSpecialAnimation();
  }

  // 切换到下一个idle动画
  void _nextIdleAnimation() async {
    // Girl03有5次脱衣，其他都是4次
    int maxIdleIndex = _currentIndex == 2 ? 5 : 4;
    
    // 检查心形货币是否足够
    if (_heartCount < 5) {
      // 心形不够，显示弹窗
      await AudioManager().playPopupOpen();
      bool? gotCoins = await _showInsufficientHeartsDialog(5 - _heartCount);
      
      if (gotCoins == true) {
        // 获得了心币，更新显示并重新尝试
        setState(() {
          _heartCount = GameStateManager().getHeartCount();
        });
        // 递归调用，重新尝试
        _nextIdleAnimation();
      }
      return;
    }
    
    if (_currentIdleIndex < maxIdleIndex && _spineController != null && _isControllerReady) {
      // 消耗5个心形
      bool consumed = await GameStateManager().consumeHearts(5);
      if (!consumed) {
        // 消费失败，显示弹窗
        await _showInsufficientHeartsDialog(5);
        return;
      }
      
      setState(() {
        _heartCount = GameStateManager().getHeartCount();
      });
      // 1. 获取当前idle编号和对应的takeoff动画
      // idle01 -> idle02 播放 takeoff_01
      // idle02 -> idle03 播放 takeoff_02  
      // idle03 -> idle04 播放 takeoff_03
      // idle04 -> underwear 播放 takeoff_04
      int takeoffIndex = _currentIdleIndex + 1; // takeoff动画对应下一阶段
      String takeoffName = 'takeoff_0${takeoffIndex}';

      print("Transitioning from idle${_currentIdleIndex + 1} to idle${takeoffIndex + 1} using $takeoffName");

      // 2. 播放takeoff音效
      await AudioManager().playTakeoffSound(_currentIndex, _currentIdleIndex);

      // 3. 验证takeoff动画是否存在
      if (_isAnimationAvailable(takeoffName)) {
        // 4. 获取动画时长
        final animation = _spineController!.skeleton.getData()!.findAnimation(takeoffName);
        double duration = 1.5; // 默认1.5秒
        if (animation != null) {
          duration = animation.getDuration();
        }
        
        print("Playing takeoff animation: $takeoffName with duration: ${duration}s");
        
        // 5. 清除当前动画轨道
        _spineController!.animationState.clearTracks();
        
        // 6. 播放takeoff动画（不循环）
        _spineController!.animationState.setAnimationByName(0, takeoffName, false);
        setState(() {
          _isAnimating = true;
        });
        
        // 7. 等待动画播完
        await Future.delayed(Duration(milliseconds: (duration * 1000).toInt()));
        
        print("Takeoff animation $takeoffName completed");
      } else {
        print("Takeoff animation '$takeoffName' not found, skipping transition animation");
        // 没有takeoff动画也要等一下，保持体验一致性
        await Future.delayed(Duration(milliseconds: 500));
      }

      // 8. 切换到下一个idle状态
      setState(() {
        _currentIdleIndex = _currentIdleIndex + 1;
        print("Switched to idle state: $_currentIdleIndex");
      });
      
      // 保存状态
      await GameStateManager().setCurrentIdleIndex(_currentIdleIndex);
      
      // 9. 如果进入underwear模式，重置皮肤选择
      // Girl03的underwear模式是index 5，其他是index 4
      bool isUnderwearMode = (_currentIndex == 2 && _currentIdleIndex == 5) || 
                             (_currentIndex != 2 && _currentIdleIndex == 4);
      
      if (isUnderwearMode) {
        _currentSkinIndices = {
          0: 0, // bra: 默认皮肤
          1: 0, // pants: 默认皮肤
          2: 0, // hands/head: 默认皮肤
          3: 0, // socks: 默认皮肤
        };
        _selectedUnderwearButton = -1;
        _previousUnderwearButton = -1;
        // 重置动画状态
        _skinListAnimationController.reset();
        print("Entered underwear mode, reset skin selections");
      }
      
      // 10. 播放下一个idle动画
      _playCurrentIdleAnimation();
    } else {
      // underwear模式或异常情况，直接循环回到idle01
      print("In underwear mode or controller not ready, cycling back to idle01");
      int maxIndex = _currentIndex == 2 ? 6 : 5; // Girl03有6个状态(0-5)，其他有5个(0-4)
      setState(() {
        _currentIdleIndex = (_currentIdleIndex + 1) % maxIndex;
        if (_currentIdleIndex == 0) {
          // 回到idle01时重置所有状态
          _selectedUnderwearButton = -1;
          _previousUnderwearButton = -1;
          _currentSkinIndices = {
            0: 0,
            1: 0, 
            2: 0,
            3: 0,
          };
        }
      });
      _playCurrentIdleAnimation();
    }
  }

  // 为指定索引构建Spine Widget
  Widget _buildSpineWidgetForIndex(int index) {
    if (_spineController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载Spine动画...'),
          ],
        ),
      );
    }

    try {
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: GestureDetector(
          onTap: _handleGirlTap,
          child: SpineWidget.fromAsset(
            _spineAssets[index].atlasFile,
            _spineAssets[index].skeletonFile,
            _spineController!,
            boundsProvider: SetupPoseBounds(),
          ),
        ),
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load Spine animation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $e',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _isControllerReady = false;
                  _availableAnimations = [];
                  _currentAnimationIndex = 0;
                });
                _initializeSpineController();
                _loadSpineInfo();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
  }

  // 构建Underwear状态下的四周按钮
  Widget _buildUnderwearButtons() {
    return Stack(
      children: [
        // 左侧按钮 - 内衣
        Positioned(
          left: 20,
          top: MediaQuery.of(context).size.height * 0.25,
          child: GestureDetector(
            onTap: () => _onUnderwearButtonTap(0),
            child: Image.asset(
              _isUnderwearButtonSelected(0) ? 'assets/images/Btn_bra_selected.png' : 'assets/images/Btn_bra_normal.png',
              height: 80,
            ),
          ),
        ),

        // 左侧按钮 - 内裤
        Positioned(
          left: 20,
          top: MediaQuery.of(context).size.height * 0.62,
          child: GestureDetector(
            onTap: () => _onUnderwearButtonTap(1),
            child: Image.asset(
              _isUnderwearButtonSelected(1)
                  ? 'assets/images/Btn_pants_selected.png'
                  : 'assets/images/Btn_pants_normal.png',
              height: 80,
            ),
          ),
        ),

        // 右侧按钮 - 根据女孩类型显示不同按钮
        Positioned(
          right: 20,
          top: MediaQuery.of(context).size.height * 0.3,
          child: GestureDetector(
            onTap: () => _onUnderwearButtonTap(2),
            child: Image.asset(
              _isUnderwearButtonSelected(2)
                  ? (_currentIndex == 0 ? 'assets/images/Btn_hand_selected.png' : 'assets/images/Btn_head_selected.png')
                  : (_currentIndex == 0 ? 'assets/images/Btn_hand_normal.png' : 'assets/images/Btn_head_normal.png'),
              height: 80,
            ),
          ),
        ),

        // 右侧按钮 - 腿
        Positioned(
          right: 20,
          top: MediaQuery.of(context).size.height * 0.65,
          child: GestureDetector(
            onTap: () => _onUnderwearButtonTap(3),
            child: Image.asset(
              _isUnderwearButtonSelected(3)
                  ? 'assets/images/Btn_socks_selected.png'
                  : 'assets/images/Btn_socks_normal.png',
              height: 80,
            ),
          ),
        ),
      ],
    );
  }

  // 处理underwear按钮点击
  void _onUnderwearButtonTap(int buttonIndex) async {
    // 播放部位按键音效
    await AudioManager().playClothingButton();
    
    // 如果正在动画中，忽略点击
    if (_isAnimatingList) return;
    
    // 记录之前的选中状态
    int previousButton = _selectedUnderwearButton;
    
    if (_selectedUnderwearButton == buttonIndex) {
      // 如果点击的是已选中的按钮，执行滑出动画
      _isAnimatingList = true;
      
      // 反向播放动画（滑出）
      await _skinListAnimationController.reverse();
      
      setState(() {
        _selectedUnderwearButton = -1;
        _previousUnderwearButton = -1;
        _isAnimatingList = false;
      });
    } else {
      // 选中新按钮
      if (_selectedUnderwearButton == -1) {
        // 当前没有选中按钮，直接滑入
        setState(() {
          _selectedUnderwearButton = buttonIndex;
          _previousUnderwearButton = buttonIndex;
        });
        
        // 播放滑入动画
        _skinListAnimationController.forward();
      } else {
        // 切换到新按钮，先滑出再滑入
        _isAnimatingList = true;
        
        // 先滑出当前列表
        await _skinListAnimationController.reverse();
        
        // 更新选中状态
        setState(() {
          _selectedUnderwearButton = buttonIndex;
          _previousUnderwearButton = buttonIndex;
        });
        
        // 延迟一点再滑入新列表，让切换更明显
        await Future.delayed(Duration(milliseconds: 100));
        
        // 滑入新列表
        await _skinListAnimationController.forward();
        
        _isAnimatingList = false;
      }
    }

    print("Underwear button $buttonIndex tapped, selected: $_selectedUnderwearButton");
  }

  // 判断underwear按钮是否应该显示选中状态
  bool _isUnderwearButtonSelected(int buttonIndex) {
    // 只有当前选中的按钮才显示选中状态（单选模式）
    return _selectedUnderwearButton == buttonIndex;
  }

  // 构建皮肤选择列表
  Widget _buildSkinSelectionList() {
    // 只有在选中某个按钮时才显示皮肤选择界面
    if (_selectedUnderwearButton == -1) {
      // 没有选中按钮时，不显示任何内容
      return Container();
    } else {
      // 选中某个按钮时，显示该部位的所有皮肤选项
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (skinIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildSkinButton(_selectedUnderwearButton, skinIndex),
            );
          }),
        ),
      );
    }
  }

  // 构建单个皮肤按钮
  Widget _buildSkinButton(int buttonType, int skinIndex) {
    String imagePath = _getSkinButtonImagePath(buttonType, skinIndex);
    bool isSelected = _currentSkinIndices[buttonType] == skinIndex;
    String partName = _getPartName(buttonType);
    bool isUnlocked = GameStateManager().isSkinUnlocked(_currentIndex, partName, skinIndex);
    int price = GameStateManager().getSkinPrice(skinIndex);

    return GestureDetector(
      onTap: () => _onSkinButtonTap(buttonType, skinIndex),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 皮肤按钮图片
          Image.asset(
            imagePath,
            height: 80,
            width: 80,
          ),
          // 选中状态的边框
          if (isSelected)
            Image.asset(
              'assets/images/Img_cloth_selected.png',
              height: 80,
              width: 80,
            ),
          // 未解锁时显示价格
          if (!isUnlocked && price > 0)
            Positioned(
              top: 5,
              bottom: 5,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      Assets.imagesIconHeart2x,
                      height: 25,
                      width: 25,
                    ),
                    SizedBox(width: 2),
                    OutlinedTextWidget(
                      text: 'x$price',
                      fontSize: 18,
                      textColor: Colors.white,
                      strokeColor: Colors.red,
                      strokeWidth: 2,
                      fontWeight: FontWeight.bold,
                    ),
                    // OutlinedButton(
                    //   'x$price',
                    //   style: TextStyle(
                    //     color: Colors.white,
                    //     fontSize: 12,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 获取皮肤按钮图片路径
  String _getSkinButtonImagePath(int buttonType, int skinIndex) {
    // 根据当前女孩索引确定文件夹名称
    String folderName = "Girl0${_currentIndex + 1}_chage_Btn_All";
    
    // 根据当前女孩索引确定按钮前缀
    String girlPrefix = "Btn_gril0${_currentIndex + 1}"; // Btn_gril01, Btn_gril02, Btn_gril03

    String partName = _getPartName(buttonType);
    String skinNumber = (skinIndex + 1).toString(); // 皮肤编号从1开始

    // 判断是否解锁
    bool isUnlocked = GameStateManager().isSkinUnlocked(_currentIndex, partName, skinIndex);

    String lockStatus = isUnlocked ? "unlock" : "lock";

    // 拼接完整路径：assets/images/Girl0X_chage_Btn_All/Btn_gril0X_部位_皮肤号_状态.png
    return "assets/images/$folderName/${girlPrefix}_${partName}_${skinNumber}_${lockStatus}.png";
  }

  // 获取部位名称
  String _getPartName(int buttonType) {
    if (_currentIndex == 0) {
      // Girl01: bra, pants, hands, socks
      switch (buttonType) {
        case 0: return "bra";
        case 1: return "pants";
        case 2: return "hands";
        case 3: return "socks";
        default: return "bra";
      }
    } else if (_currentIndex == 1) {
      // Girl02: bra, pants, head, socks
      switch (buttonType) {
        case 0: return "bra";
        case 1: return "hands";
        case 2: return "head";
        case 3: return "socks";
        default: return "bra";
      }
    } else if (_currentIndex == 2) {
      // Girl03: bra, pants, head, socks
      switch (buttonType) {
        case 0: return "bra";
        case 1: return "pants";
        case 2: return "head";
        case 3: return "socks";
        default: return "bra";
      }
    }
    return "bra";
  }

  // 获取女孩头像路径
  String _getGirlIconPath(int index, bool isUnlocked) {
    if (index == 0) {
      // Girl01只有解锁状态
      return "assets/grils/Icon_girl_01_head_unlock.png";
    } else if (index == 1) {
      // Girl02有锁定和解锁两种状态
      return isUnlocked 
          ? "assets/grils/Icon_girl_02_head_unlock.png" 
          : "assets/grils/Icon_girl_02_head_lock.png";
    } else if (index == 2) {
      // Girl03有锁定和解锁两种状态
      return isUnlocked 
          ? "assets/grils/Icon_girl_03_head_unlock.png" 
          : "assets/grils/Icon_girl_03_head_lock.png";
    } else {
      // Girl04只有锁定状态（假的）
      return "assets/grils/Icon_girl_04_head_unlock.png";
    }
  }

  // 处理皮肤按钮点击
  void _onSkinButtonTap(int buttonType, int skinIndex) async {
    String partName = _getPartName(buttonType);
    bool isUnlocked = GameStateManager().isSkinUnlocked(_currentIndex, partName, skinIndex);
    
    if (!isUnlocked) {
      // 未解锁，检查是否可以购买
      int price = GameStateManager().getSkinPrice(skinIndex);
      
      if (_heartCount < price) {
        // 心形不足，记录待解锁信息
        _pendingUnlockSkinIndex = skinIndex;
        _pendingUnlockButtonType = buttonType;
        
        // 显示心形不足弹窗
        await AudioManager().playPopupOpen();
        bool? gotCoins = await _showInsufficientHeartsDialog(price - _heartCount);
        
        if (gotCoins == true) {
          // 获得了心币，尝试再次购买
          setState(() {
            _heartCount = GameStateManager().getHeartCount();
          });
          // 递归调用，重新尝试购买
          _onSkinButtonTap(buttonType, skinIndex);
        }
        return;
      }
      
      // 心形足够，购买皮肤
      bool consumed = await GameStateManager().consumeHearts(price);
      if (consumed) {
        await GameStateManager().unlockSkin(_currentIndex, partName, skinIndex);
        setState(() {
          _heartCount = GameStateManager().getHeartCount();
        });
        
        // 播放购买成功音效
        await AudioManager().playHeartEffect();
      } else {
        // 购买失败
        return;
      }
    }
    
    // 播放切换音效
    await AudioManager().playSwitch();
    
    setState(() {
      _currentSkinIndices[buttonType] = skinIndex;
    });
    
    // 保存皮肤选择
    await GameStateManager().setCurrentSkin(_currentIndex, partName, skinIndex);

    // underwear阶段切换皮肤时，先播放idlesp_underwear动画
    // Girl03的underwear模式是index 5，其他是index 4
    bool isUnderwearMode = (_currentIndex == 2 && _currentIdleIndex == 5) || 
                          (_currentIndex != 2 && _currentIdleIndex == 4);
    
    if (isUnderwearMode && _spineController != null && _isControllerReady) {
      print("Playing idlesp_underwear animation for skin change");
      
      // 先应用新的皮肤设置
      _applyCurrentSkins();
      
      String animName = 'idlesp_underwear';

      // 验证动画是否存在
      if (_isAnimationAvailable(animName)) {
        // 清除当前动画轨道
        _spineController!.animationState.clearTracks();
        
        // 播放idlesp_underwear动画（不循环）
        _spineController!.animationState.setAnimationByName(0, animName, false);
        setState(() {
          _isAnimating = true;
        });
        
        // 获取动画时长
        final animation = _spineController!.skeleton.getData()!.findAnimation(animName);
        double duration = 1.0; // 默认1秒
        if (animation != null) {
          duration = animation.getDuration();
        }
        
        print("Playing idlesp_underwear for ${duration}s");
        
        // 等待动画播放完成
        await Future.delayed(Duration(milliseconds: (duration * 1000).toInt()));
        
        // 动画播放完成后，回到正常的idle_underwear循环动画
        if (mounted && _spineController != null && _isControllerReady) {
          print("idlesp_underwear completed, switching back to idle_underwear loop");
          _spineController!.animationState.setAnimationByName(0, 'idle_underwear', true);
        }
      } else {
        print("Animation '$animName' not found, skipping transition");
        // 如果没有idlesp_underwear动画，直接应用皮肤
        _applyCurrentSkins();
      }
    } else {
      // 非underwear阶段，直接应用皮肤
      _applyCurrentSkins();
    }
    
    print("Skin button tapped: type=$buttonType, skin=$skinIndex");
  }

}

class SpineAsset {
  final String name;
  final String imagePath;
  final String? image2Path;
  final String atlasFile;
  final String skeletonFile;

  SpineAsset({
    required this.name,
    required this.imagePath,
    this.image2Path,
    required this.atlasFile,
    required this.skeletonFile,
  });
}
