import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../widgets/black_text_button.dart';
import '../../widgets/reward_dialog.dart';
import '../../providers/audio_providers.dart';
import '../../providers/app_providers.dart';
import '../../utils/game_logger.dart';
import '../../services/storage/prefs_service.dart';
import '../../services/ads/ad_manager.dart';
import '../../services/ads/ads_service.dart';
import 'signin_providers.dart';

bool _signInDialogShowing = false;

class SignInDialog extends ConsumerStatefulWidget {
  const SignInDialog({super.key});

  @override
  ConsumerState<SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends ConsumerState<SignInDialog> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AdManager _adManager;

  @override
  void initState() {
    super.initState();

    // 初始化广告管理器
    final adsService = ref.read(adsServiceProvider);
    _adManager = AdManager.getInstance(adsService);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(signInProvider);
    final prefs = ref.watch(prefsServiceProvider);
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
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.black.withOpacity(0.45),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: _buildDialogSurface(context, async, prefs),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogSurface(BuildContext context, AsyncValue<SignInState> async, PrefsService prefs) {
    return Container(
      width: 500,
      height: 600,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/diaog_bg_big.png'),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (e, _) => Center(
              child: Text('Error: $e', style: const TextStyle(color: Colors.white, decoration: TextDecoration.none))),
          data: (s) => _buildContent(context, s, prefs),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SignInState s, PrefsService prefs) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 50),
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildDailySignIn(context, s, prefs),
          const SizedBox(height: 40),
          _buildBottomButtons(context, s),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: _buildOutlinedText(
            'DAILY SIGN-IN',
            const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        // 关闭按钮在右上角
        Positioned(
          top: 0,
          right: 0,
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

  Widget _buildDailySignIn(BuildContext context, SignInState s, PrefsService prefs) {
    final cycleClaimed = _cycleClaimedDays(s);

    GameLogger.log(GameLogger.tagSignIn,
        'dayIndex=${s.dayIndex}, totalDays=${s.totalSignInDays}, cycleClaimed=$cycleClaimed, claimedToday=${s.claimedToday}');
    GameLogger.log(GameLogger.tagSignIn, 'firstSignDate=${s.firstSignDate}, lastSignDate=${s.lastSignDate}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 第一排：1-4天
        Row(
          children: [
            for (var day = 1; day <= 4; day++)
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.only(right: day < 4 ? 8 : 0),
                  child: _buildDailyCell(
                    day: day,
                    reward: s.dailyRewards[day - 1],
                    // 当天高亮：今天未签到且是今天
                    isToday: !s.claimedToday && day == s.dayIndex,
                    // 已签到条件：自然签到
                    claimed: _isNaturalSigned(day, s),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // 第二排：5-7天（第7天占2个格子宽度）
        Row(
          children: [
            for (var day = 5; day <= 7; day++)
              Expanded(
                flex: day == 7 ? 2 : 1,
                child: Padding(
                  padding: EdgeInsets.only(right: day < 7 ? 8 : 0),
                  child: _buildDailyCell(
                    day: day,
                    reward: s.dailyRewards[day - 1],
                    // 当天高亮：今天未签到且是今天
                    isToday: !s.claimedToday && day == s.dayIndex,
                    // 已签到条件：自然签到
                    claimed: _isNaturalSigned(day, s),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyCell({
    required int day,
    required SignReward reward,
    required bool isToday,
    required bool claimed,
  }) {
    GameLogger.log(GameLogger.tagSignIn,
        'Cell day=$day: reward.type=${reward.type.name}, reward.amount=${reward.amount}, isToday=$isToday, claimed=$claimed');

    // 当天高亮背景色 #336A70
    final backgroundColor = isToday ? HexColor('#336A70') : HexColor('#3B4B50').withOpacity(0.5);
    final label = '${day}Day';
    final displayText = claimed ? '✓' : '+${reward.amount}';
    final icon = _getRewardIcon(reward.type);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: backgroundColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 4),
          _buildOutlinedText(
            label,
            const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Image.asset(icon, width: 40, height: 40),
          const SizedBox(height: 4),
          // 显示文本，不可点击（领取逻辑移到底部按钮）
          _buildOutlinedText(
            displayText,
            TextStyle(
              color: claimed ? Colors.green : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  int _cycleClaimedDays(SignInState s) => s.cycleClaimedDays.length;

  /// 检查指定天数是否已自然签到
  bool _isNaturalSigned(int day, SignInState s) {
    return s.cycleClaimedDays.contains(day);
  }

  /// 构建底部按钮区域（样式参考 game_success_page 的 BlackTextButtonStyle）
  Widget _buildBottomButtons(BuildContext context, SignInState s) {
    final canClaim = !s.claimedToday;
    const buttonHeight = 50.0;

    // 已签到：只显示 OK 按钮（与 DOUBLE 同款背景，无图标）
    if (!canClaim) {
      return SizedBox(
        width: double.infinity,
        height: buttonHeight,
        child: BlackTextButtonStyle.normalImageBackground(
          text: 'OK',
          width: double.infinity,
          height: buttonHeight,
          onTap: () {
            AudioActions.playClickSound(ref);
            Navigator.of(context).pop();
          },
        ),
      );
    }

    // 未签到：显示 DOUBLE 和 GET 按钮
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: BlackTextButtonStyle.withPlayIcon(
            text: 'DOUBLE',
            width: double.infinity,
            height: buttonHeight,
            iconSize: 20,
            onTap: () {
              AudioActions.playClickSound(ref);
              _claimDouble(context);
            },
          ),
        ),
        const SizedBox(height: 12),
        // GET 按钮：白字加粗，无背景
        GestureDetector(
          onTap: () {
            AudioActions.playClickSound(ref);
            _claimDaily(context);
          },
          child: SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: Center(
              child: Text(
                'GET',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getRewardIcon(SignRewardType type) {
    switch (type) {
      case SignRewardType.coin:
        return 'assets/spin/coin_small.png';
      case SignRewardType.undo:
        return 'assets/spin/undo_small.png';
      case SignRewardType.reminder:
        return 'assets/spin/reminder_small.png';
      case SignRewardType.pipe:
        return 'assets/spin/tube_small.png';
    }
  }

  RewardItem _convertToRewardItem(SignReward reward) {
    switch (reward.type) {
      case SignRewardType.coin:
        return RewardItem(
          type: RewardType.coin,
          amount: reward.amount,
          title: 'DAILY REWARD',
          description: 'COINS',
          iconPath: 'assets/spin/conins_big.png',
        );
      case SignRewardType.undo:
        return RewardItem(
          type: RewardType.undo,
          amount: reward.amount,
          title: 'REVOCATION',
          description: 'ADD UNDO',
          iconPath: 'assets/spin/undo_big.png',
        );
      case SignRewardType.reminder:
        return RewardItem(
          type: RewardType.reminder,
          amount: reward.amount,
          title: 'REMIND',
          description: 'REMINDER',
          iconPath: 'assets/spin/reminder_big.png',
        );
      case SignRewardType.pipe:
        return RewardItem(
          type: RewardType.pipe,
          amount: reward.amount,
          title: 'PIPE',
          description: 'ADD PIPE',
          iconPath: 'assets/spin/tube_big.png',
        );
    }
  }

  Future<void> _claimDaily(BuildContext context) async {
    try {
      GameLogger.log(GameLogger.tagSignIn, '开始日常签到（普通领取）');

      // 直接调用签到逻辑，不需要看视频，倍数为1
      final ok = await ref.read(signInProvider.notifier).claimDailyWithoutAd(multiplier: 1);
      if (!context.mounted) return;

      if (ok) {
        // 播放成功音效
        AudioActions.playSuccessSound(ref);

        // 先关闭主签到弹窗，再在下方页面上弹出成功奖励弹窗
        final state = ref.read(signInProvider).value;
        if (state != null && state.lastClaimedReward != null) {
          final rewardItem = _convertToRewardItem(state.lastClaimedReward!);
          final navigator = Navigator.of(context);
          navigator.pop(); // 关闭主签到弹窗
          await Future.microtask(() {}); // 等待关闭完成
          if (navigator.context.mounted) {
            await showSingleRewardDialog(
              navigator.context,
              reward: rewardItem,
              onClose: () => Navigator.of(navigator.context).pop(),
              onReceive: () => Navigator.of(navigator.context).pop(),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('签到失败'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      GameLogger.log(GameLogger.tagSignIn, '日常签到异常: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('签到异常，请稍后重试'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _claimDouble(BuildContext context) async {
    try {
      GameLogger.log(GameLogger.tagSignIn, '开始播放双倍签到激励视频广告');

      // 使用 AdManager 播放激励视频广告
      final result = await _adManager.showRewardedAd(
        placement: AdPlacements.signinDouble,
        onStart: () {
          GameLogger.log(GameLogger.tagSignIn, '双倍签到广告开始播放');
        },
        onCompleted: () {
          GameLogger.log(GameLogger.tagSignIn, '双倍签到广告播放完成');
        },
        onSkipped: () {
          GameLogger.log(GameLogger.tagSignIn, '用户跳过双倍签到广告');
        },
        onFailed: (error) {
          GameLogger.log(GameLogger.tagSignIn, '双倍签到广告播放失败: $error');
        },
      );

      if (!context.mounted) return;

      if (result == AdResult.completed) {
        // 广告播放成功，调用双倍签到逻辑
        GameLogger.log(GameLogger.tagSignIn, '广告完成，调用双倍签到逻辑');
        final ok = await ref.read(signInProvider.notifier).claimDailyWithoutAd(multiplier: 2);
        GameLogger.log(GameLogger.tagSignIn, 'claimDailyWithoutAd 返回结果: ok=$ok');

        if (ok) {
          // 播放成功音效
          AudioActions.playSuccessSound(ref);

          // 先关闭主签到弹窗，再在下方页面上弹出成功奖励弹窗
          final state = ref.read(signInProvider).value;
          if (state != null && state.lastClaimedReward != null) {
            final rewardItem = _convertToRewardItem(state.lastClaimedReward!);
            final navigator = Navigator.of(context);
            navigator.pop(); // 关闭主签到弹窗
            await Future.microtask(() {}); // 等待关闭完成
            if (navigator.context.mounted) {
              await showSingleRewardDialog(
                navigator.context,
                reward: rewardItem,
                onClose: () => Navigator.of(navigator.context).pop(),
                onReceive: () => Navigator.of(navigator.context).pop(),
              );
            }
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('双倍签到失败'),
              backgroundColor: Colors.red,
            ));
          }
        }
      } else {
        // 广告未完成或失败
        String message = '需要完整观看广告才能获得双倍奖励';
        if (result == AdResult.failed) {
          message = '广告播放失败，请稍后重试';
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
          ));
        }
      }
    } catch (e) {
      GameLogger.log(GameLogger.tagSignIn, '双倍签到广告异常: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('广告播放异常，请稍后重试'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Widget _buildOutlinedText(String text, TextStyle style) {
    const strokeWidth = 2.0;
    // 确保原始样式包含 decoration: TextDecoration.none
    final baseStyle = style.copyWith(decoration: TextDecoration.none);

    // 轮廓样式需要单独设置，因为 foreground 会覆盖 decoration
    final outlineStyle = TextStyle(
      color: Colors.transparent, // 让前景色透明，只显示轮廓
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      decoration: TextDecoration.none,
    ).copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.black,
    );

    return Stack(
      children: [
        Text(text, style: outlineStyle),
        Text(text, style: baseStyle),
      ],
    );
  }
}

/// 显示签到弹窗
Future<void> showSignInDialog(BuildContext context) async {
  if (_signInDialogShowing) return;
  _signInDialogShowing = true;
  try {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => const SignInDialog(),
    );
  } finally {
    _signInDialogShowing = false;
  }
}
