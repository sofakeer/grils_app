import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage/prefs_service.dart';
import '../services/level_image_sequence_service.dart';
import 'app_providers.dart';

/// 关卡状态数据模型
class LevelState {
  final int currentLevel;
  final bool isFirstLevel;
  final bool needsCharacterSelection;
  final String? selectedCharacterId;
  final DateTime lastPlayTime;
  final String? currentLevelType;
  final int? currentLevelIndex;
  final String? currentLevelImagePath;
  final String? currentImageId;

  const LevelState({
    required this.currentLevel,
    required this.isFirstLevel,
    required this.needsCharacterSelection,
    this.selectedCharacterId,
    required this.lastPlayTime,
    this.currentLevelType,
    this.currentLevelIndex,
    this.currentLevelImagePath,
    this.currentImageId,
  });

  LevelState copyWith({
    int? currentLevel,
    bool? isFirstLevel,
    bool? needsCharacterSelection,
    String? selectedCharacterId,
    DateTime? lastPlayTime,
    String? currentLevelType,
    int? currentLevelIndex,
    String? currentLevelImagePath,
    String? currentImageId,
  }) {
    return LevelState(
      currentLevel: currentLevel ?? this.currentLevel,
      isFirstLevel: isFirstLevel ?? this.isFirstLevel,
      needsCharacterSelection: needsCharacterSelection ?? this.needsCharacterSelection,
      selectedCharacterId: selectedCharacterId ?? this.selectedCharacterId,
      lastPlayTime: lastPlayTime ?? this.lastPlayTime,
      currentLevelType: currentLevelType ?? this.currentLevelType,
      currentLevelIndex: currentLevelIndex ?? this.currentLevelIndex,
      currentLevelImagePath: currentLevelImagePath ?? this.currentLevelImagePath,
      currentImageId: currentImageId ?? this.currentImageId,
    );
  }
}

/// 关卡状态管理器
class LevelNotifier extends StateNotifier<LevelState> {
  final PrefsService _prefsService;

  LevelNotifier(this._prefsService) : super(LevelState(
    currentLevel: 1,
    isFirstLevel: true,
    needsCharacterSelection: false,
    lastPlayTime: DateTime.now(),
    currentLevelType: 'b',
    currentLevelIndex: 0,
    currentLevelImagePath: 'assets/pic_level/b/level_b_1.png',
  )) {
    _loadLevelState();
  }

  /// 加载关卡状态
  Future<void> _loadLevelState() async {
    final savedLevel = _prefsService.getInt('current_level') ?? 1;
    final isFirstLevel = savedLevel == 1;
    final needsSelection = _prefsService.getBool('needs_character_selection') ?? false;
    final selectedCharacter = _prefsService.getString('selected_character_id');
    final lastPlayTime = DateTime.now(); // 可以从存储中读取
    String? currentLevelType = _prefsService.getString('current_level_type');
    int? currentLevelIndex = _prefsService.getInt('current_level_index');
    String? currentLevelImagePath = _prefsService.getString('current_level_image_path');

    currentLevelType ??= state.currentLevelType ?? 'b';
    currentLevelIndex ??= state.currentLevelIndex ?? 0;
    currentLevelImagePath ??= state.currentLevelImagePath ?? 'assets/pic_level/b/level_b_1.png';
    final currentImageId = _prefsService.getString('current_image_id');

    state = state.copyWith(
      currentLevel: savedLevel,
      isFirstLevel: isFirstLevel,
      needsCharacterSelection: needsSelection,
      selectedCharacterId: selectedCharacter,
      lastPlayTime: lastPlayTime,
      currentLevelType: currentLevelType,
      currentLevelIndex: currentLevelIndex,
      currentLevelImagePath: currentLevelImagePath,
      currentImageId: currentImageId,
    );
  }

  /// 开始新关卡
  Future<void> startLevel() async {
    // 注意：start埋点现在在游戏真正开始时上报，不在关卡开始时上报
    
    if (state.isFirstLevel) {
      // 第一关直接进入游戏
      await _prefsService.setInt('current_level', 1);
      await _prefsService.setBool('needs_character_selection', false);
      
      state = state.copyWith(
        currentLevel: 1,
        isFirstLevel: true,
        needsCharacterSelection: false,
      );
    } else {
      // 其他关卡需要选择人物
      await _prefsService.setBool('needs_character_selection', true);
      
      state = state.copyWith(
        needsCharacterSelection: true,
      );
    }
  }

