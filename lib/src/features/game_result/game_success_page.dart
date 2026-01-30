import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_image_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import '../../features/score/score_providers.dart';
import '../../providers/level_providers.dart';
import '../../providers/audio_providers.dart';
import '../../providers/user_type_provider.dart';
import '../../widgets/black_text_button.dart';
import '../../widgets/reward_dialog.dart';
import '../photo_unlock/photo_unlock_page.dart';
import '../photo_album/photo_set_providers.dart';
import '../../models/image_item.dart';
import '../../utils/game_logger.dart';
import '../../services/analytics_manager.dart';
import '../../repositories/album_repository.dart';
import '../../providers/album_providers.dart';
import '../../services/ads/ad_manager.dart';
import '../../services/ads/ads_service.dart';
import '../../providers/app_providers.dart';
import '../level/next_level_selection_dialog.dart';
import '../home/home_page.dart';
import '../game/game_manager.dart';

class GameSuccessPage extends ConsumerStatefulWidget {
  final int coinsEarned;
  final int? currentCoins;
  final VoidCallback? onClaim;
  final VoidCallback? onClaimX3;
  final VoidCallback? onNoThanks;
  final int level;
  final int? percent; // 0-100，可为空
  final Duration? clearTime; // 闯关时间
  final int? starRating; // 星级评分 1-3
  final String? levelType; // 关卡类型
  final int? levelIndex; // 关卡索引
  // 新增：自定义图片信息（用于套图等特殊场景）
  final String? customImagePath;
  final ImageSourceType? customImageSourceType;
  final String? secretSetId;
  final int? secretSlotIndex;
  // 新增：标记关卡是否已在 PhotoUnlockPage 完成（避免重复累加）
  final bool isLevelAlreadyCompleted;

  const GameSuccessPage({
    super.key,
    this.coinsEarned = 5,
    this.currentCoins,
    this.onClaim,
    this.onClaimX3,
    this.onNoThanks,
    this.level = 1,
    this.percent,
    this.clearTime,
    this.starRating,
    this.levelType,
    this.levelIndex,
    this.customImagePath,
    this.customImageSourceType,
    this.secretSetId,
    this.secretSlotIndex,
    this.isLevelAlreadyCompleted = false,
  });

  @override
  ConsumerState<GameSuccessPage> createState() => _GameSuccessPageState();
}

