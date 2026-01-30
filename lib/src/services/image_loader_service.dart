import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_type_provider.dart';
import 'firebase_config_service.dart';
import '../models/firebase_config.dart';
import '../utils/game_logger.dart';
import '../utils/secret_image_utils.dart';

/// 图片加载器服务
class ImageLoaderService {
  static final ImageLoaderService _instance = ImageLoaderService._internal();
  factory ImageLoaderService() => _instance;
  ImageLoaderService._internal();

  /// 获取图片URL
  String? getImageUrl(String imageId, UserType userType, FirebaseConfig? config) {
    if (config == null) return null;
    
    // 解析imageId获取类型和索引
    final parts = imageId.split('_');
    if (parts.length < 3) return null;
    
    final type = parts[1]; // a, b, c
    final index = int.tryParse(parts[2]);
    if (index == null) return null;
    
    // 根据用户类型和图片类型获取配置
    switch (userType) {
      case UserType.natural:
        // 自然用户只处理A类图片
        if (type == 'a' && config.images.levelA.totalCount > 0) {
          if (index >= 1 && index <= config.images.levelA.totalCount) {
            return config.images.levelA.baseUrl + 
                   config.images.levelA.fileNamePattern.replaceAll('{index}', index.toString());
          }
        }
        break;
      case UserType.paid:
        // 买量用户处理B类和C类图片
        if (type == 'b' && config.images.levelB.totalCount > 0) {
          if (index >= 1 && index <= config.images.levelB.totalCount) {
            return config.images.levelB.baseUrl + 
                   config.images.levelB.fileNamePattern.replaceAll('{index}', index.toString());
          }
        } else if (type == 'c' && config.images.levelC.totalCount > 0) {
          if (index >= 1 && index <= config.images.levelC.totalCount) {
            return config.images.levelC.baseUrl + 
                   config.images.levelC.fileNamePattern.replaceAll('{index}', index.toString());
          }
        }
        break;
    }
    
    return null;
  }

  /// 获取本地图片路径
  String getLocalImagePath(String imageId, [FirebaseConfig? config]) {
    final parts = imageId.split('_');
    // level_* 使用静态或配置的本地模板
    if (parts.length >= 3 && parts[0] == 'level') {
      final type = parts[1];
      final index = parts[2];
      String localPath;
      if (config != null) {
        switch (type) {
          case 'a':
            if (config.images.levelA.localPathPattern.isNotEmpty) {
              return config.images.levelA.localPathPattern.replaceAll('{index}', index);
            }
            break;
          case 'b':
            if (config.images.levelB.localPathPattern.isNotEmpty) {
              return config.images.levelB.localPathPattern.replaceAll('{index}', index);
            }
            break;
          case 'c':
            if (config.images.levelC.localPathPattern.isNotEmpty) {
              return config.images.levelC.localPathPattern.replaceAll('{index}', index);
            }
            break;
        }
      }
      return 'assets/pic_level/$type/level_${type}_$index.png';
    }
    // secret_{setId}_{slot}
    if (parts.length >= 3 && parts[0] == 'secret') {
      final setId = int.tryParse(parts[1]);
      final slot = int.tryParse(parts[2]);
      if (config != null && setId != null && slot != null) {
        final set = config.secrets.sets.firstWhere(
          (s) => s.setId == setId,
          orElse: () => config.secrets.sets.isNotEmpty
              ? config.secrets.sets.first
              : SecretSet(
                  setId: 0,
                  title: '',
                  unlockLevel: 1,
                  fileNamePattern: '',
                  localPathPattern: '',
                  slotCount: 0,
                  priority: 1,
                ),
        );
        if (set.localPathPattern.isNotEmpty) {
          final resolved = set.localPathPattern
              .replaceAll('{slot}', slot.toString())
              .replaceAll('{setId}', setId.toString())
              .replaceAll('{type}', SecretImageUtils.typeLetter(slot));
          final expected = 'secret_${setId}_${SecretImageUtils.typeLetter(slot)}_$slot';
          if (resolved.contains(expected)) {
            return resolved;
          }
          final directory = _extractDirectory(set.localPathPattern);
          final extension = _extractExtension(set.localPathPattern);
          if (directory.isNotEmpty) {
            return directory + expected + extension;
          }
        }
      }
      final fallbackType = slot != null ? SecretImageUtils.typeLetter(slot) : 'b';
      // 兜底：老命名兼容
      return 'assets/pic_secret/b/secret_${parts[1]}_${fallbackType}_${parts[2]}.png';
    }
    // pass_c_{index} - TREASURE图片
    if (parts.length >= 3 && parts[0] == 'pass') {
      final type = parts[1]; // 通常是 'c'
      final index = parts[2];
      if (config != null && config.treasure.localPathPattern.isNotEmpty) {
        return config.treasure.localPathPattern.replaceAll('{index}', index);
      }
      // 回退到默认路径
      return 'assets/pic_pass/$type/pass_${type}_$index.png';
    }
    return 'assets/pic_level/b/level_b_1.png';
  }

