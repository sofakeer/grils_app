/// 人物数据模型
class Character {
  final String id;
  final String name;
  final String imagePath;
  final String description;
  final bool isUnlocked;
  final int unlockLevel;
  final CharacterType type;

  const Character({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.description,
    this.isUnlocked = false,
    this.unlockLevel = 1,
    this.type = CharacterType.basic,
  });

  Character copyWith({
    String? id,
    String? name,
    String? imagePath,
    String? description,
    bool? isUnlocked,
    int? unlockLevel,
    CharacterType? type,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockLevel: unlockLevel ?? this.unlockLevel,
      type: type ?? this.type,
    );
  }
}

/// 人物类型枚举
enum CharacterType {
  basic,    // 基础人物
  premium,  // 高级人物
  special,  // 特殊人物
}

/// 人物选择状态
class CharacterSelectionState {
  final String? selectedCharacterId;
  final bool hasCompletedLevel;
  final bool needsCharacterSelection;

  const CharacterSelectionState({
    this.selectedCharacterId,
    this.hasCompletedLevel = false,
    this.needsCharacterSelection = false,
  });

  CharacterSelectionState copyWith({
    String? selectedCharacterId,
    bool? hasCompletedLevel,
    bool? needsCharacterSelection,
  }) {
    return CharacterSelectionState(
      selectedCharacterId: selectedCharacterId ?? this.selectedCharacterId,
      hasCompletedLevel: hasCompletedLevel ?? this.hasCompletedLevel,
      needsCharacterSelection: needsCharacterSelection ?? this.needsCharacterSelection,
    );
  }
}