  /// 完成关卡
  Future<void> completeLevel() async {
    // 注意：
    // - pass 埋点在 GameSuccessPage 进入时上报，不在这里上报
    // - playcount_x 埋点在游戏开始时上报，不在完成时上报

    final nextLevel = state.currentLevel + 1;
    await _prefsService.setInt('current_level', nextLevel);
    await _prefsService.setBool('needs_character_selection', true);

    state = state.copyWith(
      currentLevel: nextLevel,
      isFirstLevel: false,
      needsCharacterSelection: true,
      lastPlayTime: DateTime.now(),
    );
  }

  /// 设置当前关卡选择的图片信息
  Future<void> setCurrentLevelSelection({
    required String levelType,
    required int levelIndex,
    String? customImagePath,
    String? imageId,
  }) async {
    // 优先使用图片ID（用于智能选择网络或本地图片）
    // 如果提供了自定义图片路径（可能是网络图片），使用它
    // 否则使用默认的本地路径
    final imagePath = imageId ?? customImagePath ?? 'assets/pic_level/$levelType/level_${levelType}_${levelIndex + 1}.png';

    await _prefsService.setString('current_level_type', levelType);
    await _prefsService.setInt('current_level_index', levelIndex);
    await _prefsService.setString('current_level_image_path', imagePath);
    if (imageId != null) {
      await _prefsService.setString('current_image_id', imageId);
    }

    state = state.copyWith(
      currentLevelType: levelType,
      currentLevelIndex: levelIndex,
      currentLevelImagePath: imagePath,
      currentImageId: imageId,
    );
  }

  /// 增加多关（调试用）
  Future<void> addLevels(int delta) async {
    if (delta <= 0) return;
    final nextLevel = state.currentLevel + delta;
    await _prefsService.setInt('current_level', nextLevel);
    await _prefsService.setBool('needs_character_selection', true);
    state = state.copyWith(
      currentLevel: nextLevel,
      isFirstLevel: nextLevel == 1,
      needsCharacterSelection: true,
      lastPlayTime: DateTime.now(),
    );
  }

  /// 选择人物后进入关卡
  Future<void> selectCharacterAndStartLevel(String characterId) async {
    await _prefsService.setString('selected_character_id', characterId);
    await _prefsService.setBool('needs_character_selection', false);
    
    state = state.copyWith(
      selectedCharacterId: characterId,
      needsCharacterSelection: false,
    );
  }

  /// 重置关卡到第一关
  Future<void> resetToFirstLevel() async {
    await _prefsService.setInt('current_level', 1);
    await _prefsService.setBool('needs_character_selection', false);
    await _prefsService.remove('selected_character_id');
    await _prefsService.remove('current_level_type');
    await _prefsService.remove('current_level_index');
    await _prefsService.remove('current_level_image_path');
    await _prefsService.remove('current_image_id');
    
    state = state.copyWith(
      currentLevel: 1,
      isFirstLevel: true,
      needsCharacterSelection: false,
      selectedCharacterId: null,
      lastPlayTime: DateTime.now(),
      currentLevelType: 'b',
      currentLevelIndex: 0,
      currentLevelImagePath: 'assets/pic_level/b/level_b_1.png',
      currentImageId: null,
    );
  }

  /// 获取当前关卡显示文本
  String get levelDisplayText => 'LEVEL${state.currentLevel}';

  /// 检查是否需要选择人物
  bool get needsCharacterSelection => state.needsCharacterSelection;

  /// 检查是否是第一关
  bool get isFirstLevel => state.isFirstLevel;
}

final levelProvider = StateNotifierProvider<LevelNotifier, LevelState>((ref) {
  final prefsService = ref.read(prefsServiceProvider);
  return LevelNotifier(prefsService);
});

/// 下一关选择弹窗的图片选择状态
class NextLevelSelectionState {
  // 记录当前展示的4张图片索引
  // 索引0-1：上排免费图片（B类）
  // 索引2-3：下排激励视频图片（C类）
  final List<int> imageIndices; // 长度为4
  final bool needsReselect; // 是否需要重新选择（游戏成功后设置为true）

  const NextLevelSelectionState({
    required this.imageIndices,
    this.needsReselect = false,
  });

  NextLevelSelectionState copyWith({
    List<int>? imageIndices,
    bool? needsReselect,
  }) {
    return NextLevelSelectionState(
      imageIndices: imageIndices ?? this.imageIndices,
      needsReselect: needsReselect ?? this.needsReselect,
    );
  }

  /// 检查是否所有图片都已选择
  bool get isComplete {
    return imageIndices.every((idx) => idx != -1);
  }

  /// 获取上排免费图片索引（索引0-1）
  List<int> get freeImageIndices => imageIndices.take(2).toList();

  /// 获取下排视频图片索引（索引2-3）
  List<int> get videoImageIndices => imageIndices.skip(2).take(2).toList();
}

