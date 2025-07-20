import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_flutter/spine_flutter.dart';
import '../models/spine_state.dart';

class TakeoffControllerNotifier extends StateNotifier<TakeoffControllerState> {
  TakeoffControllerNotifier() : super(const TakeoffControllerState()) {
    _initializeController();
  }

  void _initializeController() {
    try {
      final controller = SpineWidgetController(onInitialized: (ctrl) {
        _onControllerInitialized(ctrl);
      });

      if (mounted) {
        state = state.copyWith(controller: controller);
      }
    } catch (e) {
      print("Takeoff controller creation failed: $e");
    }
  }

  void _onControllerInitialized(SpineWidgetController controller) {
    try {
      controller.animationState.getData().setDefaultMix(0.2);
      final animations = controller.skeleton.getData()?.getAnimations();
      
      if (animations != null && animations.isNotEmpty) {
        if (mounted) {
          state = state.copyWith(isReady: true);
        }
        // 播放第一个动画循环
        controller.animationState.setAnimationByName(0, animations.first.getName(), true);
      }
    } catch (e) {
      print("Takeoff animation initialization failed: $e");
    }
  }

  void toggleVisibility() {
    if (mounted) {
      state = state.copyWith(isVisible: !state.isVisible);
    }
  }

  void setVisibility(bool visible) {
    if (mounted) {
      state = state.copyWith(isVisible: visible);
    }
  }

  @override
  void dispose() {
    final controller = state.controller;
    if (controller != null) {
      // 注释掉 dispose 调用，避免错误
      // controller.dispose();
    }
    super.dispose();
  }
}

// Takeoff controller provider
final takeoffControllerProvider = StateNotifierProvider<TakeoffControllerNotifier, TakeoffControllerState>((ref) {
  return TakeoffControllerNotifier();
});