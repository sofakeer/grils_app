import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:game_image_app/generated/assets.dart';
import '../../widgets/small_button.dart';
import '../home/home_page.dart';
import '../game/game_manager.dart';
import '../../providers/level_providers.dart';
import '../../providers/audio_providers.dart';
import '../../widgets/coin_display.dart';

class GameFailPage extends ConsumerStatefulWidget {
  final int? currentCoins;
  final VoidCallback? onHome;
  final VoidCallback? onRestart;
  final String? levelType; // 关卡类型

  const GameFailPage({
    super.key,
    this.currentCoins,
    this.onHome,
    this.onRestart,
    this.levelType,
  });

  @override
  ConsumerState<GameFailPage> createState() => _GameFailPageState();
}

class _GameFailPageState extends ConsumerState<GameFailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

    // 震动动画
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.8, curve: Curves.elasticIn),
    ));

    // 开始动画
    _animationController.forward();

    // 停止游戏背景音乐（失败页面保持安静）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioStateProvider.notifier).stopBackgroundMusic();
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
                    // 顶部金币显示
                    _buildTopBar(),
                    SizedBox(height: 20),
                    // 主要内容
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: _buildMainContent(),
                    ),
                    const SizedBox(height: 140),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const CoinDisplay(
            backgroundColor: Color(0x33000000),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // FAIL 标题
        const Text(
          'FAIL',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            letterSpacing: 2,
          ),
        ),
        // 失败图标
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                (math.sin(_shakeAnimation.value * math.pi * 4) * 5),
                0,
              ),
              child: Image.asset(
                Assets.assetsIcFail2x,
                width: 120,
                height: 120,
              ),
            );
          },
        ),
        const SizedBox(height: 66),
        _buildBottomButtons(),
      ],
    );
  }


  Widget _buildBottomButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // HOME 按钮（蓝色图片背景）
            SmallButtonHelper.blueImageBackground(
              text: 'HOME',
              height: 65,
              width: 150,
              onPressed: () {
                AudioActions.playClickSound(ref);
                if (widget.onHome != null) {
                  widget.onHome!();
                } else {
                  // 默认导航到首页
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(width: 10),
            // RESTART 按钮（绿色图片背景）
            SmallButtonHelper.greenImageBackground(
              text: 'RESTART',
              height: 65,
              width: 150,
              iconPath: 'assets/ic_play.png',
              iconSize: 16,
              onPressed: () {
                AudioActions.playClickSound(ref);
                if (widget.onRestart != null) {
                  widget.onRestart!();
                } else {
                  // 根据关卡类型选择游戏类型
                  final levelType = widget.levelType ?? 'b'; // 默认类型
                  GameType gameType;
                  switch (levelType) {
                    case 'b':
                      gameType = GameType.simplePuzzle;
                      break;
                    case 'c':
                      gameType = GameType.simplePuzzle;
                      break;
                    default:
                      gameType = GameType.simplePuzzle;
                  }

                  // 获取当前关卡状态
                  final levelState = ref.read(levelProvider);

                  // 启动游戏
                  GameNavigator.navigateToGame(
                    context: context,
                    gameType: gameType,
                    level: levelState.currentLevel,
                    callbacks: DefaultGameCallbacks(
                      context: context,
                      ref: ref,
                    ),
                    ref: ref,
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
