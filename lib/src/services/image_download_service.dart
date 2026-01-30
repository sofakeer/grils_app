import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/firebase_config.dart';
import '../services/firebase_config_service.dart';

/// 图片下载和缓存服务
class ImageDownloadService {
  static const String _cacheDirName = 'image_cache';
  static const String _manifestFileName = 'image_manifest.json';
  
  Directory? _cacheDir;
  Map<String, DownloadTask> _downloadTasks = {};
  
  /// 初始化缓存目录
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/$_cacheDirName');
      
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
        print('[ImageDownload] 创建缓存目录: ${_cacheDir!.path}');
      }
      
      await _loadManifest();
      print('[ImageDownload] 缓存服务初始化完成');
    } catch (e) {
      print('[ImageDownload] 初始化异常: $e');
    }
  }

  /// 加载本地清单
  Future<void> _loadManifest() async {
    try {
      final manifestFile = File('${_cacheDir!.path}/$_manifestFileName');
      if (await manifestFile.exists()) {
        final content = await manifestFile.readAsString();
        final Map<String, dynamic> manifest = jsonDecode(content);
        
        _downloadTasks = manifest.map((key, value) {
          final taskData = value as Map<String, dynamic>;
          return MapEntry(key, DownloadTask(
            id: taskData['id'] ?? key,
            url: taskData['url'] ?? '',
            localPath: taskData['localPath'] ?? '',
            priority: taskData['priority'] ?? 5,
            status: DownloadStatus.values.firstWhere(
              (e) => e.name == taskData['status'],
              orElse: () => DownloadStatus.pending,
            ),
            progress: taskData['progress'] ?? 0,
            error: taskData['error'],
          ));
        });
        
        print('[ImageDownload] 加载本地清单: ${_downloadTasks.length} 个任务');
      }
    } catch (e) {
      print('[ImageDownload] 加载清单异常: $e');
    }
  }

  /// 保存本地清单
  Future<void> _saveManifest() async {
    try {
      final manifestFile = File('${_cacheDir!.path}/$_manifestFileName');
      final manifest = _downloadTasks.map((key, value) {
        return MapEntry(key, {
          'id': value.id,
          'url': value.url,
          'localPath': value.localPath,
          'priority': value.priority,
          'status': value.status.name,
          'progress': value.progress,
          'error': value.error,
        });
      });
      
      await manifestFile.writeAsString(jsonEncode(manifest));
      print('[ImageDownload] 保存本地清单完成');
    } catch (e) {
      print('[ImageDownload] 保存清单异常: $e');
    }
  }

  /// 检查图片是否已缓存
  bool isImageCached(String imageId) {
    final task = _downloadTasks[imageId];
    if (task == null) return false;
    
    if (task.status == DownloadStatus.completed || task.status == DownloadStatus.cached) {
      return File(task.localPath).existsSync();
    }
    
    return false;
  }

  /// 获取图片本地路径
  String? getImageLocalPath(String imageId) {
    final task = _downloadTasks[imageId];
    if (task == null) return null;
    
    if (isImageCached(imageId)) {
      return task.localPath;
    }
    
    return null;
  }

  /// 获取图片URL（如果未缓存则返回网络URL）
  String getImageUrl(String imageId, String networkUrl) {
    if (isImageCached(imageId)) {
      return getImageLocalPath(imageId)!;
    }
    return networkUrl;
  }

  /// 开始下载任务
  Future<void> startDownloadTasks(List<ImageResource> resources) async {
    print('[ImageDownload] 开始下载任务: ${resources.length} 个资源');
    
    // 创建下载任务
    for (final resource in resources) {
      if (!isImageCached(resource.id)) {
        final localPath = '${_cacheDir!.path}/${resource.id}';
        _downloadTasks[resource.id] = DownloadTask(
          id: resource.id,
          url: resource.url,
          localPath: localPath,
          priority: resource.priority,
          status: DownloadStatus.pending,
        );
      }
    }
    
    await _saveManifest();
    
    // 按优先级排序并开始下载
    final sortedTasks = _downloadTasks.values
        .where((task) => task.status == DownloadStatus.pending)
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    
    // 并发下载（限制并发数）
    const maxConcurrent = 3;
    for (int i = 0; i < sortedTasks.length; i += maxConcurrent) {
      final batch = sortedTasks.skip(i).take(maxConcurrent);
      await Future.wait(batch.map((task) => _downloadImage(task)));
    }
    
    print('[ImageDownload] 所有下载任务完成');
  }

  /// 下载单个图片
  Future<void> _downloadImage(DownloadTask task) async {
    try {
      print('[ImageDownload] 开始下载: ${task.id}');
      
      // 更新状态为下载中
      _downloadTasks[task.id] = task.copyWith(status: DownloadStatus.downloading);
      await _saveManifest();
      
      // 下载文件
      final response = await HttpClient().getUrl(Uri.parse(task.url));
      final request = await response.close();
      
      final file = File(task.localPath);
      final sink = file.openWrite();
      
      int totalBytes = 0;
      int receivedBytes = 0;
      
      if (response.contentLength != -1) {
        totalBytes = response.contentLength;
      }
      
      await for (final data in request) {
        sink.add(data);
        receivedBytes += data.length;
        
        if (totalBytes > 0) {
          final progress = (receivedBytes / totalBytes * 100).round();
          _downloadTasks[task.id] = task.copyWith(progress: progress);
        }
      }
      
      await sink.close();
      
      // 验证文件完整性
      if (await _verifyFile(task)) {
        _downloadTasks[task.id] = task.copyWith(
          status: DownloadStatus.completed,
          progress: 100,
        );
        print('[ImageDownload] 下载完成: ${task.id}');
      } else {
        _downloadTasks[task.id] = task.copyWith(
          status: DownloadStatus.failed,
          error: '文件校验失败',
        );
        print('[ImageDownload] 文件校验失败: ${task.id}');
      }
      
      await _saveManifest();
      
    } catch (e) {
      _downloadTasks[task.id] = task.copyWith(
        status: DownloadStatus.failed,
        error: e.toString(),
      );
      await _saveManifest();
      print('[ImageDownload] 下载失败: ${task.id}, 错误: $e');
    }
  }

  /// 验证文件完整性
  Future<bool> _verifyFile(DownloadTask task) async {
    try {
      final file = File(task.localPath);
      if (!await file.exists()) return false;
      
      // 这里可以添加MD5校验等
      // 暂时只检查文件是否存在且大小大于0
      final stat = await file.stat();
      return stat.size > 0;
    } catch (e) {
      print('[ImageDownload] 文件验证异常: $e');
      return false;
    }
  }

  /// 清理缓存
  Future<void> clearCache() async {
    try {
      if (_cacheDir != null && await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create(recursive: true);
        _downloadTasks.clear();
        await _saveManifest();
        print('[ImageDownload] 缓存清理完成');
      }
    } catch (e) {
      print('[ImageDownload] 缓存清理异常: $e');
    }
  }

  /// 获取缓存大小
  Future<int> getCacheSize() async {
    try {
      if (_cacheDir == null || !await _cacheDir!.exists()) return 0;
      
      int totalSize = 0;
      await for (final entity in _cacheDir!.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      print('[ImageDownload] 获取缓存大小异常: $e');
      return 0;
    }
  }

  /// 获取下载进度
  Map<String, int> getDownloadProgress() {
    final total = _downloadTasks.length;
    final completed = _downloadTasks.values
        .where((task) => task.status == DownloadStatus.completed)
        .length;
    
    return {
      'total': total,
      'completed': completed,
      'progress': total > 0 ? (completed / total * 100).round() : 0,
    };
  }
}

