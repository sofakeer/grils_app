import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../../generated/assets.dart';
import '../../models/image_item.dart';
import '../../providers/level_providers.dart';
import '../../providers/audio_providers.dart';
import '../../providers/user_type_provider.dart';
import '../../providers/album_providers.dart';
import '../photo_album/photo_set_providers.dart';
import '../game/main_game_page.dart';
import '../../services/ads/banner_placeholder.dart';
import '../../services/firebase_config_service.dart';
import '../../services/image_loader_service.dart';
import '../../widgets/mystery_mask.dart';
import '../../widgets/common_header.dart';
import '../../widgets/small_button.dart';
import 'treasure_providers.dart';
import '../../widgets/reward_dialog.dart';
import '../../utils/treasure_debug.dart';

class TreasurePage extends ConsumerStatefulWidget {
  const TreasurePage({super.key});

  @override
  ConsumerState<TreasurePage> createState() => _TreasurePageState();
}

class _TreasurePageState extends ConsumerState<TreasurePage> with WidgetsBindingObserver {
  int? _lastKnownLevel;

  @override
  void initState() {
    super.initState();
    // 注意：start_trsasure 埋点现在在游戏开始时上报，不在进入页面时上报

    // 注册生命周期监听器
    WidgetsBinding.instance.addObserver(this);

    // 记录当前关卡并延迟刷新宝藏状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _lastKnownLevel = ref.read(levelProvider).currentLevel;
        if (kDebugMode) {
          print('[TreasurePage] initState - 记录初始关卡: $_lastKnownLevel');
        }

        // 延迟刷新宝藏状态，确保关卡数据已完全加载
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            final currentLevel = ref.read(levelProvider).currentLevel;
            if (kDebugMode) {
              print('[TreasurePage] 延迟刷新 - 当前关卡: $currentLevel');
            }
            ref.read(treasureProvider.notifier).refresh();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // 应用恢复到前台时，检查关卡是否变化
      final currentLevel = ref.read(levelProvider).currentLevel;
      if (kDebugMode) {
        print('[TreasurePage] 应用恢复 - 上次关卡: $_lastKnownLevel, 当前关卡: $currentLevel');
      }
      if (_lastKnownLevel != null && _lastKnownLevel != currentLevel) {
        if (kDebugMode) {
          print('[TreasurePage] 检测到关卡变化，刷新宝藏状态');
        }
        ref.read(treasureProvider.notifier).refresh();
        _lastKnownLevel = currentLevel;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(treasureProvider);
    final levelState = ref.watch(levelProvider);

    // 检查关卡是否变化（每次 build 时检查）
    if (_lastKnownLevel != null && _lastKnownLevel != levelState.currentLevel) {
      if (kDebugMode) {
        print('[TreasurePage] build 检测到关卡变化: $_lastKnownLevel -> ${levelState.currentLevel}');
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(treasureProvider.notifier).refresh();
          _lastKnownLevel = levelState.currentLevel;
        }
      });
    }

    // 打印当前关卡信息（调试用）
    if (kDebugMode) {
      print('[TreasurePage] build - 当前关卡: ${levelState.currentLevel}');
    }

    // 监听关卡变化，刷新宝藏状态
    ref.listen<LevelState>(levelProvider, (previous, next) {
      if (kDebugMode) {
        print('[TreasurePage] listen 触发 - previous: ${previous?.currentLevel}, next: ${next.currentLevel}');
      }
      if (previous?.currentLevel != next.currentLevel) {
        // 关卡发生变化时，刷新宝藏状态
        if (kDebugMode) {
          print('[TreasurePage] 关卡变化: ${previous?.currentLevel} -> ${next.currentLevel}，刷新宝藏状态');
        }
        ref.read(treasureProvider.notifier).refresh();
      }
    });
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // 拦截返回键，返回首页
          if (kDebugMode) {
            print('[TreasurePage] 拦截返回键，返回首页');
          }
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: HexColor('#040018'),
        appBar: CommonHeader(
          title: 'Treasure',
          onBackPressed: () {
            // 直接返回首页，避免黑屏问题
            if (kDebugMode) {
              print('[TreasurePage] 点击返回按钮，返回首页');
            }
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          },
        ),
        body: Column(
          children: [
            // 顶部Banner图片
            Container(
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: Image.asset(
                Assets.assetsTopBg2x,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
                data: (s) {
                  return _TreasureGridWithArrows(cards: s.cards);
                },
              ),
            ),
            const DummyBannerAd(height: 56, placement: 'treasure_bottom'),
          ],
        ),
        // 🐛 调试模式下显示调试按钮
        floatingActionButton: kDebugMode ? _DebugFloatingButton() : null,
      ),
    );
  }
}

