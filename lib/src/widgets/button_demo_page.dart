import 'package:flutter/material.dart';
import 'small_button.dart';
import 'reward_dialog.dart';
import '../../generated/assets.dart';

/// 按钮组件示例页面
class ButtonDemoPage extends StatefulWidget {
  const ButtonDemoPage({super.key});

  @override
  State<ButtonDemoPage> createState() => _ButtonDemoPageState();
}

class _ButtonDemoPageState extends State<ButtonDemoPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          '小按钮组件示例',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('基础按钮'),
            const SizedBox(height: 16),
            _buildBasicButtons(),
            
            const SizedBox(height: 32),
            _buildSectionTitle('带图标的按钮'),
            const SizedBox(height: 16),
            _buildIconButtons(),
            
            const SizedBox(height: 32),
            _buildSectionTitle('不同大小的按钮'),
            const SizedBox(height: 16),
            _buildSizeButtons(),
            
            const SizedBox(height: 32),
            _buildSectionTitle('加载状态按钮'),
            const SizedBox(height: 16),
            _buildLoadingButtons(),
            
            const SizedBox(height: 32),
            _buildSectionTitle('禁用状态按钮'),
            const SizedBox(height: 16),
            _buildDisabledButtons(),
            
            const SizedBox(height: 32),
            _buildSectionTitle('奖励弹窗示例'),
            const SizedBox(height: 16),
            _buildRewardDialogButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildBasicButtons() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SmallButton(
          text: '绿色按钮',
          style: SmallButtonStyle.green,
          onPressed: () => _showSnackBar('绿色按钮被点击'),
        ),
        SmallButton(
          text: '蓝色按钮',
          style: SmallButtonStyle.blue,
          onPressed: () => _showSnackBar('蓝色按钮被点击'),
        ),
      ],
    );
  }

  Widget _buildIconButtons() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SmallButton(
          text: '50',
          iconPath: Assets.spinCoinBig,
          style: SmallButtonStyle.green,
          onPressed: () => _showSnackBar('金币按钮被点击'),
        ),
        SmallButton(
          text: 'GET',
          iconPath: Assets.assetsIcPlay,
          style: SmallButtonStyle.blue,
          onPressed: () => _showSnackBar('播放按钮被点击'),
        ),
        SmallButton(
          iconPath: Assets.assetsClose,
          style: SmallButtonStyle.green,
          onPressed: () => _showSnackBar('关闭按钮被点击'),
        ),
      ],
    );
  }

  Widget _buildSizeButtons() {
    return Column(
      children: [
        Row(
          children: [
            SmallButton(
              text: '小',
              size: SmallButtonSize.small,
              style: SmallButtonStyle.green,
              onPressed: () => _showSnackBar('小按钮被点击'),
            ),
            const SizedBox(width: 16),
            SmallButton(
              text: '中',
              size: SmallButtonSize.medium,
              style: SmallButtonStyle.green,
              onPressed: () => _showSnackBar('中按钮被点击'),
            ),
            const SizedBox(width: 16),
            SmallButton(
              text: '大',
              size: SmallButtonSize.large,
              style: SmallButtonStyle.green,
              onPressed: () => _showSnackBar('大按钮被点击'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingButtons() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SmallButton(
          text: '加载中',
          isLoading: _isLoading,
          style: SmallButtonStyle.green,
          onPressed: () {
            setState(() {
              _isLoading = !_isLoading;
            });
            if (_isLoading) {
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              });
            }
          },
        ),
        SmallButton(
          text: '蓝色加载',
          iconPath: Assets.assetsIcPlay,
          isLoading: _isLoading,
          style: SmallButtonStyle.blue,
          onPressed: () {
            setState(() {
              _isLoading = !_isLoading;
            });
            if (_isLoading) {
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDisabledButtons() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SmallButton(
          text: '禁用按钮',
          style: SmallButtonStyle.green,
          enabled: false,
          onPressed: () => _showSnackBar('这个按钮被禁用了'),
        ),
        SmallButton(
          text: '禁用蓝色',
          iconPath: Assets.assetsIcPlay,
          style: SmallButtonStyle.blue,
          enabled: false,
          onPressed: () => _showSnackBar('这个按钮被禁用了'),
        ),
      ],
    );
  }

  Widget _buildRewardDialogButtons() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SmallButton(
          text: '单个奖励',
          style: SmallButtonStyle.green,
          onPressed: () => _showSingleRewardDialog(),
        ),
        SmallButton(
          text: '多个奖励',
          style: SmallButtonStyle.blue,
          onPressed: () => _showMultipleRewardDialog(),
        ),
        SmallButton(
          text: '金币奖励',
          style: SmallButtonStyle.green,
          onPressed: () => _showCoinRewardDialog(),
        ),
        SmallButton(
          text: '撤销奖励',
          style: SmallButtonStyle.blue,
          onPressed: () => _showUndoRewardDialog(),
        ),
      ],
    );
  }

  void _showSingleRewardDialog() {
    showSingleRewardDialog(
      context,
      reward: RewardData.commonRewards[0], // 金币奖励
      onClose: () => Navigator.of(context).pop(),
      onReceive: () {
        Navigator.of(context).pop();
        _showSnackBar('已领取金币奖励！');
      },
    );
  }

  void _showMultipleRewardDialog() {
    showMultipleRewardDialog(
      context,
      rewards: RewardData.commonRewards.take(4).toList(),
      onClose: () => Navigator.of(context).pop(),
      onReceive: () {
        Navigator.of(context).pop();
        _showSnackBar('已领取所有奖励！');
      },
    );
  }

  void _showCoinRewardDialog() {
    showSingleRewardDialog(
      context,
      reward: const RewardItem(
        type: RewardType.coin,
        amount: 500,
        title: 'DAILY REWARD',
        description: 'COINS',
        iconPath: 'assets/spin/conins_big.png',
      ),
      onClose: () => Navigator.of(context).pop(),
      onReceive: () {
        Navigator.of(context).pop();
        _showSnackBar('已领取500金币！');
      },
    );
  }

  void _showUndoRewardDialog() {
    showSingleRewardDialog(
      context,
      reward: const RewardItem(
        type: RewardType.undo,
        amount: 1,
        title: 'REVOCATION',
        description: 'ADD UNDO',
        iconPath: 'assets/spin/undo_big.png',
      ),
      onClose: () => Navigator.of(context).pop(),
      onReceive: () {
        Navigator.of(context).pop();
        _showSnackBar('已领取撤销道具！');
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
