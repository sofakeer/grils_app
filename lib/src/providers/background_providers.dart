import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'level_providers.dart';
import 'photo_providers.dart';
import '../models/photo_set_progress.dart';
import '../models/image_item.dart';
import '../services/storage/prefs_service.dart';
import 'app_providers.dart';
import 'user_type_provider.dart';
import '../services/firebase_config_service.dart';
import '../models/firebase_config.dart';
import 'dart:math';
import '../utils/secret_image_utils.dart';

const _backgroundSequenceKey = 'background_sequence_index';

/// 自动背景图片提供者（基于游戏进度的智能背景选择）
/// 优先显示最近解锁的图片，如果用户刚解锁了图片则显示该图片；
/// 如果没有任何解锁图片，首次启动时随机展示，否则根据当前关卡显示准备解锁的人物套图
final autoBackgroundImageProvider = Provider<String>((ref) {
  final photoListState = ref.watch(photoListProvider);
  final levelState = ref.watch(levelProvider);
  final currentLevel = levelState.currentLevel;

  // 尝试获取最近解锁的图片作为背景
  if (photoListState.hasValue && photoListState.value!.isNotEmpty) {
    final recentUnlockedImage = _getMostRecentUnlockedImage(photoListState.value!);
    if (recentUnlockedImage != null) {
      return recentUnlockedImage.src;
    }

    // 没有已解锁的图片，且图片列表已加载完成，说明是首次启动
    // 按顺序选择线上背景图片
    return _getNextConfiguredBackgroundImage(ref);
  }

  // 如果图片列表还未加载完成，则根据关卡计算应该显示的人物套图
  return _getBackgroundImageForLevel(currentLevel);
});

/// 根据关卡获取背景图片
String _getBackgroundImageForLevel(int level) {
  // 人物套图解锁关卡：第1套(3级), 第2套(10级), 第3套(20级), 第4套(50级), 第5套(70级), 第6套(90级), 第7套(110级), 第8套(130级), 第9套(150级)
  const unlockLevels = [3, 10, 20, 50, 70, 90, 110, 130, 150];
  const folders = ['a', 'b', 'c', 'd', 'e', 'f', 'j', 'h', 'i'];
  
  // 找到当前关卡应该解锁的套图
  int targetSetIndex = 0;
  for (int i = 0; i < unlockLevels.length; i++) {
    if (level >= unlockLevels[i]) {
      targetSetIndex = i;
    } else {
      break;
    }
  }
  
  // 确保不超过最大套图数量
  targetSetIndex = targetSetIndex.clamp(0, unlockLevels.length - 1);
  
  // 获取套图信息
  final setId = targetSetIndex + 1;
  final folder = folders[targetSetIndex % folders.length];
  
  final letter = SecretImageUtils.typeLetter(1);
  return 'assets/pic_secret/$folder/secret_${setId}_${letter}_1.png';
}

/// 获取当前套图的解锁信息
final currentSetInfoProvider = Provider<Map<String, dynamic>>((ref) {
  final levelState = ref.watch(levelProvider);
  final userProgress = ref.watch(userProgressProvider).valueOrNull;
  final currentLevel = levelState.currentLevel;

  const unlockLevels = [3, 10, 20, 50, 70, 90, 110, 130, 150];
  const folders = ['a', 'b', 'c', 'd', 'e', 'f', 'j', 'h', 'i'];

  // 找到当前关卡应该解锁的套图
  int targetSetIndex = 0;
  for (int i = 0; i < unlockLevels.length; i++) {
    if (currentLevel >= unlockLevels[i]) {
      targetSetIndex = i;
    } else {
      break;
    }
  }

  targetSetIndex = targetSetIndex.clamp(0, unlockLevels.length - 1);

  final setId = targetSetIndex + 1;
  final folder = folders[targetSetIndex % folders.length];
  final unlockLevel = unlockLevels[targetSetIndex];

  // 计算已完成的总数量
  int totalCompleted = 0;
  int totalCount = 9; // 每套图有9张

  if (userProgress != null && userProgress.unlockedSecrets.isNotEmpty) {
    // 计算当前套图已解锁的数量
    print('=== 套图进度计算调试 ===');
    print('当前套图ID: $setId');
    print('所有已解锁的secret: ${userProgress.unlockedSecrets}');

    for (int slotIndex = 1; slotIndex <= 9; slotIndex++) {
      final key = '${setId}_${slotIndex}';  // 使用正确的key格式：setId_slotIndex
      if (userProgress.unlockedSecrets.containsKey(key) && userProgress.unlockedSecrets[key] == 1) {
        totalCompleted++;
        print('找到已解锁的图片: $key');
      }
    }
    print('套图$setId已完成数量: $totalCompleted/$totalCount');
  }

  return {
    'setId': setId,
    'folder': folder,
    'unlockLevel': unlockLevel,
    'isUnlocked': currentLevel >= unlockLevel,
    'completedCount': totalCompleted,
    'totalCount': totalCount,
    'nextUnlockLevel': targetSetIndex < unlockLevels.length - 1
        ? unlockLevels[targetSetIndex + 1]
        : null,
  };
});