class _TreasureGridWithArrows extends ConsumerWidget {
  final List<TreasureCard> cards;
  const _TreasureGridWithArrows({required this.cards});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const arrowSize = 24.0;
          final availableWidth = constraints.maxWidth - 60; // 减去左右padding
          final cardWidth = (availableWidth - arrowSize) / 2; // 减去箭头宽度，无间距
          const cardHeight = 235.0; // 卡片高度（+15dp 便于图片居中）
          final totalRows = (cards.length + 1) ~/ 2;
          final rows = <Widget>[];

          for (var rowIndex = 0; rowIndex < totalRows; rowIndex++) {
            final startIndex = rowIndex * 2;
            final leftIndex = rowIndex.isEven ? startIndex : startIndex + 1;
            final rightIndex = rowIndex.isEven ? startIndex + 1 : startIndex;

            rows.add(
              _buildRowWithArrows(leftIndex, rightIndex, cardWidth, cardHeight, arrowSize, ref),
            );

            final hasNextRow = rowIndex < totalRows - 1;
            if (hasNextRow) {
              rows.add(
                _buildVerticalArrow(
                  arrowSize,
                  cardWidth,
                  alignWithLeftColumn: rowIndex.isOdd,
                ),
              );
            }
          }

          return SingleChildScrollView(
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: rows,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRowWithArrows(
      int leftIndex, int rightIndex, double cardWidth, double cardHeight, double arrowSize, WidgetRef ref) {
    // 判断是否是从右到左的布局（rightIndex < leftIndex）
    final isRightToLeft = rightIndex < leftIndex;
    final hasLeftCard = leftIndex < cards.length;
    final hasRightCard = rightIndex < cards.length;
    final showArrow = hasLeftCard && hasRightCard;
    final rowWidth = cardWidth * 2 + arrowSize;

    return SizedBox(
      width: rowWidth,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 左侧卡片
          SizedBox(
            width: cardWidth - 2,
            height: cardHeight,
            child: hasLeftCard ? _TreasureCardGrid(card: cards[leftIndex]) : const SizedBox(),
          ),
          // 水平箭头
          SizedBox(
            width: arrowSize,
            height: arrowSize,
            child: showArrow
                ? Transform.rotate(
                    angle: isRightToLeft ? 3.14159 : 0, // 从右到左时旋转180度
                    child: Image.asset(
                      'assets/treasure/arrow_righ.png',
                      width: arrowSize,
                      height: arrowSize,
                      fit: BoxFit.contain,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // 右侧卡片
          SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: hasRightCard ? _TreasureCardGrid(card: cards[rightIndex]) : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalArrow(double arrowSize, double cardWidth, {required bool alignWithLeftColumn}) {
    final rowWidth = cardWidth * 2 + arrowSize;
    final offsetBase = (cardWidth - arrowSize) / 2;
    var arrowLeft = alignWithLeftColumn ? offsetBase : cardWidth + arrowSize + offsetBase;

    if (arrowLeft < 0) {
      arrowLeft = 0;
    }
    final maxLeft = rowWidth - arrowSize;
    if (arrowLeft > maxLeft) {
      arrowLeft = maxLeft;
    }

    return SizedBox(
      width: rowWidth,
      height: arrowSize,
      child: Stack(
        children: [
          Positioned(
            left: arrowLeft,
            child: SizedBox(
              width: arrowSize,
              height: arrowSize,
              child: Transform.rotate(
                angle: 1.5708, // 90度旋转
                child: Image.asset(
                  'assets/treasure/arrow_righ.png',
                  width: arrowSize,
                  height: arrowSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreasureCardGrid extends ConsumerWidget {
  final TreasureCard card;
  const _TreasureCardGrid({required this.card});

  /// 构建带遮罩的通行证图片
  Widget _buildTreasureImageWithMask({
    required WidgetRef ref,
    required String treasureImageId,
    required int imageSequence,
    required UserType userType,
  }) {
    final albumRepo = ref.read(albumRepositoryProvider);

    // 第1个图片关卡不加遮罩，后续关卡默认加遮罩
    final isUnlocked = albumRepo.isUnlocked(treasureImageId);
    final showMask = imageSequence > 1 && !isUnlocked;

    return MysteryMask(
      showMask: showMask,
      child: (showMask)
          ? Image.asset(
              'assets/images/ic_draw.png',
              width: 50,
              height: 80,
              fit: BoxFit.cover,
            )
          : SmartImageWidget(
              imageId: treasureImageId,
              userType: userType,
              width: 50,
              height: 80,
              alignment: Alignment.topCenter,
              fit: BoxFit.cover,
            ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userType = ref.watch(userTypeProvider);
    final firebaseConfig = ref.watch(firebaseConfigProvider).valueOrNull;
    const fallbackTreasureCount = 18;
    final configuredTreasureCount = firebaseConfig?.treasure.totalCount ?? fallbackTreasureCount;
    final effectiveTreasureCount = configuredTreasureCount > 0 ? configuredTreasureCount : fallbackTreasureCount;

    // 背景：index 0 蓝、1 绿、2 蓝… 渐变 + 渐变边框
    final isBlue = card.index % 2 == 0;
    final fillGradient = isBlue
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF48EDFF), Color(0xFF2E7DFC), Color(0xFF48EDFF)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3AD57B), Color(0xFF4EC4B4)],
          );
    final borderGradient = isBlue
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF49F9FF), Color(0xFF6EEAE0)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF85DCFF), Color(0xFF58F5EE)],
          );

    String? iconAsset;
    String? treasureImageId;
    switch (card.type) {
      case TreasureRewardType.coin:
        iconAsset = 'assets/spin/conins_small.png';
        break;
      case TreasureRewardType.undo:
        iconAsset = 'assets/spin/undo_small.png';
        break;
      case TreasureRewardType.reminder:
        iconAsset = 'assets/spin/reminder_small.png';
        break;
      case TreasureRewardType.pipe:
        iconAsset = 'assets/spin/tube_small.png';
        break;
      case TreasureRewardType.image:
        var imageIndex = card.imageSequence ?? 1;
        if (imageIndex < 1) {
          imageIndex = 1;
        } else if (imageIndex > effectiveTreasureCount) {
          imageIndex = effectiveTreasureCount;
        }
        treasureImageId = 'pass_c_$imageIndex';
        break;
    }

    final isImage = card.type == TreasureRewardType.image;

    final rewardText = () {
      switch (card.type) {
        case TreasureRewardType.coin:
          return '+${card.amount}';
        case TreasureRewardType.undo:
          return '+${card.amount}';
        case TreasureRewardType.reminder:
          return '+${card.amount}';
        case TreasureRewardType.pipe:
          return '+${card.amount}';
        case TreasureRewardType.image:
          return '';
      }
    }();

    final action = _resolveAction(context, ref, card, isImage);

    return GestureDetector(
      onTap: () {
        if (action.onTap == null) {
          return;
        }
        if (action.enabled) {
          AudioActions.playClickSound(ref);
        }
        action.onTap!.call();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: borderGradient,
        ),
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: constraints.maxHeight,
                child: Stack(
                  clipBehavior: Clip.antiAlias,
                  children: [
                    // 背景层：渐变铺满，避免底部露出页面深色背景
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: fillGradient,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/treasure/union.png',
                            fit: BoxFit.contain,
                            width: 320,
                            height: 320,
                          ),
                        ),
                      ),
                    ),

                    // 主要内容（图标区整体下移 10dp）
                    Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                // 图标 - 统一高度 180，图片 5:7、道具图标方形
                SizedBox(
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 道具类型始终显示对应图标
                      if (!isImage && iconAsset != null)
                        Center(
                          child: Image.asset(
                            iconAsset,
                            width: 120,
                            height: 120,
                          ),
                        )
                      // 图片类型：如果关卡没解锁（locked 或 progressNeeded），显示默认 silhouette 图片
                      else if (isImage && (card.state == TreasureCardState.locked || card.state == TreasureCardState.progressNeeded))
                        Center(
                          child: Container(
                            width: 100,
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Image.asset(
                                'assets/images/ic_draw.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                      // 图片类型：可 PLAY/可领（claimable 或 rvNeeded）直接显示真实图，无遮罩无默认图
                      else if (isImage &&
                          (card.state == TreasureCardState.claimable ||
                              card.state == TreasureCardState.rvNeeded) &&
                          treasureImageId != null)
                        Center(
                          child: Container(
                            width: 100,
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: SmartImageWidget(
                                imageId: treasureImageId,
                                userType: userType,
                                width: 100,
                                height: 140,
                                alignment: Alignment.topCenter,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                      // 图片类型：已领取等其余状态，走遮罩逻辑
                      else if (isImage && treasureImageId != null)
                        Center(
                          child: Transform.rotate(
                            angle: 0, // 移除旋转，角度设为0
                            child: Container(
                              width: 100,
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: _buildTreasureImageWithMask(
                                  ref: ref,
                                  treasureImageId: treasureImageId,
                                  imageSequence: card.imageSequence ?? 1,
                                  userType: userType,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Positioned(
                        right: 10,
                        bottom: 50,
                        child: Stack(
                          children: [
                            // 底层：黑色描边
                            Text(
                              rewardText,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 2
                                  ..color = Colors.black,
                              ),
                            ),
                            // 上层：白色填充
                            Text(
                              rewardText,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 底部按钮区：贴底、半透明黑衬底、仅底部两角圆角、上下 padding 10
          if (action.text.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Center(
                  child: SmallButton(
                    text: action.text,
                    iconPath: action.iconPath,
                    iconColor: Colors.white,
                    iconSize: 14,
                    width: 110,
                    height: 26,
                    style: SmallButtonStyle.green,
                    size: SmallButtonSize.small,
                    backgroundColor: action.backgroundColor,
                    textColor: Colors.white,
                    borderRadius: 10,
                    enabled: action.enabled,
                    onPressed: action.enabled ? action.onTap : null,
                  ),
                ),
              ),
            ),

          // 状态图标（锁定或已领取）- 简化显示逻辑
          if (card.state == TreasureCardState.locked || card.state == TreasureCardState.progressNeeded)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            )
          else if (card.state == TreasureCardState.claimed)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
              },
            ),
          ),
    ),
    );
  }
}

class _CardActionDescriptor {
  final String text;
  final String? iconPath;
  final Color backgroundColor;
  final bool enabled;
  final VoidCallback? onTap;

  const _CardActionDescriptor({
    required this.text,
    this.iconPath,
    required this.backgroundColor,
    this.enabled = true,
    this.onTap,
  });
}

/// 根据卡片类型构建奖励弹窗项
RewardItem _buildRewardItem(TreasureCard card) {
  switch (card.type) {
    case TreasureRewardType.coin:
      return RewardItem(
        type: RewardType.coin,
        amount: card.amount,
        title: 'DAILY REWARD',
        description: 'COINS',
        iconPath: 'assets/spin/conins_big.png',
      );
    case TreasureRewardType.undo:
      return RewardItem(
        type: RewardType.undo,
        amount: card.amount,
        title: 'REVOCATION',
        description: 'ADD UNDO',
        iconPath: 'assets/spin/undo_big.png',
      );
    case TreasureRewardType.reminder:
      return RewardItem(
        type: RewardType.reminder,
        amount: card.amount,
        title: 'REMIND',
        description: 'REMINDER',
        iconPath: 'assets/spin/reminder_big.png',
      );
    case TreasureRewardType.pipe:
      return RewardItem(
        type: RewardType.pipe,
        amount: card.amount,
        title: 'PIPE',
        description: 'ADD PIPE',
        iconPath: 'assets/spin/tube_big.png',
      );
    case TreasureRewardType.image:
      // 图片类型不应该走 CLAIM 路径，这里仅作兜底
      return const RewardItem(
        type: RewardType.coin,
        amount: 0,
        title: 'IMAGE',
        description: 'IMAGE UNLOCKED',
        iconPath: 'assets/ic_success_2x.png',
      );
  }
}

/// 调试浮动按钮
class _DebugFloatingButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      backgroundColor: Colors.purple,
      child: const Icon(Icons.bug_report, color: Colors.white),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.grey[900],
          builder: (context) => _DebugPanel(ref: ref),
        );
      },
    );
  }
}

/// 调试面板
class _DebugPanel extends StatelessWidget {
  final WidgetRef ref;

  const _DebugPanel({required this.ref});

  @override
  Widget build(BuildContext context) {
    final currentLevel = ref.watch(levelProvider).currentLevel;

    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🐛 宝藏调试面板',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '当前关卡: LEVEL $currentLevel',
              style: const TextStyle(color: Colors.white70),
            ),
            const Divider(color: Colors.white30, height: 30),

            // 打印完整状态
            _buildDebugButton(
              context,
              icon: Icons.info_outline,
              label: '📋 打印完整状态',
              color: Colors.blue,
              onPressed: () {
                TreasureDebug.printFullState(ref);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已在控制台输出完整状态')),
                );
              },
            ),

            // 强制刷新
            _buildDebugButton(
              context,
              icon: Icons.refresh,
              label: '🔄 强制刷新状态',
              color: Colors.green,
              onPressed: () async {
                await TreasureDebug.forceRefresh(ref);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已刷新宝藏状态')),
                  );
                }
              },
            ),

            // 延迟刷新
            _buildDebugButton(
              context,
              icon: Icons.schedule,
              label: '⏱️  延迟刷新 (300ms)',
              color: Colors.cyan,
              onPressed: () async {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('等待300ms后刷新...')),
                  );
                }
                await Future.delayed(const Duration(milliseconds: 300));
                await TreasureDebug.forceRefresh(ref);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('延迟刷新完成'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),

            // 设置关卡到10级
            _buildDebugButton(
              context,
              icon: Icons.arrow_upward,
              label: '⬆️  设置关卡到 LEVEL 10',
              color: Colors.orange,
              onPressed: () async {
                await TreasureDebug.testLevelChange(ref, 10);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('关卡已设置到 LEVEL 10')),
                  );
                }
              },
            ),

            // 设置关卡到3级
            _buildDebugButton(
              context,
              icon: Icons.arrow_downward,
              label: '⬇️  设置关卡到 LEVEL 3',
              color: Colors.teal,
              onPressed: () async {
                await TreasureDebug.testLevelChange(ref, 3);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('关卡已设置到 LEVEL 3')),
                  );
                }
              },
            ),

