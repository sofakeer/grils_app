import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'game_page_base.dart';
import '../../providers/app_providers.dart';

/// 简单游戏页面示例
class SimpleGamePage extends ConsumerWidget {
  final GamePageConfig config;
  final GameCallbacks? callbacks;

  const SimpleGamePage({
    super.key,
    required this.config,
    this.callbacks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部状态栏
              _buildTopBar(context, ref),
              // 游戏内容区域
              Expanded(
                child: _SimpleGameContent(
                  config: config,
                  callbacks: callbacks,
                ),
              ),
              // 底部控制栏
              _buildBottomControls(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 金币显示
          if (config.showCoins)
            _buildCoinsDisplay(context, ref),
          // 计时器显示
          if (config.showTimer)
            _buildTimerDisplay(context),
        ],
      ),
    );
  }

  Widget _buildCoinsDisplay(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final userProgress = ref.watch(userProgressProvider);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                userProgress.when(
                  data: (progress) => '${progress.coins}',
                  loading: () => '0',
                  error: (_, __) => '0',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerDisplay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            '${config.timeLimit}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (config.allowPause)
            _buildControlButton(
              icon: Icons.pause,
              label: '暂停',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('游戏暂停')),
                );
              },
            ),
          if (config.allowQuit)
            _buildControlButton(
              icon: Icons.home,
              label: '退出',
              onTap: () {
                callbacks?.onGameQuit(level: config.level);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleGameContent extends ConsumerStatefulWidget {
  final GamePageConfig config;
  final GameCallbacks? callbacks;

  const _SimpleGameContent({
    required this.config,
    this.callbacks,
  });

  @override
  ConsumerState<_SimpleGameContent> createState() => _SimpleGameContentState();
}

class _SimpleGameContentState extends ConsumerState<_SimpleGameContent>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  final List<Target> _targets = [];
  int _score = 0;
  int _hits = 0;
  int _misses = 0;
  bool _isGameActive = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _startGame();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isGameActive = true;
      _score = 0;
      _hits = 0;
      _misses = 0;
      _targets.clear();
    });
    _spawnTarget();
  }

  void _spawnTarget() {
    if (!_isGameActive) return;

    final random = math.Random();
    final target = Target(
      id: DateTime.now().millisecondsSinceEpoch,
      x: random.nextDouble() * 0.8 + 0.1,
      y: random.nextDouble() * 0.6 + 0.2,
      size: 60.0 + random.nextDouble() * 40.0,
      duration: 3000 - (widget.config.level * 100).clamp(1000, 2500),
      onTimeout: _onTargetTimeout,
    );

    setState(() {
      _targets.add(target);
    });

    Future.delayed(Duration(milliseconds: 800 - (widget.config.level * 50).clamp(200, 600)), () {
      if (_isGameActive) {
        _spawnTarget();
      }
    });
  }

  void _onTargetTap(Target target) {
    if (!_isGameActive) return;

    setState(() {
      _targets.remove(target);
      _hits++;
      _score += _calculateScore(target);
    });

    _animationController.forward().then((_) {
      _animationController.reset();
    });

    if (_hits >= _getRequiredHits()) {
      _endGame(true);
    }
  }

  void _onTargetTimeout(Target target) {
    if (!_isGameActive) return;

    setState(() {
      _targets.remove(target);
      _misses++;
    });

    if (_misses >= _getMaxMisses()) {
      _endGame(false);
    }
  }

  int _calculateScore(Target target) {
    final sizeBonus = (100 - target.size).clamp(0, 40);
    final timeBonus = (target.duration / 1000).floor();
    return ((10 + sizeBonus + timeBonus) * widget.config.level).toInt();
  }

  int _getRequiredHits() {
    return 5 + (widget.config.level * 2);
  }

  int _getMaxMisses() {
    return 3 + (widget.config.level ~/ 2);
  }

  void _endGame(bool success) {
    setState(() {
      _isGameActive = false;
    });

    if (success) {
      final coins = _calculateCoins();
      widget.callbacks?.onGameSuccess(
        score: _score,
        coins: coins,
        level: widget.config.level,
        performance: _calculatePerformance(),
      );
    } else {
      widget.callbacks?.onGameFailure(
        reason: '错过了太多目标',
        level: widget.config.level,
      );
    }
  }

  int _calculateCoins() {
    return (_score / 10).floor() + widget.config.level * 2;
  }

  int _calculatePerformance() {
    if (_hits == 0) return 0;
    final accuracy = _hits / (_hits + _misses);
    return (accuracy * 100).floor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          _buildGameInfo(),
          ..._targets.map((target) => _buildTarget(target)),
          if (!_isGameActive) _buildGameOverlay(),
        ],
      ),
    );
  }

  Widget _buildGameInfo() {
    return Positioned(
      top: 20,
      left: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '关卡 ${widget.config.level}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '得分: $_score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Text(
            '命中: $_hits / ${_getRequiredHits()}',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 14,
            ),
          ),
          Text(
            '失误: $_misses / ${_getMaxMisses()}',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarget(Target target) {
    return Positioned(
      left: target.x * MediaQuery.of(context).size.width - target.size / 2,
      top: target.y * MediaQuery.of(context).size.height - target.size / 2,
      child: GestureDetector(
        onTap: () => _onTargetTap(target),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: target.size,
                  height: target.size,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGameOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _hits >= _getRequiredHits() ? '胜利!' : '失败!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '最终得分: $_score',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startGame,
              child: const Text('重新开始'),
            ),
          ],
        ),
      ),
    );
  }
}

class Target {
  final int id;
  final double x;
  final double y;
  final double size;
  final int duration;
  final Function(Target) onTimeout;

  Target({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.duration,
    required this.onTimeout,
  }) {
    Future.delayed(Duration(milliseconds: duration), () {
      onTimeout(this);
    });
  }
}