  /// 获取网络图片URL
  String? getNetworkImageUrl(String imageId, FirebaseConfig? config) {
    final parts = imageId.split('_');
    // level_* 使用配置生成
    if (parts.length >= 3 && parts[0] == 'level') {
      final type = parts[1];
      final index = parts[2];
      String? networkUrl;
      if (config != null) {
        switch (type) {
          case 'a':
            if (config.images.levelA.baseUrl.isNotEmpty && config.images.levelA.fileNamePattern.isNotEmpty) {
              return config.images.levelA.baseUrl + config.images.levelA.fileNamePattern.replaceAll('{index}', index);
            }
            break;
          case 'b':
            if (config.images.levelB.baseUrl.isNotEmpty && config.images.levelB.fileNamePattern.isNotEmpty) {
              return config.images.levelB.baseUrl + config.images.levelB.fileNamePattern.replaceAll('{index}', index);
            }
            break;
          case 'c':
            if (config.images.levelC.baseUrl.isNotEmpty && config.images.levelC.fileNamePattern.isNotEmpty) {
              return config.images.levelC.baseUrl + config.images.levelC.fileNamePattern.replaceAll('{index}', index);
            }
            break;
        }
      }
      // 兜底静态
      switch (type) {
        case 'a':
          return 'https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/level_a_$index.png';
        case 'b':
          return 'https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/level_b_$index.png';
        case 'c':
          return 'https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/level_c_$index.png';
      }
    }
    // secret_{setId}_{slot} 使用配置生成
    if (parts.length >= 3 && parts[0] == 'secret') {
      final setId = int.tryParse(parts[1]);
      final slot = int.tryParse(parts[2]);
      if (setId != null && slot != null) {
        final type = SecretImageUtils.typeLetter(slot);
        if (config != null) {
          final set = config.secrets.sets.firstWhere(
            (s) => s.setId == setId,
            orElse: () => config.secrets.sets.isNotEmpty
                ? config.secrets.sets.first
                : SecretSet(
                    setId: 0,
                    title: '',
                    unlockLevel: 1,
                    fileNamePattern: '',
                    localPathPattern: '',
                    slotCount: 0,
                    priority: 1,
                  ),
          );
          final baseUrl = config.secrets.baseUrl;
          if (baseUrl.isNotEmpty) {
            String fileName;
            if (set.fileNamePattern.isNotEmpty) {
              fileName = set.fileNamePattern
                  .replaceAll('{slot}', slot.toString())
                  .replaceAll('{setId}', setId.toString())
                  .replaceAll('{type}', type);
              final expected = 'secret_${setId}_${type}_$slot';
              if (!fileName.contains(expected)) {
                final extension = _extractExtension(set.fileNamePattern);
                fileName = '$expected$extension';
              }
            } else {
              fileName = 'secret_${setId}_${type}_$slot.png';
            }
            final url = baseUrl + fileName;
            GameLogger.log(
              GameLogger.tagAlbum,
              'resolve secret network url: imageId=$imageId, url=$url',
            );
            return url;
          }
        }
        final url = 'https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/secret_${setId}_${type}_$slot.png';
        GameLogger.log(
          GameLogger.tagAlbum,
          'fallback secret network url: imageId=$imageId, url=$url',
        );
        return url;
      }
    }
    // pass_c_{index} - TREASURE图片
    if (parts.length >= 3 && parts[0] == 'pass') {
      final type = parts[1]; // 通常是 'c'
      final index = parts[2];
      if (config != null && config.treasure.baseUrl.isNotEmpty && config.treasure.fileNamePattern.isNotEmpty) {
        return config.treasure.baseUrl + config.treasure.fileNamePattern.replaceAll('{index}', index);
      }
      // 回退到默认URL
      return 'https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/pass_${type}_$index.png';
    }
    return null;
  }

