import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/widgets/common_header.dart';
import 'package:grils_app/pages/settings_page.dart';
import 'package:grils_app/pages/signin_page.dart';
import 'package:grils_app/pages/gallery_page.dart';
import 'package:grils_app/pages/shop_page.dart';
import 'package:grils_app/pages/game_page.dart';
import 'package:grils_app/pages/special_page.dart';
import 'package:grils_app/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spine_flutter/spine_flutter.dart' as spine;

import '../main_old.dart';
import '../managers/audio_manager.dart';
import '../managers/game_state_manager.dart';
import '../utils/audio_assets.dart';
import '../widgets/outlined_text_widget.dart';
import '../services/user_service.dart';
import '../widgets/unlock_new_gril_dialog.dart';
import '../widgets/gril_waiting_dialog.dart';
import 'spine_preview_page.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage>
    with TickerProviderStateMixin {
  late AnimationController _takeoffController;
  late Animation<double> _takeoffAnimation;

  // 修改：使用可空类型避免 LateInitializationError
  AnimationController? _maskController;
  Animation<double>? _maskAnimation;

  // 页面加载状态
  bool _isPageReady = false;

  // 防重复调用标记
  bool _isRestoringState = false;
  DateTime? _lastRestoreTime;

  // 背景女孩Spine控制器
  spine.SpineWidgetController? _backgroundSpineController;
  bool _isBackgroundSpineReady = false;
  int _backgroundIdleIndex = 0;
  Map<String, int> _backgroundSkinSelections = {};

  // 使用UserService管理金币和爱心
  late UserService _userService;
  int _currentLevel = 1;

  // 最新解锁的图片索引
  int _latestUnlockedImageIndex = 0;

  // 标记是否已经弹过 GrilWaitingDialog
  bool _hasShownGrilWaitingDialog = false;
  static const String _kHasShownGrilWaitingDialogKey =
      'has_shown_gril_waiting_dialog';

  Future<void> _loadHasShownGrilWaitingDialogFlag() async {
    final prefs = await SharedPreferences.getInstance();
    _hasShownGrilWaitingDialog =
        prefs.getBool(_kHasShownGrilWaitingDialogKey) ?? false;
  }

  Future<void> _setHasShownGrilWaitingDialogFlag(bool value) async {
    _hasShownGrilWaitingDialog = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasShownGrilWaitingDialogKey, value);
  }

  Future<void> _restoreBackgroundState() async {
    // 防重复调用检查
    final now = DateTime.now();
    if (_isRestoringState) {
      print("[SPINE流程] 警告: 正在恢复状态中，跳过重复调用");
      return;
    }

    if (_lastRestoreTime != null) {
      final timeDiff = now.difference(_lastRestoreTime!);
      if (timeDiff.inMilliseconds < 500) {
        print("[SPINE流程] 警告: 距离上次恢复时间过短(${timeDiff.inMilliseconds}ms)，跳过重复调用");
        return;
      }
    }

    print("=== [SPINE流程] 开始恢复背景女孩状态 ===");
    print("[SPINE流程] 防重复检查通过，开始执行状态恢复");

    _isRestoringState = true;
    _lastRestoreTime = now;

    try {
      print("[SPINE流程] 步骤1: 初始化GameStateManager");
      await GameStateManager().init();

      print("[SPINE流程] 步骤2: 尝试获取上次保存的女孩状态");
      // 优先尝试恢复上次保存的女孩状态
      final lastState = GameStateManager().getLastGirlState();
      int targetGirlIndex;
      int idleOverride;
      Map<String, int>? skinsOverride;

      if (lastState != null) {
        print("[SPINE流程] 步骤2a: 找到保存的状态，正在解析...");
        print("[SPINE流程] 原始状态数据: $lastState");

        // 如果有上次保存的状态，使用它
        targetGirlIndex = (lastState['girlIndex'] as int?) ?? 0;
        idleOverride = (lastState['idleIndex'] as int?) ?? 0;

        print("[SPINE流程] 解析出的基础值 - 女孩索引: $targetGirlIndex, 待机索引: $idleOverride");

        // 解析皮肤状态
        final dynamic skins = lastState['skins'];
        if (skins is Map) {
          print("[SPINE流程] 开始解析皮肤状态...");
          final map = <String, int>{};
          skins.forEach((key, value) {
            if (key is String) {
              if (value is int) {
                map[key] = value;
              } else if (value is num) {
                map[key] = value.toInt();
              }
            }
          });
          if (map.isNotEmpty) {
            skinsOverride = map;
          }
          print("[SPINE流程] 解析完成的皮肤状态: $skinsOverride");
        } else {
          print("[SPINE流程] 未找到皮肤状态或皮肤状态格式错误");
        }

        print("[SPINE流程] 恢复上次保存的女孩状态: girl=$targetGirlIndex, idle=$idleOverride, skins=$skinsOverride");
      } else {
        print("[SPINE流程] 步骤2b: 未找到保存的状态，使用StateManager当前状态");
        // 如果没有保存的状态，使用当前StateManager的状态
        targetGirlIndex = GameStateManager().getCurrentGirlIndex();
        idleOverride = GameStateManager().getCurrentIdleIndex();
        skinsOverride = GameStateManager().getCurrentSkins(targetGirlIndex);
        print("[SPINE流程] 使用StateManager当前状态: girl=$targetGirlIndex, idle=$idleOverride, skins=$skinsOverride");
      }

      print("[SPINE流程] 步骤3: 调用_loadGirlStateForBackground加载女孩状态");
      await _loadGirlStateForBackground(
        targetGirlIndex,
        idleIndexOverride: idleOverride,
        skinsOverride: skinsOverride,
        ensureInit: false,
      );

      print("[SPINE流程] 步骤4: 更新GameStateManager状态");
      // 更新StateManager状态
      await GameStateManager().setCurrentGirlIndex(targetGirlIndex);
      await GameStateManager().setCurrentIdleIndex(idleOverride);

      print("[SPINE流程] 步骤5: 标记页面准备就绪");
      // 标记页面准备就绪
      if (mounted) {
        setState(() {
          _isPageReady = true;
        });
        print("[SPINE流程] 页面状态已更新为准备就绪");
      } else {
        print("[SPINE流程] 警告: Widget已销毁，无法更新页面状态");
      }

      print("=== [SPINE流程] 背景女孩状态恢复完成 ===");
    } catch (e) {
      print("[SPINE流程] 错误: 状态恢复过程中发生异常: $e");
    } finally {
      // 确保无论如何都重置恢复标记
      _isRestoringState = false;
      print("[SPINE流程] 状态恢复标记已重置");
    }
  }

  Future<void> _loadGirlStateForBackground(
      int girlIndex, {
        int? idleIndexOverride,
        Map<String, int>? skinsOverride,
        bool ensureInit = true,
      }) async {
    print("=== [SPINE流程] 开始加载女孩状态到背景 ===");
    print("[SPINE流程] 输入参数 - girlIndex: $girlIndex, idleIndexOverride: $idleIndexOverride, skinsOverride: $skinsOverride, ensureInit: $ensureInit");

    print("[SPINE流程] 步骤1: 检查GameStateManager初始化");
    if (ensureInit) {
      await GameStateManager().init();
      print("[SPINE流程] GameStateManager已初始化");
    } else {
      print("[SPINE流程] 跳过GameStateManager初始化");
    }

    print("[SPINE流程] 步骤2: 获取Spine资源");
    final assets = ref.read(spineAssetsProvider);
    print("[SPINE流程] 获取到的Spine资源数量: ${assets.length}");
    if (assets.isEmpty) {
      print("[SPINE流程] 错误: Spine资源为空，无法继续加载");
      return;
    }

    print("[SPINE流程] 步骤3: 规范化女孩索引和状态");
    final int normalizedGirlIndex =
    girlIndex.clamp(0, assets.length - 1) as int;
    print("[SPINE流程] 原始女孩索引: $girlIndex, 规范化后: $normalizedGirlIndex");

    final int storedIdle = idleIndexOverride ??
        GameStateManager().getGirlIdleIndex(normalizedGirlIndex);
    print("[SPINE流程] 使用的待机索引: $storedIdle (override: $idleIndexOverride)");

    final Map<String, int> storedSkins =
    GameStateManager().getCurrentSkins(normalizedGirlIndex);
    print("[SPINE流程] 当前存储的皮肤: $storedSkins");

    final Map<String, int> mergedSkins = {...storedSkins};
    if (skinsOverride != null) {
      mergedSkins.addAll(skinsOverride);
      print("[SPINE流程] 合并了覆盖皮肤: $skinsOverride");
    }
    print("[SPINE流程] 最终合并的皮肤: $mergedSkins");

    print("[SPINE流程] 步骤4: 检查Widget状态");
    if (!mounted) {
      print("[SPINE流程] 警告: Widget已销毁，退出加载流程");
      return;
    }

    print("[SPINE流程] 步骤5: 更新Provider状态");
    ref.read(currentGirlIndexProvider.notifier).state = normalizedGirlIndex;
    print("[SPINE流程] currentGirlIndexProvider已更新为: $normalizedGirlIndex");

    print("[SPINE流程] 步骤6: 规范化并设置状态变量");
    final normalizedIdle = _normalizeIdleIndex(normalizedGirlIndex, storedIdle);
    final normalizedSkins = _normalizeSkinSelections(normalizedGirlIndex, mergedSkins);
    print("[SPINE流程] 规范化后的待机索引: $normalizedIdle");
    print("[SPINE流程] 规范化后的皮肤选择: $normalizedSkins");

    setState(() {
      _backgroundIdleIndex = normalizedIdle;
      _backgroundSkinSelections = normalizedSkins;
      _isBackgroundSpineReady = false;
    });
    print("[SPINE流程] 背景状态变量已更新，Spine状态标记为未就绪");

    print("[SPINE流程] 步骤7: 更新GameStateManager");
    await GameStateManager().setCurrentGirlIndex(normalizedGirlIndex);
    await GameStateManager().setCurrentIdleIndex(_backgroundIdleIndex);
    print("[SPINE流程] GameStateManager状态已更新");

    print("[SPINE流程] 步骤8: 再次检查Widget状态");
    if (!mounted) {
      print("[SPINE流程] 警告: Widget已销毁，无法初始化Spine控制器");
      return;
    }

    print("[SPINE流程] 步骤9: 初始化背景Spine控制器");
    _initializeBackgroundSpine();

    print("=== [SPINE流程] 女孩状态加载完成 ===");
  }

  Map<String, int> _normalizeSkinSelections(
      int girlIndex, Map<String, int> skins) {
    if (girlIndex == 0) {
      return {
        'bra': skins['bra'] ?? 0,
        'pants': skins['pants'] ?? 0,
        'hands': skins['hands'] ?? 0,
        'socks': skins['socks'] ?? 0,
      };
    } else if (girlIndex == 1) {
      return {
        'head': skins['head'] ?? 0,
        'bra': skins['bra'] ?? 0,
        'hands': skins['hands'] ?? 0,
        'socks': skins['socks'] ?? 0,
      };
    } else {
      return {
        'head': skins['head'] ?? 0,
        'bra': skins['bra'] ?? 0,
        'pants': skins['pants'] ?? 0,
        'socks': skins['socks'] ?? 0,
      };
    }
  }

  int _normalizeIdleIndex(int girlIndex, int idleIndex) {
    final int maxIndex = girlIndex == 2 ? 5 : 4;
    if (idleIndex < 0) {
      return 0;
    }
    if (idleIndex > maxIndex) {
      return maxIndex;
    }
    return idleIndex;
  }

  bool _isUnderwearMode(int girlIndex, int idleIndex) {
    return girlIndex == 2 ? idleIndex == 5 : idleIndex == 4;
  }

  String _resolveIdleAnimationName(int girlIndex, int idleIndex) {
    if (_isUnderwearMode(girlIndex, idleIndex)) {
      return 'idle_underwear';
    }
    final int safeIndex = idleIndex < 0 ? 0 : idleIndex;
    final String formatted = (safeIndex + 1).toString().padLeft(2, '0');
    return 'idle_$formatted';
  }

  List<String> _buildDefaultSkinNames(int girlIndex) {
    if (girlIndex == 0) {
      return [
        'bra/bra_none',
        'pants/pants_none',
        'hands/hands_none',
        'socks/socks_none',
      ];
    } else if (girlIndex == 1) {
      return [
        'bra/bra_none',
        'hands/hands_none',
        'head/head_none',
        'socks/socks_none',
      ];
    } else {
      return [
        'bra/bra_none',
        'head/head_none',
        'pants/pants_none',
        'socks/socks_none',
      ];
    }
  }

  List<String> _buildUnderwearSkinNames(int girlIndex, Map<String, int> skins) {
    if (girlIndex == 0) {
      return [
        'bra/bra${(skins['bra'] ?? 0) + 1}',
        'pants/pants${(skins['pants'] ?? 0) + 1}',
        'hands/hands${(skins['hands'] ?? 0) + 1}',
        'socks/socks${(skins['socks'] ?? 0) + 1}',
      ];
    } else if (girlIndex == 1) {
      return [
        'bra/bra${(skins['bra'] ?? 0) + 1}',
        'hands/hands${(skins['hands'] ?? 0) + 1}',
        'head/head${(skins['head'] ?? 0) + 1}',
        'socks/socks${(skins['socks'] ?? 0) + 1}',
      ];
    } else {
      return [
        'bra/bra${(skins['bra'] ?? 0) + 1}',
        'head/head${(skins['head'] ?? 0) + 1}',
        'pants/pants${(skins['pants'] ?? 0) + 1}',
        'socks/socks${(skins['socks'] ?? 0) + 1}',
      ];
    }
  }

  void _applySkinSet(
      spine.SpineWidgetController controller, List<String> skinNames) {
    print("=== [SPINE流程] 开始应用皮肤设置 ===");
    print("[SPINE流程] 皮肤名称列表: $skinNames");

    try {
      print("[SPINE流程] 步骤1: 获取骨骼数据和骨骼对象");
      final data = controller.skeletonData;
      final skeleton = controller.skeleton;
      if (data == null || skeleton == null) {
        print("[SPINE流程] 错误: 骨骼数据或骨骼对象为空，无法应用皮肤");
        return;
      }
      print("[SPINE流程] 骨骼数据和骨骼对象获取成功");

      print("[SPINE流程] 步骤2: 创建自定义皮肤");
      final customSkin = spine.Skin('background-custom-skin');
      bool hasAnySkin = false;
      int foundSkins = 0;
      int missingSkins = 0;

      print("[SPINE流程] 步骤3: 查找并添加皮肤");
      for (final name in skinNames) {
        print("[SPINE流程] 查找皮肤: $name");
        final skin = data.findSkin(name);
        if (skin != null) {
          customSkin.addSkin(skin);
          hasAnySkin = true;
          foundSkins++;
          print("[SPINE流程] 皮肤找到并添加: $name");
        } else {
          missingSkins++;
          print('[SPINE流程] 警告: 背景女孩皮肤缺失: $name');
        }
      }

      print("[SPINE流程] 皮肤查找统计 - 找到: $foundSkins, 缺失: $missingSkins");

      print("[SPINE流程] 步骤4: 应用皮肤到骨骼");
      if (hasAnySkin) {
        skeleton.setSkin(customSkin);
        skeleton.setSlotsToSetupPose();

        print("[SPINE流程] 自定义皮肤应用成功");
      } else {
        print("[SPINE流程] 未找到任何自定义皮肤，尝试应用默认皮肤");
        final defaultSkin = data.findSkin('default');
        if (defaultSkin != null) {
          skeleton.setSkin(defaultSkin);
          skeleton.setSlotsToSetupPose();
          print("[SPINE流程] 默认皮肤应用成功");
        } else {
          skeleton.setToSetupPose();
          print("[SPINE流程] 使用默认姿势（未找到任何皮肤）");
        }
      }

      print("[SPINE流程] 步骤5: 验证皮肤应用结果");
      final currentSkin = skeleton.getSkin();
      if (currentSkin != null) {
        print("[SPINE流程] 当前皮肤名称: ${currentSkin.getName()}");
      } else {
        print("[SPINE流程] 当前没有设置皮肤");
      }

    } catch (e) {
      print('[SPINE流程] 错误: 背景女孩皮肤设置失败: $e');
      print('[SPINE流程] 错误类型: ${e.runtimeType}');
      print('[SPINE流程] 错误堆栈: ${StackTrace.current}');
    }

    print("=== [SPINE流程] 皮肤设置完成 ===");
  }

  void _applyBackgroundSkin(
      spine.SpineWidgetController controller, int girlIndex, bool isUnderwear) {
    print("=== [SPINE流程] 开始应用背景皮肤 ===");
    print("[SPINE流程] 皮肤参数 - 女孩索引: $girlIndex, 是否内衣模式: $isUnderwear");
    print("[SPINE流程] 当前皮肤选择: $_backgroundSkinSelections");

    print("[SPINE流程] 构建皮肤名称列表...");
    final skinNames = isUnderwear
        ? _buildUnderwearSkinNames(girlIndex, _backgroundSkinSelections)
        : _buildDefaultSkinNames(girlIndex);

    print("[SPINE流程] 生成的皮肤名称: $skinNames");
    print("[SPINE流程] 调用_applySkinSet应用皮肤...");

    _applySkinSet(controller, skinNames);
// 新增：延迟1秒后重新应用皮肤参数
    _scheduleDelayedSkinReapply(controller, girlIndex, isUnderwear);
    print("=== [SPINE流程] 背景皮肤应用完成 ===");
  }

  void _scheduleDelayedSkinReapply(
      spine.SpineWidgetController controller, int girlIndex, bool isUnderwear) {
    print("[SPINE流程] 安排延迟1秒后重新应用皮肤...");

    Future.delayed(Duration(milliseconds: 100 ), () {
      if (!mounted || controller != _backgroundSpineController) {
        print("[SPINE流程] 延迟应用: Widget已销毁或控制器已变更，跳过重新应用");
        return;
      }

      print("[SPINE流程] 延迟1秒后重新应用皮肤参数");
      print("[SPINE流程] 重新应用的皮肤选择: $_backgroundSkinSelections");

      // 重新构建皮肤名称（可能参数已经更新）
      final updatedSkinNames = isUnderwear
          ? _buildUnderwearSkinNames(girlIndex, _backgroundSkinSelections)
          : _buildDefaultSkinNames(girlIndex);

      print("[SPINE流程] 重新生成的皮肤名称: $updatedSkinNames");

      // 重新应用皮肤
      _applySkinSet(controller, updatedSkinNames);

      print("[SPINE流程] 延迟皮肤重新应用完成");
    });
  }
  void _applyBackgroundState(spine.SpineWidgetController controller) {
    print("=== [SPINE流程] 开始应用背景状态 ===");

    print("[SPINE流程] 步骤1: 获取控制器组件");
    final animationState = controller.animationState;
    final stateData = animationState?.getData();
    final skeleton = controller.skeleton;
    final skeletonData = skeleton?.getData();

    print("[SPINE流程] 组件状态检查:");
    print("[SPINE流程] - animationState: ${animationState != null ? '存在' : '缺失'}");
    print("[SPINE流程] - stateData: ${stateData != null ? '存在' : '缺失'}");
    print("[SPINE流程] - skeleton: ${skeleton != null ? '存在' : '缺失'}");
    print("[SPINE流程] - skeletonData: ${skeletonData != null ? '存在' : '缺失'}");

    if (animationState == null ||
        stateData == null ||
        skeleton == null ||
        skeletonData == null) {
      print("[SPINE流程] 警告: 控制器尚未准备就绪，将在下一帧重试");
      // 控制器尚未准备就绪，等待下一帧再试
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller == _backgroundSpineController) {
          print("[SPINE流程] 重试应用背景状态...");
          _applyBackgroundState(controller);
        } else {
          print("[SPINE流程] 重试失败: Widget已销毁或控制器已变更");
        }
      });
      return;
    }

    print("[SPINE流程] 步骤2: 设置动画过渡时间");
    try {
      stateData.setDefaultMix(0.2);
      print("[SPINE流程] 动画过渡时间设置为: 0.2秒");
    } catch (e) {
      print('[SPINE流程] 错误: 背景女孩动画过渡设置失败: $e');
    }

    print("[SPINE流程] 步骤3: 获取当前状态参数");
    final girlIndex = ref.read(currentGirlIndexProvider);
    final idleIndex = _backgroundIdleIndex;
    final isUnderwear = _isUnderwearMode(girlIndex, idleIndex);
    final desiredAnimation = _resolveIdleAnimationName(girlIndex, idleIndex);

    print("[SPINE流程] 状态参数:");
    print("[SPINE流程] - 女孩索引: $girlIndex");
    print("[SPINE流程] - 待机索引: $idleIndex");
    print("[SPINE流程] - 是否内衣模式: $isUnderwear");
    print("[SPINE流程] - 期望动画名称: $desiredAnimation");

    print("[SPINE流程] 步骤4: 查找可用动画");
    String? animationToPlay;
    try {
      if (skeletonData.findAnimation(desiredAnimation) != null) {
        animationToPlay = desiredAnimation;
        print("[SPINE流程] 找到期望动画: $animationToPlay");
      } else if (skeletonData.findAnimation('idle_01') != null) {
        animationToPlay = 'idle_01';
        print("[SPINE流程] 使用默认动画: $animationToPlay");
      } else {
        final animations = skeletonData.getAnimations();
        if (animations != null && animations.isNotEmpty) {
          animationToPlay = animations.first.getName();
          print("[SPINE流程] 使用第一个可用动画: $animationToPlay");
          print("[SPINE流程] 总共找到 ${animations.length} 个动画");
        } else {
          print("[SPINE流程] 警告: 未找到任何可用动画");
        }
      }
    } catch (e) {
      print('[SPINE流程] 错误: 背景女孩查询动画失败: $e');
    }

    print("[SPINE流程] 步骤5: 设置动画播放");
    if (animationToPlay != null && animationToPlay.isNotEmpty) {
      try {
        animationState.setAnimationByName(0, animationToPlay, true);
        print("[SPINE流程] 动画设置成功: $animationToPlay (循环播放)");

        // 添加动画状态验证
        _scheduleAnimationHealthCheck(controller, animationToPlay);
      } catch (e) {
        print('[SPINE流程] 错误: 背景女孩动画播放失败: $e');
      }
    } else {
      print("[SPINE流程] 警告: 没有可播放的动画");
    }

    print("[SPINE流程] 步骤6: 应用皮肤设置");
    _applyBackgroundSkin(controller, girlIndex, isUnderwear);

    print("[SPINE流程] 步骤7: 标记Spine准备就绪");
    if (mounted) {
      setState(() {
        _isBackgroundSpineReady = true;
      });
      print("[SPINE流程] 背景Spine状态已标记为准备就绪");
    } else {
      print("[SPINE流程] 警告: Widget已销毁，无法更新状态");
    }

    print("=== [SPINE流程] 背景状态应用完成 ===");
  }

  // 动画健康检查 - 确保动画正常播放
  void _scheduleAnimationHealthCheck(spine.SpineWidgetController controller, String expectedAnimation) {
    // 延迟500ms检查动画状态
    Future.delayed(Duration(milliseconds: 500), () {
      if (!mounted || controller != _backgroundSpineController) {
        print("[SPINE流程] 健康检查: Widget或控制器已变更，跳过检查");
        return;
      }

      try {
        final animationState = controller.animationState;
        if (animationState == null) {
          print("[SPINE流程] 健康检查: animationState为空，尝试重新设置动画");
          _retryAnimationSetup(controller, expectedAnimation);
          return;
        }

        final currentAnimation = animationState.getCurrent(0);
        final currentAnimationName = currentAnimation?.getAnimation()?.getName();

        print("[SPINE流程] 健康检查: 期望动画=$expectedAnimation, 当前动画=$currentAnimationName");

        if (currentAnimationName != expectedAnimation) {
          print("[SPINE流程] 健康检查: 动画不匹配，尝试重新设置");
          _retryAnimationSetup(controller, expectedAnimation);
        } else {
          print("[SPINE流程] 健康检查: 动画正常播放");

          // 再检查一次动画是否真的在播放
          _verifyAnimationPlaying(controller, expectedAnimation);
        }
      } catch (e) {
        print("[SPINE流程] 健康检查失败: $e");
        _retryAnimationSetup(controller, expectedAnimation);
      }
    });
  }

  // 重试动画设置
  void _retryAnimationSetup(spine.SpineWidgetController controller, String animationName) {
    print("[SPINE流程] 尝试重新设置动画: $animationName");

    try {
      final animationState = controller.animationState;
      if (animationState != null) {
        // 清除现有动画
        animationState.clearTracks();

        // 重新设置动画
        animationState.setAnimationByName(0, animationName, true);
        print("[SPINE流程] 动画重新设置成功: $animationName");

        // 再次验证
        _verifyAnimationPlaying(controller, animationName);
      }
    } catch (e) {
      print("[SPINE流程] 重新设置动画失败: $e");
    }
  }

  // 验证动画是否真的在播放
  void _verifyAnimationPlaying(spine.SpineWidgetController controller, String animationName) {
    // 再延迟200ms验证动画播放状态
    Future.delayed(Duration(milliseconds: 100), () {
      if (!mounted || controller != _backgroundSpineController) return;

      try {
        final animationState = controller.animationState;
        if (animationState == null) {
          print("[SPINE流程] 验证: animationState为空");
          return;
        }

        final currentAnimation = animationState.getCurrent(0);
        final currentAnimationName = currentAnimation?.getAnimation()?.getName();

        print("[SPINE流程] 验证: 当前动画=$currentAnimationName, 是否循环=${currentAnimation?.getLoop()}");

        if (currentAnimationName == animationName) {
          print("[SPINE流程] ✅ 动画验证成功: $animationName 正常播放");

          // 检查动画时间轴
          final trackTime = currentAnimation?.getTrackTime() ?? 0.0;
          final animationDuration = currentAnimation?.getAnimation()?.getDuration() ?? 0.0;
          print("[SPINE流程] 动画时间轴: 当前时间=${trackTime.toStringAsFixed(2)}s, 总时长=${animationDuration.toStringAsFixed(2)}s");

          if (trackTime > 0) {
            print("[SPINE流程] ✅ 动画时间轴正常运行");

            // 启动持续监控，确保动画不会卡住
            _scheduleContinuousAnimationCheck(controller, animationName);
          } else {
            print("[SPINE流程] ⚠️ 动画时间轴未开始，可能存在问题");

            // 尝试强制重启动画
            _forceRestartAnimation(controller, animationName);
          }
        } else {
          print("[SPINE流程] ❌ 动画验证失败: 期望$animationName, 实际$currentAnimationName");
        }
      } catch (e) {
        print("[SPINE流程] 动画验证异常: $e");
      }
    });
  }

  // 持续动画检查 - 确保动画不会卡住
  void _scheduleContinuousAnimationCheck(spine.SpineWidgetController controller, String animationName) {
    // 每2秒检查一次动画状态，连续检查3次
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(seconds: 2 + (i * 2)), () {
        if (!mounted || controller != _backgroundSpineController) {
          print("[SPINE流程] 持续检查: Widget或控制器已变更，停止检查");
          return;
        }

        try {
          final animationState = controller.animationState;
          if (animationState == null) {
            print("[SPINE流程] 持续检查: animationState为空，尝试重启动画");
            _forceRestartAnimation(controller, animationName);
            return;
          }

          final currentAnimation = animationState.getCurrent(0);
          final currentAnimationName = currentAnimation?.getAnimation()?.getName();
          final trackTime = currentAnimation?.getTrackTime() ?? 0.0;

          print("[SPINE流程] 持续检查#${i + 1}: 动画=$currentAnimationName, 时间轴=${trackTime.toStringAsFixed(2)}s");

          if (currentAnimationName != animationName || trackTime <= 0) {
            print("[SPINE流程] 持续检查: 检测到动画异常，尝试重启");
            _forceRestartAnimation(controller, animationName);
            return;
          }

          if (i == 2) {
            print("[SPINE流程] ✅ 持续检查完成: 动画稳定运行");
          }
        } catch (e) {
          print("[SPINE流程] 持续检查异常: $e");
        }
      });
    }
  }

  // 强制重启动画
  void _forceRestartAnimation(spine.SpineWidgetController controller, String animationName) {
    print("[SPINE流程] 🔧 强制重启动画: $animationName");

    try {
      final animationState = controller.animationState;
      if (animationState == null) {
        print("[SPINE流程] 重启失败: animationState为空");
        return;
      }

      // 方法1: 清除并重新设置动画
      animationState.clearTracks();

      // 等待一帧
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller == _backgroundSpineController) {
          try {
            animationState.setAnimationByName(0, animationName, true);
            print("[SPINE流程] 强制重启成功: $animationName");

            // 验证重启结果
            Future.delayed(Duration(milliseconds: 300), () {
              _verifyAnimationPlaying(controller, animationName);
            });
          } catch (e) {
            print("[SPINE流程] 强制重启失败: $e");

            // 方法2: 如果重启失败，尝试重新创建控制器
            _recreateSpineController();
          }
        }
      });
    } catch (e) {
      print("[SPINE流程] 强制重启异常: $e");
      _recreateSpineController();
    }
  }

  // 重新创建Spine控制器 - 最后的手段
  void _recreateSpineController() {
    print("[SPINE流程] 🔄 重新创建Spine控制器");

    if (!mounted) return;

    // 保存当前状态
    final currentGirlIndex = ref.read(currentGirlIndexProvider);
    final currentIdleIndex = _backgroundIdleIndex;
    final currentSkins = _backgroundSkinSelections;

    print("[SPINE流程] 保存状态: girl=$currentGirlIndex, idle=$currentIdleIndex, skins=$currentSkins");

    // 重新初始化控制器
    _initializeBackgroundSpine();

    // 延迟重新应用状态
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _loadGirlStateForBackground(
          currentGirlIndex,
          idleIndexOverride: currentIdleIndex,
          skinsOverride: currentSkins,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    print("[遮罩动画] initState 开始");

    _userService = UserService.instance;

    // 先初始化动画
    _initializeAnimations();

    print("[遮罩动画] 动画初始化后，准备加载数据");

    _loadUserData();
    _restoreBackgroundState();
    _initializeAudio();
    _loadHasShownGrilWaitingDialogFlag();

    print("[遮罩动画] initState 完成");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当从其它页面返回到主界面时再次检查特殊关卡
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      // 延迟到当前帧结束，确保上下文稳定
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkForSpecialStage();
          // 检查并播放待播放的爱心动画
          _checkAndPlayPendingHeartAnimation();
        }
      });
    }
  }

  void _initializeAudio() async {
    await AudioManager().initialize();
  }

  void _initializeAnimations() {
    print("[遮罩动画] 开始初始化动画控制器");

    _takeoffController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _takeoffAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _takeoffController,
      curve: Curves.easeInOut,
    ));

    // 初始化黑色遮罩动画
    _maskController = AnimationController(
      duration: const Duration(milliseconds: 30), // 0.3秒
      vsync: this,
    );

    _maskAnimation = Tween<double>(
      begin: 1.0, // 完全不透明（黑色）
      end: 0.0,   // 完全透明
    ).animate(CurvedAnimation(
      parent: _maskController!,
      curve: Curves.easeOut,
    ));

    // 开始循环播放takeoff动画
    _takeoffController.repeat();

    print("[遮罩动画] 动画控制器初始化完成");

    // 立即启动黑色遮罩动画
    _startMaskAnimation();
  }

  // 启动遮罩动画
  void _startMaskAnimation() {
    print("[遮罩动画] 尝试启动遮罩动画");

    // 检查动画是否已初始化
    if (_maskController == null || _maskAnimation == null) {
      print("[遮罩动画] 错误: 动画控制器未初始化");
      return;
    }

    if (!mounted) {
      print("[遮罩动画] 警告: Widget未挂载");
      return;
    }

    print("[遮罩动画] 黑色遮罩开始淡出");

    // 添加一个微小延迟确保构建完成
    Future.delayed(Duration(milliseconds: 16), () {
      if (mounted && _maskController != null) {
        _maskController!.forward().then((_) {
          print("[遮罩动画] 黑色遮罩淡出完成");
        });
      }
    });
  }

  void _initializeBackgroundSpine() {
    print("=== [SPINE流程] 开始初始化背景Spine控制器 ===");

    print("[SPINE流程] 步骤1: 检查并销毁现有控制器");
    // 销毁旧的控制器
    if (_backgroundSpineController != null) {
      print("[SPINE流程] 发现现有控制器，正在销毁...");
      _backgroundSpineController = null;
      print("[SPINE流程] 现有控制器已销毁");
    } else {
      print("[SPINE流程] 未发现现有控制器");
    }

    print("[SPINE流程] 步骤2: 创建新的SpineWidgetController");

    try {
      _backgroundSpineController =
          spine.SpineWidgetController(onInitialized: (controller) {
            print("[SPINE流程] SpineWidgetController初始化回调触发");
            print("[SPINE流程] 控制器对象: ${controller.runtimeType}");
            print("[SPINE流程] 骨骼数据: ${controller.skeletonData?.runtimeType}");
            print("[SPINE流程] 骨骼对象: ${controller.skeleton?.runtimeType}");
            print("[SPINE流程] 动画状态: ${controller.animationState?.runtimeType}");
            print("[SPINE流程] 开始应用背景状态...");
            _applyBackgroundState(controller);
          });
      print("[SPINE流程] SpineWidgetController创建成功");
    } catch (e) {
      print("[SPINE流程] 错误: 背景女孩控制器创建失败: $e");
      print("[SPINE流程] 错误类型: ${e.runtimeType}");
      print("[SPINE流程] 错误堆栈: ${StackTrace.current}");
    }

    print("=== [SPINE流程] 背景Spine控制器初始化完成 ===");
  }

  Future<void> _loadUserData() async {
    // 初始化UserService
    await _userService.initialize();

    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentLevel = prefs.getInt('current_level') ?? 1;

        // 加载最新解锁的图片
        _latestUnlockedImageIndex = _getLatestUnlockedImageIndex(prefs);
      });
    }
    print(
        "MainPage: UserService初始化完成，金币: ${_userService.coinCount}, 爱心: ${_userService.heartCount}");

    // 检查是否应该触发特殊关卡
    await _checkForSpecialStage();

    // 检查是否有待解锁的女孩
    await _checkForUnlockGirl();

    // 检查是否有可进行的操作
    await _checkForAvailableActions();
  }

  // 检查是否应该触发特殊关卡
  Future<void> _checkForSpecialStage() async {
    await GameStateManager().init();
    // 仅当标记要求在返回后触发时，才检查并弹出
    if (GameStateManager().shouldTriggerSpecialOnReturn() && GameStateManager().shouldTriggerSpecialStage()) {
      // 延迟一下，等页面完全加载后再显示弹窗
      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        // 显示特殊关卡弹窗
        await AudioManager().playPopupOpen();
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const SpecialPage(),
        );

        await GameStateManager().markSpecialStageTriggered();
      }
    }
  }

  // 检查是否有待解锁的女孩
  Future<void> _checkForUnlockGirl() async {
    await GameStateManager().init();

    // 获取待解锁的女孩索引
    int? pendingUnlockGirl = GameStateManager().getPendingUnlockGirl();

    if (pendingUnlockGirl != null && mounted) {
      // 延迟一下，等页面完全加载后再显示弹窗
      await Future.delayed(Duration(milliseconds: 800));

      if (mounted) {
        // 清除待解锁女孩标记
        await GameStateManager().setPendingUnlockGirl(null);

        // 显示解锁新女孩弹窗
        await AudioManager().playPopupOpen();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => UnlockNewGrilDialog(
            girlIndex: pendingUnlockGirl,
            onAccept: () {
              Navigator.of(context).pop();
              // 用户同意解锁，可以在这里添加额外的逻辑
              print("用户同意解锁女孩: $pendingUnlockGirl");
            },
            onDecline: () {
              Navigator.of(context).pop();
              // 用户拒绝解锁，可以在这里添加额外的逻辑
              print("用户拒绝解锁女孩: $pendingUnlockGirl");
            },
          ),
        );
      }
    }
  }

  // 检查是否有可进行的操作
  Future<void> _checkForAvailableActions() async {
    await GameStateManager().init();

    // 如果已经弹过这个弹窗，就不再弹了
    if (_hasShownGrilWaitingDialog) {
      return;
    }

    // 获取当前女孩索引
    int currentGirlIndex = GameStateManager().getCurrentGirlIndex();

    // 检查是否可以脱衣或解锁新皮肤
    bool canTakeoff = GameStateManager().canTakeoff();
    var affordableSkin = GameStateManager().getAffordableSkin(currentGirlIndex);

    if (canTakeoff || affordableSkin != null) {
      // 延迟一下，等页面完全加载后再显示弹窗
      await Future.delayed(Duration(milliseconds: 1200));

      if (mounted) {
        // 标记已经弹过弹窗（持久化）
        await _setHasShownGrilWaitingDialogFlag(true);

        // 【关键代码】解锁提示弹窗 - 当用户有足够爱心货币时显示
        await AudioManager().playPopupOpen();
        await GrilWaitingDialog.show(
          context: context,
          onAccept: () {
            Navigator.of(context).pop();
            // 用户选择去使用心币，导航到预览页面
            _startTakeOff();
          },
          onDecline: () {
            Navigator.of(context).pop();
            // 用户拒绝，不做任何操作
          },
        );
      }
    }
  }

  // 检查并播放待播放的爱心动画
  Future<void> _checkAndPlayPendingHeartAnimation() async {
    try {
      await GameStateManager().init();

      final pendingAnimation = GameStateManager().getPendingHeartAnimation();
      if (pendingAnimation != null && mounted) {
        final int heartAmount = pendingAnimation['heartAmount'] ?? 0;

        if (heartAmount > 0) {
          print("MainPage: 播放待播放的爱心动画，数量: $heartAmount");

          // 播放爱心动画，金币数量设为0
          CommonHeader.playSignInEffects(context, 0, heartAmount);

          // 清除待播放的动画标记
          await GameStateManager().clearPendingHeartAnimation();
        }
      }
    } catch (e) {
      print("检查并播放爱心动画失败: $e");
    }
  }

  // 获取最新解锁的图片索引
  int _getLatestUnlockedImageIndex(SharedPreferences prefs) {
    // 总共75张图片，从后往前查找最新解锁的
    for (int i = 74; i >= 0; i--) {
      // 前5张图片默认解锁
      if (i < 5) {
        print("使用默认解锁图片: Bg_${(i + 1).toString().padLeft(2, '0')}.png");
        return i;
      }
      if (prefs.getBool('photo_unlocked_$i') ?? false) {
        print("找到最新解锁图片: Bg_${(i + 1).toString().padLeft(2, '0')}.png");
        return i;
      }
    }
    // 如果没有找到，返回第一张图片
    print("没有找到解锁图片，使用默认第一张");
    return 0;
  }

  // 获取图片路径
  String _getImagePath(int index) {
    // 图片索引从0开始，但文件名从01开始
    final imageNumber = (index + 1).toString().padLeft(2, '0');
    return 'assets/images/grils_list/Bg_$imageNumber.png';
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    // 金币和爱心通过UserService自动保存，这里只保存其他数据
    await prefs.setInt('current_level', _currentLevel);
  }

  void _showSettingsDialog() async {
    await AudioManager().playPopupOpen();
    SettingsPage.showSettingsDialog(context);
  }

  void _navigateToSignIn() async {
    await AudioManager().playPopupOpen();
    SignInPage.showSignInDialog(context).then((_) {
      // 从签到页面返回时重新加载数据，可能有新图片解锁或新女孩解锁
      _loadUserData();
      // 不再重置已弹标记
    });
  }

  void _navigateToShop() async {
    await AudioManager().playPopupOpen();
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const ShopPage(),
      ),
    )
        .then((_) {
      // 从商店页面返回时重新加载数据，可能有新图片解锁或新女孩解锁
      _loadUserData();
      // 不再重置已弹标记
    });
  }

  void _navigateToGallery() async {
    await AudioManager().playPopupOpen();
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const GalleryPage(),
      ),
    )
        .then((_) {
      // 从图鉴页面返回时重新加载数据，可能有新图片解锁或新女孩解锁
      _loadUserData();
      // 不再重置已弹标记
    });
  }

  
  void _navigateToGame() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const GamePage(),
      ),
    )
        .then((_) {
      // 从游戏页面返回时重新加载数据，可能有新图片解锁或新女孩解锁
      _loadUserData();
      // 不再重置已弹标记
    });
  }

  
  // 处理预览页面状态变化
  void _handlePreviewStateChanged(Map<String, dynamic> stateData) {
    if (!mounted) return;

    final girlIndex = stateData['girlIndex'] as int?;
    final idleIndex = stateData['idleIndex'] as int?;
    final skins = stateData['skins'] as Map<String, int>?;
    final fromPreview = stateData['fromPreview'] as bool? ?? false;

    if (girlIndex != null) {
      print("MainPage: 收到预览页面状态变化 - girl=$girlIndex, idle=$idleIndex, skins=$skins");

      // 如果是从预览页面返回的最终状态，不需要立即更新，等待_restoreBackgroundState处理
      if (fromPreview) {
        print("MainPage: 检测到从预览页面返回，跳过立即状态更新，等待批量恢复");
        return;
      }

      // 更新背景女孩状态（仅在预览页面内部状态变化时）
      _loadGirlStateForBackground(
        girlIndex,
        idleIndexOverride: idleIndex,
        skinsOverride: skins,
      );
    }
  }

  void _startTakeOff() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => SpinePreviewPage(
          onStateChanged: _handlePreviewStateChanged,
        ),
      ),
    )
        .then((_) {
      // 从预览页面返回时重新加载数据，可能有新图片解锁或新女孩解锁
      print("[SPINE流程] 从预览页面返回，开始数据同步...");
      _loadUserData();

      // 延迟一点再恢复背景状态，避免与_loadUserData中的状态更新冲突
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          print("[SPINE流程] 延迟恢复背景状态");
          _restoreBackgroundState();
        }
      });
    });
  }

  
  
  @override
  void dispose() {
    _takeoffController.dispose();
    _maskController?.dispose(); // 使用安全调用
    _backgroundSpineController = null;
    _saveUserData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentGirlAsset = ref.watch(currentGirlAssetProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            // 背景显示当前选择的女孩 currentGirlAsset spine 动画默认的
            if (_backgroundSpineController != null)
              Positioned.fill(
                child: spine.SpineWidget.fromAsset(
                  currentGirlAsset.atlasFile,
                  currentGirlAsset.skeletonFile,
                  _backgroundSpineController!,
                  boundsProvider: const spine.SetupPoseBounds(),
                ),
              ),

            // 新增：黑色遮罩层
            if (_maskAnimation != null)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _maskAnimation!,
                  builder: (context, child) {
                    final opacity = _maskAnimation!.value;
                    print("[遮罩动画] 当前透明度: $opacity");
                    return Container(
                      color: Colors.black.withOpacity(opacity),
                    );
                  },
                ),
              ),

            // 顶部货币显示区域
            CommonHeader(
              settingsButton: true,
              onBackPressed: () {
                _showSettingsDialog();
              },
            ),

            // 左侧功能按钮
            Positioned(
              left: 20,
              top: 130,
              child: Column(
                children: [
                  // 签到按钮
                  GestureDetector(
                    onTap: _navigateToSignIn,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Image.asset(
                        Assets.mainMainBtnSign,
                        height: 60,
                      ),
                    ),
                  ),

                  // 皮肤商店按钮
                  GestureDetector(
                    onTap: _navigateToShop,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Image.asset(
                        Assets.mainMainBtnGameskin,
                        height: 60,
                      ),
                    ),
                  ),

                  
                  // 图鉴按钮 - 显示最新选择的女孩

                  // 游戏按钮
                  // GestureDetector(
                  //   onTap: _navigateToGame,
                  //   child: Container(
                  //     margin: const EdgeInsets.only(top: 20),
                  //     child: Image.asset(
                  //       Assets.mainMainBtnGamestart,
                  //       height: 80,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),

            Positioned(
              left: 20,
              bottom: 30,
              child: GestureDetector(
                onTap: _navigateToGallery,
                child: Stack(
                  children: [
                    Image.asset(
                      Assets.mainMainFrameGallary,
                      height: 120,
                    ),
                    Positioned(
                      top: 5,
                      left: 6,
                      right: 6,
                      bottom: 30,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          _getImagePath(_latestUnlockedImageIndex),
                          fit: BoxFit.cover, // 使用cover填充整个容器
                          alignment: Alignment.topCenter, // 确保头部优先显示
                        ),
                      ),
                    ),
                    Positioned(
                      top: 75,
                      left: 6,
                      right: 6,
                      bottom: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          Assets.mainMainBtnGallary,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _navigateToGallery,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 右侧功能按钮
            Positioned(
              right: 20,
              bottom: 150,
              child: Column(
                children: [
                  
                  // 倾斜测试按钮
                  // GestureDetector(
                  //   onTap: _navigateToTiltTest,
                  //   child: Container(
                  //     margin: const EdgeInsets.only(bottom: 20),
                  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  //     decoration: BoxDecoration(
                  //       color: Colors.blue.withOpacity(0.8),
                  //       borderRadius: BorderRadius.circular(20),
                  //       border: Border.all(color: Colors.white, width: 2),
                  //     ),
                  //     child: const OutlinedTextWidget(
                  //       text: '倾斜测试',
                  //       fontSize: 14,
                  //       textColor: Colors.white,
                  //       strokeColor: Colors.black,
                  //       strokeWidth: 2.0,
                  //       fontWeight: FontWeight.bold,
                  //     ),
                  //   ),
                  // ),

                  // 换按钮 (动画)
                  GestureDetector(
                    onTap: () {
                      _startTakeOff();
                    },
                    child: const SizedBox(
                      width: 100,
                      height: 120,
                      child: TakeoffButtonAnimation(),
                    ),
                  ),
                ],
              ),
            ),

            // 底部开始游戏按钮,
            Positioned(
              bottom: 30,
              right: 20,
              child: Center(
                child: GestureDetector(
                  onTap: _navigateToGame,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        Assets.mainMainBtnGamestart,
                        height: 100,
                      ),
                      Positioned(
                        bottom: 15,
                        child: OutlinedTextWidget(
                          text:
                          'Level ${_currentLevel.toString().padLeft(3, '0')}',
                          fontSize: 11,
                          textColor: Colors.white,
                          strokeColor: Colors.black,
                          strokeWidth: 4.0, // 为小字体增加描边宽度
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.6),
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 脱衣按钮动画组件 - 使用 btn_takeoff spine 动画
class TakeoffButtonAnimation extends StatefulWidget {
  const TakeoffButtonAnimation({super.key});

  @override
  _TakeoffButtonAnimationState createState() => _TakeoffButtonAnimationState();
}

class _TakeoffButtonAnimationState extends State<TakeoffButtonAnimation> {
  spine.SpineWidgetController? _spineController;
  bool _isControllerReady = false;

  @override
  void initState() {
    super.initState();
    _initializeBtnTakeoffController();
  }

  void _initializeBtnTakeoffController() {
    // 先销毁旧的控制器
    if (_spineController != null) {
      _spineController = null;
    }

    try {
      _spineController =
          spine.SpineWidgetController(onInitialized: (controller) {
            try {
              // 设置默认过渡时间
              controller.animationState.getData().setDefaultMix(0.2);

              // 获取可用动画
              final animations = controller.skeleton.getData()?.getAnimations();
              print("=== btn_takeoff 可用动画 ===");
              if (animations != null && animations.isNotEmpty) {
                for (var anim in animations) {
                  print("动画名称: ${anim.getName()}");
                }

                if (mounted) {
                  setState(() {
                    _isControllerReady = true;
                  });
                }

                // 播放第一个可用的动画（循环播放）
                if (animations.isNotEmpty) {
                  final firstAnimationName = animations.first.getName();
                  print("开始播放动画: $firstAnimationName");
                  if (firstAnimationName.isNotEmpty) {
                    controller.animationState
                        .setAnimationByName(0, firstAnimationName, true);
                    print("btn_takeoff 动画播放成功");
                  } else {
                    print("动画名称为空");
                  }
                }
              } else {
                print("btn_takeoff 没有找到动画");
              }
              print("========================");
            } catch (e) {
              print("btn_takeoff 动画初始化失败: $e");
            }
          });
    } catch (e) {
      print("btn_takeoff 控制器创建失败: $e");
    }
  }

  @override
  void dispose() {
    _spineController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_spineController == null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.pink.withOpacity(0.3),
          borderRadius: BorderRadius.circular(60),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.pink,
          ),
        ),
      );
    }

    try {
      return SizedBox(
        width: 120,
        height: 120,
        child: spine.SpineWidget.fromAsset(
          "assets/spine/btn_takeoff.atlas",
          "assets/spine/btn_takeoff.skel",
          _spineController!,
          boundsProvider: const spine.SetupPoseBounds(),
        ),
      );
    } catch (e) {
      print("btn_takeoff SpineWidget 创建失败: $e");
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.3),
          borderRadius: BorderRadius.circular(60),
        ),
        child: const Center(
          child: OutlinedTextWidget(
            text: 'SPINE\n加载失败',
            fontSize: 12,
            textColor: Colors.white,
            strokeColor: Colors.red,
            strokeWidth: 1.0,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }
}