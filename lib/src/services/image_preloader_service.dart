import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/firebase_config.dart';
import '../providers/user_type_provider.dart';
import 'firebase_config_service.dart';
import 'image_loader_service.dart';
import 'level_image_sequence_service.dart';
import 'logger.dart';

/// 图片预加载服务
class ImagePreloaderService {
  static final ImagePreloaderService _instance = ImagePreloaderService._internal();
  factory ImagePreloaderService() => _instance;
  ImagePreloaderService._internal();

  final Map<String, ImageProvider> _preloadedImages = {};
  final Set<String> _preloadingImages = {};
  
  /// 预加载所有配置图片
  Future<void> preloadAllImages(WidgetRef ref, BuildContext context) async {
    try {
      Log.game('🚀 开始预加载所有图片...');
      
      // 获取用户类型和配置
      final userType = ref.read(userTypeProvider);
      final configService = FirebaseConfigService();
      final config = configService.getDefaultConfig(userType);
      
      // config不会为null，因为getDefaultConfig总是返回一个配置
      
      // 获取所有图片资源
      final allResources = configService.getAllImageResources(config);
      Log.game('📦 需要预加载的图片总数: ${allResources.length}');
      
      // 按优先级分组预加载
      await _preloadByPriority(ref, allResources, userType, config, context);
      
      Log.game('✅ 图片预加载完成');
      
    } catch (e) {
      Log.e('PRELOADER', '❌ 图片预加载异常: $e');
    }
  }
  
