import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/image_item.dart';
import '../../services/ads/ads_service.dart';
import '../../services/image_save_service.dart';
import '../../services/image_loader_service.dart';
import '../../providers/album_providers.dart';
import '../../providers/app_providers.dart';
import '../../providers/user_type_provider.dart';
import '../../../generated/assets.dart';
import '../../services/network_service.dart';

// 提示状态Provider
final photoDetailHintShownProvider = StateProvider<bool>((ref) => false);

class PhotoDetailPage extends ConsumerStatefulWidget {
  final ImageItem image;
  final List<ImageItem>? allImages;

  const PhotoDetailPage({
    super.key,
    required this.image,
    this.allImages,
  });

  @override
  ConsumerState<PhotoDetailPage> createState() => _PhotoDetailPageState();
}

class _PhotoDetailPageState extends ConsumerState<PhotoDetailPage> {
  bool _isDownloading = false;
  bool _showHint = false;
  bool _hintDismissed = false;
  bool _isWatchingAd = false;
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _checkHintStatus();
    
    // 初始化PageController和当前索引
    final allImages = widget.allImages ?? [widget.image];
    _currentIndex = allImages.indexWhere((img) => img.id == widget.image.id);
    if (_currentIndex == -1) _currentIndex = 0;
    
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 检查提示状态
  void _checkHintStatus() {
    final hasShownHint = ref.read(photoDetailHintShownProvider);
    
    if (!hasShownHint) {
      setState(() {
        _showHint = true;
      });
      
      // 3秒后自动隐藏提示
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showHint) {
          _markHintAsShown();
          setState(() {
            _showHint = false;
          });
        }
      });
    }
  }

  /// 标记提示已显示
  void _markHintAsShown() {
    ref.read(photoDetailHintShownProvider.notifier).state = true;
  }

  /// 切换收藏状态
  Future<void> _toggleLike() async {
    final allImages = widget.allImages ?? [widget.image];
    final currentImage = allImages[_currentIndex];
    await ref.read(albumNotifierProvider.notifier).toggleLike(currentImage.id);
    
    if (mounted) {
      // 强制重新构建UI以更新按钮状态
      setState(() {});
    }
  }

  /// 下载图片（需要先看广告）
  Future<void> _downloadImage() async {
    if (_isDownloading || _isWatchingAd) return;

    final allImages = widget.allImages ?? [widget.image];
    final currentImage = allImages[_currentIndex];

    // 检查图片来源：本地资源图片不需要检查网络，网络图片才需要检查网络
    final isNetworkImage = currentImage.src.startsWith('http://') || currentImage.src.startsWith('https://');

    setState(() {
      _isWatchingAd = true;
    });

    try {
      if (isNetworkImage) {
        // 网络图片需要检查网络连接
        final networkResult = await NetworkService.checkNetworkConnection();
        if (!networkResult.isConnected) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('网络错误，请稍后重试'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: '重试',
                  textColor: Colors.white,
                  onPressed: _downloadImage,
                ),
              ),
            );
          }
          return;
        }
      }

      // 模拟广告播放过程
      await Future.delayed(const Duration(milliseconds: 1500));

      // 显示激励视频广告
      final adsService = ref.read(adsServiceProvider);
      final adResult = await adsService.showRewarded(placement: 'photo_download');

      if (adResult == AdResult.completed) {
        // 广告观看完成，开始下载
        setState(() {
          _isWatchingAd = false;
          _isDownloading = true;
        });

        // 模拟下载过程
        await Future.delayed(const Duration(milliseconds: 800));

        // 根据图片类型选择不同的保存方法
        SaveImageResult saveResult;
        if (isNetworkImage) {
          saveResult = await ImageSaveService.saveImageToGallery(currentImage.src);
        } else {
          // 本地资源图片使用Asset保存方法
          saveResult = await ImageSaveService.saveAssetImageToGallery(currentImage.src);
        }

        if (saveResult.isSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(saveResult.details ?? (isNetworkImage ? '网络图片已保存到相册' : '图片已保存到相册')),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isNetworkImage ? '网络错误，请稍后重试' : '保存失败，请稍后重试'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: '重试',
                  textColor: Colors.white,
                  onPressed: _downloadImage,
                ),
              ),
            );
          }
        }
      } else {
        // 广告未完成或被跳过
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要观看广告才能下载'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNetworkImage ? '网络错误，请稍后重试' : '保存失败，请稍后重试'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isWatchingAd = false;
          _isDownloading = false;
        });
      }
    }
  }

  /// 分享图片
  void _shareImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('分享功能开发中...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allImages = widget.allImages ?? [widget.image];
    final currentImage = allImages[_currentIndex];
    final repository = ref.read(albumRepositoryProvider);
    final isLiked = repository.isLiked(currentImage.id);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 可滑动的图片页面
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: allImages.length,
              itemBuilder: (context, index) {
                final image = allImages[index];
                return _buildImagePage(image);
              },
            ),
          ),
          
          // 顶部返回按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          
          // 右侧底部按钮
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 56,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 收藏按钮
                _buildFloatingButton(
                  icon: isLiked ? Assets.assetsIcCollected2x : Assets.assetsIcCollect2x,
                  onPressed: _toggleLike,
                ),
                const SizedBox(height: 12),
                // 下载按钮
                _buildDownloadButton(),
              ],
            ),
          ),
          
          // 首次打开提示动画
          if (_showHint && !_hintDismissed)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showHint ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: GestureDetector(
                      onTap: () {
                        _markHintAsShown();
                        setState(() {
                          _showHint = false;
                          _hintDismissed = true;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.swipe_down,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '向下滑动查看下一张',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '点击任意位置关闭',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建单个图片页面
  Widget _buildImagePage(ImageItem image) {
    return image.unlocked
        ? SmartImageWidget(
            imagePath: image.src,
            userType: ref.read(userTypeProvider),
            fit: BoxFit.cover,
            errorWidget: Container(
              color: Colors.grey[800],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                    size: 60,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '图片加载失败',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Container(
            color: Colors.grey[800],
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  color: Colors.white54,
                  size: 60,
                ),
                SizedBox(height: 16),
                Text(
                  '图片未解锁',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
  }

  /// 构建浮动按钮
  Widget _buildFloatingButton({
    required String icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Image.asset(
        icon,
        width: 54,
        height: 54,
      ),
      onPressed: onPressed,
      iconSize: 24,
    );
  }

  /// 构建下载按钮（带广告图标）
  Widget _buildDownloadButton() {
    return Stack(
      children: [
        Container(
          child: IconButton(
            icon: _isWatchingAd
                ? const SizedBox(
                    width: 54,
                    height: 54,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  )
                : _isDownloading
                    ? const SizedBox(
                        width: 54,
                        height: 54,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Image.asset(
                        Assets.assetsIcDownload2x,
                        width: 54,
                        height: 54,
                      ),
            onPressed: (_isDownloading || _isWatchingAd) ? null : _downloadImage,
            iconSize: 24,
          ),
        ),
        // 广告图标 - 始终显示
        if (!_isDownloading && !_isWatchingAd)
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset(
              Assets.assetsIcAd2x,
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
      ],
    );
  }
}
