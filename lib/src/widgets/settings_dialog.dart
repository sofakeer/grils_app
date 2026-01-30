import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../generated/assets.dart';
import '../features/splash/web_view_screen.dart';
import '../providers/audio_providers.dart';
import '../providers/vibration_providers.dart';

/// 设置弹窗组件
class SettingsDialog extends ConsumerStatefulWidget {
  final VoidCallback? onContinue;
  final VoidCallback? onRestart;
  final VoidCallback? onQuit;
  final bool showGameActions; // 是否显示游戏操作按钮

  const SettingsDialog({
    super.key,
    this.onContinue,
    this.onRestart,
    this.onQuit,
    this.showGameActions = false,
  });

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // 设置状态
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _musicEnabled = true;

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

    // 初始化状态为实际状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioState = ref.read(audioStateProvider);
      final vibrationState = ref.read(vibrationProvider);
      setState(() {
        _soundEnabled = !audioState.isSoundMuted;
        _musicEnabled = !audioState.isMusicMuted;
        _vibrationEnabled = vibrationState;
      });
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 400,
                    height: widget.showGameActions ? 650 : 500,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(Assets.assetsDiaogBgBig ),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildContent(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 50),
          _buildHeader(context),
          const SizedBox(height: 30),
          _buildSettingsList(),
          const SizedBox(height: 20),
          // 只在游戏页面显示操作按钮
          if (widget.showGameActions) ...[
            _buildBottomButtons(),
            const SizedBox(height: 16),
          ],
          if (!widget.showGameActions) _buildVersionInfo(),
          if (!widget.showGameActions) const SizedBox(height: 10),
          if (!widget.showGameActions) _buildAgreementLinks(),
          if (!widget.showGameActions) const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        const Center(
          child: Text(
            'SETTING',
            style: TextStyle(
              decoration: TextDecoration.none,
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
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

  Widget _buildSettingsList() {
    return Column(
      children: [
        _buildSettingItem(
          icon: Icons.volume_up,
          label: 'Sound',
          value: _soundEnabled,
          onChanged: (value) {
            AudioActions.playClickSound(ref);
            setState(() => _soundEnabled = value);
            ref.read(audioStateProvider.notifier).setSoundMuted(!value);
          },
        ),
        const SizedBox(height: 20),
        _buildSettingItem(
          icon: Icons.vibration,
          label: 'Vibration',
          value: _vibrationEnabled,
          onChanged: (value) async {
            AudioActions.playClickSound(ref);
            setState(() => _vibrationEnabled = value);
            await VibrationActions.toggleVibration(ref);
          },
        ),
        const SizedBox(height: 20),
        _buildSettingItem(
          icon: Icons.music_note,
          label: 'Music',
          value: _musicEnabled,
          onChanged: (value) {
            AudioActions.playClickSound(ref);
            setState(() => _musicEnabled = value);
            ref.read(audioStateProvider.notifier).setMusicMuted(!value);
          },
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: HexColor('#08EF9A'),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          _buildToggleSwitch(value, onChanged),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () {
        AudioActions.playClickSound(ref);
        onChanged(!value);
      },
      child: Container(
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value ? HexColor('#08EF9A') : HexColor('#6B7280'),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Column(
      children: [
        _buildActionButton(
          text: 'CONTINUE',
          color: HexColor('#08EF9A'),
          onTap: () {
            AudioActions.playClickSound(ref);
            Navigator.of(context).pop();
            widget.onContinue?.call();
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          text: 'RESTART',
          color: HexColor('#08EF9A'),
          onTap: () {
            AudioActions.playClickSound(ref);
            Navigator.of(context).pop();
            widget.onRestart?.call();
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          text: 'QUIT',
          color: HexColor('#08EF9A'),
          onTap: () {
            AudioActions.playClickSound(ref);
            Navigator.of(context).pop();
            widget.onQuit?.call();
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({required String text, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: 250,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Text(
      'v1.0',
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 14,
        fontWeight: FontWeight.w400,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget _buildAgreementLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            AudioActions.playClickSound(ref);
            _showPrivacyAgreement();
          },
          child: Text(
            'Privacy Agreement',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            AudioActions.playClickSound(ref);
            _showUserAgreement();
          },
          child: Text(
            'User Agreement',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  void _showPrivacyAgreement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WebViewScreen(
          title: 'Privacy Agreement',
          url: 'https://fantasy-ball-quest.web.app/privacy.html',
        ),
      ),
    );
  }

  void _showUserAgreement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WebViewScreen(
          title: 'User Agreement',
          url: 'https://fantasy-ball-quest.web.app/terms.html',
        ),
      ),
    );
  }
}

/// 显示设置弹窗的全局函数
Future<void> showSettingsDialog(
  BuildContext context, {
  VoidCallback? onContinue,
  VoidCallback? onRestart,
  VoidCallback? onQuit,
  bool showGameActions = false,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => SettingsDialog(
      onContinue: onContinue,
      onRestart: onRestart,
      onQuit: onQuit,
      showGameActions: showGameActions,
    ),
  );
}