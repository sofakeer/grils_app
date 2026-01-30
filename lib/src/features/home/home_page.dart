import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/analytics_manager.dart';
import 'package:hexcolor/hexcolor.dart';
import '../../../generated/assets.dart';
import '../../widgets/coin_display.dart';
import '../../widgets/black_text_button.dart';
import '../spin/spin_page.dart';
import '../photo_album/photo_album_page.dart';
import '../photo_album/photo_set_page.dart';
import '../photo_album/photo_set_providers.dart';
import '../signin/signin_dialog.dart';
import '../signin/signin_providers.dart';
import '../treasure/treasure_page.dart';
import '../game/game_manager.dart';
import '../character/character_selection_dialog.dart';
import '../character/character_selection_reward_dialog.dart';
import '../level/next_level_selection_dialog.dart';
import '../../providers/character_providers.dart';
import '../../providers/level_providers.dart';
import '../../providers/game_items_providers.dart';
import '../../providers/background_providers.dart';
import '../../providers/audio_providers.dart';
import '../../providers/user_type_provider.dart';
import '../../services/image_loader_service.dart';
import '../../widgets/settings_dialog.dart';
import '../../widgets/guide_dialog.dart';
import '../../providers/guide_providers.dart';

// 标记home埋点是否已上报，避免重复上报
bool _homeAnalyticsReported = false;

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 初始化道具系统
    _initializeGameItems(ref);

    // 记录进入主页埋点（只在首次进入时上报）
    if (!_homeAnalyticsReported) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AnalyticsManager().logHome();
        _homeAnalyticsReported = true;
      });
    }

    // 播放主页背景音乐 - 确保每次页面可见时都播放
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioActions.playHomeMusic(ref);
    });

    // 监听签到弹窗关闭，重新播放背景音乐
    ref.listen<AsyncValue<SignInState>>(signInProvider, (previous, next) {
      final prevState = previous?.valueOrNull;
      final nextState = next.valueOrNull;

      // 如果签到弹窗从显示状态变为非显示状态，重新播放背景音乐
      if (prevState?.shouldAutoPopup == true && nextState?.shouldAutoPopup == false) {
        print('签到弹窗已关闭，重新播放主页背景音乐');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AudioActions.playHomeMusic(ref);
        });

        // 延迟再次确保音乐播放，防止被其他组件中断
        Future.delayed(const Duration(milliseconds: 500), () {
          if (ref.context.mounted) {
            print('延迟检查：确保主页背景音乐在播放');
            AudioActions.playHomeMusic(ref);
          }
        });
      }
    });

    ref.listen<AsyncValue<SignInState>>(signInProvider, (previous, next) {
      final state = next.valueOrNull;
      if (state == null || !state.shouldAutoPopup) {
        return;
      }
      ref.read(signInProvider.notifier).markPopupShown();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // if (!ref.mounted) return;
        final navigator = Navigator.of(context);
        if (!navigator.mounted) return;
        await showSignInDialog(context);
      });
    });

    // 检测并显示引导弹窗
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowGuideDialog(context, ref);
    });

    return Scaffold(
      body: Consumer(
        builder: (context, ref, child) {
          final backgroundImage = ref.watch(backgroundImageProvider);
          print("[BACKGROUND] 主页背景图片: " + backgroundImage);
          // 监听背景图片变化，添加调试信息
          ref.listen<String>(backgroundImageProvider, (previous, next) {
            print('[BACKGROUND] 主页背景图片变化: $previous -> $next');
          });

          return Stack(
            children: [
              // 背景图片
              Positioned.fill(
                child: SmartImageWidget(
                  imagePath: backgroundImage,
                  userType: ref.read(userTypeProvider),
                  fit: BoxFit.cover,
                ),
              ),
              // 主要内容
              SafeArea(
                child: Column(
                  children: [
                    // 顶部栏
                    _buildTopBar(context, ref),
                    // 中央内容区域
                    Expanded(
                      child: Row(
                        children: [
                          // 左侧功能栏
                          _buildLeftSidebar(context, ref),
                        ],
                      ),
                    ),
                    _buildCenterArea(context, ref),
                    // 底部广告区域
                    _buildBottomAd(context),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧按钮组
          Row(
            children: [
              // 设置按钮
              GestureDetector(
                onTap: () {
                  showSettingsDialog(context).then((_) {
                    if (!context.mounted) return;
                    AudioActions.playHomeMusic(ref);
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              // 测试入口按钮
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/main');
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.bug_report,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          // 金币显示
          CoinDisplay(
            backgroundColor: Colors.black.withOpacity(0.3),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar(BuildContext context, WidgetRef ref) {
    return Container(
      width: 60,
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // 仅买量用户可见的入口控制
          // 买量用户：UserType.paid
          // 其他用户不展示“人物套图”和“无尽宝箱”

          // 签到/活动
          _buildSidebarButton(
            imagePath: Assets.assetsIcSign2x,
            color: Colors.orange,
            onTap: () => showSignInDialog(context),
            ref: ref,
          ),
          const SizedBox(height: 16),
          // 转盘抽奖
          _buildSidebarButton(
            imagePath: Assets.assetsIcRoute2x,
            color: Colors.purple,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SpinPage()),
            ),
            ref: ref,
          ),
          // 买量用户专属入口：人物套图、无尽宝箱
          if (ref.watch(userTypeProvider) == UserType.paid) ...[
            const SizedBox(height: 16),
            _buildSidebarButton(
              imagePath: Assets.assetsIcSecret2x,
              color: Colors.deepPurple,
              onTap: () {
                // 标记已进入套图页面
                ref.read(guideProvider.notifier).markPhotoSetPageEntered();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PhotoSetPage()),
                );
              },
              ref: ref,
            ),
            const SizedBox(height: 16),
            // 宝箱奖励
            _buildSidebarButton(
              imagePath: Assets.assetsIcTreasure2x,
              color: Colors.amber,
              onTap: () {
                // 标记已进入通行证页面
                ref.read(guideProvider.notifier).markTreasurePageEntered();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TreasurePage()),
                );
              },
              ref: ref,
            ),
          ],
          // // 宝箱奖励
          // _buildSidebarButton(
          //   imagePath: Assets.assetsIcTreasure2x,
          //   color: Colors.amber,
          //   onTap: () => Navigator.of(context).push(
          //     MaterialPageRoute(builder: (_) => TiltTestPage()),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildSidebarButton({
    IconData? icon,
    String? imagePath,
    required Color color,
    required VoidCallback onTap,
    WidgetRef? ref,
  }) {
    return GestureDetector(
      onTap: () {
        // 播放点击音效
        if (ref != null) {
          AudioActions.playClickSound(ref);
        }
        onTap();
      },
      child: Container(
        width: 50,
        height: 50,
        child: imagePath != null
            ? Image.asset(
                imagePath,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
            : Icon(
                icon ?? Icons.help,
                color: Colors.white,
                size: 24,
              ),
      ),
    );
  }

  Widget _buildCenterArea(BuildContext context, WidgetRef ref) {
    const double levelButtonWidth = 200;
    const double photoButtonWidth = 50;
    const double horizontalGap = 20;
    final double photoButtonOffset = levelButtonWidth / 2 + horizontalGap + photoButtonWidth / 2;

    return Padding(
      padding: const EdgeInsets.only(bottom: 28.0),
      child: SizedBox(
        width: double.infinity,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Consumer(
              builder: (context, ref, child) {
                final levelState = ref.watch(levelProvider);
                return BlackTextButtonStyle.normalImageBackground(
                  text: 'LEVEL ${levelState.currentLevel}',
                  onTap: () => _onLevelButtonTap(context, ref),
                  width: levelButtonWidth,
                  height: 80,
                );
              },
            ),
            Transform.translate(
              offset: Offset(photoButtonOffset, 0),
              child: _buildSidebarButton(
                imagePath: Assets.assetsIcImages2x,
                color: Colors.amber,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PhotoAlbumPage()),
                ),
                ref: ref,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildBottomAd(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HexColor('#ff6b6b'),
            HexColor('#4ecdc4'),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // AD 标识
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // 广告内容
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 角色图标占位
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // 广告文字
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOP UP',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'DI STORE KAMI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 显示游戏选择对话框
  void _showGameSelectionDialog(BuildContext context, [WidgetRef? ref]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择游戏'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGameOption(
              context,
              title: '简单拼图游戏',
              description: '拼图游戏，测试逻辑能力',
              icon: Icons.extension,
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).pop();
                _startGame(context, GameType.simplePuzzle, ref);
              },
            ),
            const SizedBox(height: 12),
            _buildGameOption(
              context,
              title: '示例游戏',
              description: '点击目标游戏，测试反应能力',
              icon: Icons.star,
              color: Colors.orange,
              onTap: () {
                Navigator.of(context).pop();
                _startGame(context, GameType.sample, ref);
              },
            ),
            const SizedBox(height: 12),
            _buildGameOption(
              context,
              title: '拼图游戏',
              description: '开发中...',
              icon: Icons.extension,
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).pop();
                _startGame(context, GameType.puzzle, ref);
              },
            ),
            const SizedBox(height: 12),
            _buildGameOption(
              context,
              title: '记忆游戏',
              description: '开发中...',
              icon: Icons.memory,
              color: Colors.green,
              onTap: () {
                Navigator.of(context).pop();
                _startGame(context, GameType.memory, ref);
              },
            ),
            const SizedBox(height: 12),
            _buildGameOption(
              context,
              title: '反应游戏',
              description: '开发中...',
              icon: Icons.speed,
              color: Colors.orange,
              onTap: () {
                Navigator.of(context).pop();
                _startGame(context, GameType.reaction, ref);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  /// Level按钮点击逻辑
  Future<void> _onLevelButtonTap(BuildContext context, WidgetRef ref) async {
    // 播放点击音效
    AudioActions.playClickSound(ref);

    // ✅ 清理其他模式的选择状态（通行证/套图）
    ref.read(photoSetGameSelectionProvider.notifier).state = null;

    final levelState = ref.read(levelProvider);
    final userType = ref.read(userTypeProvider);
    final isPaidUser = userType == UserType.paid;

    if (isPaidUser) {
      if (levelState.isFirstLevel) {
        await ref.read(levelProvider.notifier).startLevel();
      }
      _showNextLevelSelectionDialog(context, ref);
      return;
    }

    // 自然量用户：不显示3选1，按顺序进入下一张图片
    if (levelState.isFirstLevel) {
      // 第一关直接进入游戏
      _startFirstLevel(context, ref);
      return;
    }

    _startNextNaturalLevel(context, ref);
  }

  /// 开始第一关
  void _startFirstLevel(BuildContext context, WidgetRef ref) {
    final userType = ref.read(userTypeProvider);
    final defaultLevelType = _defaultLevelTypeForUser(userType);
    // 开始第一关
    ref.read(levelProvider.notifier).startLevel();
    // 传递图片ID而不是路径，让SmartImageWidget智能选择网络或本地图片
    final imageId = 'level_${defaultLevelType}_1';
    ref.read(levelProvider.notifier).setCurrentLevelSelection(
          levelType: defaultLevelType,
          levelIndex: 0,
          imageId: imageId,
        );

    // 直接进入游戏
    GameNavigator.navigateToGame(
      context: context,
      gameType: GameType.simplePuzzle,
      level: 1,
      callbacks: DefaultGameCallbacks(
        context: context,
        ref: ref,
      ),
    );
  }

  /// 自然量用户：按顺序进入下一张图片（不弹3选1）
  void _startNextNaturalLevel(BuildContext context, WidgetRef ref) async {
    final levelState = ref.read(levelProvider);
    final userType = ref.read(userTypeProvider);
    final defaultLevelType = _defaultLevelTypeForUser(userType);

    // 使用当前关卡类型与索引；默认从 'a' 开始（自然流量用户）
    final String currentType = levelState.currentLevelType ?? defaultLevelType;
    final int currentIndex = levelState.currentLevelIndex ?? 0;
    final int nextIndex = currentIndex + 1; // 修复：应该递增到下一张图片

    // 传递图片ID而不是路径，让SmartImageWidget智能选择网络或本地图片
    final imageId = 'level_${currentType}_${nextIndex + 1}';
    await ref.read(levelProvider.notifier).setCurrentLevelSelection(
          levelType: currentType,
          levelIndex: nextIndex,
          imageId: imageId,
        );

    _startGameWithLevel(context, ref, currentType, nextIndex);
  }

  /// 显示选择下一关弹窗
  Future<void> _showNextLevelSelectionDialog(BuildContext context, WidgetRef ref) async {
    await showNextLevelSelectionDialog(
      context,
      onLevelChosen: (levelType, levelIndex) async {
        // 处理关卡选择
        await _handleLevelSelection(context, ref, levelType, levelIndex);
      },
      onLevelSelected: () {
        // 关卡选择完成后的回调
        print('关卡选择完成');
      },
    );
    if (!context.mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      AudioActions.playHomeMusic(ref);
    });
  }

  /// 处理关卡选择
  Future<void> _handleLevelSelection(BuildContext context, WidgetRef ref, String levelType, int levelIndex) async {
    // // 显示选择结果
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('选择了 $levelType 类型，第 ${levelIndex + 1} 张图片'),
    //     backgroundColor: Colors.green,
    //     duration: const Duration(seconds: 2),
    //   ),
    // );

    // 根据选择的关卡类型启动游戏
    // 传递图片ID而不是路径，让SmartImageWidget智能选择网络或本地图片
    final imageId = 'level_${levelType}_${levelIndex + 1}';
    await ref.read(levelProvider.notifier).setCurrentLevelSelection(
          levelType: levelType,
          levelIndex: levelIndex,
          imageId: imageId,
        );
    _startGameWithLevel(context, ref, levelType, levelIndex);
  }

  /// 根据选择的关卡启动游戏
  void _startGameWithLevel(BuildContext context, WidgetRef ref, String levelType, int levelIndex) {
    final levelState = ref.read(levelProvider);

    // 根据关卡类型选择游戏类型
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

  /// 显示选择图片弹窗（保留兼容性）
  void _showCharacterSelectionRewardDialog(BuildContext context, WidgetRef ref) {
    // 进入主页埋点
    AnalyticsManager().logHome();
    showCharacterSelectionRewardDialog(
      context,
      onCharacterSelected: () {
        // 人物选择完成后，开始新关卡
        _startGameAfterCharacterSelection(context, ref);
      },
      onClose: () {
        // 关闭弹窗，返回主页
        Navigator.of(context).pop();
      },
    );
  }

  /// 选择人物后开始游戏
  void _startGameAfterCharacterSelection(BuildContext context, WidgetRef ref) {
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

  /// 显示选择人物弹窗（旧版本，保留兼容性）
  void _showCharacterSelectionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CharacterSelectionDialog(
        onCharacterSelected: () {
          // 人物选择完成后，开始新关卡
          ref.read(characterSelectionProvider.notifier).startNewLevel();
          // 显示游戏选择对话框
          _showGameSelectionDialog(context, ref);
        },
      ),
    );
  }

  /// 开始游戏
  void _startGame(BuildContext context, GameType gameType, WidgetRef? ref) {
    // 获取当前关卡（可以从用户进度中获取）
    const currentLevel = 1;

    GameNavigator.navigateToGame(
      context: context,
      gameType: gameType,
      level: currentLevel,
      callbacks: DefaultGameCallbacks(
        context: context,
        ref: ref,
        onGameEnd: () {
          // 游戏结束后的回调
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('游戏结束，返回主页'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
      ref: ref,
    );
  }

  /// 构建背景图片（移除重复的背景图片设置，只保留内容叠加）
  Widget _buildBackgroundImage(String backgroundImage, Map<String, dynamic> setInfo) {
    return Positioned.fill(
      child: Container(
        // 移除背景图片设置，避免与主Container的背景图片冲突
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // // 套图信息显示
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              //   decoration: BoxDecoration(
              //     color: Colors.black.withOpacity(0.5),
              //     borderRadius: BorderRadius.circular(20),
              //   ),
              //   child: Text(
              //     '套图 ${setInfo['setId']}',
              //     style: const TextStyle(
              //       color: Colors.white,
              //       fontSize: 16,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 8),
              // // 解锁信息
              // if (setInfo['nextUnlockLevel'] != null)
              //   Container(
              //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              //     decoration: BoxDecoration(
              //       color: Colors.orange.withOpacity(0.8),
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     child: Text(
              //       'Level ${setInfo['nextUnlockLevel']} 解锁',
              //       style: const TextStyle(
              //         color: Colors.white,
              //         fontSize: 12,
              //         fontWeight: FontWeight.w500,
              //       ),
              //     ),
              //   ),
            ],
          ),
        ),
      ),
    );
  }

  /// 初始化游戏道具系统
  void _initializeGameItems(WidgetRef ref) {
    // 检查是否需要初始化道具
    final itemsState = ref.read(gameItemsProvider);
    if (itemsState.items.isEmpty) {
      // 初始化默认道具
      ref.read(gameItemsProvider.notifier).initializeDefaultItems();
    }
  }

  /// 检测并显示引导弹窗
  void _checkAndShowGuideDialog(BuildContext context, WidgetRef ref) {
    final levelState = ref.read(levelProvider);
    final guideController = ref.read(guideProvider.notifier);
    final userType = ref.read(userTypeProvider);

    // 只有买量用户才显示引导弹窗
    if (userType != UserType.paid) {
      return;
    }

    final currentLevel = levelState.currentLevel;

    // 检查是否应该显示套图引导
    if (guideController.shouldShowPhotoSetGuide(currentLevel)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          showPhotoSetGuideDialog(context);
        }
      });
      return;
    }

    // 检查是否应该显示通行证引导
    if (guideController.shouldShowTreasureGuide(currentLevel)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          showTreasureGuideDialog(context);
        }
      });
    }
  }
}

String _defaultLevelTypeForUser(UserType userType) {
  return userType == UserType.natural ? 'a' : 'b';
}
