import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _showSpineAnimationWidget = false; // 添加状态变量
  
  // 定义所有spine文件的信息
  final List<SpineAsset> _spineAssets = [
    SpineAsset(
      name: "Girl 01",
      imagePath: "assets/spine/girl01.png",
      image2Path: "assets/spine/girl01_2.png",
      atlasFile: "assets/spine/girl01.atlas",
      skeletonFile: "assets/spine/girl01.skel",
    ),
    SpineAsset(
      name: "Girl 02", 
      imagePath: "assets/spine/girl02.png",
      image2Path: "assets/spine/girl02_2.png",
      atlasFile: "assets/spine/girl02.atlas",
      skeletonFile: "assets/spine/girl02.skel",
    ),
    SpineAsset(
      name: "Girl 03",
      imagePath: "assets/spine/girl03.png",
      image2Path: "assets/spine/girl03_2.png", 
      atlasFile: "assets/spine/girl03.atlas",
      skeletonFile: "assets/spine/girl03.skel",
    ),
    SpineAsset(
      name: "Takeoff",
      imagePath: "assets/spine/Takeoff.png",
      image2Path: null,
      atlasFile: "assets/spine/Takeoff.atlas",
      skeletonFile: "assets/spine/Takeoff.skel",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSpineInfo();
    _initializeSpineController();
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
    _spineController = null;
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Spine Girls Preview - ${_spineAssets[_currentIndex].name}'),
        actions: [
          // IconButton(
          //   icon: Icon(_isAnimating ? Icons.pause : Icons.play_arrow),
          //   onPressed: _isAnimating ? _pauseAnimation : _resumeAnimation,
          // ),
          // IconButton(
          //   icon: const Icon(Icons.refresh),
          //   onPressed: _loadSpineInfo,
          // ),
          // // 添加测试 SpineAnimationWidget 的按钮
          // IconButton(
          //   icon: const Icon(Icons.animation),
          //   onPressed: () {
          //     setState(() {
          //       _showSpineAnimationWidget = !_showSpineAnimationWidget;
          //     });
          //   },
          // ),
          // // 添加导航到 Girl01Page 的按钮
          // IconButton(
          //   icon: const Icon(Icons.person),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => const Girl01Page()),
          //     );
          //   },
          // ),
          // // 添加导航到 SimpleSpineTest 的按钮
          // IconButton(
          //   icon: const Icon(Icons.bug_report),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => const SimpleSpineTest()),
          //     );
          //   },
          // ),
          // // 添加导航到 SpineGalleryPage 的按钮
          // IconButton(
          //   icon: const Icon(Icons.photo_library),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => const SpineGalleryPage()),
          //     );
          //   },
          // ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 顶部控制区域 - 可滚动
              Flexible(
                child: SingleChildScrollView(
              child: Column(
                children: [
                  // 编号按钮行
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_spineAssets.length, (index) {
                        return ElevatedButton(
                          onPressed: () => _loadSpineAsset(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentIndex == index 
                                ? Theme.of(context).colorScheme.primary 
                                : null,
                            foregroundColor: _currentIndex == index 
                                ? Theme.of(context).colorScheme.onPrimary 
                                : null,
                          ),
                          child: Text('${index + 1}'),
                        );
                      }),
                    ),
                  ),
                  // 当前信息显示
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        if (_availableAnimations.isNotEmpty)
                          Text(
                            '当前动画: ${_availableAnimations.isNotEmpty ? _availableAnimations[_currentAnimationIndex] : "无"}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        // 添加 SpineAnimationWidget 状态显示
                        // Text(
                        //   'SpineAnimationWidget: ${_showSpineAnimationWidget ? "显示中" : "隐藏"}',
                        //   style: Theme.of(context).textTheme.bodySmall,
                        // ),
                      ],
                    ),
                  ),
                  
                  // 图片切换按钮（如果有第二张图片）
                  // if (_spineAssets[_currentIndex].image2Path != null)
                  //   Padding(
                  //     padding: const EdgeInsets.all(8.0),
                  //     child: ElevatedButton(
                  //       onPressed: () {
                  //         setState(() {
                  //           _showSecondImage = !_showSecondImage;
                  //         });
                  //       },
                  //       child: Text(_showSecondImage ? '显示图片1' : '显示图片2'),
                  //     ),
                  //   ),
                ],
              ),
            ),
          ),
          
          // Spine动画预览区域 - 固定高度
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade50,
                    Colors.purple.shade50,
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildSpineWidget(),
              ),
            ),
          ),
              
          
          // 底部控制区域
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 动画控制按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isControllerReady ? (_isAnimating ? _pauseAnimation : _resumeAnimation) : null,
                      icon: Icon(_isAnimating ? Icons.pause : Icons.play_arrow),
                      label: Text(_isAnimating ? '暂停' : '播放'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isControllerReady ? _stopAnimation : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('停止'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isControllerReady ? _nextAnimation : null,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('下一个'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_availableAnimations.isNotEmpty)
                  Text(
                    '可用动画: ${_availableAnimations.join(", ")}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
            ],
          ),
          
          // 添加 SpineAnimationWidget 覆盖层
          if (_showSpineAnimationWidget)
            SpineAnimationWidget(
              assetName: _spineAssets[_currentIndex].name.toLowerCase().replaceAll(' ', ''),
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
      return Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.8,
          child: SpineWidget.fromAsset(
            _spineAssets[_currentIndex].atlasFile,
            _spineAssets[_currentIndex].skeletonFile,
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
