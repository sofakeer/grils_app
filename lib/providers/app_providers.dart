import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_flutter/spine_flutter.dart';
import '../models/spine_state.dart';

// Spine 资源数据
final spineAssetsProvider = Provider<List<SpineAsset>>((ref) {
  return [
    const SpineAsset(
      name: "Girl 01",
      imagePath: "assets/grils/Icon_girl_01_head_unlock.png",
      image2Path: "assets/spine/girl01_2.png",
      atlasFile: "assets/spine/girl01.atlas",
      skeletonFile: "assets/spine/girl01.skel",
    ),
    const SpineAsset(
      name: "Girl 02",
      imagePath: "assets/grils/Icon_girl_02_head_unlock.png",
      image2Path: "assets/spine/girl02_2.png",
      atlasFile: "assets/spine/girl02.atlas",
      skeletonFile: "assets/spine/girl02.skel",
    ),
    const SpineAsset(
      name: "Girl 03",
      imagePath: "assets/grils/Icon_girl_03_head_unlock.png",
      image2Path: "assets/spine/girl03_2.png",
      atlasFile: "assets/spine/girl03.atlas",
      skeletonFile: "assets/spine/girl03.skel",
    ),
  ];
});

// 当前女孩索引
final currentGirlIndexProvider = StateProvider<int>((ref) => 0);

// 心形数量
final heartCountProvider = StateProvider<int>((ref) => 5);

// 心形弹窗状态
final heartDialogProvider = StateProvider<bool>((ref) => false);

// 当前女孩资源
final currentGirlAssetProvider = Provider<SpineAsset>((ref) {
  final assets = ref.watch(spineAssetsProvider);
  final currentIndex = ref.watch(currentGirlIndexProvider);
  return assets[currentIndex];
});