import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../../generated/assets.dart';
import '../../services/image_loader_service.dart';
import '../../widgets/small_button.dart';
import '../../providers/photo_providers.dart';
import '../../providers/audio_providers.dart';
import '../../providers/user_type_provider.dart';
import '../../providers/level_providers.dart';
import '../../models/image_item.dart';
import '../../models/firebase_config.dart';
import '../../utils/game_logger.dart';
import '../../services/firebase_config_service.dart';
import '../../services/level_image_sequence_service.dart';
import '../../services/ads/ad_manager.dart';
import '../../services/ads/ads_service.dart';
import '../../services/image_preloader_service.dart';
import '../../providers/app_providers.dart';

/// 选择下一关弹窗
class NextLevelSelectionDialog extends ConsumerStatefulWidget {
  final VoidCallback? onLevelSelected;
  final Function(String levelType, int levelIndex)? onLevelChosen;

  const NextLevelSelectionDialog({
    super.key,
    this.onLevelSelected,
    this.onLevelChosen,
  });

  @override
  ConsumerState<NextLevelSelectionDialog> createState() => _NextLevelSelectionDialogState();
}

class _NextLevelSelectionDialogState extends ConsumerState<NextLevelSelectionDialog> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final Map<String, int> _imageReloadTokens = {};
  late AdManager _adManager;

  // 记录上次的用户类型，用于检测变化
  UserType? _lastUserType;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

    _animationController.forward();

    // 初始化广告管理器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final adsService = ref.read(adsServiceProvider);
        _adManager = AdManager.getInstance(adsService);
      }
    });
  }

  void _resetImageQueues() {
    ref.read(nextLevelSelectionProvider.notifier).reset();
    _imageReloadTokens.clear();
    GameLogger.log(GameLogger.tagLevel, '重置图片缓存队列');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 从已加载的图片列表中选择图片（使用顺序轮询）
  /// B类图片用于位置1、2（免费），C类图片用于位置3、4（视频）
  void _selectImagesFromLoadedList(List<ImageItem> allImages, UserType userType) {
    final selectionState = ref.read(nextLevelSelectionProvider);

    // 如果不需要重新选择且状态完整，直接返回
    if (!selectionState.needsReselect && selectionState.isComplete) {
      GameLogger.log(GameLogger.tagLevel, '图片已选择且完整，无需重新选择');
      _printCurrentSelection(selectionState);
      return;
    }

    // 获取图片总数
    final configService = ref.read(firebaseConfigServiceProvider);
    final config = configService.getDefaultConfig(userType);
    final bTotal = configService.getTotalCountForLevelType('b', config);
    final cTotal = configService.getTotalCountForLevelType('c', config);

    // 使用顺序轮询服务获取图片
    final sequenceService = LevelImageSequenceService();

    // ========== 四选一图片分配规则 ==========
    // 位置1、2：B类图片（免费）- 按顺序获取
    // 位置3、4：C类图片（视频）- 按顺序获取
    
    // 获取2张B类图片（位置1、2）
    final bIndices = sequenceService.getNextGroupByType(
      levelType: 'b',
      totalCount: bTotal,
      count: 2,
    );

    // 获取2张C类图片（位置3、4）
    final cIndices = sequenceService.getNextGroupByType(
      levelType: 'c',
      totalCount: cTotal,
      count: 2,
    );

    // 合并为4张图片索引：[B1, B2, C1, C2]
    final allIndices = [
      ...bIndices.take(2),
      ...cIndices.take(2),
    ];

    // 确保有4张图片
    while (allIndices.length < 4) {
      allIndices.add(-1);
    }

    // ========== 打印弹窗图片信息 ==========
    GameLogger.divider(GameLogger.tagLevel, '四选一弹窗图片');
    GameLogger.log(GameLogger.tagLevel, '┌─────────────────────────────────────────────');
    GameLogger.log(GameLogger.tagLevel, '│ 位置1 (免费): B类图片 level_b_${bIndices.isNotEmpty ? bIndices[0] + 1 : "N/A"}');
    GameLogger.log(GameLogger.tagLevel, '│ 位置2 (免费): B类图片 level_b_${bIndices.length > 1 ? bIndices[1] + 1 : "N/A"}');
    GameLogger.log(GameLogger.tagLevel, '│ 位置3 (视频): C类图片 level_c_${cIndices.isNotEmpty ? cIndices[0] + 1 : "N/A"}');
    GameLogger.log(GameLogger.tagLevel, '│ 位置4 (视频): C类图片 level_c_${cIndices.length > 1 ? cIndices[1] + 1 : "N/A"}');
    GameLogger.log(GameLogger.tagLevel, '├─────────────────────────────────────────────');
    GameLogger.log(GameLogger.tagLevel, '│ B类图片总数: $bTotal, 本次选择索引: $bIndices');
    GameLogger.log(GameLogger.tagLevel, '│ C类图片总数: $cTotal, 本次选择索引: $cIndices');
    GameLogger.log(GameLogger.tagLevel, '└─────────────────────────────────────────────');

    // 保存到 Provider
    final selectionNotifier = ref.read(nextLevelSelectionProvider.notifier);
    selectionNotifier.setImageIndices(allIndices.take(4).toList());

    // 当前组展示后立刻在后台预加载下一组
    _scheduleNextGroupPreload(configService, config);

    // 保留当前展示图片的重载令牌，移除其他图片的令牌
    final currentImageIds = <String>{};
    for (var i = 0; i < allIndices.length; i++) {
      if (allIndices[i] != -1) {
        if (i < 2) {
          // 位置1、2是B类图片
          currentImageIds.add('level_b_${allIndices[i] + 1}');
        } else {
          // 位置3、4是C类图片
          currentImageIds.add('level_c_${allIndices[i] + 1}');
        }
      }
    }
    _imageReloadTokens.removeWhere((key, value) => !currentImageIds.contains(key));

    setState(() {});
  }

  /// 后台预加载下一组 4 张图（不阻塞 UI）
  void _scheduleNextGroupPreload(FirebaseConfigService configService, FirebaseConfig config) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bTotal = configService.getTotalCountForLevelType('b', config);
      final cTotal = configService.getTotalCountForLevelType('c', config);
      final nextIndices = LevelImageSequenceService().peekNextGroup(bTotal, cTotal);
      final imageIds = [
        for (var i = 0; i < nextIndices.length; i++)
          i < 2 ? 'level_b_${nextIndices[i] + 1}' : 'level_c_${nextIndices[i] + 1}',
      ];
      ref.read(imagePreloaderServiceProvider).preloadSpecificImages(ref, imageIds, context);
    });
  }

  /// 打印当前选择的图片信息
  void _printCurrentSelection(NextLevelSelectionState state) {
    GameLogger.divider(GameLogger.tagLevel, '四选一弹窗图片（已缓存）');
    GameLogger.log(GameLogger.tagLevel, '┌─────────────────────────────────────────────');
    GameLogger.log(GameLogger.tagLevel, '│ 位置1 (免费): B类图片 level_b_${state.imageIndices[0] != -1 ? state.imageIndices[0] + 1 : "N/A"}');
    GameLogger.log(GameLogger.tagLevel, '│ 位置2 (免费): B类图片 level_b_${state.imageIndices[1] != -1 ? state.imageIndices[1] + 1 : "N/A"}');
    GameLogger.log(GameLogger.tagLevel, '│ 位置3 (视频): C类图片 level_c_${state.imageIndices[2] != -1 ? state.imageIndices[2] + 1 : "N/A"}');
    GameLogger.log(GameLogger.tagLevel, '│ 位置4 (视频): C类图片 level_c_${state.imageIndices[3] != -1 ? state.imageIndices[3] + 1 : "N/A"}');
    GameLogger.log(GameLogger.tagLevel, '└─────────────────────────────────────────────');
  }

  // 注意：_consumeSelectedImage 方法已移除
  // 现在只在游戏成功后通过 Provider 触发重新随机

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // 监听 photoListProvider、userTypeProvider 和 nextLevelSelectionProvider 的变化
        final photoList = ref.watch(photoListProvider);
        final userType = ref.watch(userTypeProvider);
        final selectionState = ref.watch(nextLevelSelectionProvider);

        // 当数据加载完成时，自动选择图片
        photoList.when(
          data: (images) {
            // 检查是否需要重新选择图片：第一次加载、用户类型发生变化或需要重新随机
            final userTypeChanged = _lastUserType != null && _lastUserType != userType;

            final needReselect = userTypeChanged || selectionState.needsReselect || !selectionState.isComplete;

            if (needReselect) {
              // 记录当前用户类型
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (userTypeChanged) {
                  _resetImageQueues();
                }
                GameLogger.log(GameLogger.tagLevel, 'photoList 数据加载完成，自动选择图片，用户类型: ${userType.name}');
                _selectImagesFromLoadedList(images, userType);
              });
            }

            _lastUserType = userType;
          },
          loading: () {
            GameLogger.log(GameLogger.tagLevel, 'photoList 正在加载中...');
          },
          error: (error, stack) {
            GameLogger.error(GameLogger.tagLevel, 'photoList 加载失败', error);
          },
        );

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _buildDialogContent(context),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildLevelSelection(context),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        const Center(
          child: Column(
            children: [
              SizedBox(height: 10),
              Text(
                'CHOOSE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: 10),
              // Text(
              //   'SELECT THE IMAGE YOU LIKE',
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: 15,
              //     fontWeight: FontWeight.bold,
              //     decoration: TextDecoration.none,
              //   ),
              // ),
            ],
          ),
        ),
        // 关闭按钮在右上角
        Positioned(
          top: 10,
          right: 20,
          child: GestureDetector(
            onTap: () {
              AudioActions.playClickSound(ref);
              Navigator.of(context).pop();
            },
            child: Image.asset(
              'assets/ic_close.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelSelection(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final selectionState = ref.watch(nextLevelSelectionProvider);

        // 2x2 布局：
        // 上排（位置1、2）：B类图片（免费）
        // 下排（位置3、4）：C类图片（视频）
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 上排：2个B类图片（免费）
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildLevelCard(
                    context,
                    levelType: 'b', // 固定B类
                    levelIndex: selectionState.imageIndices[0],
                    isFree: true,
                    title: 'LEVEL B',
                    buttonText: '',
                    buttonStyle: SmallButtonStyle.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLevelCard(
                    context,
                    levelType: 'b', // 固定B类
                    levelIndex: selectionState.imageIndices[1],
                    isFree: true,
                    title: 'LEVEL B',
                    buttonText: '',
                    buttonStyle: SmallButtonStyle.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 下排：2个C类图片（视频）
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildLevelCard(
                    context,
                    levelType: 'c', // 固定C类
                    levelIndex: selectionState.imageIndices[2],
                    isFree: false,
                    title: 'LEVEL C',
                    buttonText: '',
                    buttonStyle: SmallButtonStyle.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLevelCard(
                    context,
                    levelType: 'c', // 固定C类
                    levelIndex: selectionState.imageIndices[3],
                    isFree: false,
                    title: 'LEVEL C',
                    buttonText: '',
                    buttonStyle: SmallButtonStyle.green,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildLevelCard(
    BuildContext context, {
    required String levelType,
    required int levelIndex,
    required bool isFree,
    required String title,
    required String buttonText,
    required SmallButtonStyle buttonStyle,
  }) {
    final hasValidIndex = levelIndex != -1;
    const double buttonSize = 32.0;

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 图片：点击图片即可进入游戏（与首页一致）
            Positioned.fill(
              child: GestureDetector(
                onTap: hasValidIndex
                    ? () {
                        AudioActions.playClickSound(ref);
                        if (isFree) {
                          _startLevelDirectly(levelType, levelIndex);
                        } else {
                          _onWatchVideo(levelType, levelIndex);
                        }
                      }
                    : null,
                child: _buildLevelImage(levelType, levelIndex),
              ),
            ),
            // 右下角圆形按钮
            if (hasValidIndex)
              Positioned(
                right: 8,
                bottom: 8,
                child: GestureDetector(
                  onTap: () {
                    AudioActions.playClickSound(ref);

                    // 免费图片直接开始，视频图片需要看广告
                    if (isFree) {
                      _startLevelDirectly(levelType, levelIndex);
                    } else {
                      _onWatchVideo(levelType, levelIndex);
                    }
                  },
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      color: buttonStyle == SmallButtonStyle.blue
                          ? const Color(0xFF2196F3)
                          : const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        isFree ? Assets.assetsIcArrowWhite2x : Assets.assetsIcPlayBlack2x,
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelImage(String levelType, int levelIndex) {
    // 如果索引为-1，表示还未选择，显示占位符
    if (levelIndex == -1) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[600]!, width: 1),
        ),
        child: const Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 32,
        ),
      );
    }

    // 构建图片ID
    final imageId = 'level_${levelType}_${levelIndex + 1}';
    
    // 添加日志：特别关注前 2 个位置（应该是 B 类图片）
    final selectionState = ref.read(nextLevelSelectionProvider);
    final isFirstTwo = levelIndex == selectionState.imageIndices[0] || levelIndex == selectionState.imageIndices[1];
    if (isFirstTwo || levelType == 'b') {
      GameLogger.divider(GameLogger.tagLevel, '加载图片（前2个位置检查）');
      GameLogger.log(GameLogger.tagLevel, '┌─────────────────────────────────────────────');
      GameLogger.log(GameLogger.tagLevel, '│ levelType: $levelType');
      GameLogger.log(GameLogger.tagLevel, '│ levelIndex: $levelIndex');
      GameLogger.log(GameLogger.tagLevel, '│ imageId: $imageId');
      GameLogger.log(GameLogger.tagLevel, '│ 是否为B类图片: ${levelType == 'b'}');
      GameLogger.log(GameLogger.tagLevel, '│ 是否为前2个位置: $isFirstTwo');
      GameLogger.log(GameLogger.tagLevel, '│ 位置1索引: ${selectionState.imageIndices[0]}');
      GameLogger.log(GameLogger.tagLevel, '│ 位置2索引: ${selectionState.imageIndices[1]}');
      GameLogger.log(GameLogger.tagLevel, '└─────────────────────────────────────────────');
    }
    
    // 如果图片还没有 reloadToken，使用弹窗打开时的时间戳作为初始值
    // 移除默认的时间戳，允许使用缓存
    final reloadToken = _imageReloadTokens[imageId];

    // 获取用户类型
    final userType = ref.read(userTypeProvider);

    // 使用智能图片组件 - 根据配置决定加载本地还是网络图片
    // 使用包含 reloadToken 的 key 和 reloadToken 参数来强制重新加载（当 reloadToken 变化时）
    return SmartImageWidget(
      key: ValueKey('level_image_${imageId}_reload_$reloadToken'),
      imageId: imageId,
      userType: userType,
      reloadToken: reloadToken, // 传递 reloadToken 以清除缓存
      fit: BoxFit.cover, // 改为 cover 以获得更好的显示效果
      placeholder: Container(
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
      ),
      errorWidget: _buildErrorWidget(imageId),
    );
  }

  /// 构建错误显示组件
  Widget _buildErrorWidget(String imageId) {
    // 获取完整路径信息用于调试（只打印一次）
    final imageLoader = ref.read(imageLoaderServiceProvider);
    final userType = ref.read(userTypeProvider);
    final config = ref.read(firebaseConfigServiceProvider).getDefaultConfig(userType);
    final localPath = imageLoader.getLocalImagePath(imageId, config);
    final networkUrl = imageLoader.getNetworkImageUrl(imageId, config);
    final shouldUseNetwork = imageLoader.shouldLoadFromNetwork(imageId, userType, config);
    
    GameLogger.error(GameLogger.tagLevel, '图片加载失败，显示占位符: $imageId');
    GameLogger.log(GameLogger.tagLevel, '完整路径信息: imageId=$imageId, userType=$userType, shouldUseNetwork=$shouldUseNetwork, 本地路径=$localPath, 网络URL=${networkUrl ?? "null"}');
    return GestureDetector(
      onTap: () {
        GameLogger.log(GameLogger.tagLevel, '用户点击重试加载图片: $imageId');
        // 增加重载令牌，强制重新加载（清除缓存）
        // 如果图片还没有 token，使用当前时间戳作为基础值
        final currentToken = _imageReloadTokens[imageId] ?? DateTime.now().millisecondsSinceEpoch;
        final newToken = currentToken + 1;
        setState(() {
          _imageReloadTokens[imageId] = newToken;
        });
        GameLogger.log(GameLogger.tagLevel, '重试加载图片: $imageId, reloadToken=$newToken (从 $currentToken 增加)');
        // 确保状态更新后触发重建
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[600]!, width: 1),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh,
              color: Colors.white70,
              size: 36,
            ),
            SizedBox(height: 6),
            Text(
              'Tap to reload',
              style: TextStyle(
                decoration: TextDecoration.none,
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onWatchVideo(String levelType, int levelIndex) async {
    // 播放点击音效
    AudioActions.playClickSound(ref);

    GameLogger.log(GameLogger.tagLevel, '开始播放激励视频: levelType=$levelType, levelIndex=$levelIndex');

    // 使用 AdManager 播放激励视频
    final result = await _adManager.showRewardedAd(
      placement: 'next_level_video',
      onStart: () {
        GameLogger.log(GameLogger.tagLevel, '激励视频开始播放');
      },
      onCompleted: () {
        GameLogger.log(GameLogger.tagLevel, '激励视频播放完成');
      },
      onSkipped: () {
        GameLogger.log(GameLogger.tagLevel, '用户跳过激励视频');
      },
      onFailed: (error) {
        GameLogger.log(GameLogger.tagLevel, '激励视频播放失败: $error');
      },
    );

    if (!mounted) return;

    if (result == AdResult.completed) {
      // 播放成功音效
      AudioActions.playSuccessSound(ref);

      // 看完视频后自动开始当前选择的关卡
      _startLevelDirectly(levelType, levelIndex);
    } else {
      // 视频未完成或失败，不进入游戏
      String message = '需要完整观看广告才能进入关卡';
      if (result == AdResult.failed) {
        message = '广告播放失败，请稍后重试';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
        ));
      }
    }
  }

  void _startLevelDirectly(String levelType, int levelIndex) async {
    // 注意：不再在这里消费图片，只有在游戏成功后才消费

    // 关闭弹窗
    Navigator.of(context).pop();

    // 执行回调
    widget.onLevelChosen?.call(levelType, levelIndex);
    widget.onLevelSelected?.call();
  }
}

/// 显示选择下一关弹窗的全局函数
Future<void> showNextLevelSelectionDialog(
  BuildContext context, {
  VoidCallback? onLevelSelected,
  Function(String levelType, int levelIndex)? onLevelChosen,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => NextLevelSelectionDialog(
      onLevelSelected: onLevelSelected,
      onLevelChosen: onLevelChosen,
    ),
  );
}