/// 获取最近解锁的图片
ImageItem? _getMostRecentUnlockedImage(List<ImageItem> images) {
  // 筛选出已解锁的图片
  final unlockedImages = images.where((image) => image.unlocked).toList();

  if (unlockedImages.isEmpty) {
    return null;
  }

  // 按时间戳降序排序，获取最近解锁的图片
  unlockedImages.sort((a, b) => b.ts.compareTo(a.ts));

  return unlockedImages.first;
}

/// 首次启动背景图片管理Provider
class FirstLaunchBackgroundNotifier extends StateNotifier<String> {
  FirstLaunchBackgroundNotifier(this._prefsService, this._ref) : super('') {
    _initializeBackground();
  }

  final PrefsService _prefsService;
  final Ref _ref;
  static const String _firstLaunchBackgroundKey = 'first_launch_background';

  /// 初始化背景图片
  Future<void> _initializeBackground() async {
    // 检查是否已经设置过首次启动背景
    final savedBackground = _prefsService.getString(_firstLaunchBackgroundKey);
    if (savedBackground != null && savedBackground.isNotEmpty && !_isLegacyAssetPath(savedBackground)) {
      state = savedBackground;
      return;
    }

    final configuredBackground = _getNextConfiguredBackgroundImage(_ref);
    state = configuredBackground;

    // 保存选择的背景
    await _prefsService.setString(_firstLaunchBackgroundKey, configuredBackground);
  }

  /// 重置首次启动背景（用于测试）
  Future<void> reset() async {
    await _prefsService.remove(_firstLaunchBackgroundKey);
    _initializeBackground();
  }
}

final firstLaunchBackgroundProvider = StateNotifierProvider<FirstLaunchBackgroundNotifier, String>((ref) {
  final prefsService = ref.read(prefsServiceProvider);
  return FirstLaunchBackgroundNotifier(prefsService, ref);
});

/// 背景图片管理Notifier
class BackgroundImageNotifier extends StateNotifier<String> {
  BackgroundImageNotifier(this._prefsService, this._ref) : super('') {
    _initializeBackground();
  }

  final PrefsService _prefsService;
  final Ref _ref;
  static const String _customBackgroundKey = 'custom_background_image';
  static const String _defaultBackgroundKey = 'default_background_image';
  static const String _lastUnlockedBackgroundKey = 'last_unlocked_background';

  /// 初始化背景图片
  Future<void> _initializeBackground() async {
    print('[BACKGROUND] 初始化背景图片...');

    // 优先检查是否有自定义背景（从PhotoUnlockPage设置的）
    final customBackground = _prefsService.getString(_customBackgroundKey);
    if (customBackground != null && customBackground.isNotEmpty) {
      state = customBackground;
      print('[BACKGROUND] 使用自定义背景: $customBackground');
      return;
    }

    // 检查是否有最近解锁的背景图片（过关获得的新图片）
    final lastUnlockedBackground = _prefsService.getString(_lastUnlockedBackgroundKey);
    if (lastUnlockedBackground != null && lastUnlockedBackground.isNotEmpty) {
      state = lastUnlockedBackground;
      print('[BACKGROUND] 使用最近解锁的背景: $lastUnlockedBackground');
      return;
    }

    // 检查是否有默认保存的背景
    final defaultBackground = _prefsService.getString(_defaultBackgroundKey);
    if (defaultBackground != null && defaultBackground.isNotEmpty && !_isLegacyAssetPath(defaultBackground)) {
      state = defaultBackground;
      print('[BACKGROUND] 使用默认背景: $defaultBackground');
      return;
    }

    final configuredBackground = _getNextConfiguredBackgroundImage(_ref);
    state = configuredBackground;
    await _prefsService.setString(_defaultBackgroundKey, configuredBackground);
    print('[BACKGROUND] 使用配置背景: $configuredBackground');
  }