  /// 按优先级预加载图片
  Future<void> _preloadByPriority(WidgetRef ref, List<ImageResource> resources, UserType userType, FirebaseConfig config, BuildContext context) async {
    // 按优先级分组
    final Map<int, List<ImageResource>> priorityGroups = {};
    for (final resource in resources) {
      priorityGroups.putIfAbsent(resource.priority, () => []).add(resource);
    }
    
    // 按优先级从高到低排序
    final sortedPriorities = priorityGroups.keys.toList()..sort((a, b) => b.compareTo(a));
    
    Log.game('📊 优先级分组: ${sortedPriorities.map((p) => 'P$p(${priorityGroups[p]!.length}张)').join(', ')}');
    
    // 分批预加载
    for (final priority in sortedPriorities) {
      final groupResources = priorityGroups[priority]!;
      Log.game('🔄 开始预加载优先级 $priority (${groupResources.length}张图片)');
      
      await _preloadBatch(ref, groupResources, userType, config, context);
      
      // 每组之间稍作延迟，避免阻塞UI
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
  
  /// 批量预加载图片
  Future<void> _preloadBatch(WidgetRef ref, List<ImageResource> resources, UserType userType, FirebaseConfig config, BuildContext context) async {
    final imageLoader = ImageLoaderService();
    final List<Future<void>> preloadTasks = [];
    
    // 限制并发数量，避免内存压力
    const maxConcurrent = 5;
    for (int i = 0; i < resources.length; i += maxConcurrent) {
      final batch = resources.skip(i).take(maxConcurrent);
      
      for (final resource in batch) {
        if (!_preloadedImages.containsKey(resource.id) && !_preloadingImages.contains(resource.id)) {
          preloadTasks.add(_preloadSingleImage(ref, resource, userType, config, imageLoader, context));
        }
      }
      
      // 等待当前批次完成
      if (preloadTasks.isNotEmpty) {
        await Future.wait(preloadTasks);
        preloadTasks.clear();
      }
    }
  }
  
  /// 预加载单个图片
  Future<void> _preloadSingleImage(WidgetRef ref, ImageResource resource, UserType userType, FirebaseConfig config, ImageLoaderService imageLoader, BuildContext context) async {
    try {
      _preloadingImages.add(resource.id);
      
      // 检查是否应该使用网络图片
      final shouldUseNetwork = imageLoader.shouldLoadFromNetwork(resource.id, userType, config);
      
      if (shouldUseNetwork && resource.url.isNotEmpty) {
        // 预加载网络图片
        await _preloadNetworkImage(resource.url, resource.id, context);
      } else {
        // 预加载本地图片
        final localPath = imageLoader.getLocalImagePath(resource.id);
        await _preloadLocalImage(localPath, resource.id, context);
      }
      
      // Log.game('✅ 预加载完成: ${resource.id}');
      
    } catch (e) {
      Log.w('PRELOADER', '⚠️ 预加载失败: ${resource.id} - $e');
    } finally {
      _preloadingImages.remove(resource.id);
    }
  }
  
  /// 预加载网络图片
  Future<void> _preloadNetworkImage(String url, String imageId, BuildContext context) async {
    try {
      // 使用CachedNetworkImage预加载
      final imageProvider = CachedNetworkImageProvider(url);
      await precacheImage(imageProvider, context);
      _preloadedImages[imageId] = imageProvider;
    } catch (e) {
      // Log.w('PRELOADER', '⚠️ 网络图片预加载失败: $url - $e');
    }
  }
  
  /// 预加载本地图片
  Future<void> _preloadLocalImage(String path, String imageId, BuildContext context) async {
    try {
      final imageProvider = AssetImage(path);
      await precacheImage(imageProvider, context);
      _preloadedImages[imageId] = imageProvider;
    } catch (e) {
      Log.w('PRELOADER', '⚠️ 本地图片预加载失败: $path - $e');
    }
  }
  
  /// 预加载必需图片（高优先级）
  Future<void> preloadRequiredImages(WidgetRef ref, BuildContext context) async {
    try {
      Log.game('🚀 开始预加载必需图片...');
      
      final userType = ref.read(userTypeProvider);
      final configService = FirebaseConfigService();
      final config = configService.getDefaultConfig(userType);
      
      // config不会为null，因为getDefaultConfig总是返回一个配置
      
      // 只预加载必需图片
      final requiredResources = configService.getRequiredImageResources(config);
      Log.game('📦 必需图片数量: ${requiredResources.length}');
      
      await _preloadBatch(ref, requiredResources, userType, config, context);
      
      Log.game('✅ 必需图片预加载完成');
      
    } catch (e) {
      Log.e('PRELOADER', '❌ 必需图片预加载异常: $e');
    }
  }
  
  /// 预加载四选一弹窗的下一组 4 张图（不消费序列，可做启动首组或弹窗下一组）
  Future<void> preloadNextLevelGroup(WidgetRef ref, BuildContext context) async {
    try {
      final userType = ref.read(userTypeProvider);
      final configService = FirebaseConfigService();
      final config = configService.getDefaultConfig(userType);
      final bTotal = configService.getTotalCountForLevelType('b', config);
      final cTotal = configService.getTotalCountForLevelType('c', config);
      final indices = LevelImageSequenceService().peekNextGroup(bTotal, cTotal);
      final imageIds = [
        for (var i = 0; i < indices.length; i++)
          i < 2 ? 'level_b_${indices[i] + 1}' : 'level_c_${indices[i] + 1}',
      ];
      await preloadSpecificImages(ref, imageIds, context);
    } catch (e) {
      Log.e('PRELOADER', '❌ 四选一预加载异常: $e');
    }
  }

  /// 预加载特定图片ID列表
  Future<void> preloadSpecificImages(WidgetRef ref, List<String> imageIds, BuildContext context) async {
    try {
      Log.game('🚀 开始预加载指定图片: ${imageIds.length}张');
      
      final userType = ref.read(userTypeProvider);
      final configService = FirebaseConfigService();
      final config = configService.getDefaultConfig(userType);
      
      // config不会为null，因为getDefaultConfig总是返回一个配置
      
      final imageLoader = ImageLoaderService();
      final List<Future<void>> tasks = [];
      
      for (final imageId in imageIds) {
        if (!_preloadedImages.containsKey(imageId) && !_preloadingImages.contains(imageId)) {
          // 创建临时资源对象
          final resource = ImageResource(
            id: imageId,
            url: imageLoader.getNetworkImageUrl(imageId, config) ?? '',
            priority: 5,
            isRequired: false,
            localPath: imageLoader.getLocalImagePath(imageId),
            size: 0,
            checksum: '',
          );
          
          tasks.add(_preloadSingleImage(ref, resource, userType, config, imageLoader, context));
        }
      }
      
      await Future.wait(tasks);
      
      Log.game('✅ 指定图片预加载完成');
      
    } catch (e) {
      Log.e('PRELOADER', '❌ 指定图片预加载异常: $e');
    }
  }
  
  /// 检查图片是否已预加载
  bool isImagePreloaded(String imageId) {
    return _preloadedImages.containsKey(imageId);
  }
  
  /// 获取预加载的图片Provider
  ImageProvider? getPreloadedImage(String imageId) {
    return _preloadedImages[imageId];
  }
  
  /// 清理预加载缓存
  void clearPreloadedCache() {
    _preloadedImages.clear();
    _preloadingImages.clear();
    Log.game('🧹 预加载缓存已清理');
  }
  
  /// 获取预加载统计信息
  Map<String, dynamic> getPreloadStats() {
    return {
      'preloadedCount': _preloadedImages.length,
      'preloadingCount': _preloadingImages.length,
      'preloadedImages': _preloadedImages.keys.toList(),
      'preloadingImages': _preloadingImages.toList(),
    };
  }
}

/// 图片预加载服务Provider
final imagePreloaderServiceProvider = Provider<ImagePreloaderService>((ref) {
  return ImagePreloaderService();
});
