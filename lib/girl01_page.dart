import 'package:flutter/material.dart';
import 'package:spine_flutter/spine_flutter.dart';

class Girl01Page extends StatefulWidget {
  const Girl01Page({super.key});

  @override
  State<Girl01Page> createState() => _Girl01PageState();
}

class _Girl01PageState extends State<Girl01Page> {
  SpineWidgetController? _spineController;
  bool _isControllerReady = false;
  List<String> _availableAnimations = [];
  int _currentAnimationIndex = 0;
  bool _isAnimating = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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
            // print("Available animations: $_availableAnimations");
            
            setState(() {
              _isLoading = false;
              _isControllerReady = true;
            });

            // 播放第一个动画
            if (_availableAnimations.isNotEmpty) {
              _playAnimation(_availableAnimations.first, true);
            }
          } else {
            // print("No animations found in spine file");
            setState(() {
              _isLoading = false;
              _errorMessage = "未找到动画";
            });
          }
        } catch (e) {
          setState(() {
            _isLoading = false;
            _errorMessage = "动画初始化失败: $e";
          });
        }
      });
    } catch (e) {
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

  void _previousAnimation() {
    if (_availableAnimations.isNotEmpty && _isControllerReady) {
      _currentAnimationIndex = (_currentAnimationIndex - 1 + _availableAnimations.length) % _availableAnimations.length;
      _playAnimation(_availableAnimations[_currentAnimationIndex], true);
    }
  }

  @override
  void dispose() {
    _spineController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Girl 01 Animation'),
        actions: [
          IconButton(
            icon: Icon(_isAnimating ? Icons.pause : Icons.play_arrow),
            onPressed: _isAnimating ? _pauseAnimation : _resumeAnimation,
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: _stopAnimation,
          ),
        ],
      ),
      body: Column(
        children: [
          // 动画状态信息
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Girl 01 Spine Animation',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '状态: ${_isAnimating ? "播放中" : "已暂停"}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_availableAnimations.isNotEmpty)
                  Text(
                    '当前动画: ${_availableAnimations[_currentAnimationIndex]} (${_currentAnimationIndex + 1}/${_availableAnimations.length})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          
          // Spine动画显示区域
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.pink.shade50,
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
          
          // 动画控制面板
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 主要控制按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isControllerReady ? _previousAnimation : null,
                      icon: const Icon(Icons.skip_previous),
                      label: const Text('上一个'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isControllerReady ? (_isAnimating ? _pauseAnimation : _resumeAnimation) : null,
                      icon: Icon(_isAnimating ? Icons.pause : Icons.play_arrow),
                      label: Text(_isAnimating ? '暂停' : '播放'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAnimating ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isControllerReady ? _nextAnimation : null,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('下一个'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 停止按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isControllerReady ? _stopAnimation : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('停止动画'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 可用动画列表
                if (_availableAnimations.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '可用动画:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _availableAnimations.join(", "),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpineWidget() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载 Girl 01 动画...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
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
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initializeSpineController();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_spineController == null || !_isControllerReady) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    try {
      return Center(
        child: SpineWidget.fromAsset(
          "assets/spine/girl02.atlas",
          "assets/spine/girl02.skel",
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
            const Text(
              'Failed to load Spine widget',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $e',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }
} 