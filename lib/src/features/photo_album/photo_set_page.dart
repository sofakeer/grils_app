import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/photo_set_progress.dart';
import '../../providers/level_providers.dart';
import '../../providers/user_type_provider.dart';
import '../../services/ads/banner_placeholder.dart';
import '../../utils/game_logger.dart';
import '../../widgets/common_header.dart';
import '../../widgets/small_button.dart';
import '../../services/image_loader_service.dart';
import 'photo_set_providers.dart';
import 'photo_set_dialog.dart';

class PhotoSetPage extends ConsumerStatefulWidget {
  const PhotoSetPage({super.key});

  @override
  ConsumerState<PhotoSetPage> createState() => _PhotoSetPageState();
}

class _PhotoSetPageState extends ConsumerState<PhotoSetPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    
    // 注意：start_secret 埋点现在在游戏开始时上报，不在进入页面时上报
    
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 页面恢复时刷新状态
    GameLogger.log(GameLogger.tagPhotoSet, 'PhotoSetPage.didChangeDependencies - 准备刷新数据');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        GameLogger.log(GameLogger.tagPhotoSet, 'PhotoSetPage - 刷新套图数据');
        ref.invalidate(photoSetProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setsAsync = ref.watch(photoSetProvider);
    final levelState = ref.watch(levelProvider);
    final level = levelState.currentLevel;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF010013),
              Color(0xFF1B0739),
            ],
          ),
        ),
        child: Column(
          children: [
            CommonHeader(
              title: '',
              backgroundColor: Colors.transparent,
              onBackPressed: () {
                // 直接返回首页，避免黑屏问题
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home',
                  (route) => false,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 66, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(18),
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
                  tabs: const [
                    Tab(text: 'ALL'), // 每日数据
                    Tab(text: 'COMPLETE'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: setsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (error, _) => Center(
                  child: Text(
                    '加载失败: $error',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                data: (sets) {
                  final showCompleted = _tabController.index == 1;
                  final filtered = showCompleted
                      ? sets
                          .where((set) => set.slots.any((slot) =>
                              slot.state == PhotoSetSlotState.acquired))
                          .toList()
                      : sets;

                  // 确保数据正确更新
                  if (showCompleted) {
                    // 调试输出，显示已获得的套图信息
                    for (final set in filtered) {
                      final acquiredCount = set.slots
                          .where((slot) => slot.state == PhotoSetSlotState.acquired)
                          .length;
                      print('套图 ${set.setId} 已获得 $acquiredCount/${set.slots.length}');
                    }
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        showCompleted ? 'No completed set of pictures yet' : 'No set of pictures yet',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 16),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final set = filtered[index];
                      return _PhotoSetTile(
                        set: set,
                        playerLevel: level,
                        showCompleted: showCompleted,
                      );
                    },
                  );
                },
              ),
            ),
            const DummyBannerAd(height: 56, placement: 'photo_set_bottom'),
          ],
        ),
      ),
    );
  }
}

class _PhotoSetTile extends ConsumerWidget {
  final PhotoSetProgress set;
  final int playerLevel;
  final bool showCompleted;

  const _PhotoSetTile({
    required this.set,
    required this.playerLevel,
    required this.showCompleted,
  });

  bool get _isUnlocked => playerLevel >= set.unlockLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userType = ref.watch(userTypeProvider);
    final acquiredSlots = set.slots
        .where((slot) => slot.state == PhotoSetSlotState.acquired)
        .toList();
    final acquiredCount = acquiredSlots.length;
    
    // 调试日志
    GameLogger.log(GameLogger.tagPhotoSet, '套图${set.setId} UI更新: acquiredCount=$acquiredCount/${set.slots.length}');
    GameLogger.log(GameLogger.tagPhotoSet, '套图${set.setId} 总slot数: ${set.slots.length}');
    for (final slot in set.slots) {
      GameLogger.log(GameLogger.tagPhotoSet, '  图片${slot.index}: ${slot.state.name}, 路径=${slot.assetPath}');
    }

    return GestureDetector(
      onTap: () {
        if (!_isUnlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unlock in Level ${set.unlockLevel}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 1),
            ),
          );
          return;
        }
        showPhotoSetDialog(context, setId: set.setId, onlyAcquired: showCompleted);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: Stack(
          children: [
            // 背景图片
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: double.infinity,
                child: SmartImageWidget(
                  imageId: _coverImageId(userType),
                  imagePath: _coverAssetPath(),
                  userType: userType,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorWidget: Container(
                    color: Colors.grey[850],
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/image_fail.png',
                      width: 44,
                      height: 44,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
            ),
            // 渐变遮罩
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Colors.black87, Colors.black54, Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            // 对于未解锁的套图或在 COMPLETE 标签页下的套图，不显示计数
            if (!_isUnlocked && acquiredCount == 0 || showCompleted)
              const SizedBox.shrink()
            else
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$acquiredCount/${set.slots.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: _buildBottomAction(context, acquiredSlots),
            ),
            if (!_isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Text(
                            'UNLOCK IN LEVEL ${set.unlockLevel}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _coverImageId(UserType userType) {
    if (set.slots.isEmpty) return set.coverImageId;
    if (set.coverImageId != null) return set.coverImageId;
    if (userType != UserType.paid) return null;
    final coverSlot = set.slots.first;
    return 'secret_${set.setId}_${coverSlot.index}';
  }

  String? _coverAssetPath() {
    if (set.slots.isEmpty) return null;
    return set.slots.first.assetPath;
  }

  Widget _buildBottomAction(
      BuildContext context, List<PhotoSetSlot> acquiredSlots) {
    if (!_isUnlocked || showCompleted) {
      return Container();
    }

    return SmallButton(
      text: 'PLAY',
      backgroundColor: const Color(0xFF7C3AED),
      textColor: Colors.white,
      width: 80,
      height: 36,
      style: SmallButtonStyle.green,
      size: SmallButtonSize.small,
      borderRadius: 12,
      onPressed: () => showPhotoSetDialog(context, setId: set.setId),
    );
  }

  void _openAcquiredPreview(BuildContext context) {
    final acquiredSlots = set.slots
        .where((slot) => slot.state == PhotoSetSlotState.acquired)
        .toList();
    if (acquiredSlots.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Not Unlocked')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AcquiredPreviewDialog(
        set: set,
        acquiredSlots: acquiredSlots,
      ),
    );
  }
}

class _LockedPreviewTile extends StatelessWidget {
  const _LockedPreviewTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.lock,
          color: Colors.white38,
        ),
      ),
    );
  }
}

class _AcquiredPreviewDialog extends StatelessWidget {
  final PhotoSetProgress set;
  final List<PhotoSetSlot> acquiredSlots;

  const _AcquiredPreviewDialog({
    required this.set,
    required this.acquiredSlots,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '套图 ${set.setId.toString().padLeft(2, '0')} (${acquiredSlots.length}/${set.slots.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: acquiredSlots.length,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemBuilder: (context, index) {
                      final slot = acquiredSlots[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SmartImageWidget(
                          imageId: slot.imageId,
                          imagePath: slot.imageId == null ? slot.assetPath : null,
                          userType: ref.watch(userTypeProvider),
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            color: Colors.grey[800],
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/image_fail.png',
                              width: 32,
                              height: 32,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