/// 下一关选择弹窗状态管理器
class NextLevelSelectionNotifier extends StateNotifier<NextLevelSelectionState> {
  NextLevelSelectionNotifier(this._prefsService)
      : super(_buildInitialState(_prefsService));

  static const _prefsKeyImageIndices = 'next_level_image_indices_v1';
  static const _prefsKeyNeedsReselect = 'next_level_needs_reselect_v1';
  final PrefsService _prefsService;

  static NextLevelSelectionState _buildInitialState(PrefsService prefs) {
    // 从持久化存储恢复图片索引
    List<int> imageIndices = const [-1, -1, -1, -1];
    final indicesStr = prefs.getString(_prefsKeyImageIndices);
    if (indicesStr != null && indicesStr.isNotEmpty) {
      try {
        final indices = indicesStr.split(',').map((s) => int.tryParse(s.trim()) ?? -1).toList();
        if (indices.length == 4) {
          imageIndices = indices;
        }
      } catch (e) {
        print('[NextLevelSelection] 恢复图片索引失败: $e');
      }
    }
    
    // 从持久化存储恢复needsReselect状态
    bool needsReselect = prefs.getBool(_prefsKeyNeedsReselect) ?? true;
    
    // 如果图片索引都是有效的，确保needsReselect为false
    final isComplete = imageIndices.every((idx) => idx != -1);
    if (isComplete) {
      needsReselect = false;
    }
    
    return NextLevelSelectionState(
      imageIndices: imageIndices,
      needsReselect: needsReselect,
    );
  }

  /// 设置图片索引（4张图片）
  void setImageIndices(List<int> imageIndices) {
    if (imageIndices.length != 4) {
      print('[NextLevelSelection] 错误：图片索引数量必须为4，实际为${imageIndices.length}');
      return;
    }
    
    state = state.copyWith(
      imageIndices: imageIndices,
      needsReselect: false, // 设置后不再需要重新选择
    );
    
    // 持久化保存图片索引
    _saveImageIndices(imageIndices, false);
  }
  
  /// 保存图片索引到持久化存储
  void _saveImageIndices(List<int> imageIndices, bool needsReselect) {
    // 保存图片索引（序列化为逗号分隔的字符串）
    final indicesStr = imageIndices.join(',');
    _prefsService.setString(_prefsKeyImageIndices, indicesStr);
    
    // 保存needsReselect状态
    _prefsService.setBool(_prefsKeyNeedsReselect, needsReselect);
  }

  /// 消费选中的图片（游戏成功后调用）
  /// 根据需求：消费任意一个后，整体替换为下一组图片
  /// [levelType] 用户选择的关卡类型（'b' 或 'c'）
  /// [levelIndex] 用户选择的图片索引
  void consumeImage(String levelType, int levelIndex, String primaryType, String premiumType) {
    // 使用图片顺序轮询服务标记已消费
    // B类图片（位置0、1）和 C类图片（位置2、3）分别管理
    final sequenceService = LevelImageSequenceService();
    
    // 获取B类图片索引（位置0、1）
    final bIndices = state.freeImageIndices.where((idx) => idx != -1).toList();
    if (bIndices.isNotEmpty) {
      sequenceService.markAsConsumedByType('b', bIndices);
    }
    
    // 获取C类图片索引（位置2、3）
    final cIndices = state.videoImageIndices.where((idx) => idx != -1).toList();
    if (cIndices.isNotEmpty) {
      sequenceService.markAsConsumedByType('c', cIndices);
    }
    
    // 标记需要重新选择（消费后整体替换）
    state = state.copyWith(
      imageIndices: const [-1, -1, -1, -1],
      needsReselect: true,
    );
    
    // 持久化保存重置后的状态
    _saveImageIndices(const [-1, -1, -1, -1], true);
  }

  /// 标记需要重新随机（游戏成功后调用）
  void markNeedsReselect() {
    state = state.copyWith(
      imageIndices: const [-1, -1, -1, -1],
      needsReselect: true,
    );
    
    // 持久化保存重置后的状态
    _saveImageIndices(const [-1, -1, -1, -1], true);
  }

  /// 重置状态
  void reset() {
    state = state.copyWith(
      imageIndices: const [-1, -1, -1, -1],
      needsReselect: true,
    );
    
    // 持久化保存重置后的状态
    _saveImageIndices(const [-1, -1, -1, -1], true);
  }
}

final nextLevelSelectionProvider = StateNotifierProvider<NextLevelSelectionNotifier, NextLevelSelectionState>((ref) {
  final prefs = ref.read(prefsServiceProvider);
  return NextLevelSelectionNotifier(prefs);
});
