import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../generated/assets.dart';
import '../../models/game_items.dart';
import '../../models/image_item.dart';
import '../../providers/app_providers.dart';
import '../../providers/game_items_providers.dart';
import '../../providers/level_providers.dart';
import '../../providers/audio_providers.dart';
import '../../providers/user_type_provider.dart';
import '../../services/ads/ads_service.dart';
import '../../services/analytics_manager.dart';
import '../../services/image_loader_service.dart';
import '../../utils/game_logger.dart';
import '../../widgets/coin_display.dart';
import '../../widgets/reward_dialog.dart';
import '../../widgets/small_button.dart';
import '../photo_album/photo_set_providers.dart';
import 'game_page_base.dart';
import '../game_result/game_fail_page.dart';
import '../photo_unlock/photo_unlock_page.dart';
import '../../widgets/settings_dialog.dart';
import '../treasure/treasure_providers.dart';
import '../home/home_page.dart';
import 'game_manager.dart';

/// 主游戏页面
class MainGamePage extends ConsumerStatefulWidget {
  final GameCallbacks? callbacks;

  const MainGamePage({
    super.key,
    this.callbacks,
  });

  @override
  ConsumerState<MainGamePage> createState() => _MainGamePageState();
}

class _MainGamePageState extends ConsumerState<MainGamePage> {
  @override
  void initState() {
    super.initState();
    // 播放游戏背景音乐
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioActions.playGamingMusic(ref);
      GameLogger.log(GameLogger.tagGame, '开始播放游戏背景音乐');

      // 记录游戏开始埋点 - 根据游戏模式上报不同的事件
      _logGameStartAnalytics();
    });
  }

  /// 记录游戏开始埋点
  void _logGameStartAnalytics() {
    final analytics = AnalyticsManager();
    final levelState = ref.read(levelProvider);
    final secretSelection = ref.read(photoSetGameSelectionProvider);

    // 检查游戏模式
    bool isSecret = secretSelection != null && secretSelection.setId != 999;
    bool isTreasure = secretSelection != null && secretSelection.setId == 999;

    if (isSecret) {
      // 套图模式
      analytics.logStart(); // start
      analytics.logStartSecret(); // start_secret
      analytics.incrementAndLogPlayCount(); // 累计次数 +1（跨模式累积）
    } else if (isTreasure) {
      // 通行证模式
      analytics.logStart(); // start
      analytics.logStartTreasure(); // start_trsasure
      analytics.incrementAndLogPlayCount(); // 累计次数 +1（跨模式累积）
    } else {
      // 普通模式
      analytics.logStart(); // start
      analytics.logStartLevelBase(); // start_level
      analytics.logStartLevel(levelState.currentLevel); // start_level_1, start_level_2, etc.
      analytics.incrementAndLogPlayCount(); // 累计次数 +1（跨模式累积）
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelState = ref.watch(levelProvider);
    final secretSelection = ref.watch(photoSetGameSelectionProvider);
    final userType = ref.watch(userTypeProvider);

    // 优先使用套图选择的图片路径
    final backgroundImage =
        secretSelection?.assetPath ?? levelState.currentLevelImagePath ?? 'assets/pic_level/b/level_b_1.png';

    // 如果是套图游戏，使用imageId来智能加载图片
    // 但宝藏图片(setId=999)不使用imageId，直接使用assetPath
    final String? backgroundImageId = secretSelection != null && secretSelection.setId != 999
        ? 'secret_${secretSelection.setId}_${secretSelection.slotIndex}'
        : null;

    // 调试日志
    GameLogger.log(GameLogger.tagGame, '背景图片: $backgroundImage, imageId: $backgroundImageId, 用户类型: ${userType.name}');

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SmartImageWidget(
              imageId: backgroundImageId,
              imagePath: backgroundImage,
              userType: userType,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 头部状态栏
                _buildHeader(context, ref),
                // 中央游戏区域
                Expanded(
                  child: _buildGameContent(context, ref),
                ),
                // 底部广告
                _buildBottomAd(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建头部状态栏
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final levelState = ref.watch(levelProvider);
    final secretSelection = ref.watch(photoSetGameSelectionProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧设置按钮
          GestureDetector(
            onTap: () {
              final levelState = ref.read(levelProvider);
              showSettingsDialog(
                context,
                showGameActions: true,
                onContinue: () {
                  // no-op; just close dialog
                },
                onRestart: () {
                  final level = levelState.currentLevel;
                  GameNavigator.navigateToSimplePuzzleGame(
                    context: context,
                    level: level,
                    callbacks: DefaultGameCallbacks(context: context, ref: ref),
                    ref: ref,
                  );
                },
                onQuit: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
                  );
                },
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          // 中央关卡显示 - 套图游戏显示Secret，宝藏游戏显示Treasure，普通游戏显示Level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              secretSelection != null
                  ? (secretSelection.setId == 999 ? 'TREASURE' : 'SECRET')
                  : 'LEVEL ${levelState.currentLevel}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 右侧金币显示
          const CoinDisplay(),
        ],
      ),
    );
  }

  /// 构建游戏内容区域
  Widget _buildGameContent(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
          ),
        ),
        // 游戏内容
        _buildGameArea(context, ref),
        // 操作按钮
        _buildActionButtons(context, ref),
      ],
    );
  }

  /// 构建游戏区域（拼图占位符）
  Widget _buildGameArea(BuildContext context, WidgetRef ref) {
    final itemsState = ref.watch(gameItemsProvider);

    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: SizedBox(
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 拼图管子
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return _buildPuzzleTube(context, index);
              }),
            ),
            const SizedBox(height: 20),
            // 游戏控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildItemButton(context, ref, itemsState, GameItemType.clear, Icons.refresh_sharp),
                _buildItemButton(context, ref, itemsState, GameItemType.undo, Icons.undo),
                _buildItemButton(context, ref, itemsState, GameItemType.bottle, Icons.add),
                _buildItemButton(context, ref, itemsState, GameItemType.hint, Icons.lightbulb),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建拼图管子
  Widget _buildPuzzleTube(BuildContext context, int index) {
    final colors = [
      [Colors.lightBlue, Colors.green, Colors.orange],
      [Colors.yellow, Colors.yellow, Colors.yellow],
      [Colors.lightBlue, Colors.lightBlue, Colors.lightBlue],
      [Colors.green, Colors.orange, Colors.purple],
    ];

    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: colors[index].map((color) {
          return Container(
            width: 40,
            height: 20,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建道具按钮
  Widget _buildItemButton(
    BuildContext context,
    WidgetRef ref,
    UserItemInventory itemsState,
    GameItemType itemType,
    IconData icon,
  ) {
    final itemCount = itemsState.getItemCount(itemType);
    final hasItem = itemsState.hasItem(itemType);

    return GestureDetector(
      onTap: () => _handleItemTap(context, ref, itemType, hasItem),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasItem ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: hasItem ? Border.all(color: Colors.cyan, width: 1) : null,
            ),
            child: Icon(
              icon,
              color: hasItem ? Colors.white : Colors.white.withOpacity(0.5),
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$itemCount',
            style: TextStyle(
              color: hasItem ? Colors.white : Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _handleItemTap(BuildContext context, WidgetRef ref, GameItemType itemType, bool hasItem) {
    if (itemType == GameItemType.clear) {
      // todo refresh
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已清空拼图'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }
    if (hasItem) {
      _useItem(context, ref, itemType);
      return;
    }

    _showItemAcquireDialog(context, ref, itemType);
  }

  /// 使用道具
  void _useItem(BuildContext context, WidgetRef ref, GameItemType itemType) {
    final itemsNotifier = ref.read(gameItemsProvider.notifier);
    final currentLevel = ref.read(levelProvider).currentLevel;

    // 使用道具
    itemsNotifier.useItem(itemType, level: currentLevel, metadata: {
      'game_type': 'simple_puzzle',
      'timestamp': DateTime.now().toIso8601String(),
    }).then((success) {
      if (success) {
        _handleItemUsage(context, itemType);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${GameItemData.getItem(itemType).name}道具不足'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  /// 处理道具使用
  void _handleItemUsage(BuildContext context, GameItemType itemType) {
    switch (itemType) {
      case GameItemType.undo:
        _handleUndo(context);
        break;
      case GameItemType.clear:
        _handleClear(context);
        break;
      case GameItemType.hint:
        _handleHint(context);
        break;
      case GameItemType.bottle:
        _handleAdd(context);
        break;
    }
  }

  /// 处理撤销
  void _handleUndo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('撤销上一步操作'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: 实现撤销逻辑
  }

  /// 处理清除
  void _handleClear(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('清除所有操作'),
        backgroundColor: Colors.orange,
      ),
    );
    // TODO: 实现清除逻辑
  }

  /// 处理提示
  void _handleHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('获得游戏提示'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: 实现提示逻辑
  }

  /// 处理添加
  void _handleAdd(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('添加额外道具'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: 实现添加逻辑
  }

  void _showItemAcquireDialog(BuildContext context, WidgetRef ref, GameItemType itemType) {
    final userProgress = ref.read(userProgressProvider);
    final coins = userProgress.maybeWhen(data: (value) => value.coins, orElse: () => 0);
    final reward = _rewardItemForType(itemType);
    final cost = _getItemCoinCost(itemType);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return RewardDialog(
          mode: RewardDialogMode.single,
          rewards: [reward],
          onClose: () => Navigator.of(dialogContext).pop(),
          bottomContent: _buildAcquireButtons(
            dialogContext: dialogContext,
            rootContext: context,
            ref: ref,
            itemType: itemType,
            cost: cost,
            userCoins: coins,
          ),
        );
      },
    );
  }

  Widget _buildAcquireButtons({
    required BuildContext dialogContext,
    required BuildContext rootContext,
    required WidgetRef ref,
    required GameItemType itemType,
    required int cost,
    required int userCoins,
  }) {
    final canAfford = userCoins >= cost;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SmallButton(
          text: '$cost',
          iconPath: Assets.spinCoinSmall,
          iconSize: 16,
          width: 110,
          height: 42,
          style: SmallButtonStyle.green,
          size: SmallButtonSize.medium,
          enabled: canAfford,
          useImageBackground: true,
          backgroundImagePath: Assets.assetsIcBtnSmallGreen2x,
          onPressed: canAfford
              ? () => _handlePurchaseWithCoins(
                    rootContext: rootContext,
                    dialogContext: dialogContext,
                    ref: ref,
                    itemType: itemType,
                    cost: cost,
                  )
              : null,
        ),
        const SizedBox(width: 16),
        SmallButton(
          text: 'GET',
          iconPath: Assets.assetsIcPlay,
          iconSize: 16,
          width: 110,
          height: 42,
          style: SmallButtonStyle.blue,
          size: SmallButtonSize.medium,
          useImageBackground: true,
          backgroundImagePath: Assets.assetsIcBtnSmallBlue2x,
          onPressed: () => _handleAcquireViaVideo(
            rootContext: rootContext,
            dialogContext: dialogContext,
            ref: ref,
            itemType: itemType,
          ),
        ),
      ],
    );
  }

  Future<void> _handlePurchaseWithCoins({
    required BuildContext rootContext,
    required BuildContext dialogContext,
    required WidgetRef ref,
    required GameItemType itemType,
    required int cost,
  }) async {
    final progressNotifier = ref.read(userProgressProvider.notifier);
    final success = await progressNotifier.consumeCoins(cost);
    if (!success) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
          content: Text('金币不足'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await ref.read(gameItemsProvider.notifier).addItem(itemType, 1);
    Navigator.of(dialogContext).pop();
    final itemName = GameItemData.getItem(itemType).name;
    ScaffoldMessenger.of(rootContext).showSnackBar(
      SnackBar(
        content: Text('已使用金币获得$itemName'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handleAcquireViaVideo({
    required BuildContext rootContext,
    required BuildContext dialogContext,
    required WidgetRef ref,
    required GameItemType itemType,
  }) async {
    final adsService = ref.read(adsServiceProvider);
    final result = await adsService.showRewarded(
      placement: 'item_acquire_${itemType.name}',
    );

    if (result == AdResult.completed) {
      await ref.read(gameItemsProvider.notifier).addItem(itemType, 1);
      Navigator.of(dialogContext).pop();
      final itemName = GameItemData.getItem(itemType).name;
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(
          content: Text('成功获取$itemName'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
          content: Text('视频未完成播放'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  RewardItem _rewardItemForType(GameItemType type) {
    switch (type) {
      case GameItemType.undo:
        return const RewardItem(
          type: RewardType.undo,
          amount: 1,
          title: 'REVOCATION',
          description: 'ADD UNDO',
          iconPath: Assets.spinUndoBig,
        );
      case GameItemType.clear:
        return const RewardItem(
          type: RewardType.reminder,
          amount: 1,
          title: 'CLEAR',
          description: 'ADD CLEAR',
          iconPath: 'assets/items/clear.png',
        );
      case GameItemType.hint:
        return const RewardItem(
          type: RewardType.reminder,
          amount: 1,
          title: 'REMIND',
          description: 'ADD REMINDER',
          iconPath: Assets.spinReminderBig,
        );
      case GameItemType.bottle:
        return const RewardItem(
          type: RewardType.bottle,
          amount: 1,
          title: 'BOTTLE',
          description: 'ADD BOTTLE',
          iconPath: Assets.spinTubeBig,
        );
    }
  }

  int _getItemCoinCost(GameItemType type) {
    switch (type) {
      case GameItemType.undo:
        return 100;
      case GameItemType.clear:
        return 50;
      case GameItemType.hint:
        return 150;
      case GameItemType.bottle:
        return 200;
    }
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Column(
          children: [
            // 成功按钮
            _buildGameButton(
              context,
              text: 'SUCCESS',
              color: Colors.green,
              onTap: () => _navigateToSuccess(context, ref),
            ),
            const SizedBox(height: 20),
            // 失败按钮
            _buildGameButton(
              context,
              text: 'FAIL',
              color: Colors.red,
              onTap: () => _navigateToFail(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建游戏按钮
  Widget _buildGameButton(
    BuildContext context, {
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              color.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建底部广告
  Widget _buildBottomAd(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // AD 标识
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // 广告内容
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 角色图标占位
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // 广告文字
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOP UP',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'DI STORE KAMI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 导航到成功页面
  void _navigateToSuccess(BuildContext context, WidgetRef ref) {
    final levelState = ref.read(levelProvider);
    final secretSelection = ref.read(photoSetGameSelectionProvider);
    final levelType = levelState.currentLevelType ?? 'b';
    final levelIndex = levelState.currentLevelIndex ?? 0;

    GameLogger.divider(GameLogger.tagGame, '游戏成功');
    GameLogger.log(GameLogger.tagGame, 'imagePath=${secretSelection?.assetPath}');
    GameLogger.log(GameLogger.tagGame, 'setId=${secretSelection?.setId}, slotIndex=${secretSelection?.slotIndex}');
    GameLogger.log(
        GameLogger.tagGame, 'levelType=$levelType, levelIndex=$levelIndex, currentLevel=${levelState.currentLevel}');

    bool isTreasure = secretSelection != null && secretSelection.setId == 999;
    bool isSecret = secretSelection != null && secretSelection.setId != 999;

    // 检查是否是宝藏游戏成功，需要刷新宝藏状态
    if (isTreasure) {
      // 记录通行宝箱关卡通关埋点（仅记录具体模式的通过，不再重复记录总通关pass）
      final analytics = AnalyticsManager();
      analytics.logPassTreasure(); // pass_trsasure (通行证通关)

      // slotIndex 已经是 imageSequence (1-18)，不需要再加1
      final sequence = secretSelection.slotIndex;
      GameLogger.log(GameLogger.tagTreasure, '宝藏游戏成功，sequence=$sequence');

      // 延迟刷新宝藏状态，确保状态更新完成
      Future.microtask(() async {
        await ref.read(treasureProvider.notifier).completeImageBySequence(sequence);
      });
    }

    // 检查是否是套图游戏
    if (isSecret) {
      // 记录私密套图关卡通关埋点（仅记录具体模式的通过，不再重复记录总通关pass）
      final analytics = AnalyticsManager();
      analytics.logPassSecret(); // pass_secret (套图通关)
      GameLogger.success(GameLogger.tagPhotoSet, '套图游戏成功，传递套图信息');

      // ✅ 更新套图状态：获取当前图片，解锁下一张
      ref.read(photoSetProvider.notifier).acquireSlot(
            secretSelection.setId,
            secretSelection.slotIndex,
          );

      // 同时更新用户进度
      ref.read(userProgressProvider.notifier).updateSecretProgress(
            secretSelection.setId,
            secretSelection.slotIndex,
          );
    }

    // 统一跳转到图片解锁页面
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PhotoUnlockPage(
          levelType: isTreasure ? 'pass_c' : (isSecret ? 'secret' : levelType),
          levelIndex: isTreasure || isSecret ? secretSelection.slotIndex : levelIndex,
          imagePath: secretSelection?.assetPath ?? levelState.currentLevelImagePath ?? '',
          imageSourceType:
              isTreasure ? ImageSourceType.treasure : (isSecret ? ImageSourceType.secret : ImageSourceType.general),
          secretSetId: secretSelection?.setId.toString(),
          secretSlotIndex: secretSelection?.slotIndex,
        ),
      ),
    );
  }

  /// 导航到失败页面
  void _navigateToFail(BuildContext context, WidgetRef ref) {
    final levelState = ref.read(levelProvider);

    if (widget.callbacks != null) {
      widget.callbacks!.onGameFailure(
        reason: '游戏失败',
        level: levelState.currentLevel,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GameFailPage(
            levelType: levelState.currentLevelType,
          ),
        ),
      );
    }
  }
}

/// 套图游戏成功页面
class SecretGameSuccessPage extends ConsumerStatefulWidget {
  final int setId;
  final int slotIndex;
  final String assetPath;
  final ImageType type;

  const SecretGameSuccessPage({
    super.key,
    required this.setId,
    required this.slotIndex,
    required this.assetPath,
    required this.type,
  });

  @override
  ConsumerState<SecretGameSuccessPage> createState() => SecretGameSuccessPageState();
}

class SecretGameSuccessPageState extends ConsumerState<SecretGameSuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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

    _animationController.forward();

    // 播放成功音效
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioActions.playSuccessSound(ref);
    });

    // 解锁图片
    Future.microtask(() async {
      await ref.read(photoSetProvider.notifier).acquireSlot(widget.setId, widget.slotIndex);

      // 增加金币奖励
      await ref.read(userProgressProvider.notifier).addCoins(30);

      // 更新用户进度中的套图完成数量
      ref.read(userProgressProvider.notifier).updateSecretProgress(widget.setId, widget.slotIndex);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF41FDFD),
              Color(0xFFA343CC),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // 顶部金币显示
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CoinDisplay(
                            backgroundColor: Color(0x33000000),
                          ),
                        ],
                      ),
                    ),
                    // 主要内容
                    Expanded(
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: _buildMainContent(),
                      ),
                    ),
                    // 底部按钮
                    _buildBottomButtons(),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // YOU WIN 标题
        const Text(
          'YOU WIN!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),
        // 解锁的图片
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SmartImageWidget(
              imagePath: widget.assetPath,
              userType: ref.read(userTypeProvider),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 成功文本
        const Text(
          'PICTURE UNLOCKED!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        // 金币奖励
        const Text(
          '+30 COINS',
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Column(
      children: [
        // NEXT 按钮
        GestureDetector(
          onTap: () {
            AudioActions.playClickSound(ref);
            _navigateToNext();
          },
          child: Container(
            width: 200,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Center(
              child: Text(
                'NEXT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToNext() {
    // 清理secret选择状态
    ref.read(photoSetGameSelectionProvider.notifier).state = null;

    // 导航到图片解锁页面，展示刚获得的SECRET类型图片
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PhotoUnlockPage(
          levelType: 'secret', // 使用secret作为类型标识
          levelIndex: widget.slotIndex, // 使用槽位索引
          imagePath: widget.assetPath,
          isWatermarked: true,
          imageSourceType: ImageSourceType.secret, // 明确指定为SECRET类型
          secretSetId: widget.setId.toString(), // 传入套图ID
          secretSlotIndex: widget.slotIndex, // 传入槽位索引
        ),
      ),
    );

    print('套图游戏成功，导航到SECRET图片解锁页面: setId=${widget.setId}, slotIndex=${widget.slotIndex}');
  }
}
