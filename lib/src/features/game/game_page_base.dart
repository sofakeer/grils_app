import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../widgets/coin_display.dart';
import '../../services/analytics_manager.dart';

/// 游戏结果枚举
enum GameResult {
  success,
  failure,
  timeout,
  quit,
}

/// 游戏回调接口
abstract class GameCallbacks {
  /// 游戏成功回调
  /// [score] 游戏得分
  /// [coins] 获得金币数量
  /// [level] 当前关卡
  void onGameSuccess({
    required int score,
    required int coins,
    required int level,
    int? performance, // 0-100 表现分数，可选
  });

  /// 游戏失败回调
  /// [reason] 失败原因
  /// [level] 当前关卡
  void onGameFailure({
    required String reason,
    required int level,
  });

  /// 游戏超时回调
  /// [level] 当前关卡
  void onGameTimeout({
    required int level,
  });

  /// 游戏退出回调
  /// [level] 当前关卡
  void onGameQuit({
    required int level,
  });

  /// 金币变化回调
  /// [oldCoins] 旧金币数量
  /// [newCoins] 新金币数量
  /// [delta] 变化量
  void onCoinsChanged({
    required int oldCoins,
    required int newCoins,
    required int delta,
  });

  /// 关卡进度回调
  /// [level] 当前关卡
  /// [progress] 进度百分比 (0.0-1.0)
  void onLevelProgress({
    required int level,
    required double progress,
  });
}

/// 游戏页面配置
class GamePageConfig {
  final int level;
  final int timeLimit; // 时间限制（秒），0表示无限制
  final bool showTimer;
  final bool showCoins;
  final bool showProgress;
  final bool allowPause;
  final bool allowQuit;
  final Map<String, dynamic> customData;

  const GamePageConfig({
    required this.level,
    this.timeLimit = 0,
    this.showTimer = true,
    this.showCoins = true,
    this.showProgress = true,
    this.allowPause = true,
    this.allowQuit = true,
    this.customData = const {},
  });
}

/// 游戏页面基类
abstract class GamePageBase extends ConsumerStatefulWidget {
  final GamePageConfig config;
  final GameCallbacks? callbacks;

  const GamePageBase({
    super.key,
    required this.config,
    this.callbacks,
  });

  /// 子类需要实现的游戏逻辑
  Widget buildGameContent(BuildContext context, WidgetRef ref);

  /// 子类可以重写的游戏初始化逻辑
  void onGameInit() {}

  /// 子类可以重写的游戏开始逻辑
  void onGameStart() {}

  /// 子类可以重写的游戏暂停逻辑
  void onGamePause() {}

  /// 子类可以重写的游戏恢复逻辑
  void onGameResume() {}

  /// 子类可以重写的游戏结束逻辑
  void onGameEnd() {}

  /// 子类可以重写的计时器更新逻辑
  void onTimerUpdate(int remainingSeconds) {}

  /// 子类可以重写的进度更新逻辑
  void onProgressUpdate(double progress) {}
}

/// 游戏页面状态管理
abstract class GamePageState<T extends GamePageBase> extends ConsumerState<T> {
  late GameTimer _timer;
  bool _isPaused = false;
  bool _isGameEnded = false;
  int _currentCoins = 0;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _timer = GameTimer(
      duration: widget.config.timeLimit,
      onUpdate: _onTimerUpdate,
      onTimeout: _onTimeout,
    );
    _loadInitialCoins();
    widget.onGameInit();
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  /// 开始游戏
  void startGame() {
    if (_isGameEnded) return;
    
    // 记录游戏开始埋点 - 在游戏真正开始时上报
    final analytics = AnalyticsManager();
    analytics.logGameStart(level: widget.config.level);
    
    // 记录累计关卡次数埋点（跨模式累计） - 在start时一起上报
    analytics.incrementAndLogPlayCount();
    
    _timer.start();
    widget.onGameStart();
  }

  /// 暂停游戏
  void pauseGame() {
    if (_isPaused || _isGameEnded) return;
    _timer.pause();
    _isPaused = true;
    widget.onGamePause();
  }

  /// 恢复游戏
  void resumeGame() {
    if (!_isPaused || _isGameEnded) return;
    _timer.resume();
    _isPaused = false;
    widget.onGameResume();
  }

