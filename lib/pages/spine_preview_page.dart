import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:spine_flutter/spine_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

import '../models/girl_state.dart';
import '../managers/audio_manager.dart';
import '../utils/audio_assets.dart';
import '../widgets/outlined_text_widget.dart';


class SpinePreviewPage extends StatefulWidget {
  const SpinePreviewPage({super.key});

  @override
  State<SpinePreviewPage> createState() => _SpinePreviewPageState();
}

class _SpinePreviewPageState extends State<SpinePreviewPage> {
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
  int _heartCount = 5;

  // 弹窗状态
  bool _showHeartDialog = false;

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
      imagePath: "assets/grils/Icon_girl_01_head_unlock.png",
      image2Path: "assets/spine/girl01_2.png",
      atlasFile: "assets/spine/girl01.atlas",
      skeletonFile: "assets/spine/girl01.skel",
    ),
    SpineAsset(
      name: "Girl 02",
      imagePath: "assets/grils/Icon_girl_02_head_lock.png",
      image2Path: "assets/spine/girl02_2.png",
      atlasFile: "assets/spine/girl02.atlas",
      skeletonFile: "assets/spine/girl02.skel",
    ),
    SpineAsset(
      name: "Girl 03",
      imagePath: "assets/grils/Icon_girl_03_head_lock.png",
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

    _loadSpineInfo();
    _initializeSpineController();
    _initializeTakeoffController();

    // 启动idle动画循环
    _startIdleAnimationCycle();
    
    // 切换到预览模式BGM
    AudioManager().switchToPreviewMode();
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

    if (_currentIndex == 0 && _spineAssets[_currentIndex].name == "Girl 01") {
      if (_currentIdleIndex == 4) {
        // underwear模式，设置内衣皮肤
        _setGirl01UnderwearSkin(controller);
      } else {
        // 普通模式，设置默认皮肤
        _setGirl01DefaultSkin(controller);
      }
    } else if (_currentIndex == 1 && _spineAssets[_currentIndex].name == "Girl 02") {
      if (_currentIdleIndex == 4) {
        // underwear模式，设置内衣皮肤
        _setGirl02UnderwearSkin(controller);
      } else {
        // 普通模式，设置默认皮肤
        _setGirl02DefaultSkin(controller);
      }
    } else if (_currentIndex == 2 && _spineAssets[_currentIndex].name == "Girl 03") {
      if (_currentIdleIndex == 4) {
        // underwear模式，设置内衣皮肤
        _setGirl03UnderwearSkin(controller);
      } else {
        // 普通模式，设置默认皮肤
        _setGirl03DefaultSkin(controller);
      }
    } else {
      print("No default skin configuration for: ${_spineAssets[_currentIndex].name}");
    }
  }

  // 设置Girl01的默认皮肤状态
  void _setGirl01DefaultSkin(SpineWidgetController controller) {
    try {
      final data = controller.skeletonData;
      final skeleton = controller.skeleton;

      // 创建自定义皮肤
      final customSkin = Skin("girl01-default-skin");

      // 添加默认皮肤状态
      final braSkin = data.findSkin("bra/bra_none");
      final handsSkin = data.findSkin("hands/hands_none");
      final pantsSkin = data.findSkin("pants/pants_none");
      final socksSkin = data.findSkin("socks/socks_none");

      if (braSkin != null) {
        customSkin.addSkin(braSkin);
        print("Added bra/bra_none skin");
      } else {
        print("bra/bra_none skin not found");
      }

      if (handsSkin != null) {
        customSkin.addSkin(handsSkin);
        print("Added hands/hands_none skin");
      } else {
        print("hands/hands_none skin not found");
      }

      if (pantsSkin != null) {
        customSkin.addSkin(pantsSkin);
        print("Added pants/pants_none skin");
      } else {
        print("pants/pants_none skin not found");
      }

      if (socksSkin != null) {
        customSkin.addSkin(socksSkin);
        print("Added socks/socks_none skin");
      } else {
        print("socks/socks_none skin not found");
      }

      // 应用自定义皮肤
      skeleton.setSkin(customSkin);
      skeleton.setSlotsToSetupPose();

      print("Girl01 default skin applied successfully");
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
    if (_spineController != null && _isControllerReady && _currentIdleIndex == 4) {
      _setDefaultSkinForCurrentGirl(_spineController!);
    }
  }

  // 重新开始游戏
  void _restartGame() {
    setState(() {
      // 重置所有状态
      _currentIdleIndex = 0; // 回到第一个idle动画
      _selectedUnderwearButton = -1; // 重置选中状态
      _heartCount = 10; // 重置心形数量
      _showHeartDialog = false; // 关闭弹窗

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

      // 添加默认皮肤状态
      final braSkin = data.findSkin("bra/bra_none");
      final handsSkin = data.findSkin("hands/hands_none");
      final headSkin = data.findSkin("head/head_none");
      final socksSkin = data.findSkin("socks/socks_none");

      if (braSkin != null) {
        customSkin.addSkin(braSkin);
        print("Added bra/bra_none skin");
      } else {
        print("bra/bra_none skin not found");
      }

      if (handsSkin != null) {
        customSkin.addSkin(handsSkin);
        print("Added hands/hands_none skin");
      } else {
        print("hands/hands_none skin not found");
      }

      if (headSkin != null) {
        customSkin.addSkin(headSkin);
        print("Added head/head_none skin");
      } else {
        print("head/head_none skin not found");
      }

      if (socksSkin != null) {
        customSkin.addSkin(socksSkin);
        print("Added socks/socks_none skin");
      } else {
        print("socks/socks_none skin not found");
      }

      // 应用自定义皮肤
      skeleton.setSkin(customSkin);
      skeleton.setSlotsToSetupPose();

      print("Girl02 default skin applied successfully");
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

      // 添加默认皮肤状态
      final braSkin = data.findSkin("bra/bra_none");
      final headSkin = data.findSkin("head/head_none");
      final pantsSkin = data.findSkin("pants/pants_none");
      final socksSkin = data.findSkin("socks/socks_none");

      if (braSkin != null) {
        customSkin.addSkin(braSkin);
        print("Added bra/bra_none skin");
      } else {
        print("bra/bra_none skin not found");
      }

      if (headSkin != null) {
        customSkin.addSkin(headSkin);
        print("Added head/head_none skin");
      } else {
        print("head/head_none skin not found");
      }

      if (pantsSkin != null) {
        customSkin.addSkin(pantsSkin);
        print("Added pants/pants_none skin");
      } else {
        print("pants/pants_none skin not found");
      }

      if (socksSkin != null) {
        customSkin.addSkin(socksSkin);
        print("Added socks/socks_none skin");
      } else {
        print("socks/socks_none skin not found");
      }

      // 应用自定义皮肤
      skeleton.setSkin(customSkin);
      skeleton.setSlotsToSetupPose();

      print("Girl03 default skin applied successfully");
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

      // 根据当前选择的皮肤索引应用皮肤
      final skinNames = [
        "bra/bra_${_currentSkinIndices[0]! + 1}",
        "hands/hands_${_currentSkinIndices[2]! + 1}",
        "head/head_${_currentSkinIndices[2]! + 1}", // Girl02使用head而不是pants
        "socks/socks_${_currentSkinIndices[3]! + 1}",
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

      // 根据当前选择的皮肤索引应用皮肤
      final skinNames = [
        "bra/bra_${_currentSkinIndices[0]! + 1}",
        "head/head_${_currentSkinIndices[2]! + 1}", // Girl03使用head而不是hands
        "pants/pants_${_currentSkinIndices[1]! + 1}",
        "socks/socks_${_currentSkinIndices[3]! + 1}",
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
    if (_currentIdleIndex < 4) {
      // 0-3: idle_01 到 idle_04
      if (_girlStates[0].isPlayingSpecial) {
        // 播放特殊动画
        animationName = 'idlesp_0${_currentIdleIndex + 1}';
      } else {
        // 播放普通idle动画
        animationName = 'idle_0${_currentIdleIndex + 1}';
      }
    } else {
      // 4: underwear模式
      if (_girlStates[0].isPlayingSpecial) {
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

      // 根据当前模式设置正确的皮肤
      Future.delayed(Duration(milliseconds: 50), () {
        if (mounted && _spineController != null) {
          _setDefaultSkinForCurrentGirl(_spineController!);
        }
      });
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
            // 只在非underwear模式下显示，确保不会遮挡underwear动画
            if (_currentIdleIndex != 4)
              Center(
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
                                          text: '10',
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
                            return Container(
                              width: 80,
                              height: 80,
                              child: ClipOval(
                                child: Image.asset(
                                  index < 3
                                      ? _spineAssets[index].imagePath
                                      : 'assets/grils/Icon_girl_04_head_unlock.png',
                                  fit: BoxFit.cover,
                                ),
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
            if (_currentIdleIndex != 4)
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
            if (_currentIdleIndex == 4 && _selectedUnderwearButton != -1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
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
            // 心形不足弹窗
            if (_showHeartDialog) _buildHeartDialog(),

            // Underwear状态下的四周按钮
            if (_currentIdleIndex == 4) _buildUnderwearButtons(),
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
    setState(() {
      _currentIndex = index;
      _showSecondImage = false;
      _atlasInfo = null;
      _isAnimating = false;
      _isLoading = true;
      _isControllerReady = false; // 重置控制器状态
      _availableAnimations = [];
      _currentAnimationIndex = 0;
      // 注意：不重置_currentIdleIndex，保持用户选择的动画状态
    });

    // 停止之前的动画循环
    _animationTimer?.cancel();

    // 重新初始化Spine控制器
    _initializeSpineController();
    _loadSpineInfo();
  }

  // 处理脱衣按钮点击
  void _handleTakeoffClick() async {
    if (_heartCount < 10) {
      // 心形不够，显示弹窗
      await AudioManager().playPopupOpen();
      setState(() {
        _showHeartDialog = true;
      });
    } else {
      // 心形足够，执行脱衣逻辑
      _heartCount -= 10;
      // 这里可以添加脱衣动画或其他逻辑
    }
  }

  // 关闭弹窗
  void _closeHeartDialog() async {
    await AudioManager().playExit();
    setState(() {
      _showHeartDialog = false;
    });
  }

  // 录制视频获得心形
  void _recordVideoForHearts() async {
    // 播放获得桃心币特效音效
    await AudioManager().playHeartEffect();
    
    // 这里可以添加录制视频的逻辑
    // 暂时直接给10个心形
    setState(() {
      _heartCount += 10;
      _showHeartDialog = false;
    });
  }

  // 切换到指定女孩
  void _switchToGirl(int index) {
    if (index != _currentIndex) {
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 处理手势点击 - 触发特殊动画
  void _handleGirlTap() {
    // 所有女孩都支持点击事件
    _playSpecialAnimation();
  }

  // 切换到下一个idle动画
  void _nextIdleAnimation() async {
    if (_currentIdleIndex < 4 && _spineController != null && _isControllerReady) {
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
        _currentIdleIndex = (_currentIdleIndex + 1) % 5;
        print("Switched to idle state: $_currentIdleIndex");
      });
      
      // 9. 如果进入underwear模式，重置皮肤选择
      if (_currentIdleIndex == 4) {
        _currentSkinIndices = {
          0: 0, // bra: 默认皮肤
          1: 0, // pants: 默认皮肤
          2: 0, // hands/head: 默认皮肤
          3: 0, // socks: 默认皮肤
        };
        _selectedUnderwearButton = -1;
        print("Entered underwear mode, reset skin selections");
      }
      
      // 10. 播放下一个idle动画
      _playCurrentIdleAnimation();
    } else {
      // underwear模式或异常情况，直接循环回到idle01
      print("In underwear mode or controller not ready, cycling back to idle01");
      setState(() {
        _currentIdleIndex = (_currentIdleIndex + 1) % 5;
        if (_currentIdleIndex == 0) {
          // 回到idle01时重置所有状态
          _selectedUnderwearButton = -1;
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
    
    setState(() {
      if (_selectedUnderwearButton == buttonIndex) {
        // 如果点击的是已选中的按钮，则取消选中
        _selectedUnderwearButton = -1;
      } else {
        // 否则选中新按钮
        _selectedUnderwearButton = buttonIndex;
      }
    });

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
        ],
      ),
    );
  }

  // 获取皮肤按钮图片路径
  String _getSkinButtonImagePath(int buttonType, int skinIndex) {
    String girlPrefix = "Btn_gril01"; // 默认Girl01 (注意：实际文件名是gril01，不是girl01)
    if (_currentIndex == 1) girlPrefix = "Btn_gril02";
    if (_currentIndex == 2) girlPrefix = "Btn_gril03";

    String partName = _getPartName(buttonType);
    String skinNumber = (skinIndex + 1).toString();

    // 判断是否解锁（这里可以根据实际逻辑调整）
    bool isUnlocked = skinIndex == 0; // 默认1号皮肤解锁

    String lockStatus = isUnlocked ? "unlock" : "lock";

    return "assets/images/Girl01_chage_Btn_All/${girlPrefix}_${partName}_${skinNumber}_${lockStatus}.png";
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
        case 1: return "pants";
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

  // 处理皮肤按钮点击
  void _onSkinButtonTap(int buttonType, int skinIndex) async {
    // 播放切换音效
    await AudioManager().playSwitch();
    
    setState(() {
      _currentSkinIndices[buttonType] = skinIndex;
    });

    // underwear阶段切换皮肤时，先播放idlesp_underwear动画
    if (_currentIdleIndex == 4 && _spineController != null && _isControllerReady) {
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

  // 构建心形不足弹窗
  Widget _buildHeartDialog() {
    return Container(
      color: Colors.black.withOpacity(0.5), // 半透明背景
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            border: Border.all(
              width: 3,
            ),
          ),
          child: Stack(
            children: [
              // 背景图片
              ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Image.asset(
                  Assets.imagesPopBack,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              // 内容
              Column(
                children: [
                  // 顶部标题栏
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(17),
                        topRight: Radius.circular(17),
                      ),
                    ),
                    child: Center(
                      child: OutlinedTextWidget(
                        text: 'Get More',
                        fontSize: 24,
                        textColor: Colors.white,
                        strokeColor: Colors.black,
                        strokeWidth: 2.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 中间内容区域
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 心形和数量显示
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(Assets.imagesIconHeart2x, height: 40),
                                SizedBox(width: 10),
                                OutlinedTextWidget(
                                  text: 'x10',
                                  fontSize: 24,
                                  textColor: HexColor("#95756A"),
                                  strokeColor: Colors.white,
                                  strokeWidth: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 30),

                          // 录制视频按钮
                          GestureDetector(
                            onTap: _recordVideoForHearts,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 视频图标（使用文字代替）
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.play_arrow,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 15),
                                  OutlinedTextWidget(
                                    text: 'GET',
                                    fontSize: 20,
                                    textColor: Colors.white,
                                    strokeColor: Colors.black,
                                    strokeWidth: 2.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 关闭按钮
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _closeHeartDialog,
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
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
