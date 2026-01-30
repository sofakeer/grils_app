import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/spin_providers.dart';
import '../../providers/audio_providers.dart';
import '../../providers/background_providers.dart';
import '../../providers/game_items_providers.dart';
import '../../providers/app_providers.dart';
import '../../providers/user_type_provider.dart';
import '../../models/game_items.dart';
import '../../services/ads/banner_placeholder.dart';
import '../../services/image_loader_service.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_image_button.dart';
import '../../widgets/reward_dialog.dart';

class SpinPage extends ConsumerStatefulWidget {
  const SpinPage({super.key});

  @override
  ConsumerState<SpinPage> createState() => _SpinPageState();
}

class _SpinPageState extends ConsumerState<SpinPage> with SingleTickerProviderStateMixin {
  double _turns = 0; // 当前旋转圈数
  bool _isSpinning = false; // 是否正在转盘中

  /// 将RewardType转换为GameItemType
  GameItemType _convertRewardTypeToGameItemType(RewardType rewardType) {
    switch (rewardType) {
      case RewardType.undo:
        return GameItemType.undo;
      case RewardType.reminder:
        return GameItemType.hint;
      case RewardType.pipe:
        return GameItemType.bottle;
      case RewardType.bottle:
        return GameItemType.bottle; // 瓶子也映射到add类型
      case RewardType.coin:
        throw ArgumentError('金币不应该转换为道具类型');
    }
  }

  /// 将转盘奖品转换为奖励弹窗数据
  RewardItem _convertPrizeToReward(SpinPrize prize) {
    switch (prize.type) {
      case SpinPrizeType.coin80:
        return RewardItem(
          type: RewardType.coin,
          amount: 80,
          title: 'DAILY REWARD',
          description: 'COINS',
          iconPath: 'assets/spin/conins_big.png',
        );
      case SpinPrizeType.coin100:
        return RewardItem(
          type: RewardType.coin,
          amount: 100,
          title: 'DAILY REWARD',
          description: 'COINS',
          iconPath: 'assets/spin/conins_big.png',
        );
      case SpinPrizeType.coin120:
        return RewardItem(
          type: RewardType.coin,
          amount: 120,
          title: 'DAILY REWARD',
          description: 'COINS',
          iconPath: 'assets/spin/conins_big.png',
        );
      case SpinPrizeType.undo1:
        return RewardItem(
          type: RewardType.undo,
          amount: 1,
          title: 'REVOCATION',
          description: 'ADD UNDO',
          iconPath: 'assets/spin/undo_big.png',
        );
      case SpinPrizeType.reminder1:
        return RewardItem(
          type: RewardType.reminder,
          amount: 1,
          title: 'REMIND',
          description: 'REMINDER',
          iconPath: 'assets/spin/reminder_big.png',
        );
      case SpinPrizeType.pipe1:
        return RewardItem(
          type: RewardType.pipe,
          amount: 1,
          title: 'PIPE',
          description: 'ADD PIPE',
          iconPath: 'assets/spin/tube_big.png',
        );
    }
  }

