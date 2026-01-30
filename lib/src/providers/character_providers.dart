import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../services/storage/prefs_service.dart';
import 'app_providers.dart';

/// 人物数据提供者
final charactersProvider = Provider<List<Character>>((ref) {
  return [
    const Character(
      id: 'character_1',
      name: 'Cyber Girl',
      imagePath: 'assets/characters/cyber_girl.png',
      description: '未来科技风格角色',
      isUnlocked: true,
      unlockLevel: 1,
      type: CharacterType.basic,
    ),
    const Character(
      id: 'character_2',
      name: 'Neon Queen',
      imagePath: 'assets/characters/neon_queen.png',
      description: '霓虹女王风格角色',
      isUnlocked: true,
      unlockLevel: 1,
      type: CharacterType.basic,
    ),
    const Character(
      id: 'character_3',
      name: 'C Class Beauty',
      imagePath: 'assets/pic_level/c/level_c_1.png',
      description: 'C类美女角色',
      isUnlocked: true,
      unlockLevel: 1,
      type: CharacterType.special,
    ),
    const Character(
      id: 'character_4',
      name: 'Elite Agent',
      imagePath: 'assets/characters/elite_agent.png',
      description: '精英特工风格角色',
      isUnlocked: false,
      unlockLevel: 5,
      type: CharacterType.premium,
    ),
    const Character(
      id: 'character_5',
      name: 'Mystic Mage',
      imagePath: 'assets/characters/mystic_mage.png',
      description: '神秘法师风格角色',
      isUnlocked: false,
      unlockLevel: 10,
      type: CharacterType.special,
    ),
  ];
});

/// 人物选择状态管理
class CharacterSelectionNotifier extends StateNotifier<CharacterSelectionState> {
  final PrefsService _prefsService;

  CharacterSelectionNotifier(this._prefsService) : super(const CharacterSelectionState()) {
    _loadSelectionState();
  }

  /// 加载选择状态
  Future<void> _loadSelectionState() async {
    final selectedId = await _prefsService.getString('selected_character_id');
    final hasCompleted = await _prefsService.getBool('has_completed_level') ?? false;
    final needsSelection = await _prefsService.getBool('needs_character_selection') ?? false;

    state = state.copyWith(
      selectedCharacterId: selectedId,
      hasCompletedLevel: hasCompleted,
      needsCharacterSelection: needsSelection,
    );
  }

  /// 选择人物
  Future<void> selectCharacter(String characterId) async {
    await _prefsService.setString('selected_character_id', characterId);
    await _prefsService.setBool('needs_character_selection', false);
    
    state = state.copyWith(
      selectedCharacterId: characterId,
      needsCharacterSelection: false,
    );
  }

  /// 标记关卡完成
  Future<void> markLevelCompleted() async {
    await _prefsService.setBool('has_completed_level', true);
    await _prefsService.setBool('needs_character_selection', true);
    
    state = state.copyWith(
      hasCompletedLevel: true,
      needsCharacterSelection: true,
    );
  }

  /// 开始新关卡
  Future<void> startNewLevel() async {
    await _prefsService.setBool('has_completed_level', false);
    await _prefsService.setBool('needs_character_selection', false);
    
    state = state.copyWith(
      hasCompletedLevel: false,
      needsCharacterSelection: false,
    );
  }

  /// 检查是否需要选择人物
  bool get needsCharacterSelection => state.needsCharacterSelection;

  /// 获取当前选择的人物ID
  String? get selectedCharacterId => state.selectedCharacterId;
}

final characterSelectionProvider = StateNotifierProvider<CharacterSelectionNotifier, CharacterSelectionState>((ref) {
  final prefsService = ref.read(prefsServiceProvider);
  return CharacterSelectionNotifier(prefsService);
});
