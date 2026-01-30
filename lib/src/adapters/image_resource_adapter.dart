import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/firebase_config.dart';
import '../services/firebase_config_service.dart';
import '../services/image_download_service.dart';
import '../services/app_resource_manager.dart';

/// 图片资源适配器 - 将Firebase配置集成到现有图片系统
class ImageResourceAdapter {
  final Ref _ref;

  ImageResourceAdapter(this._ref);

  /// 获取关卡图片资源
  List<ImageResource> getLevelImages(String levelType) {
    try {
      final config = _ref.read(firebaseConfigProvider).valueOrNull;
      if (config == null) return [];

      switch (levelType.toLowerCase()) {
        case 'a':
          return config.images.levelA.generateImageResources();
        case 'b':
          return config.images.levelB.generateImageResources();
        case 'c':
          return config.images.levelC.generateImageResources();
        default:
          return [];
      }
    } catch (e) {
      print('[ImageResourceAdapter] 获取关卡图片异常: $e');
      return [];
    }
  }

  /// 获取套图资源
  List<SecretSet> getSecretSets() {
    try {
      final config = _ref.read(firebaseConfigProvider).valueOrNull;
      if (config == null) return [];

      return config.secrets.sets;
    } catch (e) {
      print('[ImageResourceAdapter] 获取套图资源异常: $e');
      return [];
    }
  }

  /// 获取宝藏图片资源
  List<ImageResource> getTreasureImages() {
    try {
      final config = _ref.read(firebaseConfigProvider).valueOrNull;
      if (config == null) return [];

      return config.treasure.generateImageResources();
    } catch (e) {
      print('[ImageResourceAdapter] 获取宝藏图片异常: $e');
      return [];
    }
  }

  /// 获取图片路径（优先本地缓存）
  String getImagePath(String imageId, String fallbackPath) {
    try {
      final resourceManager = _ref.read(appResourceManagerProvider);
      return resourceManager.getResourceUrl(imageId, fallbackPath);
    } catch (e) {
      print('[ImageResourceAdapter] 获取图片路径异常: $e');
      return fallbackPath;
    }
  }

  /// 检查图片是否可用
  bool isImageAvailable(String imageId) {
    try {
      final resourceManager = _ref.read(appResourceManagerProvider);
      return resourceManager.isResourceAvailable(imageId);
    } catch (e) {
      print('[ImageResourceAdapter] 检查图片可用性异常: $e');
      return false;
    }
  }

  /// 获取图片下载状态
  Map<String, int> getDownloadProgress() {
    try {
      final downloadState = _ref.read(imageDownloadServiceProvider);
      return downloadState.progress;
    } catch (e) {
      print('[ImageResourceAdapter] 获取下载进度异常: $e');
      return {};
    }
  }

  /// 检查是否需要下载
  bool needsDownload(String imageId) {
    try {
      return !isImageAvailable(imageId);
    } catch (e) {
      print('[ImageResourceAdapter] 检查下载需求异常: $e');
      return false;
    }
  }

  /// 获取图片资源信息
  ImageResource? getImageResource(String imageId) {
    try {
      final config = _ref.read(firebaseConfigProvider).valueOrNull;
      if (config == null) return null;

      // 在所有资源中查找
      final allResources = _ref.read(firebaseConfigServiceProvider).getAllImageResources(config);
      return allResources.firstWhere(
        (resource) => resource.id == imageId,
        orElse: () => throw StateError('Resource not found'),
      );
    } catch (e) {
      print('[ImageResourceAdapter] 获取图片资源信息异常: $e');
      return null;
    }
  }

  /// 预加载图片
  Future<void> preloadImage(String imageId) async {
    try {
      if (isImageAvailable(imageId)) return;

      final resource = getImageResource(imageId);
      if (resource == null) return;

      final downloadService = _ref.read(imageDownloadServiceProvider.notifier);
      await downloadService.downloadRequiredResources();
    } catch (e) {
      print('[ImageResourceAdapter] 预加载图片异常: $e');
    }
  }

  /// 批量预加载图片
  Future<void> preloadImages(List<String> imageIds) async {
    try {
      final resources = <ImageResource>[];
      
      for (final imageId in imageIds) {
        final resource = getImageResource(imageId);
        if (resource != null && !isImageAvailable(imageId)) {
          resources.add(resource);
        }
      }

      if (resources.isNotEmpty) {
        final downloadService = _ref.read(imageDownloadServiceProvider.notifier);
        await downloadService.downloadAllResources();
      }
    } catch (e) {
      print('[ImageResourceAdapter] 批量预加载图片异常: $e');
    }
  }
}

/// 图片资源适配器Provider
final imageResourceAdapterProvider = Provider<ImageResourceAdapter>((ref) {
  return ImageResourceAdapter(ref);
});

/// 图片路径Provider - 用于替换现有的图片路径逻辑
final imagePathProvider = Provider.family<String, String>((ref, imageId) {
  try {
    final adapter = ref.read(imageResourceAdapterProvider);
    final resource = adapter.getImageResource(imageId);
    
    if (resource != null) {
      return adapter.getImagePath(imageId, resource.url);
    }
    
    // 回退到本地路径
    return _getFallbackPath(imageId);
  } catch (e) {
    print('[ImagePathProvider] 获取图片路径异常: $e');
    return _getFallbackPath(imageId);
  }
});

/// 获取回退路径
String _getFallbackPath(String imageId) {
  // 根据图片ID推断本地路径
  if (imageId.startsWith('level_a_')) {
    return 'assets/pic_level/a/$imageId.png';
  } else if (imageId.startsWith('level_b_')) {
    return 'assets/pic_level/b/$imageId.png';
  } else if (imageId.startsWith('level_c_')) {
    return 'assets/pic_level/c/$imageId.png';
  } else if (imageId.startsWith('secret_')) {
    return 'assets/pic_secret/a/$imageId.png';
  } else if (imageId.startsWith('pass_c_')) {
    return 'assets/pic_pass/c/$imageId.png';
  }
  
  return 'assets/images/$imageId.png';
}

/// 图片可用性Provider
final imageAvailabilityProvider = Provider.family<bool, String>((ref, imageId) {
  try {
    final adapter = ref.read(imageResourceAdapterProvider);
    return adapter.isImageAvailable(imageId);
  } catch (e) {
    print('[ImageAvailabilityProvider] 检查图片可用性异常: $e');
    return false;
  }
});

/// 下载进度Provider
final downloadProgressProvider = Provider<Map<String, int>>((ref) {
  try {
    final adapter = ref.read(imageResourceAdapterProvider);
    return adapter.getDownloadProgress();
  } catch (e) {
    print('[DownloadProgressProvider] 获取下载进度异常: $e');
    return {};
  }
});