/// 图片下载服务Provider
final imageDownloadServiceProvider = StateNotifierProvider<ImageDownloadNotifier, ImageDownloadState>((ref) {
  return ImageDownloadNotifier(ref);
});

/// 图片下载状态
class ImageDownloadState {
  final bool isInitialized;
  final bool isDownloading;
  final Map<String, int> progress;
  final String? error;

  const ImageDownloadState({
    this.isInitialized = false,
    this.isDownloading = false,
    this.progress = const {},
    this.error,
  });

  ImageDownloadState copyWith({
    bool? isInitialized,
    bool? isDownloading,
    Map<String, int>? progress,
    String? error,
  }) {
    return ImageDownloadState(
      isInitialized: isInitialized ?? this.isInitialized,
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}

class ImageDownloadNotifier extends StateNotifier<ImageDownloadState> {
  final Ref _ref;
  ImageDownloadService? _service;

  ImageDownloadNotifier(this._ref) : super(const ImageDownloadState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _service = ImageDownloadService();
      await _service!.initialize();
      
      state = state.copyWith(isInitialized: true);
      print('[ImageDownload] 服务初始化完成');
    } catch (e) {
      state = state.copyWith(error: e.toString());
      print('[ImageDownload] 服务初始化异常: $e');
    }
  }

  /// 开始下载必需资源
  Future<void> downloadRequiredResources() async {
    if (_service == null || !state.isInitialized) return;
    
    try {
      state = state.copyWith(isDownloading: true, error: null);
      
      final config = _ref.read(firebaseConfigProvider).valueOrNull;
      if (config == null) {
        state = state.copyWith(isDownloading: false, error: '配置未加载');
        return;
      }
      
      final requiredResources = _ref.read(firebaseConfigServiceProvider).getRequiredImageResources(config);
      await _service!.startDownloadTasks(requiredResources);
      
      final progress = _service!.getDownloadProgress();
      state = state.copyWith(
        isDownloading: false,
        progress: progress,
      );
      
      print('[ImageDownload] 必需资源下载完成: $progress');
    } catch (e) {
      state = state.copyWith(isDownloading: false, error: e.toString());
      print('[ImageDownload] 必需资源下载异常: $e');
    }
  }

  /// 开始下载所有资源
  Future<void> downloadAllResources() async {
    if (_service == null || !state.isInitialized) return;
    
    try {
      state = state.copyWith(isDownloading: true, error: null);
      
      final config = _ref.read(firebaseConfigProvider).valueOrNull;
      if (config == null) {
        state = state.copyWith(isDownloading: false, error: '配置未加载');
        return;
      }
      
      final allResources = _ref.read(firebaseConfigServiceProvider).getAllImageResources(config);
      await _service!.startDownloadTasks(allResources);
      
      final progress = _service!.getDownloadProgress();
      state = state.copyWith(
        isDownloading: false,
        progress: progress,
      );
      
      print('[ImageDownload] 所有资源下载完成: $progress');
    } catch (e) {
      state = state.copyWith(isDownloading: false, error: e.toString());
      print('[ImageDownload] 所有资源下载异常: $e');
    }
  }

  /// 检查图片是否已缓存
  bool isImageCached(String imageId) {
    return _service?.isImageCached(imageId) ?? false;
  }

  /// 获取图片路径
  String? getImagePath(String imageId) {
    return _service?.getImageLocalPath(imageId);
  }

  /// 清理缓存
  Future<void> clearCache() async {
    await _service?.clearCache();
    state = state.copyWith(progress: const {});
  }
}
