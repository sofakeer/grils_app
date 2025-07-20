import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_flutter/spine_flutter.dart';
import '../models/spine_state.dart';
import 'app_providers.dart';

class SpineControllerNotifier extends StateNotifier<SpineControllerState> {
  final int girlIndex;
  final SpineAsset asset;
  Timer? _skinUpdateTimer;

  SpineControllerNotifier(this.girlIndex, this.asset) : super(const SpineControllerState()) {
    _initializeController();
  }

  void _initializeController() {
    if (mounted) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final controller = SpineWidgetController(onInitialized: (ctrl) {
        _onControllerInitialized(ctrl);
      });

      if (mounted) {
        state = state.copyWith(controller: controller);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: "控制器创建失败: $e",
        );
      }
    }
  }

  void _onControllerInitialized(SpineWidgetController controller) {
    try {
      // 设置默认过渡时间
      controller.animationState.getData().setDefaultMix(0.2);

      // 获取可用动画
      final animations = controller.skeleton.getData()?.getAnimations();
      if (animations != null && animations.isNotEmpty) {
        final animationNames = animations.map((a) => a.getName()).toList();
        
        if (mounted) {
          state = state.copyWith(
            availableAnimations: animationNames,
            isReady: true,
            isLoading: false,
          );
        }

        // 设置默认皮肤
        _setDefaultSkin(controller);

        // 播放第一个动画
        if (animationNames.isNotEmpty) {
          playAnimation(animationNames.first, true);
        }
      } else {
        if (mounted) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: "未找到动画",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: "动画初始化失败: $e",
        );
      }
    }
  }

  void _setDefaultSkin(SpineWidgetController controller) {
    try {
      final data = controller.skeletonData;
      final skeleton = controller.skeleton;

      // 根据女孩索引设置默认皮肤
      final customSkin = Skin("girl${girlIndex + 1}-default-skin");

      switch (girlIndex) {
        case 0: // Girl 01
          _addSkinIfExists(data, customSkin, "bra/bra_none");
          _addSkinIfExists(data, customSkin, "hands/hands_none");
          _addSkinIfExists(data, customSkin, "pants/pants_none");
          _addSkinIfExists(data, customSkin, "socks/socks_none");
          break;
        case 1: // Girl 02
          _addSkinIfExists(data, customSkin, "bra/bra_none");
          _addSkinIfExists(data, customSkin, "hands/hands_none");
          _addSkinIfExists(data, customSkin, "head/head_none");
          _addSkinIfExists(data, customSkin, "socks/socks_none");
          break;
        case 2: // Girl 03
          _addSkinIfExists(data, customSkin, "bra/bra_none");
          _addSkinIfExists(data, customSkin, "head/head_none");
          _addSkinIfExists(data, customSkin, "pants/pants_none");
          _addSkinIfExists(data, customSkin, "socks/socks_none");
          break;
      }

      // 应用自定义皮肤
      skeleton.setSkin(customSkin);
      skeleton.setSlotsToSetupPose();
    } catch (e) {
      print("Failed to set default skin for girl ${girlIndex + 1}: $e");
    }
  }

  void _addSkinIfExists(SkeletonData data, Skin customSkin, String skinName) {
    final skin = data.findSkin(skinName);
    if (skin != null) {
      customSkin.addSkin(skin);
      print("Added $skinName skin for girl ${girlIndex + 1}");
    } else {
      print("$skinName skin not found for girl ${girlIndex + 1}");
    }
  }

  void playAnimation(String animationName, bool loop) {
    final controller = state.controller;
    if (controller != null && state.isReady) {
      controller.animationState.setAnimationByName(0, animationName, loop);
      
      // 延迟确保皮肤设置正确
      _skinUpdateTimer?.cancel();
      _skinUpdateTimer = Timer(const Duration(milliseconds: 50), () {
        if (mounted && state.controller != null) {
          _setDefaultSkin(state.controller!);
        }
      });
    }
  }

  void nextAnimation() {
    if (state.availableAnimations.isNotEmpty && state.isReady) {
      final nextIndex = (state.currentAnimationIndex + 1) % state.availableAnimations.length;
      if (mounted) {
        state = state.copyWith(currentAnimationIndex: nextIndex);
      }
      playAnimation(state.availableAnimations[nextIndex], true);
    }
  }

  void pauseAnimation() {
    final controller = state.controller;
    if (controller != null && state.isReady) {
      controller.animationState.setTimeScale(0.0);
    }
  }

  void resumeAnimation() {
    final controller = state.controller;
    if (controller != null && state.isReady) {
      controller.animationState.setTimeScale(1.0);
    }
  }

  void stopAnimation() {
    final controller = state.controller;
    if (controller != null && state.isReady) {
      controller.animationState.clearTracks();
    }
  }

  @override
  void dispose() {
    _skinUpdateTimer?.cancel();
    final controller = state.controller;
    if (controller != null) {
      // 注释掉 dispose 调用，避免错误
      // controller.dispose();
    }
    super.dispose();
  }
}

// Provider for each girl's spine controller
final spineControllerProvider = StateNotifierProvider.family<SpineControllerNotifier, SpineControllerState, int>((ref, girlIndex) {
  final assets = ref.watch(spineAssetsProvider);
  return SpineControllerNotifier(girlIndex, assets[girlIndex]);
});

// Current girl's spine controller
final currentSpineControllerProvider = Provider<SpineControllerState>((ref) {
  final currentIndex = ref.watch(currentGirlIndexProvider);
  return ref.watch(spineControllerProvider(currentIndex));
});