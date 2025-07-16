import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spine_flutter/spine_flutter.dart';

class SpineAnimationWidget extends StatefulWidget {
  final bool isFlower;
  final String? assetName; // 添加资源名称参数

  const SpineAnimationWidget({
    this.isFlower = true, 
    this.assetName,
    Key? key
  }) : super(key: key);

  @override
  _SpineAnimationWidgetState createState() => _SpineAnimationWidgetState();
}

class _SpineAnimationWidgetState extends State<SpineAnimationWidget> {
  SpineWidgetController? controller;
  List<String> _availableAnimations = [];
  bool _isControllerReady = false;

  @override
  void initState() {
    super.initState();
    try {
      controller = SpineWidgetController(onInitialized: (controller) {
        try {
          // 设置默认过渡时间
          controller.animationState.getData().setDefaultMix(0.2);

          // 获取可用动画
          final animations = controller.skeleton.getData()?.getAnimations();
          if (animations != null && animations.isNotEmpty) {
            _availableAnimations = animations.map((a) => a.getName()).toList();
            // print("Available animations: $_availableAnimations");
            
            setState(() {
              _isControllerReady = true;
            });

            // 播放第一个可用的动画
            if (_availableAnimations.isNotEmpty) {
              final firstAnimation = _availableAnimations.first;
              // print("Playing animation: $firstAnimation");
              controller.animationState.setAnimationByName(0, firstAnimation, true); // 循环播放
              
              // 获取动画时长
              final animation = controller.skeleton.getData()!.findAnimation(firstAnimation);
              if (animation != null) {
                final duration = animation.getDuration();
                // print("Animation duration: $duration seconds");
              }
            }
          } else {
            // print("No animations found in spine file");
          }
        } catch (e) {
          // print("Animation initialization failed: $e");
        }
      });
    } catch (e) {
      // print("Controller creation failed: $e");
    }
  }

  @override
  void dispose() {
    controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用传入的资源名称，默认为 girl01
    final assetName = widget.assetName ?? "girl01";

    if (controller == null || !_isControllerReady) {
      return const Positioned.fill(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在加载Spine动画...'),
            ],
          ),
        ),
      );
    }

    try {
      return Stack(
        children: [
          Positioned(
            top: -200,
            left: 0,
            right: 0,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: SpineWidget.fromAsset(
                    "assets/spine/$assetName.atlas",
                    "assets/spine/$assetName.skel",
                    controller!,
                    boundsProvider: SetupPoseBounds(),
                  ),
                ),
              ),
            ),
          ),
          // 添加调试信息显示
          if (_availableAnimations.isNotEmpty)
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '可用动画: ${_availableAnimations.join(", ")}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    } catch (e) {
      return Positioned.fill(
        child: Center(
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
                'Failed to load Spine animation',
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
        ),
      );
    }
  }
}