  /// 检查图片是否应该从网络加载
  bool shouldLoadFromNetwork(String imageId, UserType userType, FirebaseConfig? config) {
    if (config == null) {
      GameLogger.debug(GameLogger.tagAlbum, 'shouldLoadFromNetwork', 'config=null, imageId=' + imageId);
      return false;
    }
    // 解析imageId获取类型和索引
    final parts = imageId.split('_');
    if (parts.length < 3) {
      GameLogger.debug(GameLogger.tagAlbum, 'shouldLoadFromNetwork', 'invalid imageId=' + imageId);
      return false;
    }
    final category = parts[0];
    final type = parts[1]; // a, b, c 或其他
    final index = int.tryParse(parts[2]);
    if (index == null) {
      GameLogger.debug(GameLogger.tagAlbum, 'shouldLoadFromNetwork', 'index parse failed, imageId=' + imageId);
      return false;
    }
    if (category == 'secret') {
      final setId = int.tryParse(type);
      if (setId == null) {
        GameLogger.debug(GameLogger.tagAlbum, 'shouldLoadFromNetwork', 'secret setId parse failed, imageId=' + imageId);
        return false;
      }
      switch (userType) {
        case UserType.natural:
          GameLogger.debug(GameLogger.tagAlbum, 'shouldLoadFromNetwork', 'natural user -> false (secret), id=' + imageId);
          return false;
        case UserType.paid:
          final hasBaseUrl = config.secrets.baseUrl.isNotEmpty;
          final bool should = hasBaseUrl;
          GameLogger.debug(
            GameLogger.tagAlbum,
            'shouldLoadFromNetwork',
            'paid user secret -> baseUrl=$hasBaseUrl, result=$should, id=' + imageId,
          );
          return should;
      }
    }
    if (category == 'pass') {
      // TREASURE图片的网络加载策略
      switch (userType) {
        case UserType.natural:
          GameLogger.debug(GameLogger.tagAlbum, 'shouldLoadFromNetwork', 'natural user -> false (treasure), id=' + imageId);
          return false;
        case UserType.paid:
          final hasBaseUrl = config.treasure.baseUrl.isNotEmpty;
          final bool should = hasBaseUrl;
          GameLogger.debug(
            GameLogger.tagAlbum,
            'shouldLoadFromNetwork',
            'paid user treasure -> baseUrl=$hasBaseUrl, result=$should, id=' + imageId,
          );
          return should;
      }
    }
    const localPriorityCount = 10;
    // 前 1-10 一律走本地（尤其是 assets/pic_level/ 的首批资源）
    // 但自然流量用户不受此限制，直接使用网络图片
    if (userType == UserType.paid && parts[0] == 'level' && index <= localPriorityCount) {
      GameLogger.debug(GameLogger.tagAlbum, 'shouldLoadFromNetwork', 'paid user force local for first $localPriorityCount: ' + imageId);
      return false;
    }
    
    // 根据用户类型和图片类型决定网络加载策略
    switch (userType) {
      case UserType.natural:
        if (type == 'a' &&
            config.images.levelA.baseUrl.isNotEmpty &&
            config.images.levelA.fileNamePattern.isNotEmpty &&
            index <= config.images.levelA.totalCount) {
          GameLogger.debug(
            GameLogger.tagAlbum,
            'shouldLoadFromNetwork',
            'natural user levelA -> true, id=' + imageId,
          );
          return true;
        }
        GameLogger.debug(
          GameLogger.tagAlbum,
          'shouldLoadFromNetwork',
          'natural user -> false, type=' + type + ', id=' + imageId,
        );
        return false;
      case UserType.paid:
        final res = (type == 'b' && config.images.levelB.totalCount > 0) ||
            (type == 'c' && config.images.levelC.totalCount > 0);
        GameLogger.debug(GameLogger.tagAlbum, 'shouldLoadFromNetwork', 'paid user, type=' + type + ', index=' + index.toString() + ' -> ' + res.toString());
        return res;
    }
  }