  /// 设置背景图片（从PhotoUnlockPage调用）
  Future<void> setBackgroundImage(String imagePath) async {
    state = imagePath;
    await _prefsService.setString(_customBackgroundKey, imagePath);
    print('[BACKGROUND] 设置自定义背景: $imagePath');
  }

  /// 设置最近解锁的背景图片（过关后调用）
  Future<void> setLastUnlockedBackground(String imagePath) async {
    state = imagePath;
    await _prefsService.setString(_lastUnlockedBackgroundKey, imagePath);
    print('[BACKGROUND] 设置最近解锁的背景: $imagePath');
  }

  /// 重置背景图片（仅在回到主页时调用）
  Future<void> resetBackground() async {
    // 清除自定义背景，恢复到最近解锁的背景或默认背景
    await _prefsService.remove(_customBackgroundKey);

    print('[BACKGROUND] 已清除自定义背景，恢复到最近解锁的背景或默认背景...');
    await _initializeBackground();
    print('[BACKGROUND] 重置背景图片完成，当前背景: ${state}');
  }

  /// 强制重新随机背景图片（用于调试）
  Future<void> forceRandomBackground() async {
    // 清除所有保存的背景图片
    await _prefsService.remove(_customBackgroundKey);
    await _prefsService.remove(_lastUnlockedBackgroundKey);
    await _prefsService.remove(_defaultBackgroundKey);

    print('[BACKGROUND] 已清除所有背景图片设置，强制重新随机...');
    await _initializeBackground();
    print('[BACKGROUND] 强制随机背景完成，当前背景: ${state}');
  }
}

final backgroundImageProvider = StateNotifierProvider<BackgroundImageNotifier, String>((ref) {
  final prefsService = ref.read(prefsServiceProvider);
  return BackgroundImageNotifier(prefsService, ref);
});

LevelImageConfig _getBackgroundLevelConfig(UserType userType, FirebaseConfig config) {
  return userType == UserType.natural
      ? config.images.levelA
      : config.images.levelB;
}

String _getNextConfiguredBackgroundImage(Ref ref) {
  final prefs = ref.read(prefsServiceProvider);
  final userType = ref.read(userTypeProvider);
  final config = ref.read(firebaseConfigServiceProvider).getDefaultConfig(userType);
  final levelConfig = _getBackgroundLevelConfig(userType, config);

  final remote = _resolveSequentialBackground(levelConfig, prefs);
  if (remote != null && remote.isNotEmpty) {
    return remote;
  }

  return _getLocalFallbackBackgroundImage();
}

String? _resolveSequentialBackground(LevelImageConfig levelConfig, PrefsService prefs) {
  if (levelConfig.baseUrl.isEmpty || levelConfig.fileNamePattern.isEmpty) {
    return null;
  }

  const maxCandidates = 14;
  final configTotal = levelConfig.totalCount > 0 ? levelConfig.totalCount : maxCandidates;
  final total = max(1, min(configTotal, maxCandidates));

  final storedIndex = prefs.getInt(_backgroundSequenceKey) ?? 1;
  final normalized = ((storedIndex - 1) % total) + 1;
  final nextIndex = (normalized % total) + 1;
  prefs.setInt(_backgroundSequenceKey, nextIndex);

  return levelConfig.baseUrl +
      levelConfig.fileNamePattern.replaceAll('{index}', normalized.toString());
}

String _getLocalFallbackBackgroundImage() {
  const levelFolders = ['a', 'b', 'c'];
  final random = Random();
  final folder = levelFolders[random.nextInt(levelFolders.length)];
  final imageIndex = random.nextInt(10) + 1;
  return 'assets/pic_level/$folder/level_${folder}_$imageIndex.png';
}

bool _isLegacyAssetPath(String path) {
  return path.startsWith('assets/pic_level/');
}
