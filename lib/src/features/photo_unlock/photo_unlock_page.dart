import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../generated/assets.dart';
import '../../services/image_save_service.dart';
import '../../services/image_loader_service.dart';
import '../../services/firebase_config_service.dart';
import '../../providers/album_providers.dart';
import '../../providers/user_type_provider.dart';
import '../../providers/level_providers.dart';
import '../../utils/game_logger.dart';
import '../../services/network_service.dart';
import '../../providers/audio_providers.dart';
import '../../widgets/coin_display.dart';
import '../../models/image_item.dart';
import '../../providers/background_providers.dart';
import '../treasure/treasure_providers.dart';
import '../game_result/game_success_page.dart';

/// 图片解锁页面
class PhotoUnlockPage extends ConsumerStatefulWidget {
  final String levelType;
  final int levelIndex;
  final String imagePath;
  final bool isWatermarked;
  final ImageSourceType imageSourceType;
  final String? secretSetId;
  final int? secretSlotIndex;

  const PhotoUnlockPage({
    super.key,
    required this.levelType,
    required this.levelIndex,
    required this.imagePath,
    this.isWatermarked = true,
    this.imageSourceType = ImageSourceType.general,
    this.secretSetId,
    this.secretSlotIndex,
  });

  @override
  ConsumerState<PhotoUnlockPage> createState() => _PhotoUnlockPageState();
}

