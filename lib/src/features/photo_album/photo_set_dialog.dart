import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/assets.dart';
import '../../models/image_item.dart';
import '../../models/photo_set_progress.dart';
import '../../providers/level_providers.dart';
import '../../providers/app_providers.dart';
import '../../providers/user_type_provider.dart';
import '../../widgets/small_button.dart';
import '../../utils/game_logger.dart';
import '../../services/image_loader_service.dart';
import '../game/game_manager.dart';
import '../game_result/game_success_page.dart';
import 'photo_set_providers.dart';
import 'photo_detail_page.dart';
import '../../widgets/mystery_mask.dart';
import '../../repositories/album_repository.dart';
import '../../providers/album_providers.dart';
import '../../core/locator.dart';
import '../../services/ads/ad_manager.dart';
import '../../services/ads/ads_service.dart';

class PhotoSetDialog extends ConsumerStatefulWidget {
  final int setId;
  final BuildContext? rootContext;
  final bool onlyAcquired;

  const PhotoSetDialog({
    super.key,
    required this.setId,
    this.rootContext,
    this.onlyAcquired = false,
  });

  @override
  ConsumerState<PhotoSetDialog> createState() => _PhotoSetDialogState();
}

class _PhotoSetDialogState extends ConsumerState<PhotoSetDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // 强制刷新数据，确保每次打开都尝试重新加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refresh(photoSetProvider);
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setsAsync = ref.watch(photoSetProvider);
    GameLogger.log(GameLogger.tagPhotoSet, 'PhotoSetDialog.build: setId=${widget.setId}');
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SizedBox.expand(
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        color: Colors.black.withOpacity(0.45),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: _buildDialogBody(context, setsAsync),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogBody(
    BuildContext context,
    AsyncValue<List<PhotoSetProgress>> setsAsync,
  ) {
    return setsAsync.when(
      loading: () => const SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      error: (error, _) => _buildErrorContent(context, '$error'),
      data: (sets) {
        final set = sets.firstWhere(
          (item) => item.setId == widget.setId,
          orElse: () => sets.first,
        );
        
        return _buildSetContent(context, set);
      },
    );
  }

  Widget _buildErrorContent(BuildContext context, String error) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '加载失败',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            error,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetContent(BuildContext context, PhotoSetProgress set) {
    final size = MediaQuery.of(context).size;
    
    // 根据onlyAcquired参数过滤图片
    final displaySlots = widget.onlyAcquired 
        ? set.slots.where((slot) => slot.state == PhotoSetSlotState.acquired).toList()
        : set.slots;
    
    return Container(
      width: size.width * 0.85,
      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(Assets.assetsDiaogBgBig),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildHeader(context),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: displaySlots.length,
                  itemBuilder: (context, index) {
                    final slot = displaySlots[index];
                    return _PhotoSetSlotTile(
                      setId: set.setId,
                      slotIndex: slot.index,
                      rootContext: widget.rootContext ?? context,
                      onlyAcquired: widget.onlyAcquired,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        children: [
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 60,
                ),
                Text(
                  'PICTURE SET',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 60,
            right: 10,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset(
                Assets.assetsIcClose,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoSetSlotTile extends ConsumerWidget {
  final int setId;
  final int slotIndex;
  final BuildContext rootContext;
  final bool onlyAcquired;

  const _PhotoSetSlotTile({
    required this.setId,
    required this.slotIndex,
    required this.rootContext,
    this.onlyAcquired = false,
  });

  BorderRadius get _radius => BorderRadius.circular(0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(photoSetProvider);
    
    return setsAsync.when(
      loading: () => Container(
        decoration: BoxDecoration(
          borderRadius: _radius,
          color: Colors.grey[850],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      error: (error, _) => Container(
        decoration: BoxDecoration(
          borderRadius: _radius,
          color: Colors.grey[850],
        ),
        child: const Center(
          child: Icon(Icons.error, color: Colors.red),
        ),
      ),
      data: (sets) {
        final set = sets.firstWhere(
          (item) => item.setId == setId,
          orElse: () => sets.first,
        );
        final slot = set.slots.firstWhere(
          (s) => s.index == slotIndex,
          orElse: () => set.slots.first,
        );
        
        GameLogger.log(GameLogger.tagPhotoSet, '弹窗更新: 套图${setId} 图片${slotIndex} 状态=${slot.state.name}');
        
        return _buildSlotContent(context, ref, set, slot);
      },
    );
  }

  Widget _buildSlotContent(BuildContext context, WidgetRef ref, PhotoSetProgress set, PhotoSetSlot slot) {
    final userType = ref.watch(userTypeProvider);
    final resolvedImageId =
        userType == UserType.paid ? 'secret_${set.setId}_${slot.index}' : null;
    final imageId = _imageId(set.setId, slot.index);
    
    GameLogger.log(
      GameLogger.tagPhotoSet,
      '图片加载: setId=${set.setId}, slot=${slot.index}, imageId=$resolvedImageId, assetPath=${slot.assetPath}, userType=${userType.name}',
    );
    
    // 判断是否需要显示遮罩
    final albumRepo = ref.read(albumRepositoryProvider);
    final showMask = _shouldShowMask(slot.index, albumRepo, imageId);
    
    // 第1张始终显示真实图片，后面的待解锁状态显示虚拟人物封面
    final shouldShowRealImage = slot.index == 1 || slot.state == PhotoSetSlotState.acquired;
    
    return Material(
      color: Colors.transparent,
      borderRadius: _radius,
      child: InkWell(
        onTap: () => _handleTap(context, ref),
        borderRadius: _radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: _radius,
            color: Colors.grey[850],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: _radius,
                  child: MysteryMask(
                    showMask: showMask,
                    child: SmartImageWidget(
                      imageId: shouldShowRealImage ? resolvedImageId : null,
                      imagePath: shouldShowRealImage 
                          ? slot.assetPath 
                          : 'assets/images/ic_draw.png',
                      userType: userType,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: Colors.grey[800],
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (slot.state == PhotoSetSlotState.acquired && !onlyAcquired)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Image.asset(
                    Assets.assetsComponentChecked,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                ),
              if (slot.state == PhotoSetSlotState.locked)
                _buildLockedOverlay()
              else if (slot.state == PhotoSetSlotState.rvNeeded)
                _buildWatchOverlay(context, ref, slot, true)
              else if (slot.state == PhotoSetSlotState.playable)
                _buildPlayOverlay(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  /// 判断是否应该显示遮罩
  /// 套图弹窗中不显示神秘遮罩，待解锁的图片直接显示 ic_draw.png
  bool _shouldShowMask(int slotIndex, AlbumRepository albumRepo, String imageId) {
    return false;
  }

  Widget _buildLockedOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: _radius,
        ),
        child: const Center(
          child: Text(
            'LOCKED',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWatchOverlay(BuildContext context, WidgetRef ref, PhotoSetSlot slot, bool showRvNeeded) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: _radius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Spacer(),
              Center(
                child: Text(
                  'WATCH VIDEO',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(height: 8),
              if(showRvNeeded)
                SmallButton(
                  text: '${slot.rvProgress}/${slot.needRv}',
                  iconPath: Assets.assetsIcPlay,
                  iconColor: Colors.white,
                  iconSize: 14,
                  width: double.infinity,
                  height: 26,
                  style: SmallButtonStyle.blue,
                  size: SmallButtonSize.small,
                  backgroundColor: const Color(0xFFFF9E46),
                  textColor: Colors.white,
                  borderRadius: 8,
                  onPressed: () => _watchVideo(ref),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayOverlay(BuildContext context, WidgetRef ref) {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: SmallButton(
        text: 'PLAY',
        width: double.infinity,
        height: 26,
        style: SmallButtonStyle.green,
        size: SmallButtonSize.small,
        backgroundColor: const Color(0xFF7C3AED),
        textColor: Colors.white,
        borderRadius: 8,
        onPressed: () => _startGame(context, ref),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final setsAsync = ref.read(photoSetProvider);
    if (!setsAsync.hasValue) return;
    
    final sets = setsAsync.value!;
    final set = sets.firstWhere(
      (item) => item.setId == setId,
      orElse: () => sets.first,
    );
    final slot = set.slots.firstWhere(
      (s) => s.index == slotIndex,
      orElse: () => set.slots.first,
    );
    
    switch (slot.state) {
      case PhotoSetSlotState.locked:
        // 前置条件未满足，统一提示
        if (slot.index > 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The previous level is not completed'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('待解锁'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        return;
      case PhotoSetSlotState.rvNeeded:
        // 看视频状态下，图片本身不能点击，只能通过底部按钮看视频
        // 所以这里什么都不做，让用户通过按钮来触发看视频
        return;
      case PhotoSetSlotState.playable:
        _startGame(context, ref);
        return;
      case PhotoSetSlotState.acquired:
        await _openDetail(context, ref);
        return;
    }
  }

  Future<void> _openDetail(BuildContext context, WidgetRef ref) async {
    // 强制刷新状态
    await ref.refresh(photoSetProvider.future);
    await Future.delayed(const Duration(milliseconds: 50));
    final latest = ref.read(photoSetProvider).value;
    final updatedSet = latest?.firstWhere(
      (item) => item.setId == setId,
      orElse: () => latest.first,
    );
    final updatedSlot = updatedSet?.slots
        .firstWhere((item) => item.index == slotIndex, orElse: () => updatedSet.slots.first);

    final targetSlot = updatedSlot ?? updatedSet?.slots.first ?? PhotoSetSlot(index: slotIndex, needRv: 0, rvProgress: 0, state: PhotoSetSlotState.locked, assetPath: '', type: ImageType.B);

    if (targetSlot.state != PhotoSetSlotState.acquired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('获取失败，请稍后重试'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final acquiredSlots = (updatedSet ?? PhotoSetProgress(setId: setId, title: '套图$setId', unlockLevel: 1, slots: []))
        .slots
        .where((s) => s.state == PhotoSetSlotState.acquired)
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    final images = acquiredSlots
        .map((s) => _buildImageItem((updatedSet ?? PhotoSetProgress(setId: setId, title: '套图$setId', unlockLevel: 1, slots: [])).setId, s))
        .toList();

    final currentImage = images.firstWhere(
      (img) => img.id == _imageId((updatedSet ?? PhotoSetProgress(setId: setId, title: '套图$setId', unlockLevel: 1, slots: [])).setId, targetSlot.index),
      orElse: () => _buildImageItem((updatedSet ?? PhotoSetProgress(setId: setId, title: '套图$setId', unlockLevel: 1, slots: [])).setId, targetSlot),
    );

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoDetailPage(
          image: currentImage,
          allImages: images,
        ),
      ),
    );
  }

  Future<void> _watchVideo(WidgetRef ref) {
    return ref.read(photoSetProvider.notifier).watchSlot(setId, slotIndex);
  }

  Future<void> _startGame(BuildContext context, WidgetRef ref) async {
    final root = rootContext;
    final setsAsync = ref.read(photoSetProvider);
    if (!setsAsync.hasValue) return;
    
    final sets = setsAsync.value!;
    final set = sets.firstWhere(
      (item) => item.setId == setId,
      orElse: () => sets.first,
    );
    final slot = set.slots.firstWhere(
      (s) => s.index == slotIndex,
      orElse: () => set.slots.first,
    );
    
    GameLogger.divider(GameLogger.tagPhotoSet, '开始游戏');
    GameLogger.log(GameLogger.tagPhotoSet, 'setId=${set.setId}, slotIndex=${slot.index}');
    GameLogger.log(GameLogger.tagPhotoSet, 'assetPath=${slot.assetPath}');
    
    // 根据 slotIndex 判断是否需要看广告
    // 第1张：免费进入，不拉广告
    // 第2-5张：插屏广告
    // 第6-9张：激励视频
    final imageId = _imageId(set.setId, slot.index);
    final albumRepo = ref.read(albumRepositoryProvider);
    final needsUnlock = slot.index > 1 && !albumRepo.isUnlocked(imageId);
    
    if (needsUnlock) {
      if (slot.index >= 2 && slot.index <= 5) {
        // 第2-5张：插屏广告
        final adsService = ref.read(adsServiceProvider);
        final adManager = AdManager.getInstance(adsService);
        final result = await adManager.showInterstitialAd(
          placement: 'photo_set_slot_${slot.index}',
          onStart: () {
            GameLogger.log(GameLogger.tagPhotoSet, '插屏广告开始播放: slotIndex=${slot.index}');
          },
          onCompleted: () {
            GameLogger.log(GameLogger.tagPhotoSet, '插屏广告播放完成: slotIndex=${slot.index}');
          },
          onFailed: (error) {
            GameLogger.log(GameLogger.tagPhotoSet, '插屏广告播放失败: slotIndex=${slot.index}, error=$error');
          },
        );
        
        if (result != AdResult.completed) {
          // 广告未完成，不进入游戏
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('需要完整观看广告才能进入关卡'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      } else if (slot.index >= 6 && slot.index <= 9) {
        // 第6-9张：激励视频
        final adsService = ref.read(adsServiceProvider);
        final adManager = AdManager.getInstance(adsService);
        final result = await adManager.showRewardedAd(
          placement: 'photo_set_slot_${slot.index}',
          onStart: () {
            GameLogger.log(GameLogger.tagPhotoSet, '激励视频开始播放: slotIndex=${slot.index}');
          },
          onCompleted: () {
            GameLogger.log(GameLogger.tagPhotoSet, '激励视频播放完成: slotIndex=${slot.index}');
          },
          onSkipped: () {
            GameLogger.log(GameLogger.tagPhotoSet, '用户跳过激励视频: slotIndex=${slot.index}');
          },
          onFailed: (error) {
            GameLogger.log(GameLogger.tagPhotoSet, '激励视频播放失败: slotIndex=${slot.index}, error=$error');
          },
        );
        
        if (result != AdResult.completed) {
          // 广告未完成，不进入游戏
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('需要完整观看广告才能进入关卡'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }
    }
    
    ref.read(photoSetGameSelectionProvider.notifier).state = SelectedPhotoSlot(
      setId: set.setId,
      slotIndex: slot.index,
      assetPath: slot.assetPath,
      type: slot.type,
    );

    final callbacks = PhotoSetGameCallbacks(
      context: root,
      setId: set.setId,
      slotIndex: slot.index,
    );

    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GameNavigator.navigateToGame(
        context: root,
        gameType: GameType.simplePuzzle,
        level: ref.read(levelProvider).currentLevel,
        callbacks: callbacks,
      );
    });
  }

  ImageItem _buildImageItem(int setId, PhotoSetSlot slot) {
    return ImageItem(
      id: _imageId(setId, slot.index),
      type: slot.type,
      src: slot.imageId ?? slot.assetPath, // 优先使用网络图片ID，回退到本地路径
      unlocked: true,
      source: ImageSourceType.secret,
      liked: false,
      downloaded: false,
      ts: DateTime.now().millisecondsSinceEpoch,
    );
  }

  String _imageId(int setId, int index) => 'secret_${setId}_$index';
}

Future<void> showPhotoSetDialog(BuildContext context,
    {required int setId, bool onlyAcquired = false}) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    builder: (_) => PhotoSetDialog(setId: setId, rootContext: context, onlyAcquired: onlyAcquired),
  );
  
  // 弹窗关闭后刷新数据
  if (context.mounted) {
    GameLogger.log(GameLogger.tagPhotoSet, '弹窗关闭，刷新数据');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        final container = ProviderScope.containerOf(context);
        container.refresh(photoSetProvider);
      }
    });
  }
}

class PhotoSetGameCallbacks extends DefaultGameCallbacks {
  final int setId;
  final int slotIndex;

  PhotoSetGameCallbacks({
    required BuildContext context,
    required this.setId,
    required this.slotIndex,
  }) : super(context: context);

  ProviderContainer get _container =>
      ProviderScope.containerOf(context, listen: false);

  SelectedPhotoSlot? get _currentSelection =>
      _container.read(photoSetGameSelectionProvider);

  void _clearGameSelection() {
    _container.read(photoSetGameSelectionProvider.notifier).state = null;
  }

  void _resetSelections() {
    _clearGameSelection();
    _container.read(photoUnlockSelectionProvider.notifier).state = null;
  }

  @override
  void onGameSuccess({
    required int score,
    required int coins,
    required int level,
    int? performance,
  }) {
    // 先获取选择信息（在清除之前）
    final selection = _currentSelection;
    GameLogger.divider(GameLogger.tagPhotoSet, '游戏成功');
    GameLogger.log(GameLogger.tagPhotoSet, 'setId=$setId, slotIndex=$slotIndex');
    GameLogger.log(GameLogger.tagPhotoSet, 'imagePath=${selection?.assetPath}');
    
    // 更新状态
    _container.read(photoSetProvider.notifier).acquireSlot(setId, slotIndex);

    // 同时更新用户进度中的套图解锁状态
    _container.read(userProgressProvider.notifier).updateSecretProgress(setId, slotIndex);

    if (selection != null) {
      _container.read(photoUnlockSelectionProvider.notifier).state = selection;
    }
    _clearGameSelection();

    // 延迟导航到成功页面，确保状态更新完成
    Future.microtask(() {
      GameLogger.log(GameLogger.tagPhotoSet, '→ 导航到 GameSuccessPage');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GameSuccessPage(
            coinsEarned: coins,
            level: level,
            percent: performance,
            // 传递套图图片信息
            customImagePath: selection?.assetPath,
            customImageSourceType: ImageSourceType.secret,
            secretSetId: setId.toString(),
            secretSlotIndex: slotIndex,
            // 套图模式：不传 onNoThanks，由 GameSuccessPage 统一 pop 回套图弹窗
          ),
        ),
      );
    });
  }

  @override
  void onGameFailure({required String reason, required int level}) {
    _resetSelections();
    super.onGameFailure(reason: reason, level: level);
  }

  @override
  void onGameTimeout({required int level}) {
    _resetSelections();
    super.onGameTimeout(level: level);
  }

  @override
  void onGameQuit({required int level}) {
    _resetSelections();
    super.onGameQuit(level: level);
  }
}
