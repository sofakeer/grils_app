import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:spine_flutter/spine_flutter.dart';
import 'spine_animation_widget.dart'; // 导入 SpineAnimationWidget
import 'girl01_page.dart'; // 导入 Girl01Page
import 'simple_spine_test.dart'; // 导入 SimpleSpineTest
import 'spine_gallery_page.dart'; // 导入 SpineGalleryPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSpineFlutter(enableMemoryDebugging: false);
  
  // 设置全屏模式
  // SystemChrome.setEnabledSystemUIMode(
  //   SystemUiMode.edgeToEdge,
  //   overlays: [SystemUiOverlay.top],
  // );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spine Girls App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SpinePreviewPage(),
      debugShowCheckedModeBanner: false, // 移除调试标记
    );
  }
}

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
    
    _loadSpineInfo();
    _initializeSpineController();
    _initializeTakeoffController();
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
            controller.animationState.setAnimationByName(0, animations.first.getName(), true);
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
            
            if (mounted) {
              setState(() {
                _isLoading = false;
                _isControllerReady = true; // 标记控制器已准备好
              });
            }

            // 播放第一个动画
            if (_availableAnimations.isNotEmpty) {
              _playAnimation(_availableAnimations.first, true);
              // 播放动画后再次确保皮肤设置正确
              Future.delayed(Duration(milliseconds: 100), () {
                if (mounted && _spineController != null) {
                  _setDefaultSkinForCurrentGirl(_spineController!);
                }
              });
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
    print("Setting default skin for current girl: ${_spineAssets[_currentIndex].name} (index: $_currentIndex)");
    
    if (_currentIndex == 0 && _spineAssets[_currentIndex].name == "Girl 01") {
      _setGirl01DefaultSkin(controller);
    } else if (_currentIndex == 1 && _spineAssets[_currentIndex].name == "Girl 02") {
      _setGirl02DefaultSkin(controller);
    } else if (_currentIndex == 2 && _spineAssets[_currentIndex].name == "Girl 03") {
      _setGirl03DefaultSkin(controller);
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

  void _playAnimation(String animationName, bool loop) {
    if (_spineController != null && _isControllerReady) {
      _spineController!.animationState.setAnimationByName(0, animationName, loop);
      setState(() {
        _isAnimating = true;
      });
      
      // 播放动画后确保皮肤设置正确
      Future.delayed(Duration(milliseconds: 50), () {
        if (mounted && _spineController != null) {
          _setDefaultSkinForCurrentGirl(_spineController!);
        }
      });
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


  @override
  void dispose() {
    // 恢复系统UI显示
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    
    // 正确销毁Spine控制器
    if (_spineController != null) {
      // _spineController!.dispose();
      _spineController = null;
    }
    
    if (_takeoffController != null) {
      // _takeoffController!.dispose();
      _takeoffController = null;
    }
    
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
          // Spine动画预览区域 - 全屏显示，支持左右滑动
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              _loadSpineAsset(index);
            },
            itemCount: _spineAssets.length,
            itemBuilder: (context, index) {
              return _buildSpineWidgetForIndex(index);
            },
          ),
          
          // Takeoff 手势覆盖动画
          // if (_showTakeoffOverlay && _isTakeoffReady)
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
                    left: 0, // 确保从左边开始
                    right: 0, // 确保宽度扩展到父容器右边
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
                                  padding: const EdgeInsets.only(left: 20,top: 10),
                                  child: Container(
                                    padding: EdgeInsets.only(right: 30),
                                      decoration: BoxDecoration(
                                        color: HexColor("#FFF5E5"),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 50),
                                        child: Text('10', style: TextStyle(color:HexColor("#95756A"),fontWeight: FontWeight.bold,)),
                                      ),
                                  ),
                                ),
                                Image.asset(Assets.imagesIconHeart2x,height: 50),
                              ],
                            ),

                            Image.asset(Assets.imagesBtnHeartBack,height: 50),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(_spineAssets.length, (index) {
                          return GestureDetector(
                            onTap: () => _switchToGirl(index),
                            child: Container(
                              width: 80,
                              height: 80,
                              child: ClipOval(
                                child: Image.asset(
                                  _spineAssets[index].imagePath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: 10,),
                    ],
                  ),
                ],
              ),
            ),
          ),

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
                      // x 字符 - 发光字效果
                      Center(
                        child: Text(
                          'x',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              // 外层红色发光 - 更粗
                              Shadow(
                                color: Colors.red,
                                offset: Offset(0, 0),
                                blurRadius: 15,
                              ),
                              // 中层红色发光
                              Shadow(
                                color: Colors.red.withOpacity(0.8),
                                offset: Offset(0, 0),
                                blurRadius: 10,
                              ),
                              // 内层橙色发光 - 更粗
                              Shadow(
                                color: Colors.orange,
                                offset: Offset(0, 0),
                                blurRadius: 8,
                              ),
                              // 中层橙色发光
                              Shadow(
                                color: Colors.orange.withOpacity(0.8),
                                offset: Offset(0, 0),
                                blurRadius: 5,
                              ),
                              // 白色核心发光 - 更粗
                              Shadow(
                                color: Colors.white.withOpacity(0.9),
                                offset: Offset(0, 0),
                                blurRadius: 4,
                              ),
                              // 白色内发光
                              Shadow(
                                color: Colors.white.withOpacity(0.6),
                                offset: Offset(0, 0),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 4), // 小间距
                      // 数字 - 发光字效果
                      Center(
                        child: Text(
                          '$_heartCount',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              // 外层红色发光 - 更粗
                              Shadow(
                                color: Colors.red,
                                offset: Offset(0, 0),
                                blurRadius: 15,
                              ),
                              // 中层红色发光
                              Shadow(
                                color: Colors.red.withOpacity(0.8),
                                offset: Offset(0, 0),
                                blurRadius: 10,
                              ),
                              // 内层橙色发光 - 更粗
                              Shadow(
                                color: Colors.orange,
                                offset: Offset(0, 0),
                                blurRadius: 8,
                              ),
                              // 中层橙色发光
                              Shadow(
                                color: Colors.orange.withOpacity(0.8),
                                offset: Offset(0, 0),
                                blurRadius: 5,
                              ),
                              // 白色核心发光 - 更粗
                              Shadow(
                                color: Colors.white.withOpacity(0.9),
                                offset: Offset(0, 0),
                                blurRadius: 4,
                              ),
                              // 白色内发光
                              Shadow(
                                color: Colors.white.withOpacity(0.6),
                                offset: Offset(0, 0),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10), // 间距
                  GestureDetector(
                    //onTap: _handleTakeoffClick,
                    child: Image.asset(Assets.imagesBtnTakeoff, height: 80),
                  ),
                ],
              ),
          ),
          
          // 心形不足弹窗
          if (_showHeartDialog)
            _buildHeartDialog(),
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
    });
    
    // 重新初始化Spine控制器
    _initializeSpineController();
    _loadSpineInfo();
  }
  
  // 处理脱衣按钮点击
  void _handleTakeoffClick() {
    if (_heartCount < 10) {
      // 心形不够，显示弹窗
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
  void _closeHeartDialog() {
    setState(() {
      _showHeartDialog = false;
    });
  }
  
  // 录制视频获得心形
  void _recordVideoForHearts() {
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
        child: SpineWidget.fromAsset(
          _spineAssets[index].atlasFile,
          _spineAssets[index].skeletonFile,
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
                      child: Text(
                        'Get More',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
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
                                Text(
                                  'x10',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: HexColor("#95756A"),
                                  ),
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
                                  Text(
                                    'GET',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
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
