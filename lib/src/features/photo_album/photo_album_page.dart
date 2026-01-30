import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/image_item.dart';
import '../../services/ads/banner_placeholder.dart';
import '../../services/firebase_config_service.dart';
import '../../services/image_loader_service.dart';
import '../../widgets/common_header.dart';
import '../../providers/album_providers.dart';
import '../../providers/audio_providers.dart';
import '../../providers/user_type_provider.dart';
import '../../utils/game_logger.dart';
import 'photo_detail_page.dart';

class PhotoAlbumPage extends ConsumerStatefulWidget {
  const PhotoAlbumPage({super.key});

  @override
  ConsumerState<PhotoAlbumPage> createState() => _PhotoAlbumPageState();
}

class _PhotoAlbumPageState extends ConsumerState<PhotoAlbumPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isPaidUser;
  late final ProviderSubscription<UserType> _userTypeSubscription;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _isPaidUser = ref.read(userTypeProvider) == UserType.paid;
    _tabController = TabController(length: _isPaidUser ? 4 : 2, vsync: this);
    _userTypeSubscription = ref.listenManual<UserType>(
      userTypeProvider,
      (previous, next) {
        final newIsPaidUser = next == UserType.paid;
        if (newIsPaidUser != _isPaidUser) {
          _recreateTabController(newIsPaidUser);
        }
      },
    );
  }

  @override
  void dispose() {
    _userTypeSubscription.close();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _recreateTabController(bool newIsPaidUser) {
    final wasPaidUser = _isPaidUser;
    final previousIndex = _tabController.index;
    _tabController.dispose();

    _isPaidUser = newIsPaidUser;
    final newLength = _isPaidUser ? 4 : 2;
    _tabController = TabController(length: newLength, vsync: this);

    final mappedIndex = _mapTabIndex(wasPaidUser, _isPaidUser, previousIndex);
    final safeIndex =
        mappedIndex.clamp(0, newLength - 1);
    _tabController.index = safeIndex.toInt();

    if (mounted) {
      setState(() {});
    }
  }

  int _mapTabIndex(bool wasPaidUser, bool isPaidUser, int previousIndex) {
    if (wasPaidUser == isPaidUser) return previousIndex;
    if (isPaidUser) {
      // 自然用户 -> 买量用户
      if (previousIndex == 1) {
        return 2; // LIKE 标签位置从 1 调整到 2
      }
      return 0;
    }

    // 买量用户 -> 自然用户
    if (previousIndex == 2) {
      return 1; // LIKE 标签位置从 2 调整到 1
    }
    return 0;
  }

  /// 为买量用户构建图片组件
  Widget _buildImageForPaidUser(ImageItem image, UserType userType) {
    // 解析图片ID获取索引
    final imageIndex = _extractImageIndex(image.src);

    GameLogger.debug(GameLogger.tagAlbum, '_buildImageForPaidUser',
        'imageId=${image.src}, userType=${userType.name}, imageIndex=$imageIndex');

    // 如果图片索引小于11，优先使用本地图片
    if (imageIndex != null && imageIndex < 11) {
      GameLogger.log(GameLogger.tagAlbum, '使用本地图片策略: imageIndex=$imageIndex < 11');

      return Image.asset(
        image.src,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          GameLogger.error(GameLogger.tagAlbum, '本地图片加载失败: ${image.src}', error);

          // 本地图片失败时，尝试使用网络图片
          final networkUrl = _getNetworkUrlFromConfig(image.src, userType);
          if (networkUrl != null) {
            GameLogger.log(GameLogger.tagAlbum, '本地图片失败，回退到网络图片: $networkUrl');
            return CachedNetworkImage(
              imageUrl: networkUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[800],
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white54,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) {
                GameLogger.error(GameLogger.tagAlbum, '网络图片也加载失败: $networkUrl', error);
                return Container(
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.image,
                    color: Colors.white54,
                    size: 40,
                  ),
                );
              },
            );
          }

          // 网络图片也不可用，显示错误图标
          return Container(
            color: Colors.grey[800],
            child: const Icon(
              Icons.image,
              color: Colors.white54,
              size: 40,
            ),
          );
        },
      );
    }

    // 其他情况使用原来的SmartImageWidget
    GameLogger.log(GameLogger.tagAlbum, '使用SmartImageWidget策略: imageIndex=$imageIndex');
    return SmartImageWidget(
      imagePath: image.src,
      userType: userType,
      fit: BoxFit.cover,
      errorWidget: Container(
        color: Colors.grey[800],
        child: const Icon(
          Icons.image,
          color: Colors.white54,
          size: 40,
        ),
      ),
    );
  }

  /// 从图片路径中提取图片索引
  int? _extractImageIndex(String imagePath) {
    // 处理完整的本地路径，如 assets/pic_level/b/level_b_1.png
    final localPathMatch = RegExp(r'level_[abc]_(\d+)').firstMatch(imagePath);
    if (localPathMatch != null) {
      return int.tryParse(localPathMatch.group(1)!);
    }

    // 处理网络URL，如 https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/level_b_1.png
    final networkPathMatch = RegExp(r'level_[abc]_(\d+)').firstMatch(imagePath);
    if (networkPathMatch != null) {
      return int.tryParse(networkPathMatch.group(1)!);
    }

    // 处理套图图片路径，如 assets/pic_secret/a/secret_1_a_1.png
    final secretLocalMatch = RegExp(r'secret_\d+_[abc]_(\d+)').firstMatch(imagePath);
    if (secretLocalMatch != null) {
      return int.tryParse(secretLocalMatch.group(1)!);
    }

    // 处理套图网络URL，如 https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/secret_1_b_1.png
    final secretNetworkMatch = RegExp(r'secret_\d+_[abc]_(\d+)').firstMatch(imagePath);
    if (secretNetworkMatch != null) {
      return int.tryParse(secretNetworkMatch.group(1)!);
    }

    // 处理宝藏图片路径，如 assets/pic_pass/c/pass_c_1.png
    final passLocalMatch = RegExp(r'pass_c_(\d+)').firstMatch(imagePath);
    if (passLocalMatch != null) {
      return int.tryParse(passLocalMatch.group(1)!);
    }

    // 处理宝藏网络URL，如 https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/pass_c_1.png
    final passNetworkMatch = RegExp(r'pass_c_(\d+)').firstMatch(imagePath);
    if (passNetworkMatch != null) {
      return int.tryParse(passNetworkMatch.group(1)!);
    }

    return null;
  }

  /// 根据配置获取网络图片URL
  String? _getNetworkUrlFromConfig(String imagePath, UserType userType) {
    try {
      GameLogger.debug(GameLogger.tagAlbum, '_getNetworkUrlFromConfig',
          'imagePath=$imagePath, userType=${userType.name}');

      // 如果已经是网络URL，直接返回
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        GameLogger.log(GameLogger.tagAlbum, '已经是网络URL: $imagePath');
        return imagePath;
      }

      // 从完整路径中提取图片ID信息
      String? type;
      String? index;

      // 处理关卡图片路径，如 assets/pic_level/b/level_b_1.png
      final levelMatch = RegExp(r'level_([abc])_(\d+)').firstMatch(imagePath);
      if (levelMatch != null) {
        type = levelMatch.group(1);
        index = levelMatch.group(2);
        GameLogger.log(GameLogger.tagAlbum, '解析关卡图片: type=$type, index=$index');
      }

      // 处理套图图片路径，如 assets/pic_secret/a/secret_1_a_1.png
      final secretMatch = RegExp(r'secret_(\d+)_([abc])_(\d+)').firstMatch(imagePath);
      if (secretMatch != null) {
        final setId = secretMatch.group(1);
        final type = secretMatch.group(2);
        final slotIndex = secretMatch.group(3);
        final url = 'https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/secret_${setId}_${type}_$slotIndex.png';
        GameLogger.log(GameLogger.tagAlbum, '套图网络URL: $url');
        return url;
      }

      // 处理宝藏图片路径，如 assets/pic_pass/c/pass_c_1.png
      final passMatch = RegExp(r'pass_c_(\d+)').firstMatch(imagePath);
      if (passMatch != null) {
        final index = passMatch.group(1);
        final url = 'https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/pass_c_$index.png';
        GameLogger.log(GameLogger.tagAlbum, '宝藏网络URL: $url');
        return url;
      }

      // 根据用户类型和图片类型生成网络URL
      if (type != null && index != null) {
        switch (userType) {
          case UserType.natural:
          // 自然用户只处理A类图片
            if (type == 'a') {
              final url = 'https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/level_a_$index.png';
              GameLogger.log(GameLogger.tagAlbum, '自然用户A类网络URL: $url');
              return url;
            }
            break;
          case UserType.paid:
          // 买量用户处理B类和C类图片
            if (type == 'b') {
              final url = 'https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/level_b_$index.png';
              GameLogger.log(GameLogger.tagAlbum, '买量用户B类网络URL: $url');
              return url;
            } else if (type == 'c') {
              final url = 'https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/level_c_$index.png';
              GameLogger.log(GameLogger.tagAlbum, '买量用户C类网络URL: $url');
              return url;
            }
            break;
        }
      }

      GameLogger.log(GameLogger.tagAlbum, '无法生成网络URL: $imagePath');
      return null;
    } catch (e) {
      GameLogger.error(GameLogger.tagAlbum, '生成网络URL失败: $imagePath', e);
      return null;
    }
  }

  /// 构建图片网格项
  Widget _buildImageGridItem(ImageItem image) {
    return GestureDetector(
      onTap: () {
        // 播放点击音效
        AudioActions.playClickSound(ref);
        // 处理图片点击
        GameLogger.log(GameLogger.tagAlbum, '图片点击: ${image.src}, unlocked=${image.unlocked}');
        _onImageTap(image);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: image.unlocked ? Colors.transparent : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // 图片
              Container(
                width: double.infinity,
                height: double.infinity,
                color: image.unlocked ? null : Colors.grey.withOpacity(0.3),
                child: image.unlocked
                    ? SmartImageWidget(
                  imagePath: image.src,
                  userType: ref.read(userTypeProvider),
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.image,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
                )
                    : Container(
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.lock,
                    color: Colors.white54,
                    size: 30,
                  ),
                ),
              ),

              // 状态指示器
              if (!image.unlocked)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }

  List<ImageItem> _sortImagesByUnlockTime(List<ImageItem> images) {
    final sorted = [...images];
    sorted.sort((a, b) => b.ts.compareTo(a.ts));
    return sorted;
  }

  /// 处理图片点击
  void _onImageTap(ImageItem image) {
    GameLogger.debug(GameLogger.tagAlbum, '_onImageTap',
        'imageId=${image.src}, unlocked=${image.unlocked}, tabIndex=${_tabController.index}');

    if (!image.unlocked) {
      GameLogger.log(GameLogger.tagAlbum, '图片未解锁，显示提示');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('图片未解锁'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 获取当前标签页的所有图片
    final allImages = ref.read(albumProvider);

    // 根据当前标签页过滤图片，并按时间倒序排列
    List<ImageItem> filteredImages;
    switch (_tabController.index) {
      case 0: // ALL - 显示所有已解锁图片：普通关卡 + SECRET + LIKE + TREASURE 的并集
      // 获取普通关卡已解锁的图片（GENERAL类型）
        final generalImages = allImages
            .where((img) => img.source == ImageSourceType.general && img.unlocked)
            .toList();

        // 获取SECRET标签页的图片
        final secretImages = allImages
            .where((img) => img.source == ImageSourceType.secret && img.unlocked)
            .toList();

        // 获取TREASURE标签页的图片
        final treasureImages = allImages
            .where((img) => img.source == ImageSourceType.treasure && img.unlocked)
            .toList();

        // 获取LIKE标签页的图片（可能与其他类型重合）
        final likedImages = allImages
            .where((img) => img.liked && img.unlocked)
            .toList();

        // ALL = GENERAL + SECRET + TREASURE + LIKE 的并集，去重后按时间排序
        final allSetImages = <String, ImageItem>{};
        for (final img in [...generalImages, ...secretImages, ...treasureImages, ...likedImages]) {
          allSetImages[img.id] = img;
        }
        filteredImages = allSetImages.values.toList()
          ..sort((a, b) => b.ts.compareTo(a.ts));
        break;
      case 1:
        if (_isPaidUser) {
          filteredImages = allImages
              .where((img) => img.source == ImageSourceType.secret && img.unlocked)
              .toList()
            ..sort((a, b) => b.ts.compareTo(a.ts));
        } else {
          filteredImages = allImages
              .where((img) => img.liked && img.unlocked)
              .toList()
            ..sort((a, b) => b.ts.compareTo(a.ts));
        }
        break;
      case 2: // LIKE（仅买量用户保留 SECRET 与 TREASURE 时存在）
        filteredImages = allImages
            .where((img) => img.liked && img.unlocked)
            .toList()
          ..sort((a, b) => b.ts.compareTo(a.ts));
        break;
      case 3: // TREASURE
        filteredImages = allImages
            .where((img) => img.source == ImageSourceType.treasure && img.unlocked)
            .toList()
          ..sort((a, b) => b.ts.compareTo(a.ts));
        break;
      default:
        filteredImages = [image];
    }

    // 导航到图片详情页面
    GameLogger.log(GameLogger.tagAlbum, '导航到图片详情页面: ${image.src}, filteredImagesCount=${filteredImages.length}');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoDetailPage(
          image: image,
          allImages: filteredImages,
        ),
      ),
    );
  }



  /// 获取指定来源类型的总图片数量
  int _getTotalImagesForSource(ImageSourceType sourceType) {
    final firebaseConfig = ref.read(firebaseConfigProvider).valueOrNull ??
        ref
            .read(firebaseConfigServiceProvider)
            .getDefaultConfig(ref.read(userTypeProvider));

    switch (sourceType) {
      case ImageSourceType.general:
        return 30; // 默认3个类型，每个10张图片
      case ImageSourceType.secret:
        if (firebaseConfig != null && firebaseConfig.secrets.sets.isNotEmpty) {
          final total = firebaseConfig.secrets.sets.fold<int>(
              0, (sum, set) => sum + (set.slotCount > 0 ? set.slotCount : 9));
          if (total > 0) {
            return total;
          }
        }
        return 81; // 默认9个集合，每个9张图片
      case ImageSourceType.treasure:
        if (firebaseConfig != null && firebaseConfig.treasure.totalCount > 0) {
          return firebaseConfig.treasure.totalCount;
        }
        return 18; // 默认宝藏图片数量
    }
  }

  /// 获取所有类型的总图片数量
  int _getTotalImagesForAll() {
    return _getTotalImagesForSource(ImageSourceType.general) +
        _getTotalImagesForSource(ImageSourceType.secret) +
        _getTotalImagesForSource(ImageSourceType.treasure);
  }

  @override
  Widget build(BuildContext context) {
    GameLogger.debug(GameLogger.tagAlbum, 'build', '构建相册页面');

    return Scaffold(
      backgroundColor: HexColor('#040018'),
      appBar: const CommonHeader(title: 'Photo Album'),
      body: Column(
        children: [
          // Tab 栏
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              dividerColor: Colors.transparent,
              tabs: _isPaidUser
                  ? const [
                      Tab(text: 'ALL'),
                      Tab(text: 'SECRET'),
                      Tab(text: 'LIKE'),
                      Tab(text: 'TREASURE'),
                    ]
                  : const [
                      Tab(text: 'ALL'),
                      Tab(text: 'LIKE'),
                    ],
            ),
          ),

          // 图片网格
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _isPaidUser
                  ? [
                      _buildAllImageGrid(),
                      _buildImageGridWithInfiniteScroll(ImageSourceType.secret),
                      _buildLikedImageGrid(),
                      _buildImageGridWithInfiniteScroll(ImageSourceType.treasure),
                    ]
                  : [
                      _buildAllImageGrid(),
                      _buildLikedImageGrid(),
                    ],
            ),
          ),

          // 底部广告
          const DummyBannerAd(height: 56, placement: 'photo_album_bottom'),
        ],
      ),
    );
  }

  /// 构建所有图片网格（ALL标签页）
  Widget _buildAllImageGrid() {
    var images = ref.watch(albumAllProvider);
    images = _sortImagesByUnlockTime(images);
    GameLogger.debug(GameLogger.tagAlbum, '_buildAllImageGrid', 'ALL标签页图片数量: ${images.length}');

    if (images.isEmpty) {
      GameLogger.log(GameLogger.tagAlbum, 'ALL标签页无数据');
      return const Center(
        child: Text(
          'NO DATA\nComplete game levels to unlock more images',
          style: TextStyle(color: Colors.white54, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) => _buildImageGridItem(images[index]),
        controller: _scrollController,
      ),
    );
  }

  /// 构建带无限滚动的图片网格
  Widget _buildImageGridWithInfiniteScroll(ImageSourceType sourceType) {
    var images = ref.watch(albumBySourceProvider(sourceType));
    images = _sortImagesByUnlockTime(images);
    GameLogger.debug(GameLogger.tagAlbum, '_buildImageGridWithInfiniteScroll',
        'sourceType=${sourceType.name}, 图片数量: ${images.length}');

    if (images.isEmpty) {
      String emptyMessage = 'NO DATA';
      if (sourceType == ImageSourceType.secret) {
        emptyMessage = 'NO DATA\nComplete secret levels to unlock images';
      } else if (sourceType == ImageSourceType.treasure) {
        emptyMessage = 'NO DATA\nOpen treasure chests to unlock images';
      }

      GameLogger.log(GameLogger.tagAlbum, '${sourceType.name}标签页无数据');
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.white54, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) => _buildImageGridItem(images[index]),
        controller: _scrollController,
      ),
    );
  }

  /// 构建收藏图片网格
  Widget _buildLikedImageGrid() {
    var likedImages = ref.watch(albumLikedProvider);
    likedImages = _sortImagesByUnlockTime(likedImages);
    GameLogger.debug(GameLogger.tagAlbum, '_buildLikedImageGrid', 'LIKE标签页图片数量: ${likedImages.length}');

    if (likedImages.isEmpty) {
      GameLogger.log(GameLogger.tagAlbum, 'LIKE标签页无数据');
      return const Center(
        child: Text(
          'NO DATA\nClick the heart icon on images to add favorites',
          style: TextStyle(color: Colors.white54, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: likedImages.length,
        itemBuilder: (context, index) => _buildImageGridItem(likedImages[index]),
      ),
    );
  }
}
