import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/image_item.dart';
import '../repositories/album_repository.dart';
import '../services/image_loader_service.dart';
import '../services/firebase_config_service.dart';
import 'user_type_provider.dart';
import '../utils/secret_image_utils.dart';

/// 相册仓库 Provider
final albumRepositoryProvider = Provider<AlbumRepository>((ref) {
  final repository = AlbumRepository();
  // 应用启动时执行数据迁移
  repository.migrateFromLegacy();
  return repository;
});

/// 相册图片目录 Provider
/// 负责构建完整的图片目录（包含所有图片的元数据）
final albumCatalogProvider = Provider<List<AlbumImageMeta>>((ref) {
  print('[Album] 构建相册目录');
  
  final configService = ref.watch(firebaseConfigServiceProvider);
  final naturalConfig = configService.getDefaultConfig(UserType.natural);
  final paidConfig = configService.getDefaultConfig(UserType.paid);
  
  int _levelCount(String type) {
    switch (type) {
      case 'a':
        return naturalConfig.images.levelA.totalCount > 0
            ? naturalConfig.images.levelA.totalCount
            : 10;
      case 'b':
        return paidConfig.images.levelB.totalCount > 0
            ? paidConfig.images.levelB.totalCount
            : 10;
      case 'c':
        return paidConfig.images.levelC.totalCount > 0
            ? paidConfig.images.levelC.totalCount
            : 10;
      default:
        return 10;
    }
  }
  
  final catalog = <AlbumImageMeta>[];
  var counter = 0;

  void _addLevelEntries(String folder, ImageType type) {
    final total = _levelCount(folder);
    for (var i = 1; i <= total; i++) {
      catalog.add(AlbumImageMeta(
        id: 'level_${folder}_$i',
        type: type,
        path: 'assets/pic_level/$folder/level_${folder}_$i.png',
        source: ImageSourceType.general,
        defaultOrder: counter++,
      ));
    }
  }

  _addLevelEntries('a', ImageType.A);
  _addLevelEntries('b', ImageType.B);
  _addLevelEntries('c', ImageType.C);

  // 2. SECRET 图片（81张：9套 × 9张）
  const secretFolders = ['a', 'b', 'c', 'd', 'e', 'f', 'j', 'h', 'i'];
  for (var setIdx = 0; setIdx < secretFolders.length; setIdx++) {
    final folder = secretFolders[setIdx];
    final setId = setIdx + 1;
    for (var slotIdx = 1; slotIdx <= 9; slotIdx++) {
      final prefix = SecretImageUtils.typeLetter(slotIdx);
      final type = SecretImageUtils.imageType(slotIdx);
      
      catalog.add(AlbumImageMeta(
        id: 'secret_${setId}_$slotIdx',
        type: type,
        path: 'assets/pic_secret/$folder/secret_${setId}_${prefix}_$slotIdx.png',
        source: ImageSourceType.secret,
        defaultOrder: counter++,
      ));
    }
  }

  // 3. TREASURE 图片（18张）
  for (var i = 1; i <= 18; i++) {
    catalog.add(AlbumImageMeta(
      id: 'pass_c_$i',
      type: ImageType.C,
      path: 'assets/pic_pass/c/pass_c_$i.png',
      source: ImageSourceType.treasure,
      defaultOrder: counter++,
    ));
  }

  print('[Album] 相册目录构建完成: ${catalog.length}张图片');
  return catalog;
});

/// 相册状态 Provider
/// 响应式地构建相册图片列表，自动反映解锁和收藏状态
final albumProvider = Provider<List<ImageItem>>((ref) {
  print('[Album] 构建相册图片列表');

  // 监听相册状态变更（解锁/收藏），确保数据重建
  ref.watch(albumNotifierProvider);
  
  final catalog = ref.watch(albumCatalogProvider);
  final repository = ref.watch(albumRepositoryProvider);
  final userType = ref.watch(userTypeProvider);
  final imageLoader = ref.watch(imageLoaderServiceProvider);
  final config = ref.watch(firebaseConfigServiceProvider).getDefaultConfig(userType);
  
  // 从持久化存储读取状态
  final unlockedIds = repository.getUnlockedImageIds();
  final unlockedTimestamps = repository.getUnlockedImageTimestamps();
  final likedIds = repository.getLikedImageIds();
  
  print('[Album] 已解锁: ${unlockedIds.length}张, 已收藏: ${likedIds.length}张');
  print('[Album] 解锁的图片ID: $unlockedIds');
  print('[Album] 收藏的图片ID: $likedIds');
  
  // 构建图片列表
  final now = DateTime.now().millisecondsSinceEpoch;
  final images = catalog.map((meta) {
    final isUnlocked = unlockedIds.contains(meta.id);
    final isLiked = likedIds.contains(meta.id);
    
    // 智能生成图片路径：根据用户类型和配置决定使用网络还是本地图片
    String imagePath = meta.path; // 默认使用本地路径
    
    if (isUnlocked) {
      // 对于已解锁的图片，根据配置智能选择路径
      final shouldUseNetwork = imageLoader.shouldLoadFromNetwork(meta.id, userType, config);
      print('[AlbumProvider] $meta.id: shouldUseNetwork=$shouldUseNetwork, userType=${userType.name}');
      if (shouldUseNetwork) {
        final networkUrl = imageLoader.getNetworkImageUrl(meta.id, config);
        if (networkUrl != null) {
          imagePath = networkUrl;
          print('[AlbumProvider] $meta.id: 使用网络图片 $networkUrl');
        }
      } else {
        print('[AlbumProvider] $meta.id: 使用本地图片 $imagePath');
      }
    }
    
    final unlockTs = unlockedTimestamps[meta.id];
    final itemTimestamp = unlockTs ?? (now - meta.defaultOrder * 1000);

    return ImageItem(
      id: meta.id,
      type: meta.type,
      src: imagePath,
      unlocked: isUnlocked,
      source: meta.source,
      liked: isLiked,
      downloaded: false,  // 不再使用下载状态
      ts: itemTimestamp,
    );
  }).toList();
  
  print('[Album] 图片列表构建完成: ${images.length}张图片');
  return images;
});