class _PhotoUnlockPageState extends ConsumerState<PhotoUnlockPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _downloadButtonAnimationController;
  late Animation<double> _downloadButtonScaleAnimation;

  late String _resolvedImagePath;

  bool _isLiked = false;
  bool _isDownloading = false;
  bool _isWatchingAd = false;

  @override
  void initState() {
    super.initState();

    _resolvedImagePath = _resolveInitialImagePath();

    // 打印接收到的参数
    GameLogger.divider(GameLogger.tagPhotoUnlock, '图片解锁页面');
    GameLogger.log(GameLogger.tagPhotoUnlock, 'imagePath: ${widget.imagePath}');
    GameLogger.log(GameLogger.tagPhotoUnlock, 'sourceType: ${widget.imageSourceType.name}');
    if (widget.imageSourceType == ImageSourceType.secret) {
      GameLogger.log(GameLogger.tagPhotoUnlock, 'setId: ${widget.secretSetId}, slotIndex: ${widget.secretSlotIndex}');
    } else {
      GameLogger.log(GameLogger.tagPhotoUnlock, 'levelType: ${widget.levelType}, levelIndex: ${widget.levelIndex}');
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Download 按钮循环缩放动画
    _downloadButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _downloadButtonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _downloadButtonAnimationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    // 启动 Download 按钮循环缩放动画
    _downloadButtonAnimationController.repeat(reverse: true);

    // 初始化收藏状态
    _initLikeStatus();

    // 延迟执行 provider 状态修改，避免在 build 过程中修改状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 设置全局背景图片为当前解锁的图片
      _setGlobalBackground();
      // 自动解锁图片
      _unlockImage();
      // 只对普通关卡（GENERAL类型）立即完成关卡
      // 因为游戏成功进入图片解锁页面时，关卡就应该算完成了
      if (widget.imageSourceType == ImageSourceType.general) {
        _completeLevel();
      }
    });
  }

  void _initLikeStatus() async {
    // 检查当前图片是否已经被收藏
    final imageId = _generateImageId();
    final repository = ref.read(albumRepositoryProvider);
    final isLiked = repository.isLiked(imageId);
    GameLogger.log(GameLogger.tagPhotoUnlock, '初始化收藏状态: $imageId, 已收藏: $isLiked');
    setState(() {
      _isLiked = isLiked;
    });
  }

  /// 生成正确的图片ID
  String _generateImageId() {
    switch (widget.imageSourceType) {
      case ImageSourceType.secret:
        // SECRET图片格式: secret_X_Y (X是套图ID, Y是槽位索引)
        if (widget.secretSetId != null && widget.secretSlotIndex != null) {
          return 'secret_${widget.secretSetId}_${widget.secretSlotIndex}';
        }
        // 回退到通用格式
        return 'secret_${widget.levelType}_${widget.levelIndex + 1}';
      case ImageSourceType.treasure:
        // TREASURE图片格式: pass_c_Y (Y是imageSequence，1-18)
        // secretSlotIndex 已经是 imageSequence，不需要再加1
        if (widget.secretSlotIndex != null) {
          return 'pass_c_${widget.secretSlotIndex!}';
        }
        // 回退到使用levelIndex
        return 'pass_c_${widget.levelIndex + 1}';
      case ImageSourceType.general:
        // GENERAL图片格式: level_X_Y
        final actualIndex = widget.levelIndex + 1;
        return 'level_${widget.levelType}_$actualIndex';
    }
  }

  /// 自动解锁图片到相册
  void _unlockImage() async {
    final imageId = _generateImageId();

    GameLogger.divider(GameLogger.tagPhotoUnlock, '开始解锁图片');
    GameLogger.log(GameLogger.tagPhotoUnlock, '生成的图片ID: $imageId');
    GameLogger.log(GameLogger.tagPhotoUnlock, '图片路径: ${widget.imagePath}');
    GameLogger.log(GameLogger.tagPhotoUnlock, '图片来源类型: ${widget.imageSourceType.name}');
    GameLogger.log(GameLogger.tagPhotoUnlock, 'levelIndex: ${widget.levelIndex}');

    switch (widget.imageSourceType) {
      case ImageSourceType.secret:
        GameLogger.log(GameLogger.tagPhotoUnlock, '解锁SECRET图片: $imageId');
        GameLogger.log(GameLogger.tagPhotoUnlock, '套图ID: ${widget.secretSetId}, 槽位索引: ${widget.secretSlotIndex}');
        break;
      case ImageSourceType.treasure:
        GameLogger.log(GameLogger.tagPhotoUnlock, '解锁TREASURE图片: $imageId');
        // 标记宝藏卡片为完成状态
        if (widget.secretSlotIndex != null) {
          final imageSequence = widget.secretSlotIndex!;
          GameLogger.log(GameLogger.tagPhotoUnlock, '标记宝藏卡片完成: imageSequence=$imageSequence');
          await ref.read(treasureProvider.notifier).completeImageBySequence(imageSequence);
          GameLogger.success(GameLogger.tagPhotoUnlock, '宝藏卡片已标记完成');
        }
        break;
      case ImageSourceType.general:
        GameLogger.log(GameLogger.tagPhotoUnlock, '解锁GENERAL图片: $imageId');
        break;
    }

    // 使用相册通知器解锁图片，触发相册数据刷新
    await ref.read(albumNotifierProvider.notifier).unlockImage(imageId);
    GameLogger.success(GameLogger.tagPhotoUnlock, '图片解锁完成: $imageId');
    GameLogger.log(GameLogger.tagPhotoUnlock, '图片将出现在: ${_getAlbumCategory()}');
  }

  String _getAlbumCategory() {
    switch (widget.imageSourceType) {
      case ImageSourceType.general:
        return 'ALL 标签';
      case ImageSourceType.secret:
        return 'SECRET 标签';
      case ImageSourceType.treasure:
        return 'TREASURE 标签';
    }
  }

  /// 完成关卡（只对普通关卡调用）
  Future<void> _completeLevel() async {
    GameLogger.log(GameLogger.tagPhotoUnlock, '普通关卡完成，调用 completeLevel()');
    await ref.read(levelProvider.notifier).completeLevel();
    GameLogger.success(GameLogger.tagPhotoUnlock, '关卡已累加');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _downloadButtonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Column(
                children: [
                  // 顶部金币显示和标题
                  _buildTopBar(),
                  const SizedBox(height: 20),
                  // 主要内容
                  Expanded(
                    child: Center(
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: _buildMainContent(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 底部按钮
                  _buildBottomButtons(),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'NEW PHOTOS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: CoinDisplay(
              backgroundColor: Color(0x4D000000),
              iconSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    // 为所有类型生成imageId，让SmartImageWidget智能选择网络或本地图片
    final String? imageId = _generateImageId();

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // 图片：优先使用imageId，让SmartImageWidget智能选择网络或本地
              SmartImageWidget(
                imageId: imageId,
                userType: ref.read(userTypeProvider),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                width: double.infinity,
                // height: MediaQuery.of(context).size.height * 0.55,
              ),

              // 收藏按钮 - 悬浮在右下角
              Positioned(
                bottom: 15,
                right: 15,
                child: _buildLikeButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLikeButton() {
    return GestureDetector(
      onTap: _onLike,
      child: Container(
        width: 45,
        height: 45,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.grey[400],
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // DOWNLOAD 按钮
        AnimatedBuilder(
          animation: _downloadButtonScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _downloadButtonScaleAnimation.value,
              child: _buildDownloadButton(),
            );
          },
        ),
        const SizedBox(height: 20),
        // OK 按钮
        GestureDetector(
          onTap: _onNext,
          child: const Text(
            'OK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    return GestureDetector(
      onTap: (_isDownloading || _isWatchingAd) ? null : _onDownload,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: 65,
        decoration: BoxDecoration(
          color: (_isDownloading || _isWatchingAd) ? Colors.grey[800] : const Color(0xFF55FF9C), // 亮绿色
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            if (!_isDownloading && !_isWatchingAd)
              BoxShadow(
                color: const Color(0xFF55FF9C).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isWatchingAd)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else if (_isDownloading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else ...[
                    // 播放图标背景
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'DOWNLOAD',
                      style: TextStyle(
                        color: (_isDownloading || _isWatchingAd) ? Colors.white : Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 广告图标
            if (!_isDownloading && !_isWatchingAd)
              const Positioned(
                top: 5,
                right: 10,
                child: Image(
                  image: AssetImage(Assets.assetsIcAdYellow2x),
                  width: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onLike() async {
    // 播放点击音效
    AudioActions.playClickSound(ref);

    final imageId = _generateImageId();

    // 先更新本地状态提供即时反馈
    final newLikedState = !_isLiked;
    setState(() {
      _isLiked = newLikedState;
    });

    try {
      // 使用相册通知器更新收藏状态，确保相册刷新
      await ref.read(albumNotifierProvider.notifier).toggleLike(imageId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newLikedState ? '已添加到收藏' : '已取消收藏'),
            backgroundColor: newLikedState ? Colors.green : Colors.orange,
          ),
        );
      }

      GameLogger.log(GameLogger.tagPhotoUnlock, '收藏状态更新: $imageId, 新状态: $newLikedState');
    } catch (e) {
      // 如果操作失败，恢复本地状态
      if (mounted) {
        setState(() {
          _isLiked = !newLikedState;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      GameLogger.error(GameLogger.tagPhotoUnlock, '收藏操作失败: $e');
    }
  }

  void _onDownload() async {
    if (_isDownloading || _isWatchingAd) return;

    // 播放点击音效
    AudioActions.playClickSound(ref);

    // 检查图片来源：网络图片需要检查网络，本地资源或imageId格式不需要
    final isNetworkImage = _resolvedImagePath.startsWith('http://') || _resolvedImagePath.startsWith('https://');
    // 如果是imageId格式，需要根据配置判断是否应该使用网络
    final isImageIdFormat = _resolvedImagePath.startsWith('level_') || 
                            _resolvedImagePath.startsWith('secret_') || 
                            _resolvedImagePath.startsWith('pass_');
    
    // 对于imageId格式，需要检查是否应该使用网络图片
    bool shouldCheckNetwork = isNetworkImage;
    if (isImageIdFormat && !isNetworkImage) {
      final userType = ref.read(userTypeProvider);
      final config = ref.read(firebaseConfigServiceProvider).getDefaultConfig(userType);
      final imageLoader = ref.read(imageLoaderServiceProvider);
      shouldCheckNetwork = imageLoader.shouldLoadFromNetwork(_resolvedImagePath, userType, config);
    }

    GameLogger.log(GameLogger.tagPhotoUnlock, '开始下载流程，图片来源: ${shouldCheckNetwork ? "网络图片" : "本地资源图片"}');
    GameLogger.log(GameLogger.tagPhotoUnlock, '图片路径: ${widget.imagePath}');
    GameLogger.log(GameLogger.tagPhotoUnlock, '解析后路径: $_resolvedImagePath');

    setState(() {
      _isWatchingAd = true;
    });

    try {
      if (shouldCheckNetwork) {
        // 网络图片需要检查网络连接
        GameLogger.log(GameLogger.tagPhotoUnlock, '检查网络连接...');
        final networkResult = await NetworkService.checkNetworkConnection();
        if (!networkResult.isConnected) {
          GameLogger.log(
              GameLogger.tagPhotoUnlock, '网络连接失败: ${networkResult.successCount}/${networkResult.totalTargets}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('网络错误，请稍后重试'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: '重试',
                  textColor: Colors.white,
                  onPressed: _onDownload,
                ),
              ),
            );
          }
          return;
        }
        GameLogger.log(GameLogger.tagPhotoUnlock, '网络连接正常');
      }

      // 显示激励视频广告
      GameLogger.log(GameLogger.tagPhotoUnlock, '显示激励视频广告...');
      await _showRewardedVideo();

      if (mounted) {
        setState(() {
          _isWatchingAd = false;
          _isDownloading = true;
        });
      }

      GameLogger.log(GameLogger.tagPhotoUnlock, '开始保存图片...');

      // 根据图片类型选择不同的保存方法
      SaveImageResult saveResult;
      if (shouldCheckNetwork) {
        // 如果是imageId格式，需要先获取实际的网络URL
        String actualPath = _resolvedImagePath;
        if (isImageIdFormat) {
          final userType = ref.read(userTypeProvider);
          final config = ref.read(firebaseConfigServiceProvider).getDefaultConfig(userType);
          final imageLoader = ref.read(imageLoaderServiceProvider);
          final networkUrl = imageLoader.getNetworkImageUrl(_resolvedImagePath, config);
          if (networkUrl != null) {
            actualPath = networkUrl;
          } else {
            // 如果无法获取网络URL，回退到本地路径
            actualPath = imageLoader.getLocalImagePath(_resolvedImagePath, config);
            shouldCheckNetwork = false;
          }
        }
        
        if (shouldCheckNetwork) {
          GameLogger.log(GameLogger.tagPhotoUnlock, '保存网络图片到相册: $actualPath');
          // 网络图片会自动下载并保存
          saveResult = await ImageSaveService.saveImageToGallery(actualPath);
        } else {
          GameLogger.log(GameLogger.tagPhotoUnlock, '保存本地资源图片到相册: $actualPath');
          // 本地资源图片使用Asset保存方法
          saveResult = await ImageSaveService.saveAssetImageToGallery(actualPath);
        }
      } else {
        GameLogger.log(GameLogger.tagPhotoUnlock, '保存本地资源图片到相册: $_resolvedImagePath');
        // 本地资源图片使用Asset保存方法
        saveResult = await ImageSaveService.saveAssetImageToGallery(_resolvedImagePath);
      }

      GameLogger.log(GameLogger.tagPhotoUnlock,
          '保存结果: ${saveResult.isSuccess} - ${saveResult.errorMessage ?? saveResult.details ?? ""}');

      if (mounted) {
        if (saveResult.isSuccess) {
          GameLogger.success(GameLogger.tagPhotoUnlock, '图片保存成功');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(saveResult.details ?? (shouldCheckNetwork ? '网络图片已保存到相册' : '图片已保存到相册')),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // 下载成功后，自动跳转至金币结算页面
          _navigateToCoinResult();
        } else {
          GameLogger.error(GameLogger.tagPhotoUnlock, '图片保存失败: ${saveResult.errorMessage ?? "未知错误"}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(shouldCheckNetwork ? '网络错误，请稍后重试' : '保存失败，请稍后重试'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: '重试',
                textColor: Colors.white,
                onPressed: _onDownload,
              ),
            ),
          );
        }
      }
    } catch (e) {
      GameLogger.error(GameLogger.tagPhotoUnlock, '保存过程出现异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shouldCheckNetwork ? '网络错误，请稍后重试' : '保存失败，请稍后重试'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: '重试',
              textColor: Colors.white,
              onPressed: _onDownload,
            ),
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
      GameLogger.log(GameLogger.tagPhotoUnlock, '下载流程完成');
    }
  }

  Future<void> _showRewardedVideo() async {
    // 模拟观看激励视频
    // 在实际应用中，这里应该调用广告SDK
    await Future.delayed(const Duration(seconds: 3));
  }

  /// 设置全局背景图片
  void _setGlobalBackground() async {
    // 将当前解锁图片设置为全局背景
    GameLogger.log(GameLogger.tagPhotoUnlock, '设置全局背景图片开始...');
    GameLogger.log(GameLogger.tagPhotoUnlock, '图片来源类型: ${widget.imageSourceType.name}');
    GameLogger.log(GameLogger.tagPhotoUnlock, '原始图片路径: ${widget.imagePath}');
    GameLogger.log(GameLogger.tagPhotoUnlock, '解析后的图片路径: $_resolvedImagePath');
    GameLogger.log(GameLogger.tagPhotoUnlock, '关卡类型: ${widget.levelType}');
    GameLogger.log(GameLogger.tagPhotoUnlock, '关卡索引: ${widget.levelIndex}');

    // 所有类型的图片都设置为首页背景
    // 对于SECRET和TREASURE图片，使用imageId格式以便SmartImageWidget智能加载
    // 对于普通关卡图片，使用解析后的路径
    switch (widget.imageSourceType) {
      case ImageSourceType.general:
        // 普通关卡图片：使用解析后的路径
        await ref.read(backgroundImageProvider.notifier).setLastUnlockedBackground(_resolvedImagePath);
        GameLogger.log(GameLogger.tagPhotoUnlock, '设置普通关卡背景图片: $_resolvedImagePath');
        break;
      case ImageSourceType.secret:
        // SECRET图片：使用imageId格式 (secret_X_Y)
        if (widget.secretSetId != null && widget.secretSlotIndex != null) {
          final imageId = 'secret_${widget.secretSetId}_${widget.secretSlotIndex}';
          await ref.read(backgroundImageProvider.notifier).setLastUnlockedBackground(imageId);
          GameLogger.log(GameLogger.tagPhotoUnlock, '设置SECRET背景图片(imageId): $imageId');
        } else {
          // 回退到使用解析后的路径
          await ref.read(backgroundImageProvider.notifier).setLastUnlockedBackground(_resolvedImagePath);
          GameLogger.log(GameLogger.tagPhotoUnlock, '设置SECRET背景图片(path): $_resolvedImagePath');
        }
        break;
      case ImageSourceType.treasure:
        // TREASURE图片：使用imageId格式 (pass_c_Y)
        if (widget.secretSlotIndex != null) {
          final imageId = 'pass_c_${widget.secretSlotIndex}';
          await ref.read(backgroundImageProvider.notifier).setLastUnlockedBackground(imageId);
          GameLogger.log(GameLogger.tagPhotoUnlock, '设置TREASURE背景图片(imageId): $imageId');
        } else {
          // 回退到使用解析后的路径
          await ref.read(backgroundImageProvider.notifier).setLastUnlockedBackground(_resolvedImagePath);
          GameLogger.log(GameLogger.tagPhotoUnlock, '设置TREASURE背景图片(path): $_resolvedImagePath');
        }
        break;
    }

    GameLogger.log(GameLogger.tagPhotoUnlock, '设置全局背景图片完成');
  }

  void _onHome() async {
    // 播放点击音效
    AudioActions.playClickSound(ref);

    GameLogger.log(GameLogger.tagPhotoUnlock, '点击HOME按钮，图片来源类型: ${widget.imageSourceType.name}');

    // 所有类型的图片：保持当前解锁的图片作为背景（不重置）
    // 这样用户在首页就能看到刚刚解锁的图片
    GameLogger.log(GameLogger.tagPhotoUnlock, '保持当前解锁的图片作为首页背景');

    // 直接导航到主页
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
    );
  }

  void _onNext() {
    // 播放点击音效
    AudioActions.playClickSound(ref);

    // OK 按钮：直接跳转金币结算页面
    _navigateToCoinResult();
  }

  /// 跳转到金币结算页面
  void _navigateToCoinResult() {
    // 获取当前关卡信息
    final levelState = ref.read(levelProvider);
    final levelType = widget.levelType.isNotEmpty ? widget.levelType : (levelState.currentLevelType ?? 'b');
    final levelIndex = widget.levelIndex > 0 ? widget.levelIndex : (levelState.currentLevelIndex ?? 0);

    // 计算奖励（使用默认值，实际奖励在金币结算页面计算）
    const coinsEarned = 5; // 默认值，实际会在 GameSuccessPage 中计算

    // 普通关卡在 PhotoUnlockPage 已经完成了，告知 GameSuccessPage 不要重复累加
    final isLevelAlreadyCompleted = widget.imageSourceType == ImageSourceType.general;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GameSuccessPage(
          coinsEarned: coinsEarned,
          level: levelState.currentLevel,
          levelType: levelType,
          levelIndex: levelIndex,
          customImagePath: widget.imagePath,
          customImageSourceType: widget.imageSourceType,
          secretSetId: widget.secretSetId,
          secretSlotIndex: widget.secretSlotIndex,
          isLevelAlreadyCompleted: isLevelAlreadyCompleted,
        ),
      ),
    );
  }

  String _resolveInitialImagePath() {
    // 对于下载功能，需要解析出实际的图片路径
    // 但显示时应该使用imageId让SmartImageWidget智能选择
    final rawPath = widget.imagePath;
    
    // 如果是网络URL，直接返回
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }
    
    // 如果是imageId格式（如 level_b_3），直接返回让SmartImageWidget处理
    if (rawPath.startsWith('level_') || rawPath.startsWith('secret_') || rawPath.startsWith('pass_')) {
      return rawPath;
    }

    // 对于本地资源路径（如 assets/pic_level/b/level_b_3.png），
    // 尝试从路径中提取imageId，或者返回原路径用于下载
    final userType = ref.read(userTypeProvider);
    final config = ref.read(firebaseConfigServiceProvider).getDefaultConfig(userType);
    final imageLoader = ref.read(imageLoaderServiceProvider);

    // 尝试从路径中提取imageId
    final imageId = _extractImageIdFromPath(rawPath);
    if (imageId != null) {
      // 检查是否应该使用网络
      final shouldUseNetwork = imageLoader.shouldLoadFromNetwork(imageId, userType, config);
      if (shouldUseNetwork) {
        final networkUrl = imageLoader.getNetworkImageUrl(imageId, config);
        if (networkUrl != null) {
          return networkUrl;
        }
      }
      // 返回imageId，让SmartImageWidget处理
      return imageId;
    }

    // 如果无法提取imageId，返回原路径（用于下载功能）
    return rawPath;
  }

  /// 从路径中提取imageId（如从 assets/pic_level/b/level_b_3.png 提取 level_b_3）
  String? _extractImageIdFromPath(String path) {
    // 匹配 assets/pic_level/{type}/level_{type}_{index}.png
    final regex = RegExp(r'assets/pic_level/([abc])/level_([abc])_(\d+)\.png');
    final match = regex.firstMatch(path);
    if (match != null) {
      final type = match.group(2);
      final index = match.group(3);
      return 'level_${type}_$index';
    }
    
    // 匹配 assets/pic_secret/.../secret_...
    final secretRegex = RegExp(r'assets/pic_secret/[^/]+/secret_(\d+)_([abc])_(\d+)\.png');
    final secretMatch = secretRegex.firstMatch(path);
    if (secretMatch != null) {
      final setId = secretMatch.group(1);
      final slot = secretMatch.group(3);
      return 'secret_${setId}_$slot';
    }
    
    // 匹配 assets/pic_pass/.../pass_...
    final passRegex = RegExp(r'assets/pic_pass/([abc])/pass_([abc])_(\d+)\.png');
    final passMatch = passRegex.firstMatch(path);
    if (passMatch != null) {
      final type = passMatch.group(2);
      final index = passMatch.group(3);
      return 'pass_${type}_$index';
    }
    
    return null;
  }
}
