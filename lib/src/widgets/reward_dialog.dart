import 'dart:ui';
import 'package:flutter/material.dart';
import 'small_button.dart';

/// 奖励类型枚举
enum RewardType {
  coin,
  undo,
  reminder,
  bottle,
  pipe,
}

/// 奖励数据模型
class RewardItem {
  final RewardType type;
  final int amount;
  final String title;
  final String description;
  final String iconPath;

  const RewardItem({
    required this.type,
    required this.amount,
    required this.title,
    required this.description,
    required this.iconPath,
  });
}

/// 奖励弹窗显示模式
enum RewardDialogMode {
  single, // 单个奖励
  multiple, // 多个奖励
}

/// 通用奖励弹窗组件
class RewardDialog extends StatefulWidget {
  final RewardDialogMode mode;
  final List<RewardItem> rewards;
  final VoidCallback? onClose;
  final VoidCallback? onReceive;
  final Widget? bottomContent;
  /// 若干秒后自动关闭（如 2 秒），关闭前会调用 onReceive
  final Duration? autoCloseAfter;
  /// 点击弹窗内容区域是否关闭（与签到一致的奖励弹窗可设为 true）
  final bool tapContentToClose;

  const RewardDialog({
    super.key,
    required this.mode,
    required this.rewards,
    this.onClose,
    this.onReceive,
    this.bottomContent,
    this.autoCloseAfter,
    this.tapContentToClose = false,
  });

  @override
  State<RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<RewardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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

    // 开始动画
    _animationController.forward();

    if (widget.autoCloseAfter != null) {
      Future.delayed(widget.autoCloseAfter!, () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  void _closeByTap() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: GestureDetector(
                    onTap: widget.tapContentToClose ? _closeByTap : null,
                    behavior: HitTestBehavior.opaque,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: widget.mode == RewardDialogMode.single ? 300 : 400,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/diaog_bg_big.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 30),
                              _buildHeader(),
                              const SizedBox(height: 20),
                              _buildContent(),
                              const SizedBox(height: 20),
                              _buildReceiveButton(),
                              // 有自定义底部时缩小留白，无按钮时不再占大块空间
                              SizedBox(height: widget.bottomContent != null ? 24 : 60),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        // 标题居中
        Center(
          child: Text(
            widget.mode == RewardDialogMode.single
                ? widget.rewards.first.title
                : 'REWARDS',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 关闭按钮在右上角
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: widget.onClose,
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

  Widget _buildContent() {
    if (widget.mode == RewardDialogMode.single) {
      return _buildSingleReward();
    } else {
      return _buildMultipleRewards();
    }
  }

  Widget _buildSingleReward() {
    final reward = widget.rewards.first;
    return Column(
      children: [
        // 大图标
        Image.asset(
          reward.iconPath,
          width: 80,
          height: 80,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        // +xx
        Text(
          '+${reward.amount}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // ADD xx
        Text(
          reward.description,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildMultipleRewards() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: widget.rewards.length,
      itemBuilder: (context, index) {
        final reward = widget.rewards[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 奖励图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(reward.iconPath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 奖励数量
              Text(
                '+${reward.amount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // 奖励标题
              Text(
                reward.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiveButton() {
    // 传入 bottomContent 时用自定义底部（如 SizedBox.shrink() 即不显示按钮）
    if (widget.bottomContent != null) {
      return widget.bottomContent!;
    }
    return SmallButton(
      text: 'RECEIVE',
      style: SmallButtonStyle.green,
      size: SmallButtonSize.large,
      onPressed: widget.onReceive,
    );
  }
}

/// 显示单个奖励弹窗
/// [autoCloseAfter] 若干秒后自动关闭（如 2 秒）
/// [tapContentToClose] 点击弹窗内容区域是否关闭
/// [bottomContent] 自定义底部区域；传入 `SizedBox.shrink()` 可隐藏领取按钮
Future<void> showSingleRewardDialog(
  BuildContext context, {
  required RewardItem reward,
  VoidCallback? onClose,
  VoidCallback? onReceive,
  Duration? autoCloseAfter,
  bool tapContentToClose = false,
  bool barrierDismissible = false,
  Widget? bottomContent,
}) {
  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => RewardDialog(
      mode: RewardDialogMode.single,
      rewards: [reward],
      onClose: onClose,
      onReceive: onReceive,
      autoCloseAfter: autoCloseAfter,
      tapContentToClose: tapContentToClose,
      bottomContent: bottomContent,
    ),
  );
}

/// 显示多个奖励弹窗
Future<void> showMultipleRewardDialog(
  BuildContext context, {
  required List<RewardItem> rewards,
  VoidCallback? onClose,
  VoidCallback? onReceive,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => RewardDialog(
      mode: RewardDialogMode.multiple,
      rewards: rewards,
      onClose: onClose,
      onReceive: onReceive,
    ),
  );
}

/// 预定义的奖励数据
class RewardData {
  static const List<RewardItem> commonRewards = [
    RewardItem(
      type: RewardType.coin,
      amount: 100,
      title: 'DAILY REWARD',
      description: 'COINS',
      iconPath: 'assets/spin/conins_big.png',
    ),
    RewardItem(
      type: RewardType.undo,
      amount: 1,
      title: 'REVOCATION',
      description: 'ADD UNDO',
      iconPath: 'assets/spin/undo_big.png',
    ),
    RewardItem(
      type: RewardType.reminder,
      amount: 1,
      title: 'REMIND',
      description: 'REMINDER',
      iconPath: 'assets/spin/reminder_big.png',
    ),
    RewardItem(
      type: RewardType.bottle,
      amount: 1,
      title: 'BOTTLE',
      description: 'ADD BOTTLE',
      iconPath: 'assets/spin/reminder_big.png', // 临时使用，需要替换为正确的瓶子图标
    ),
    RewardItem(
      type: RewardType.pipe,
      amount: 1,
      title: 'BOTTLE',
      description: 'ADD BOTTLE',
      iconPath: 'assets/spin/reminder_big.png', // 临时使用，需要替换为正确的管道图标
    ),
  ];
}
