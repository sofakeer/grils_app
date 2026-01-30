import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../models/character.dart';
import '../../providers/character_providers.dart';
import '../game/game_manager.dart';

/// 选择人物弹窗
class CharacterSelectionDialog extends ConsumerStatefulWidget {
  final VoidCallback? onCharacterSelected;

  const CharacterSelectionDialog({
    super.key,
    this.onCharacterSelected,
  });

  @override
  ConsumerState<CharacterSelectionDialog> createState() => _CharacterSelectionDialogState();
}

class _CharacterSelectionDialogState extends ConsumerState<CharacterSelectionDialog>
    with TickerProviderStateMixin {
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

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _buildDialogContent(context, availableCharacters),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogContent(BuildContext context, List<Character> characters) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.grey[900]!.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.cyan.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题区域
          _buildHeader(context),
          // 人物选择区域
          _buildCharacterSelection(context, characters),
          // 底部按钮区域
          _buildBottomButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 关闭按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 标题
          const Text(
            'CHOOSE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          // 副标题
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
    );
  }

  Widget _buildCharacterSelection(BuildContext context, List<Character> characters) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: characters.take(3).map((character) {
          return _buildCharacterCard(context, character);
        }).toList(),
      ),
    );
  }

  Widget _buildCharacterCard(BuildContext context, Character character) {
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

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 左侧按钮（继续）
          _buildActionButton(
            context,
            icon: Icons.arrow_forward,
            color: Colors.blue,
            onTap: _selectedCharacterId != null ? _onContinue : null,
          ),
          // 中间按钮（继续）
          _buildActionButton(
            context,
            icon: Icons.arrow_forward,
            color: Colors.blue,
            onTap: _selectedCharacterId != null ? _onContinue : null,
          ),
          // 右侧按钮（开始游戏）
          _buildActionButton(
            context,
            icon: Icons.play_arrow,
            color: Colors.green,
            onTap: _selectedCharacterId != null ? _onStartGame : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
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
    
    // 关闭弹窗
    Navigator.of(context).pop();
    
    // 执行回调
    widget.onCharacterSelected?.call();
  }

  void _onStartGame() async {
    if (_selectedCharacterId == null) return;

    // 选择人物
    await ref.read(characterSelectionProvider.notifier).selectCharacter(_selectedCharacterId!);
    
    // 关闭弹窗
    Navigator.of(context).pop();
    
    // 开始游戏
    _startGame();
  }

  void _startGame() {
    // 这里可以导航到游戏页面
    GameNavigator.navigateToGame(
      context: context,
      gameType: GameType.sample,
      level: 1,
      callbacks: DefaultGameCallbacks(
        context: context,
        onGameEnd: () {
          // 游戏结束后标记需要选择人物
          ref.read(characterSelectionProvider.notifier).markLevelCompleted();
        },
      ),
    );
  }
}