/// 按来源类型过滤的图片列表
final albumBySourceProvider = Provider.family<List<ImageItem>, ImageSourceType>((ref, sourceType) {
  final allImages = ref.watch(albumProvider);
  final filtered = allImages
      .where((img) => img.source == sourceType && img.unlocked)
      .toList()
    ..sort((a, b) => b.ts.compareTo(a.ts));  // 按时间倒序
  return filtered;
});

/// 收藏的图片列表
final albumLikedProvider = Provider<List<ImageItem>>((ref) {
  final allImages = ref.watch(albumProvider);
  final liked = allImages
      .where((img) {
        final shouldInclude = img.liked && img.unlocked;
        if (shouldInclude) {
          print('[AlbumLiked] 包含收藏图片: ${img.id}, 类型: ${img.type.name}, 来源: ${img.source.name}');
        }
        return shouldInclude;
      })
      .toList()
    ..sort((a, b) => b.ts.compareTo(a.ts));  // 按时间倒序
  
  print('[AlbumLiked] LIKE标签页最终图片数: ${liked.length}');
  return liked;
});

/// ALL 标签页的图片列表（所有已解锁的图片）
final albumAllProvider = Provider<List<ImageItem>>((ref) {
  final allImages = ref.watch(albumProvider);
  final userType = ref.watch(userTypeProvider);
  final isPaidUser = userType == UserType.paid;
  
  print('[AlbumAll] 用户类型: ${userType.name}, 是否买量用户: $isPaidUser');
  print('[AlbumAll] 总图片数: ${allImages.length}');
  
  final unlocked = allImages
      .where((img) {
        // ✅ 买量用户：过滤掉 A 类图片
        if (isPaidUser && img.type == ImageType.A) {
          print('[AlbumAll] 过滤掉A类图片: ${img.id}');
          return false;
        }
        final shouldInclude = img.unlocked;
        if (shouldInclude) {
          print('[AlbumAll] 包含已解锁图片: ${img.id}, 类型: ${img.type.name}, 来源: ${img.source.name}');
        }
        return shouldInclude;
      })
      .toList()
    ..sort((a, b) => b.ts.compareTo(a.ts));  // 按时间倒序
  
  print('[AlbumAll] ALL标签页最终图片数: ${unlocked.length}');
  return unlocked;
});

/// 相册操作 Notifier
class AlbumNotifier extends StateNotifier<int> {
  AlbumNotifier(this.repository) : super(0);
  
  final AlbumRepository repository;

  /// 解锁图片
  Future<void> unlockImage(String imageId) async {
    await repository.unlockImage(imageId);
    state++;  // 触发状态更新
    print('[AlbumNotifier] 已解锁图片: $imageId, 状态: $state');
  }

  /// 批量解锁图片
  Future<void> unlockImages(List<String> imageIds) async {
    await repository.unlockImages(imageIds);
    state++;
    print('[AlbumNotifier] 批量解锁${imageIds.length}张图片, 状态: $state');
  }

  /// 切换收藏状态
  Future<void> toggleLike(String imageId) async {
    await repository.toggleLike(imageId);
    state++;
    print('[AlbumNotifier] 切换收藏: $imageId, 状态: $state');
  }
}

final albumNotifierProvider = StateNotifierProvider<AlbumNotifier, int>((ref) {
  final repository = ref.watch(albumRepositoryProvider);
  return AlbumNotifier(repository);
});

/// 相册图片元数据
/// 用于定义图片的基本信息，不包含状态
class AlbumImageMeta {
  final String id;
  final ImageType type;
  final String path;
  final ImageSourceType source;
  final int defaultOrder;  // 默认排序

  const AlbumImageMeta({
    required this.id,
    required this.type,
    required this.path,
    required this.source,
    required this.defaultOrder,
  });
}
