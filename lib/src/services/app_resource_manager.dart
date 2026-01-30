import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_config_service.dart';
import '../services/image_download_service.dart';
import '../providers/user_type_provider.dart';

/// 应用启动资源管理服务
class AppResourceManager {
  final Ref _ref;
  
  AppResourceManager(this._ref);

  /// 应用启动时的资源初始化流程
  Future<void> initializeAppResources() async {
    try {
      print('[AppResourceManager] 开始应用资源初始化');
      
      // 1. 获取用户类型
      final userType = _ref.read(userTypeProvider);
      print('[AppResourceManager] 用户类型: ${userType.name}');
      
      // 2. 加载Firebase配置
      await _loadFirebaseConfig(userType);
      
      // 3. 检查本地资源
      await _checkLocalResources();
      
      // 4. 启动必需资源下载
      await _downloadRequiredResources();
      
      // 5. 启动后台资源下载
      _startBackgroundDownload();
      
      print('[AppResourceManager] 应用资源初始化完成');
    } catch (e) {
      print('[AppResourceManager] 资源初始化异常: $e');
    }
  }

  /// 加载Firebase配置
  Future<void> _loadFirebaseConfig(UserType userType) async {
    try {
      print('[AppResourceManager] 加载Firebase配置...');
      
      final configNotifier = _ref.read(firebaseConfigProvider.notifier);
      await configNotifier.refresh();
      
      final config = _ref.read(firebaseConfigProvider).valueOrNull;
      if (config != null) {
        print('[AppResourceManager] 配置加载成功: version=${config.version}');
      } else {
        print('[AppResourceManager] 配置加载失败，使用本地资源');
      }
    } catch (e) {
      print('[AppResourceManager] 配置加载异常: $e');
    }
  }

  /// 检查本地资源
  Future<void> _checkLocalResources() async {
    try {
      print('[AppResourceManager] 检查本地资源...');
      
      final downloadNotifier = _ref.read(imageDownloadServiceProvider.notifier);
      final config = _ref.read(firebaseConfigProvider).valueOrNull;
      
      if (config == null) {
        print('[AppResourceManager] 无配置信息，跳过资源检查');
        return;
      }
      
      // 检查必需资源是否已缓存
      final requiredResources = _ref.read(firebaseConfigServiceProvider)
          .getRequiredImageResources(config);
      
      int cachedCount = 0;
      for (final resource in requiredResources) {
        if (downloadNotifier.isImageCached(resource.id)) {
          cachedCount++;
        }
      }
      
      print('[AppResourceManager] 本地资源检查完成: $cachedCount/${requiredResources.length} 必需资源已缓存');
    } catch (e) {
      print('[AppResourceManager] 本地资源检查异常: $e');
    }
  }

  /// 下载必需资源
  Future<void> _downloadRequiredResources() async {
    try {
      print('[AppResourceManager] 开始下载必需资源...');
      
      final downloadNotifier = _ref.read(imageDownloadServiceProvider.notifier);
      await downloadNotifier.downloadRequiredResources();
      
      print('[AppResourceManager] 必需资源下载完成');
    } catch (e) {
      print('[AppResourceManager] 必需资源下载异常: $e');
    }
  }

  /// 启动后台下载
  void _startBackgroundDownload() {
    try {
      print('[AppResourceManager] 启动后台资源下载...');
      
      // 延迟启动后台下载，避免影响应用启动速度
      Future.delayed(const Duration(seconds: 5), () async {
        final downloadNotifier = _ref.read(imageDownloadServiceProvider.notifier);
        await downloadNotifier.downloadAllResources();
        print('[AppResourceManager] 后台资源下载完成');
      });
    } catch (e) {
      print('[AppResourceManager] 后台下载启动异常: $e');
    }
  }

  /// 检查资源是否可用
  bool isResourceAvailable(String resourceId) {
    try {
      final downloadNotifier = _ref.read(imageDownloadServiceProvider.notifier);
      return downloadNotifier.isImageCached(resourceId);
    } catch (e) {
      print('[AppResourceManager] 资源可用性检查异常: $e');
      return false;
    }
  }

  /// 获取资源路径
  String? getResourcePath(String resourceId) {
    try {
      final downloadNotifier = _ref.read(imageDownloadServiceProvider.notifier);
      return downloadNotifier.getImagePath(resourceId);
    } catch (e) {
      print('[AppResourceManager] 获取资源路径异常: $e');
      return null;
    }
  }

  /// 获取资源URL（优先本地，其次网络）
  String getResourceUrl(String resourceId, String networkUrl) {
    try {
      final localPath = getResourcePath(resourceId);
      if (localPath != null) {
        return localPath;
      }
      return networkUrl;
    } catch (e) {
      print('[AppResourceManager] 获取资源URL异常: $e');
      return networkUrl;
    }
  }

  /// 强制刷新配置
  Future<void> refreshConfig() async {
    try {
      print('[AppResourceManager] 强制刷新配置...');
      
      final configNotifier = _ref.read(firebaseConfigProvider.notifier);
      await configNotifier.refresh();
      
      // 重新检查资源
      await _checkLocalResources();
      
      print('[AppResourceManager] 配置刷新完成');
    } catch (e) {
      print('[AppResourceManager] 配置刷新异常: $e');
    }
  }

  /// 清理所有缓存
  Future<void> clearAllCache() async {
    try {
      print('[AppResourceManager] 清理所有缓存...');
      
      final downloadNotifier = _ref.read(imageDownloadServiceProvider.notifier);
      await downloadNotifier.clearCache();
      
      print('[AppResourceManager] 缓存清理完成');
    } catch (e) {
      print('[AppResourceManager] 缓存清理异常: $e');
    }
  }
}

/// 应用资源管理器Provider
final appResourceManagerProvider = Provider<AppResourceManager>((ref) {
  return AppResourceManager(ref);
});

/// 资源状态Provider
final resourceStatusProvider = StateProvider<ResourceStatus>((ref) {
  return const ResourceStatus(
    isInitialized: false,
    isDownloading: false,
    progress: 0,
    error: null,
  );
});

/// 资源状态
class ResourceStatus {
  final bool isInitialized;
  final bool isDownloading;
  final int progress; // 0-100
  final String? error;

  const ResourceStatus({
    this.isInitialized = false,
    this.isDownloading = false,
    this.progress = 0,
    this.error,
  });

  ResourceStatus copyWith({
    bool? isInitialized,
    bool? isDownloading,
    int? progress,
    String? error,
  }) {
    return ResourceStatus(
      isInitialized: isInitialized ?? this.isInitialized,
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}