  /// 结束游戏
  void endGame() {
    if (_isGameEnded) return;
    
    // 记录游戏时长埋点
    final analytics = AnalyticsManager();
    final playedMinutes = ((widget.config.timeLimit - _timer.remainingSeconds) / 60).ceil();
    if (playedMinutes > 0) {
      analytics.logPlayTime(playedMinutes.clamp(1, 30));
    }
    
    _timer.stop();
    _isGameEnded = true;
    widget.onGameEnd();
  }

  /// 游戏成功
  void gameSuccess({
    required int score,
    required int coins,
    int? performance,
  }) {
    endGame();
    widget.callbacks?.onGameSuccess(
      score: score,
      coins: coins,
      level: widget.config.level,
      performance: performance,
    );
  }

  /// 游戏失败
  void gameFailure({required String reason}) {
    endGame();
    widget.callbacks?.onGameFailure(
      reason: reason,
      level: widget.config.level,
    );
  }

  /// 游戏超时
  void gameTimeout() {
    endGame();
    widget.callbacks?.onGameTimeout(level: widget.config.level);
  }

  /// 游戏退出
  void gameQuit() {
    endGame();
    widget.callbacks?.onGameQuit(level: widget.config.level);
  }

  /// 更新金币
  void updateCoins(int newCoins) {
    final oldCoins = _currentCoins;
    final delta = newCoins - oldCoins;
    _currentCoins = newCoins;

    widget.callbacks?.onCoinsChanged(
      oldCoins: oldCoins,
      newCoins: newCoins,
      delta: delta,
    );
  }

  /// 更新进度
  void updateProgress(double progress) {
    _currentProgress = progress.clamp(0.0, 1.0);
    widget.callbacks?.onLevelProgress(
      level: widget.config.level,
      progress: _currentProgress,
    );
  }

  void _onTimerUpdate(int remainingSeconds) {
    widget.onTimerUpdate(remainingSeconds);
  }

  void _onTimeout() {
    gameTimeout();
  }

  void _loadInitialCoins() {
    // 从用户进度中加载初始金币
    ref.listen(userProgressProvider, (previous, next) {
      next.when(
        data: (progress) => _currentCoins = progress.coins,
        loading: () {},
        error: (_, __) {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部状态栏
              if (widget.config.showCoins || widget.config.showTimer)
                _buildTopBar(),
              // 游戏内容区域
              Expanded(
                child: widget.buildGameContent(context, ref),
              ),
              // 底部控制栏
              if (widget.config.allowPause || widget.config.allowQuit)
                _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 金币显示
          if (widget.config.showCoins) _buildCoinsDisplay(),
          // 计时器显示
          if (widget.config.showTimer) _buildTimerDisplay(),
        ],
      ),
    );
  }

  Widget _buildCoinsDisplay() {
    return CoinDisplay(coins: _currentCoins);
  }

  Widget _buildTimerDisplay() {
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
            '${_timer.remainingSeconds}',
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

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (widget.config.allowPause)
            _buildControlButton(
              icon: _isPaused ? Icons.play_arrow : Icons.pause,
              label: _isPaused ? '继续' : '暂停',
              onTap: _isPaused ? resumeGame : pauseGame,
            ),
          if (widget.config.allowQuit)
            _buildControlButton(
              icon: Icons.home,
              label: '退出',
              onTap: gameQuit,
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

/// 游戏计时器
class GameTimer {
  final int duration;
  final Function(int) onUpdate;
  final VoidCallback onTimeout;

  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;

  GameTimer({
    required this.duration,
    required this.onUpdate,
    required this.onTimeout,
  }) : _remainingSeconds = duration;

  int get remainingSeconds => _remainingSeconds;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _isPaused = false;
    _remainingSeconds = duration;
    _tick();
  }

  void pause() {
    if (!_isRunning || _isPaused) return;
    _isPaused = true;
  }

  void resume() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;
    _tick();
  }

  void stop() {
    _isRunning = false;
    _isPaused = false;
  }

  void dispose() {
    stop();
  }

  void _tick() {
    if (!_isRunning || _isPaused) return;

    if (_remainingSeconds <= 0) {
      onTimeout();
      return;
    }

    onUpdate(_remainingSeconds);
    _remainingSeconds--;

    Future.delayed(const Duration(seconds: 1), _tick);
  }
}