  /// 获取默认图片路径（用于回退）
  String getDefaultImagePath(String imageId) {
    final parts = imageId.split('_');
    if (parts.length >= 3) {
      final type = parts[1]; // a, b, c
      return 'assets/pic_level/$type/level_${type}_1.png';
    }
    
    return 'assets/pic_level/b/level_b_1.png'; // 默认使用B类图片
  }

  String _extractExtension(String pattern, {String fallback = '.png'}) {
    if (pattern.isEmpty) return fallback;
    final dotIndex = pattern.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == pattern.length - 1) {
      return fallback;
    }
    return pattern.substring(dotIndex);
  }

  String _extractDirectory(String pattern) {
    final slashIndex = pattern.lastIndexOf('/');
    if (slashIndex == -1) {
      return '';
    }
    return pattern.substring(0, slashIndex + 1);
  }
}

/// 图片加载器Provider
final imageLoaderServiceProvider = Provider<ImageLoaderService>((ref) {
  return ImageLoaderService();
});

/// 智能图片组件 - 支持在线图片和本地图片
class SmartImageWidget extends ConsumerWidget {
  final String? imageId; // 图片ID，用于智能选择本地或网络图片
  final String? imagePath; // 图片路径，可以是本地路径或网络URL
  final UserType? userType; // 用户类型，用于决定是否使用网络图片
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Alignment alignment;
  final int? reloadToken; // 重载令牌，用于强制重新加载图片（清除缓存）

