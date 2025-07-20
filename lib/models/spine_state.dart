import 'package:spine_flutter/spine_flutter.dart';

// Spine 控制器状态
class SpineControllerState {
  final SpineWidgetController? controller;
  final bool isReady;
  final bool isLoading;
  final List<String> availableAnimations;
  final int currentAnimationIndex;
  final String? errorMessage;

  const SpineControllerState({
    this.controller,
    this.isReady = false,
    this.isLoading = false,
    this.availableAnimations = const [],
    this.currentAnimationIndex = 0,
    this.errorMessage,
  });

  SpineControllerState copyWith({
    SpineWidgetController? controller,
    bool? isReady,
    bool? isLoading,
    List<String>? availableAnimations,
    int? currentAnimationIndex,
    String? errorMessage,
  }) {
    return SpineControllerState(
      controller: controller ?? this.controller,
      isReady: isReady ?? this.isReady,
      isLoading: isLoading ?? this.isLoading,
      availableAnimations: availableAnimations ?? this.availableAnimations,
      currentAnimationIndex: currentAnimationIndex ?? this.currentAnimationIndex,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Takeoff 控制器状态
class TakeoffControllerState {
  final SpineWidgetController? controller;
  final bool isReady;
  final bool isVisible;

  const TakeoffControllerState({
    this.controller,
    this.isReady = false,
    this.isVisible = true,
  });

  TakeoffControllerState copyWith({
    SpineWidgetController? controller,
    bool? isReady,
    bool? isVisible,
  }) {
    return TakeoffControllerState(
      controller: controller ?? this.controller,
      isReady: isReady ?? this.isReady,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

// 皮肤状态
class SkinState {
  final String? braType;
  final String? handsType;
  final String? headType;
  final String? pantsType;
  final String? socksType;

  const SkinState({
    this.braType,
    this.handsType,
    this.headType,
    this.pantsType,
    this.socksType,
  });

  SkinState copyWith({
    String? braType,
    String? handsType,
    String? headType,
    String? pantsType,
    String? socksType,
  }) {
    return SkinState(
      braType: braType ?? this.braType,
      handsType: handsType ?? this.handsType,
      headType: headType ?? this.headType,
      pantsType: pantsType ?? this.pantsType,
      socksType: socksType ?? this.socksType,
    );
  }
}

// Spine 资源信息
class SpineAsset {
  final String name;
  final String imagePath;
  final String? image2Path;
  final String atlasFile;
  final String skeletonFile;

  const SpineAsset({
    required this.name,
    required this.imagePath,
    this.image2Path,
    required this.atlasFile,
    required this.skeletonFile,
  });
}