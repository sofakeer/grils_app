import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_page_base.dart';
import 'simple_game_page.dart';
import 'main_game_page.dart';
import '../game_result/game_success_page.dart';
import '../game_result/game_fail_page.dart';
import '../photo_unlock/photo_unlock_page.dart';
import '../../providers/character_providers.dart';
import '../../providers/level_providers.dart';
import '../../providers/audio_providers.dart';
import '../../providers/user_type_provider.dart';
import '../../services/analytics_manager.dart';
import '../../services/image_loader_service.dart';
import '../../services/firebase_config_service.dart';

/// 游戏类型枚举
enum GameType {
  sample, // 示例游戏
  puzzle, // 拼图游戏
  memory, // 记忆游戏
  reaction, // 反应游戏
  simplePuzzle, // 简单拼图游戏
  // 可以继续添加更多游戏类型
}

/// 游戏管理器
class GameManager {
  static GameManager? _instance;
  static GameManager get instance => _instance ??= GameManager._();
  
  GameManager._();

  /// 创建游戏页面
  Widget createGamePage({
    required GameType gameType,
    required GamePageConfig config,
    GameCallbacks? callbacks,
  }) {
    switch (gameType) {
      case GameType.sample:
        return SimpleGamePage(
          config: config,
          callbacks: callbacks,
        );
      case GameType.simplePuzzle:
        return MainGamePage(callbacks: callbacks);
      case GameType.puzzle:
        // TODO: 实现拼图游戏
        return _buildPlaceholderGame('拼图游戏', config, callbacks);
      case GameType.memory:
        // TODO: 实现记忆游戏
        return _buildPlaceholderGame('记忆游戏', config, callbacks);
      case GameType.reaction:
        // TODO: 实现反应游戏
        return _buildPlaceholderGame('反应游戏', config, callbacks);
    }
  }

  /// 构建占位符游戏页面
  Widget _buildPlaceholderGame(String gameName, GamePageConfig config, GameCallbacks? callbacks) {
    return _PlaceholderGamePage(
      gameName: gameName,
      config: config,
      callbacks: callbacks,
    );
  }

  /// 获取游戏配置
  GamePageConfig getDefaultConfig({
    required int level,
    GameType? gameType,
  }) {
    switch (gameType) {
      case GameType.sample:
        return GamePageConfig(
          level: level,
          timeLimit: 60,
          showTimer: true,
          showCoins: true,
          showProgress: true,
          allowPause: true,
          allowQuit: true,
        );
      case GameType.puzzle:
        return GamePageConfig(
          level: level,
          timeLimit: 0, // 拼图游戏无时间限制
          showTimer: false,
          showCoins: true,
          showProgress: true,
          allowPause: true,
          allowQuit: true,
        );
      case GameType.memory:
        return GamePageConfig(
          level: level,
          timeLimit: 30 + (level * 5),
          showTimer: true,
          showCoins: true,
          showProgress: true,
          allowPause: false,
          allowQuit: true,
        );
      case GameType.reaction:
        return GamePageConfig(
          level: level,
          timeLimit: 45,
          showTimer: true,
          showCoins: true,
          showProgress: true,
          allowPause: true,
          allowQuit: true,
        );
      default:
        return GamePageConfig(level: level);
    }
  }
}

/// 占位符游戏页面
class _PlaceholderGamePage extends ConsumerWidget {
  final String gameName;
  final GamePageConfig config;
  final GameCallbacks? callbacks;