  const SmartImageWidget({
    super.key,
    this.imageId,
    this.imagePath,
    this.userType,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.alignment = Alignment.center,
    this.reloadToken,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageLoader = ref.read(imageLoaderServiceProvider);
    
    // 优先使用 imageId 和 userType 进行智能选择
    if (imageId != null && userType != null) {
      return _buildSmartImage(ref, imageLoader, imageId!, userType!);
    }
    
    // 回退到 imagePath
    if (imagePath != null) {
      return _buildImageFromPath(ref, imageLoader, imagePath!);
    }
    
    // 如果都没有提供，显示错误
    return errorWidget ?? _buildErrorWidget();
  }

  /// 根据 imageId 和 userType 智能选择图片
  Widget _buildSmartImage(WidgetRef ref, ImageLoaderService imageLoader, String imageId, UserType userType) {
    // 获取 Firebase 配置
    final config = ref.read(firebaseConfigServiceProvider).getDefaultConfig(userType);
    
    // 检查是否应该使用网络图片
    final shouldUseNetwork = imageLoader.shouldLoadFromNetwork(imageId, userType, config);
    
    // 获取本地路径和网络URL（用于日志和回退）
    final localPath = imageLoader.getLocalImagePath(imageId, config);
    final networkUrl = imageLoader.getNetworkImageUrl(imageId, config);
    
    // 只在关键位置打印一次完整信息
    GameLogger.log(GameLogger.tagAlbum, '_buildSmartImage: imageId=$imageId, userType=$userType, shouldUseNetwork=$shouldUseNetwork, 本地路径=$localPath, 网络URL=${networkUrl ?? "null"}');
    
    if (shouldUseNetwork) {
      // 尝试使用网络图片
      if (networkUrl != null) {
        // 使用 reloadToken 在 URL 后添加查询参数，确保重试时绕过缓存
        final finalUrl = reloadToken != null 
            ? '${networkUrl}${networkUrl.contains('?') ? '&' : '?'}_reload=$reloadToken'
            : networkUrl;
        if (reloadToken != null) {
          GameLogger.log(GameLogger.tagAlbum, '重试加载图片: $imageId, reloadToken=$reloadToken, finalUrl=$finalUrl');
        }
        return CachedNetworkImage(
          imageUrl: finalUrl,
          // 使用包含 reloadToken 的 key，确保重试时重新创建 widget 并清除缓存
          key: reloadToken != null ? ValueKey('network_${imageId}_reload_$reloadToken') : null,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
          errorWidget: (context, url, error) {
            GameLogger.error(GameLogger.tagAlbum, 'Network image failed: imageId=$imageId, networkUrl=$networkUrl, error=$error');
            // 网络图片失败时回退到本地图片
            GameLogger.log(GameLogger.tagAlbum, '网络图片失败，回退到本地: imageId=$imageId, 网络URL=$networkUrl -> 本地路径=$localPath');
            return Image.asset(
              localPath,
              key: reloadToken != null ? ValueKey('asset_${localPath}_reload_$reloadToken') : null,
              width: width,
              height: height,
              fit: fit,
              alignment: alignment,
              errorBuilder: (context, error, stackTrace) {
                GameLogger.error(GameLogger.tagAlbum, 'Asset image failed in fallback: imageId=$imageId, 本地路径=$localPath, error=$error');
                return errorWidget ?? _buildErrorWidget();
              },
            );
          },
          // 优化内存缓存：使用更高的分辨率来保持图片清晰度
          memCacheWidth: _scaledCacheDimension(width),
          memCacheHeight: _scaledCacheDimension(height),
          // 添加图片质量优化
          filterQuality: FilterQuality.high,
          // 优化图片加载
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
        );
      }
    }
    
    // 使用本地图片
    return Image.asset(
      localPath,
      key: reloadToken != null ? ValueKey('asset_${localPath}_reload_$reloadToken') : null,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) {
        GameLogger.error(GameLogger.tagAlbum, 'Asset image failed: imageId=$imageId, 本地路径=$localPath, error=$error');
        // 本地图片失败时，尝试回退到网络图片（特别是前10张图片可能本地资源不存在）
        if (networkUrl != null) {
          GameLogger.log(GameLogger.tagAlbum, '本地图片失败，回退到网络图片: imageId=$imageId, 本地路径=$localPath -> 网络URL=$networkUrl');
          // 使用 reloadToken 在 URL 后添加查询参数，确保重试时绕过缓存
          final finalUrl = reloadToken != null 
              ? '${networkUrl}${networkUrl.contains('?') ? '&' : '?'}_reload=$reloadToken'
              : networkUrl;
          return CachedNetworkImage(
            imageUrl: finalUrl,
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
            errorWidget: (context, url, error) {
              GameLogger.error(GameLogger.tagAlbum, '网络图片也加载失败: imageId=$imageId, 本地路径=$localPath, 网络URL=$networkUrl, error=$error');
              return errorWidget ?? _buildErrorWidget();
            },
            // 优化内存缓存：使用更高的分辨率来保持图片清晰度
            memCacheWidth: _scaledCacheDimension(width),
            memCacheHeight: _scaledCacheDimension(height),
            // 添加图片质量优化
            filterQuality: FilterQuality.high,
            // 优化图片加载
            fadeInDuration: const Duration(milliseconds: 200),
            fadeOutDuration: const Duration(milliseconds: 100),
          );
        }
        return errorWidget ?? _buildErrorWidget();
      },
    );
  }

