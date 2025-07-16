import 'package:flutter/material.dart';
import 'package:spine_flutter/spine_flutter.dart';

class SimpleSpineTest extends StatefulWidget {
  const SimpleSpineTest({super.key});

  @override
  State<SimpleSpineTest> createState() => _SimpleSpineTestState();
}

class _SimpleSpineTestState extends State<SimpleSpineTest> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Spine Test'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Testing Spine Animation Loading',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
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
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: _buildSpineWidget(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpineWidget() {
    try {
      return SpineWidget.fromAsset(
        "assets/spine/girl03.atlas",
        "assets/spine/girl03.skel",
        SpineWidgetController(onInitialized: (controller) {
          try {
            // 尝试获取动画列表
            final animations = controller.skeleton.getData()?.getAnimations();
            if (animations != null && animations.isNotEmpty) {
              final animationNames = animations.map((a) => a.getName()).toList();
              print("Available animations: $animationNames");
              
              // 播放第一个动画
              if (animationNames.isNotEmpty) {
                controller.animationState.setAnimationByName(0, animationNames.first, true);
              }
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
              'Failed to load Spine animation',
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
} 