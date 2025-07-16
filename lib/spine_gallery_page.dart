import 'package:flutter/material.dart';
import 'package:spine_flutter/spine_flutter.dart';

class SpineGalleryPage extends StatefulWidget {
  const SpineGalleryPage({super.key});

  @override
  State<SpineGalleryPage> createState() => _SpineGalleryPageState();
}

class _SpineGalleryPageState extends State<SpineGalleryPage> {
  int _currentIndex = 0;
  
  final List<SpineAssetInfo> _spineAssets = [
    SpineAssetInfo(
      name: "Girl 01",
      atlasPath: "assets/spine/girl01.atlas",
      skeletonPath: "assets/spine/girl01.skel",
    ),
    SpineAssetInfo(
      name: "Girl 02",
      atlasPath: "assets/spine/girl02.atlas",
      skeletonPath: "assets/spine/girl02.skel",
    ),
    SpineAssetInfo(
      name: "Girl 03",
      atlasPath: "assets/spine/girl03.atlas",
      skeletonPath: "assets/spine/girl03.skel",
    ),
    SpineAssetInfo(
      name: "Takeoff",
      atlasPath: "assets/spine/Takeoff.atlas",
      skeletonPath: "assets/spine/Takeoff.skel",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Spine Animation Gallery'),
      ),
      body: Column(
        children: [
          // 选择器
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_spineAssets.length, (index) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentIndex == index 
                        ? Theme.of(context).colorScheme.primary 
                        : null,
                    foregroundColor: _currentIndex == index 
                        ? Theme.of(context).colorScheme.onPrimary 
                        : null,
                  ),
                  child: Text(_spineAssets[index].name),
                );
              }),
            ),
          ),
          
          // 当前选择的动画信息
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '当前: ${_spineAssets[_currentIndex].name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          
          // 动画显示区域
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
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
                child: SpineAnimationDisplay(
                  key: ValueKey(_currentIndex),
                  assetInfo: _spineAssets[_currentIndex],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SpineAnimationDisplay extends StatefulWidget {
  final SpineAssetInfo assetInfo;

  const SpineAnimationDisplay({
    super.key,
    required this.assetInfo,
  });

  @override
  State<SpineAnimationDisplay> createState() => _SpineAnimationDisplayState();
}

class _SpineAnimationDisplayState extends State<SpineAnimationDisplay> {
  bool _hasError = false;
  String _errorMessage = '';
  List<String> _availableAnimations = [];
  int _currentAnimationIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 错误显示
        if (_hasError)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red),
            ),
            child: Text(
              'Error: $_errorMessage',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        
        // 动画信息
        if (_availableAnimations.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '可用动画 (${_availableAnimations.length}):',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  _availableAnimations.join(", "),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_availableAnimations.isNotEmpty)
                  Text(
                    '当前播放: ${_availableAnimations[_currentAnimationIndex]}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        
        // Spine 动画
        Expanded(
          child: Center(
            child: _buildSpineWidget(),
          ),
        ),
        
        // 动画控制按钮
        if (_availableAnimations.length > 1)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _previousAnimation,
                  child: const Text('上一个'),
                ),
                ElevatedButton(
                  onPressed: _nextAnimation,
                  child: const Text('下一个'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSpineWidget() {
    try {
      return SpineWidget.fromAsset(
        widget.assetInfo.atlasPath,
        widget.assetInfo.skeletonPath,
        SpineWidgetController(onInitialized: (controller) {
          try {
            // 获取可用动画
            final animations = controller.skeleton.getData()?.getAnimations();
            if (animations != null && animations.isNotEmpty) {
              final animationNames = animations.map((a) => a.getName()).toList();
              
              setState(() {
                _availableAnimations = animationNames;
                _currentAnimationIndex = 0;
                _hasError = false;
                _errorMessage = '';
              });
              
              // 播放第一个动画
              if (animationNames.isNotEmpty) {
                controller.animationState.setAnimationByName(0, animationNames.first, true);
              }
            } else {
              setState(() {
                _hasError = true;
                _errorMessage = "No animations found";
              });
            }
          } catch (e) {
            setState(() {
              _hasError = true;
              _errorMessage = "Animation setup failed: $e";
            });
          }
        }),
        boundsProvider: SetupPoseBounds(),
      );
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = "Widget creation failed: $e";
      });
      
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
              'Failed to load ${widget.assetInfo.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  void _nextAnimation() {
    if (_availableAnimations.isNotEmpty) {
      setState(() {
        _currentAnimationIndex = (_currentAnimationIndex + 1) % _availableAnimations.length;
      });
      // 这里需要重新创建 SpineWidget 来切换动画
      // 或者实现动画切换逻辑
    }
  }

  void _previousAnimation() {
    if (_availableAnimations.isNotEmpty) {
      setState(() {
        _currentAnimationIndex = (_currentAnimationIndex - 1 + _availableAnimations.length) % _availableAnimations.length;
      });
      // 这里需要重新创建 SpineWidget 来切换动画
      // 或者实现动画切换逻辑
    }
  }
}

class SpineAssetInfo {
  final String name;
  final String atlasPath;
  final String skeletonPath;

  SpineAssetInfo({
    required this.name,
    required this.atlasPath,
    required this.skeletonPath,
  });
} 