  const _PlaceholderGamePage({
    required this.gameName,
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.construction,
                  size: 80,
                  color: Colors.orange,
                ),
                const SizedBox(height: 20),
                Text(
                  '$gameName 开发中',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '关卡 ${config.level}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // 模拟游戏成功
                    callbacks?.onGameSuccess(
                      score: 100,
                      coins: 10,
                      level: config.level,
                      performance: 85,
                    );
                  },
                  child: const Text('模拟成功'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // 模拟游戏失败
                    callbacks?.onGameFailure(
                      reason: '游戏未完成',
                      level: config.level,
                    );
                  },
                  child: const Text('模拟失败'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('返回'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 游戏页面导航器
class GameNavigator {
  /// 导航到游戏页面
  static Future<void> navigateToGame({
    required BuildContext context,
    required GameType gameType,
    required int level,
    GameCallbacks? callbacks,
    WidgetRef? ref,
  }) {
    // 播放游戏背景音乐
    if (ref != null) {
      AudioActions.playGamingMusic(ref);
    }

    final manager = GameManager.instance;
    final config = manager.getDefaultConfig(
      level: level,
      gameType: gameType,
    );

    final gamePage = manager.createGamePage(
      gameType: gameType,
      config: config,
      callbacks: callbacks,
    );

    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => gamePage,
      ),
    );
  }

  /// 导航到示例游戏
  static Future<void> navigateToSampleGame({
    required BuildContext context,
    required int level,
    GameCallbacks? callbacks,
    WidgetRef? ref,
  }) {
    return navigateToGame(
      context: context,
      gameType: GameType.sample,
      level: level,
      callbacks: callbacks,
      ref: ref,
    );
  }

  /// 导航到简单拼图游戏
  static Future<void> navigateToSimplePuzzleGame({
    required BuildContext context,
    required int level,
    GameCallbacks? callbacks,
    WidgetRef? ref,
  }) {
    return navigateToGame(
      context: context,
      gameType: GameType.simplePuzzle,
      level: level,
      callbacks: callbacks,
      ref: ref,
    );
  }
}

/// 默认游戏回调实现
class DefaultGameCallbacks implements GameCallbacks {
  final BuildContext context;
  final VoidCallback? onGameEnd;
  final WidgetRef? ref;

  DefaultGameCallbacks({
    required this.context,
    this.onGameEnd,
    this.ref,
  });

  @override
  void onGameSuccess({
    required int score,
    required int coins,
    required int level,
    int? performance,
  }) {
    // 记录游戏成功埋点
    final analytics = AnalyticsManager();
    analytics.logGameEnd(level: level, isSuccess: true);

    // 播放成功音效
    if (ref != null) {
      AudioActions.playSuccessSound(ref!);
    }

    // 显示成功消息
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('游戏成功!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    // 标记关卡完成，需要选择人物
    if (ref != null) {
      ref!.read(characterSelectionProvider.notifier).markLevelCompleted();
    }

    String? levelType;
    int? levelIndex;
    String? imageId;
    if (ref != null) {
      final levelState = ref!.read(levelProvider);
      levelType = levelState.currentLevelType;
      levelIndex = levelState.currentLevelIndex;
      imageId = levelState.currentImageId;
    }

    // 导航到图片解锁页面
    if (ref != null && levelType != null && levelIndex != null) {
      // 获取图片路径
      final userType = ref!.read(userTypeProvider);
      final imageLoader = ref!.read(imageLoaderServiceProvider);
      final config = ref!.read(firebaseConfigServiceProvider).getDefaultConfig(userType);
      
      final currentImageId = imageId ?? 'level_${levelType}_${levelIndex + 1}';
      final bool shouldUseNetwork = imageLoader.shouldLoadFromNetwork(currentImageId, userType, config);
      
      String imagePath;
      if (shouldUseNetwork) {
        imagePath = imageLoader.getNetworkImageUrl(currentImageId, config) ?? 
                    imageLoader.getLocalImagePath(currentImageId, config);
      } else {
        imagePath = imageLoader.getLocalImagePath(currentImageId, config);
      }

      final String finalLevelType = levelType;
      final int finalLevelIndex = levelIndex;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PhotoUnlockPage(
            levelType: finalLevelType,
            levelIndex: finalLevelIndex,
            imagePath: imagePath,
          ),
        ),
      );
    } else {
      // 降级：如果信息不全，仍然跳成功页面
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GameSuccessPage(
            coinsEarned: coins,
            level: level,
            percent: performance,
            levelType: levelType,
            levelIndex: levelIndex,
          ),
        ),
      );
    }

    onGameEnd?.call();
  }

  @override
  void onGameFailure({
    required String reason,
    required int level,
  }) {
    // 记录游戏失败埋点
    final analytics = AnalyticsManager();
    analytics.logGameEnd(level: level, isSuccess: false);

    // 显示失败消息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('游戏失败: $reason'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );

    // 导航到失败页面
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const GameFailPage(),
      ),
    );

    onGameEnd?.call();
  }

  @override
  void onGameTimeout({required int level}) {
    onGameFailure(reason: '时间到', level: level);
  }

  @override
  void onGameQuit({required int level}) {
    Navigator.of(context).pop();
    onGameEnd?.call();
  }

  @override
  void onCoinsChanged({
    required int oldCoins,
    required int newCoins,
    required int delta,
  }) {
    // 可以在这里添加金币变化的动画效果
    if (delta > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+$delta 金币'),
          backgroundColor: Colors.amber,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  void onLevelProgress({
    required int level,
    required double progress,
  }) {
    // 可以在这里添加进度更新的逻辑
  }
}