class _GameSuccessPageState extends ConsumerState<GameSuccessPage>
    with TickerProviderStateMixin {
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

    // 开始动画
    _animationController.forward();

    // 停止游戏背景音乐并播放成功音效
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioStateProvider.notifier).stopBackgroundMusic();
      AudioActions.playSuccessSound(ref);
    });

    // 上报通关埋点（进入结算页面时立即上报）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportPassAnalytics();
    });

    // 延迟计算奖励，确保在 widget tree 构建完成后执行
    Future.microtask(() {
      _computeRewards();
    });
  }

  /// 上报通关埋点
  void _reportPassAnalytics() {
    final analytics = AnalyticsManager();

    // 总的通关埋点（所有类型都上报）
    analytics.logPass();

    // 根据图片来源类型判断是哪种关卡
    if (widget.customImageSourceType != null) {
      switch (widget.customImageSourceType!) {
        case ImageSourceType.secret:
          // SECRET关卡
          GameLogger.log(GameLogger.tagLevel, '上报SECRET通关埋点');
          analytics.logPassSecret();
          break;
        case ImageSourceType.treasure:
          // TREASURE关卡
          GameLogger.log(GameLogger.tagLevel, '上报TREASURE通关埋点');
          analytics.logPassTreasure();
          break;
        case ImageSourceType.general:
        default:
          // 普通关卡
          GameLogger.log(GameLogger.tagLevel, '上报普通关卡通关埋点');
          analytics.logPassLevel();
          break;
      }
    } else {
      // 没有指定图片来源类型，默认为普通关卡
      GameLogger.log(GameLogger.tagLevel, '上报普通关卡通关埋点（默认）');
      analytics.logPassLevel();
    }
  }

  /// 计算奖励
  Future<void> _computeRewards() async {
    // 如果没有完成度，首次游戏默认给80%的完成度（A级评分）
    final percent = widget.percent ?? 80;
    GameLogger.divider(GameLogger.tagLevel, 'GameSuccess 计算奖励');
    GameLogger.log(GameLogger.tagLevel, 'level=${widget.level}, percent=$percent');

    try {
      // 仅计算奖励，推进关卡与pass上报在领取奖励/No Thanks时统一处理
      GameLogger.log(GameLogger.tagLevel, '调用 compute 方法...');
      await ref
          .read(levelScoreProvider.notifier)
          .compute(level: widget.level, percent: percent);
      
      GameLogger.log(GameLogger.tagLevel, 'compute 方法执行完成，读取结果...');
      
      final result = ref.read(levelScoreProvider);
      GameLogger.success(GameLogger.tagLevel, '奖励计算完成: totalCoins=${result.totalCoins}, baseCoins=${result.baseCoins}, grade=${result.grade.name}');
    } catch (e, stack) {
      GameLogger.error(GameLogger.tagLevel, '奖励计算失败: $e');
      GameLogger.error(GameLogger.tagLevel, 'Stack: ${stack.toString().split('\n').take(5).join('\n')}');
    }

    // 确保UI更新
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildOriginalContent();
  }

  Widget _buildOriginalContent() {
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                HexColor('#41FDFD'), // 从#41FDFD
                HexColor('#A343CC'), // 到#A343CC
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
                    const SizedBox(height: 20),
                    // 主要内容
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: _buildMainContent(),
                    ),
                    // 底部按钮
                    _buildBottomButtons(),
                  ],
                ),
              );
            },
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final score = ref.watch(levelScoreProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
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
        Image.asset(
          Assets.assetsIcSuccess2x,
          width: 180,
          height: 180,
        ),
        const SizedBox(height: 20),
        // 奖励数量,
        Text(
          '+${score.totalCoins}',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold),
        ),

        // // 宝箱显示（每5关一个宝箱）
        // if (levelState.currentLevel % 5 == 0) ...[
        //   const SizedBox(height: 20),
        //   _buildTreasureChest(),
        // ],
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Column(
      children: [
        const SizedBox(height: 12),
        // CLAIM X3 按钮
        Container(
          width: 200,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Stack(
            children: [
              // 带播放图标的背景图片按钮
              BlackTextButtonStyle.withPlayIcon(
                text: 'CLAIM X3',
                width: 200,
                height: 80,
                iconSize: 24,
                onTap: () async {
                  AudioActions.playClickSound(ref);
                  print('点击了CLAIM X3按钮');

                  // 等待奖励计算完成
                  await Future.delayed(const Duration(milliseconds: 100));

                  final score = ref.read(levelScoreProvider);
                  final baseCoins = score.totalCoins;

                  // 播放激励视频
                  final adsService = ref.read(adsServiceProvider);
                  final adManager = AdManager.getInstance(adsService);
                  
                  final result = await adManager.showRewardedAd(
                    placement: AdPlacements.levelClaimX3,
                    onStart: () {
                      print('激励视频开始播放');
                    },
                    onCompleted: () {
                      print('激励视频播放完成');
                    },
                    onSkipped: () {
                      print('用户跳过激励视频');
                    },
                    onFailed: (error) {
                      print('激励视频播放失败: $error');
                    },
                  );

                  if (result != AdResult.completed) {
                    // 广告未完成，不变更奖励，保留在同页
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('需要完整观看广告才能获得3倍奖励'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    return;
                  }

                  // 广告成功，奖励×3
                  final tripleCoins = baseCoins * 3;
                  await ref.read(userProgressProvider.notifier).addCoins(tripleCoins - baseCoins);
                  
                  // 奖励发放后，增加关卡（如果关卡未在 PhotoUnlockPage 完成）
                  if (!widget.isLevelAlreadyCompleted) {
                    await ref.read(levelProvider.notifier).completeLevel();
                    print('关卡已完成，level +1');
                  } else {
                    print('关卡已在 PhotoUnlockPage 完成，跳过 completeLevel');
                  }
                  
                  // 游戏成功后，消费选中的图片并触发重新随机（仅对普通关卡）
                  final levelState = ref.read(levelProvider);
                  final levelType = widget.levelType ?? levelState.currentLevelType ?? 'b';
                  final levelIndex = widget.levelIndex ?? levelState.currentLevelIndex ?? 0;
                  
                  // 判断是否是普通关卡（GENERAL类型）
                  final isGeneralLevel = widget.customImageSourceType == null || widget.customImageSourceType == ImageSourceType.general;
                  // 判断是否是套图模式（SECRET类型）
                  final isSecretLevel = widget.customImageSourceType == ImageSourceType.secret;
                  // 判断是否是通行证模式（TREASURE类型）
                  final isTreasureLevel = widget.customImageSourceType == ImageSourceType.treasure;
                  
                  // 只有普通关卡（GENERAL类型）才需要消费图片选择状态和重新随机
                  if (isGeneralLevel) {
                    final userType = ref.read(userTypeProvider);
                    final primaryType = userType == UserType.natural ? 'a' : 'b';
                    final premiumType = userType == UserType.natural ? 'a' : 'c';
                    
                    // 消费图片（消费任意一个后整体替换下一组）
                    ref.read(nextLevelSelectionProvider.notifier).consumeImage(
                      levelType,
                      levelIndex,
                      primaryType,
                      premiumType,
                    );
                    print('已消费图片选择: type=$levelType, index=$levelIndex');
                  } else if (isSecretLevel) {
                    print('套图模式（SECRET）通关，不更新主页四选一');
                    
                    // 解锁套图图片遮罩
                    if (widget.secretSetId != null && widget.secretSlotIndex != null) {
                      final albumRepo = ref.read(albumRepositoryProvider);
                      final imageId = 'secret_${widget.secretSetId}_${widget.secretSlotIndex}';
                      await albumRepo.unlockImage(imageId);
                      print('已解锁套图图片: $imageId');
                    }
                  } else if (isTreasureLevel) {
                    print('通行证模式（TREASURE）通关，不更新主页四选一');
                    
                    // 解锁通行证图片遮罩
                    if (widget.customImagePath != null) {
                      final albumRepo = ref.read(albumRepositoryProvider);
                      await albumRepo.unlockImage(widget.customImagePath!);
                      print('已解锁通行证图片: ${widget.customImagePath}');
                    }
                  }

                  // 直接弹奖励弹窗（2 秒自动关闭或触摸关闭），关闭后弹四选一
                  if (mounted) {
                    await showSingleRewardDialog(
                      context,
                      reward: RewardItem(
                        type: RewardType.coin,
                        amount: tripleCoins,
                        title: 'LEVEL REWARD',
                        description: 'RECEIVED',
                        iconPath: 'assets/spin/conins_big.png',
                      ),
                      autoCloseAfter: const Duration(seconds: 2),
                      tapContentToClose: true,
                      barrierDismissible: true,
                      // 关卡奖励弹窗不需要“领取”按钮，只展示结果
                      bottomContent: const SizedBox.shrink(),
                    );
                  }
                  if (mounted) _handleNextLevel();
                },
              ),
              // 右上角广告图标
              Positioned(
                top: 10,
                right: 0,
                child: Image.asset(
                  Assets.assetsIcAdYellow2x,
                  width: 20,
                  height: 20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            AudioActions.playClickSound(ref);

            // 等待奖励计算完成
            await Future.delayed(const Duration(milliseconds: 100));

            final coinsAmount = ref.read(levelScoreProvider).totalCoins;

            // 先播插屏，返回后奖励不变（1倍）
            final adsService = ref.read(adsServiceProvider);
            final adManager = AdManager.getInstance(adsService);
            await adManager.showInterstitialAd(placement: AdPlacements.levelClaim);

            if (!mounted) return;

            // 发放正常奖励（1倍）
            await ref.read(levelScoreProvider.notifier).claim(triple: false);

            // 奖励发放后，增加关卡（如果关卡未在 PhotoUnlockPage 完成）
            if (!widget.isLevelAlreadyCompleted) {
              await ref.read(levelProvider.notifier).completeLevel();
              print('关卡已完成，level +1');
            } else {
              print('关卡已在 PhotoUnlockPage 完成，跳过 completeLevel');
            }
            
            // 游戏成功后，消费选中的图片并触发重新随机（仅对普通关卡）
            final levelState = ref.read(levelProvider);
            final levelType = widget.levelType ?? levelState.currentLevelType ?? 'b';
            final levelIndex = widget.levelIndex ?? levelState.currentLevelIndex ?? 0;
            
            // 判断是否是普通关卡（GENERAL类型）
            final isGeneralLevel = widget.customImageSourceType == null || widget.customImageSourceType == ImageSourceType.general;
            // 判断是否是套图模式（SECRET类型）
            final isSecretLevel = widget.customImageSourceType == ImageSourceType.secret;
            // 判断是否是通行证模式（TREASURE类型）
            final isTreasureLevel = widget.customImageSourceType == ImageSourceType.treasure;
            
            // 只有普通关卡（GENERAL类型）才需要消费图片选择状态和重新随机
            if (isGeneralLevel) {
              final userType = ref.read(userTypeProvider);
              final primaryType = userType == UserType.natural ? 'a' : 'b';
              final premiumType = userType == UserType.natural ? 'a' : 'c';
              
              // 消费图片（消费任意一个后整体替换下一组）
              ref.read(nextLevelSelectionProvider.notifier).consumeImage(
                levelType,
                levelIndex,
                primaryType,
                premiumType,
              );
              print('已消费图片选择: type=$levelType, index=$levelIndex');
            } else if (isSecretLevel) {
              print('套图模式（SECRET）通关，不更新主页四选一');
            } else if (isTreasureLevel) {
              print('通行证模式（TREASURE）通关，不更新主页四选一');
            }
            
            // 执行自定义回调（如果有）
            if (widget.onNoThanks != null) {
              widget.onNoThanks!();
            }

            // 直接弹奖励弹窗（2 秒自动关闭或触摸关闭），关闭后弹四选一
            if (mounted) {
              await showSingleRewardDialog(
                context,
                reward: RewardItem(
                  type: RewardType.coin,
                  amount: coinsAmount,
                  title: 'LEVEL REWARD',
                  description: 'RECEIVED',
                  iconPath: 'assets/spin/conins_big.png',
                ),
                autoCloseAfter: const Duration(seconds: 2),
                tapContentToClose: true,
                barrierDismissible: true,
                // 关卡奖励弹窗不需要“领取”按钮，只展示结果
                bottomContent: const SizedBox.shrink(),
              );
            }
            if (mounted) _handleNextLevel();
          },
          child: const Text(
            'CLAIM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// 普通关卡：先弹四选一；选关后直接进游戏（与首页一致），关掉弹窗不选则回首页。
  /// 套图/通行证：直接 pop 回来源页（哪里来的回哪里）。
  Future<void> _handleNextLevel() async {
    final isGeneralLevel = widget.customImageSourceType == null ||
        widget.customImageSourceType == ImageSourceType.general;

    if (isGeneralLevel && mounted) {
      await showNextLevelSelectionDialog(
        context,
        onLevelChosen: (levelType, levelIndex) async {
          final imageId = 'level_${levelType}_${levelIndex + 1}';
          await ref.read(levelProvider.notifier).setCurrentLevelSelection(
                levelType: levelType,
                levelIndex: levelIndex,
                imageId: imageId,
              );
          if (!context.mounted) return;
          Navigator.of(context).pop(); // 关掉 GameSuccessPage
          final levelState = ref.read(levelProvider);
          GameNavigator.navigateToGame(
            context: context,
            gameType: GameType.simplePuzzle,
            level: levelState.currentLevel,
            callbacks: DefaultGameCallbacks(context: context, ref: ref),
            ref: ref,
          );
        },
      );
      // 用户关掉四选一未选关：回首页
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } else {
      // 套图模式、通行证模式：直接回来源页
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _navigateToPhotoUnlock() {
    // 逻辑已改为 handleNextLevel
    _handleNextLevel();
  }
}
