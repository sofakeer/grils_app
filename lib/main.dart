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
    // 设置全屏模式，隐藏状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _loadSpineInfo();
    _initializeSpineController();
    _initializeTakeoffController();
  }

  void _initializeTakeoffController() {
    try {
      _takeoffController = SpineWidgetController(onInitialized: (controller) {
        try {
          controller.animationState.getData().setDefaultMix(0.2);
          final animations = controller.skeleton.getData()?.getAnimations();
          if (animations != null && animations.isNotEmpty) {
            setState(() {
              _isTakeoffReady = true;
            });
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
            
            setState(() {
              _isLoading = false;
              _isControllerReady = true; // 标记控制器已准备好
            });

            // 播放第一个动画
            if (_availableAnimations.isNotEmpty) {
              _playAnimation(_availableAnimations.first, true);
            }
          } else {
            print("No animations found in spine file");
            setState(() {
              _isLoading = false;
              _errorMessage = "未找到动画";
            });
          }
        } catch (e) {
          print("Animation initialization failed: $e");
          setState(() {
            _isLoading = false;
            _errorMessage = "动画初始化失败: $e";
          });
        }
      });
    } catch (e) {
      print("Controller creation failed: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "控制器创建失败: $e";
      });
    }
  }

  void _playAnimation(String animationName, bool loop) {
    if (_spineController != null && _isControllerReady) {
      _spineController!.animationState.setAnimationByName(0, animationName, loop);
      setState(() {
        _isAnimating = true;
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _spineController = null;
    _takeoffController = null;
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
      body: Stack(
        children: [
          // Spine动画预览区域 - 全屏显示
          _buildSpineWidget(),
          
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
            top: 0, // 移除状态栏padding，直接设置为0
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
                            onTap: () => _loadSpineAsset(index),
                            child: Container(
                              width: 80,
                              height: 80,
                              child: ClipOval(
                                child: Image.asset(

                                  _spineAssets[index].imagePath ,
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
        ],
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
      return SpineWidget.fromAsset(
        _spineAssets[_currentIndex].atlasFile,
        _spineAssets[_currentIndex].skeletonFile,
        _spineController!,
        boundsProvider: SetupPoseBounds(),
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