  /// 构建6个道具图标，平均分布在转盘上，垂直显示
  List<Widget> _buildPrizeIcons() {
    final prizes = ref.read(spinPrizesProvider);
    final List<Widget> icons = [];
    
    for (int i = 0; i < 6; i++) {
      final prize = prizes[i];
      final angle = (i * 60.0) * (math.pi / 180.0); // 每个扇区60度
      final radius = 110.0; // 距离中心的距离
      
      final x = radius * math.cos(angle - math.pi / 2); // 从顶部开始
      final y = radius * math.sin(angle - math.pi / 2);
      
      icons.add(
        Positioned(
          left: 160 + x - 40,  // 80 宽的一半
          top:  160 + y - 60,  // 120 高的一半
          child: Transform.rotate(
              // 以"正上方为 0°"，顺时针：右上约 45°、右约 90°、右下约 135°、正下 180°…
              angle: math.atan2(y, x) + math.pi / 2,
              alignment: Alignment.center,
              child: Container(
                width: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 35),
                    Text(
                      _getPrizeText(prize),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    ClipRect(
                      child: Align(
                        alignment: Alignment.center,
                        widthFactor: 0.7, // 裁剪掉20%的宽度
                        heightFactor: 0.7, // 裁剪掉20%的高度
                        child: Image.asset(
                          _getPrizeIconPath(prize),
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ), ),
      );
    }
    
    return icons;
  }

  /// 获取奖品对应的文字显示
  String _getPrizeText(SpinPrize prize) {
    switch (prize.type) {
      case SpinPrizeType.coin80:
        return '+80';
      case SpinPrizeType.coin100:
        return '+100';
      case SpinPrizeType.coin120:
        return '+120';
      case SpinPrizeType.undo1:
        return '+1';
      case SpinPrizeType.reminder1:
        return '+1';
      case SpinPrizeType.pipe1:
        return '+1';
    }
  }

  /// 获取奖品对应的图标路径
  String _getPrizeIconPath(SpinPrize prize) {
    switch (prize.type) {
      case SpinPrizeType.coin80:
      case SpinPrizeType.coin100:
      case SpinPrizeType.coin120:
        return 'assets/spin/coin_small.png';
      case SpinPrizeType.undo1:
        return 'assets/spin/undo_small.png';
      case SpinPrizeType.reminder1:
        return 'assets/spin/reminder_small.png';
      case SpinPrizeType.pipe1:
        return 'assets/spin/tube_small.png';
    }
  }

  Future<void> _onStart() async {
    // 防止重复点击
    if (_isSpinning) return;

    // 播放点击音效
    AudioActions.playClickSound(ref);

    setState(() => _isSpinning = true);

    try {
      final spin = ref.read(spinControllerProvider.notifier);
      final state = ref.read(spinControllerProvider).valueOrNull;
      if (state == null) return;
      if (state.used >= state.limit) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Continue Tomorrow')));
        }
        return;
      }
      final idx = await spin.startSpin();
      if (idx == null) return; // 广告失败或被取消

      // 让转盘旋转到目标扇区
      const seg = 6;
      final randomTurns = 20 + math.Random().nextInt(20); // 随机10-20圈
      // 指针永远向上，目标是让目标扇区转到指针位置
      // 图标按顺时针排列：index 0在顶部(0°), index 1在右上(60°), index 2在右侧(120°)...
      // 转盘需要逆时针旋转，使目标扇区移动到顶部
      // 例如：抽中index=1(位于60°)，转盘逆时针转60°，该扇区就到了顶部
      final prizes = ref.read(spinPrizesProvider);
      final selectedPrize = prizes[idx];
      debugPrint('[Spin] selected index=$idx, prize=${selectedPrize.label}');
      
      // 计算目标旋转圈数
      // 先重置到初始位置，然后旋转到目标位置
      final targetAngle = idx * (360.0 / seg); // 目标扇区的顺时针角度
      final target = randomTurns - (targetAngle / 360.0); // 逆时针旋转到目标
      
      debugPrint('[Spin] targetAngle=$targetAngle°, randomTurns=$randomTurns, targetTurns=$target');
      
      // 先重置到初始位置
      setState(() => _turns = 0);
      
      // 等待一帧后开始旋转，确保重置完成
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      
      // 开始旋转到目标位置
      setState(() => _turns = target);

      // 动画结束后弹窗提示
      await Future.delayed(const Duration(milliseconds: 3200)); // 等待转盘完全停下来
      if (!mounted) return;
      final prize = prizes[idx];
      final reward = _convertPrizeToReward(prize);

      // 播放成功音效
      AudioActions.playSuccessSound(ref);

      // 使用新的奖励弹窗
      await showSingleRewardDialog(
        context,
        reward: reward,
        onClose: () => Navigator.of(context).pop(),
        onReceive: () async {
          Navigator.of(context).pop();
          
          // 根据奖励类型添加到相应的系统中
          if (reward.type == RewardType.coin) {
            // 添加金币
            await ref.read(userProgressProvider.notifier).addCoins(reward.amount);
          } else {
            // 添加道具
            final itemType = _convertRewardTypeToGameItemType(reward.type);
            await ref.read(gameItemsProvider.notifier).addItem(itemType, reward.amount);
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已领取: ${prize.label}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );
    } finally {
      // 无论成功还是失败，都要重新启用按钮
      if (mounted) {
        setState(() => _isSpinning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(spinControllerProvider);
    final backgroundImage = ref.watch(backgroundImageProvider);
    final userType = ref.watch(userTypeProvider);

    return Scaffold(
      body: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: SmartImageWidget(
              imagePath: backgroundImage,
              userType: userType,
              fit: BoxFit.cover,
              errorWidget: Container(
                color: const Color(0xFF010013),
                child: const Center(
                  child: Icon(
                    Icons.image,
                    color: Colors.white24,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          // 内容区域
          asyncState.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
            data: (s) {
              return SafeArea(
                child: Column(
                  children: [
                    const CommonHeader(title: 'Fortune Spin',backgroundColor: Colors.transparent),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 320,
                      height: 320,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 转盘背景
                          AnimatedRotation(
                            duration: const Duration(milliseconds: 3000), // 延长到3秒，让转盘慢慢停下来
                            curve: Curves.easeOutCubic,
                            turns: _turns,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 背景图
                                Image.asset(
                                  'assets/spin/rate_bg.png',
                                  width: 320,
                                  height: 320,
                                  fit: BoxFit.contain,
                                ),
                                // 6个道具图标
                                ..._buildPrizeIcons(),
                              ],
                            ),
                          ),
                          // 中心装饰（固定不转）
                          Center(
                            child: Image.asset(
                              'assets/spin/pointer.png',
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 测试按钮 - 只在debug模式下显示
                    if (kDebugMode) ...[
                      ElevatedButton(
                        onPressed: () async {
                          AudioActions.playClickSound(ref);
                          final spin = ref.read(spinControllerProvider.notifier);
                          await spin.resetUsedCount();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('次数已重置')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('重置次数 (测试)'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    CustomImageButton(
                      normalImagePath: 'assets/_btn_mid.png',
                      pressedImagePath: 'assets/_btn_mid_click.png',
                      width: 150,
                      height: 60,
                      onPressed: (s.busy || _isSpinning)
          ? null
          : () {
              AudioActions.playClickSound(ref);
              _onStart();
            },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image(
                            image: AssetImage('assets/ic_play.png'),
                            width: 24,
                            height: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'START',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Daily available  (${s.used}/${s.limit})',
                        style: const TextStyle(fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 24),
                    const Spacer(),
                    const DummyBannerAd(height: 56, placement: 'spin_bottom'),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 顶部三角针，用于判定选中的扇区（固定在顶部不旋转）。
class _TopNeedle extends StatelessWidget {
  const _TopNeedle();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(18, 24),
      painter: _TopNeedlePainter(),
    );
  }
}

class _TopNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fill = Paint()..color = Colors.redAccent;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