            // 重置宝藏
            _buildDebugButton(
              context,
              icon: Icons.delete_forever,
              label: '⚠️  重置所有宝藏数据',
              color: Colors.red,
              onPressed: () async {
                // 二次确认
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认重置'),
                    content: const Text('这将清空所有宝藏进度，确定要继续吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('确定', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  await TreasureDebug.resetTreasure(ref);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已重置所有宝藏数据')),
                  );
                }
              },
            ),

            const SizedBox(height: 20),
            const Text(
              '💡 提示: 所有操作的详细日志会输出到控制台',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.centerLeft,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

_CardActionDescriptor _resolveAction(BuildContext context, WidgetRef ref, TreasureCard card, bool isImage) {
  final notifier = ref.read(treasureProvider.notifier);

  void showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  switch (card.state) {
    case TreasureCardState.claimed:
      // 图片类型完成后不显示按钮
      if (isImage) {
        return const _CardActionDescriptor(
          text: '',
          backgroundColor: Colors.transparent,
          enabled: false,
          onTap: null,
        );
      }
      return _CardActionDescriptor(
        text: 'COMPLETED',
        backgroundColor: Colors.grey,
        enabled: false,
        onTap: () => showToast('已解锁'),
      );
    case TreasureCardState.claimable:
      if (isImage) {
        return _CardActionDescriptor(
          text: 'PLAY',
          backgroundColor: const Color(0xFF7C3AED),
          onTap: () async {
            final config = ref.read(firebaseConfigProvider).valueOrNull;
            const fallbackTreasureCount = 18;
            final configuredTreasureCount = config?.treasure.totalCount ?? fallbackTreasureCount;
            final effectiveTreasureCount =
                configuredTreasureCount > 0 ? configuredTreasureCount : fallbackTreasureCount;

            var imageIndex = card.imageSequence ?? 1;
            if (imageIndex < 1) {
              imageIndex = 1;
            } else if (imageIndex > effectiveTreasureCount) {
              imageIndex = effectiveTreasureCount;
            }
            final treasureImageId = 'pass_c_$imageIndex';

            // 设置当前选择的宝藏图片游戏
            // 注意：setId=999 是宝藏图片的特殊标识，使用 imageId 让 SmartImageWidget 根据配置加载资源
            ref.read(photoSetGameSelectionProvider.notifier).state = SelectedPhotoSlot(
              setId: 999, // 使用特殊setId标识宝藏图片
              slotIndex: imageIndex, // 使用实际的图片序号
              assetPath: treasureImageId,
              type: ImageType.C, // 宝藏图片使用C类型
            );

            // 直接导航到游戏页面，使用宝藏图片
            if (!context.mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MainGamePage(),
              ),
            );
          },
        );
      } else {
        return _CardActionDescriptor(
          text: 'CLAIM',
          backgroundColor: const Color(0xFF10EC9F),
          onTap: () async {
            await notifier.claim(card.index);
            if (!context.mounted) return;
            AudioActions.playSuccessSound(ref);
            // ✅ 按类型弹出对应奖励弹窗
            final reward = _buildRewardItem(card);
            await showSingleRewardDialog(
              context,
              reward: reward,
              onClose: () => Navigator.of(context).pop(),
              onReceive: () async {
                Navigator.of(context).pop();

                // 显示成功提示
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已领取: ${reward.title} x${reward.amount}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            );
          },
        );
      }
    case TreasureCardState.rvNeeded:
      return _CardActionDescriptor(
        text: '${card.rvProgress}/${card.needRv}',
        iconPath: Assets.assetsIcPlay,
        backgroundColor: const Color(0xFFFF9E46),
        onTap: () async {
          await notifier.watchRv(card.index);
        },
      );
    case TreasureCardState.progressNeeded:
      return _CardActionDescriptor(
        text: 'LOCKED',
        backgroundColor: Colors.grey,
        enabled: false,
        onTap: () {
          showToast('请先完成上一项奖励');
        },
      );
    case TreasureCardState.locked:
      // 图片类型显示 "LEVEL X"，道具类型显示 "UNLOCK"
      final text = isImage && card.needLevel != null ? 'LEVEL ${card.needLevel}' : 'UNLOCK';
      return _CardActionDescriptor(
        text: text,
        backgroundColor: Colors.grey,
        enabled: false,
        onTap: () {
          if (card.needLevel != null) {
            showToast('Reach level ${card.needLevel} to unlock');
          } else {
            showToast('前置条件未满足');
          }
        },
      );
  }
}
