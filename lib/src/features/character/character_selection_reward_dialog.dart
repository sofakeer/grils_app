import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../models/character.dart';
import '../../providers/character_providers.dart';
import '../../providers/level_providers.dart';
import '../game/game_manager.dart';

/// 选择图片弹窗（参考reward_dialog.dart风格）
class CharacterSelectionRewardDialog extends ConsumerStatefulWidget {
  final VoidCallback? onCharacterSelected;
  final VoidCallback? onClose;

  const CharacterSelectionRewardDialog({
    super.key,
    this.onCharacterSelected,
    this.onClose,
  });

  @override
  ConsumerState<CharacterSelectionRewardDialog> createState() => _CharacterSelectionRewardDialogState();
}

class _CharacterSelectionRewardDialogState extends ConsumerState<CharacterSelectionRewardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  String? _selectedCharacterId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    final characters = ref.watch(charactersProvider);
    final availableCharacters = characters.where((char) => char.isUnlocked).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                width: 400,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withOpacity(0.95),
                      Colors.grey[900]!.withOpacity(0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.cyan.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildCharacterSelection(availableCharacters),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                    ],
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
          child: Column(
            children: [
              const Text(
                'CHOOSE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'SELECT THE PICTURE YOU LIKE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        // 关闭按钮在右上角
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.8),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterSelection(List<Character> characters) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: characters.take(3).map((character) {
        return _buildCharacterCard(character);
      }).toList(),
    );
  }

  Widget _buildCharacterCard(Character character) {
    final isSelected = _selectedCharacterId == character.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCharacterId = character.id;
        });
      },
      child: Container(
        width: 100,
        height: 160, // 增加高度以完整显示图片
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.cyan : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // 显示真实的人物图片
              Container(
                width: double.infinity,
                height: double.infinity,
                child: Image.asset(
                  character.imagePath,
                  fit: BoxFit.cover, // 保持宽高比，完整显示图片
                  errorBuilder: (context, error, stackTrace) {
                    // 图片加载失败时显示占位符
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.purple.withOpacity(0.8),
                            Colors.blue.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
              // 选中状态覆盖层
              if (isSelected)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              // 选中图标
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 左侧按钮（继续）
        _buildActionButton(
          icon: Icons.arrow_forward,
          color: Colors.blue,
          onTap: _selectedCharacterId != null ? _onContinue : null,
        ),
        // 中间按钮（继续）
        _buildActionButton(
          icon: Icons.arrow_forward,
          color: Colors.blue,
          onTap: _selectedCharacterId != null ? _onContinue : null,
        ),
        // 右侧按钮（开始游戏）
        _buildActionButton(
          icon: Icons.play_arrow,
          color: Colors.green,
          onTap: _selectedCharacterId != null ? _onStartGame : null,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: onTap != null ? color : color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(25),
          boxShadow: onTap != null ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void _onContinue() async {
    if (_selectedCharacterId == null) return;

    // 选择人物
    await ref.read(characterSelectionProvider.notifier).selectCharacter(_selectedCharacterId!);
    await ref.read(levelProvider.notifier).selectCharacterAndStartLevel(_selectedCharacterId!);
    
    // 关闭弹窗
    Navigator.of(context).pop();
    
    // 执行回调
    widget.onCharacterSelected?.call();
  }

  void _onStartGame() async {
    if (_selectedCharacterId == null) return;

    // 选择人物
    await ref.read(characterSelectionProvider.notifier).selectCharacter(_selectedCharacterId!);
    await ref.read(levelProvider.notifier).selectCharacterAndStartLevel(_selectedCharacterId!);
    
    // 关闭弹窗
    Navigator.of(context).pop();
    
    // 开始游戏
    _startGame();
  }

  void _startGame() {
    final levelState = ref.read(levelProvider);
    
    GameNavigator.navigateToGame(
      context: context,
      gameType: GameType.simplePuzzle,
      level: levelState.currentLevel,
      callbacks: DefaultGameCallbacks(
        context: context,
        ref: ref,
      ),
    );
  }
}

/// 显示选择图片弹窗
Future<void> showCharacterSelectionRewardDialog(
  BuildContext context, {
  VoidCallback? onCharacterSelected,
  VoidCallback? onClose,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => CharacterSelectionRewardDialog(
      onCharacterSelected: onCharacterSelected,
      onClose: onClose,
    ),
  );
}