  /// 根据 imagePath 构建图片
  Widget _buildImageFromPath(WidgetRef ref, ImageLoaderService imageLoader, String imagePath) {
    GameLogger.debug(GameLogger.tagAlbum, '_buildImageFromPath', 'imagePath=' + imagePath);
    // 检查是否为直接的网络URL
    if (_isNetworkImage(imagePath)) {
      GameLogger.log(GameLogger.tagAlbum, 'Load network: ' + imagePath);
      // 使用 reloadToken 在 URL 后添加查询参数，确保重试时绕过缓存
      final finalUrl = reloadToken != null 
          ? '${imagePath}${imagePath.contains('?') ? '&' : '?'}_reload=$reloadToken'
          : imagePath;
      if (reloadToken != null) {
        GameLogger.log(GameLogger.tagAlbum, '重试加载网络图片: $imagePath, reloadToken=$reloadToken, finalUrl=$finalUrl');
      }
      return CachedNetworkImage(
        imageUrl: finalUrl,
        // 使用包含 reloadToken 的 key，确保重试时重新创建 widget 并清除缓存
        key: reloadToken != null ? ValueKey('network_${imagePath}_reload_$reloadToken') : null,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
        errorWidget: (context, url, error) {
          GameLogger.error(GameLogger.tagAlbum, 'Network image failed: ' + imagePath, error);
          return errorWidget ?? _buildErrorWidget();
        },
        // 优化内存缓存：使用更高的分辨率来保持图片清晰度
        memCacheWidth: _scaledCacheDimension(width),
        memCacheHeight: _scaledCacheDimension(height),
        // 添加图片质量优化
        filterQuality: FilterQuality.high,
        // 优化图片加载
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
      );
    }

    // 检查是否为图片ID格式（如 level_b_199）
    if (_isImageId(imagePath)) {
      GameLogger.log(GameLogger.tagAlbum, 'Treat as imageId -> smart load: ' + imagePath);
      // 如果是图片ID格式，使用智能选择逻辑
      final userType = ref.read(userTypeProvider);
      return _buildSmartImage(ref, imageLoader, imagePath, userType);
    }

    // 通行证/套图 asset 路径：assets/pic_pass/.../pass_c_X.png -> 按 imageId 智能加载（网络优先）
    final passAssetMatch = RegExp(r'assets/pic_pass/[^/]+/pass_c_(\d+)\.png').firstMatch(imagePath);
    if (passAssetMatch != null) {
      final imageId = 'pass_c_${passAssetMatch.group(1)}';
      GameLogger.log(GameLogger.tagAlbum, 'Treat pass asset path as imageId -> smart load: $imageId');
      final userType = ref.read(userTypeProvider);
      return _buildSmartImage(ref, imageLoader, imageId, userType);
    }

    // 套图 asset 路径：assets/pic_secret/.../secret_X_Y_Z.png -> 按 imageId 智能加载
    final secretAssetMatch = RegExp(r'assets/pic_secret/[^/]+/secret_(\d+)_[a-z]_(\d+)\.png').firstMatch(imagePath);
    if (secretAssetMatch != null) {
      final imageId = 'secret_${secretAssetMatch.group(1)}_${secretAssetMatch.group(2)}';
      GameLogger.log(GameLogger.tagAlbum, 'Treat secret asset path as imageId -> smart load: $imageId');
      final userType = ref.read(userTypeProvider);
      return _buildSmartImage(ref, imageLoader, imageId, userType);
    }

    // 使用本地图片路径
    GameLogger.log(GameLogger.tagAlbum, 'Load asset: ' + imagePath);
    return Image.asset(
      imagePath,
      key: reloadToken != null ? ValueKey('asset_${imagePath}_reload_$reloadToken') : null,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) {
        GameLogger.error(GameLogger.tagAlbum, 'Asset image failed: ' + imagePath, error);
        return errorWidget ?? _buildErrorWidget();
      },
    );
  }

  /// 检查是否为网络图片
  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  /// 检查是否为图片ID格式
  bool _isImageId(String path) {
    // 仅当是规范的图片ID格式时才按ID处理，避免把 assets 路径误判为ID
    return path.startsWith('level_') || path.startsWith('secret_') || path.startsWith('pass_');
  }

  /// 构建默认占位符
  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  /// 构建错误组件
  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }
}

int? _scaledCacheDimension(double? dimension) {
  if (dimension == null) return null;
  if (dimension.isNaN || dimension.isInfinite) return null;
  return (dimension * 3).toInt();
}
