class SetSlotState {
  static const String locked = 'locked';
  static const String rvNeeded = 'rv_needed';
  static const String playable = 'playable';
  static const String acquired = 'acquired';
}

class SetSlot {
  final int idx; // 1..9
  final int needRv; // required videos
  final int progress; // watched count
  final String state; // SetSlotState

  const SetSlot({required this.idx, required this.needRv, required this.progress, required this.state});

  SetSlot copyWith({int? idx, int? needRv, int? progress, String? state}) =>
      SetSlot(idx: idx ?? this.idx, needRv: needRv ?? this.needRv, progress: progress ?? this.progress, state: state ?? this.state);

  Map<String, Object?> toJson() => {'idx': idx, 'needRv': needRv, 'progress': progress, 'state': state};

  static SetSlot fromJson(Map<String, Object?> json) =>
      SetSlot(idx: (json['idx'] as int?) ?? 0, needRv: (json['needRv'] as int?) ?? 0, progress: (json['progress'] as int?) ?? 0, state: (json['state'] as String?) ?? SetSlotState.locked);
}

class SetProgress {
  final int setId;
  final int unlockedByLevel;
  final List<SetSlot> slots;

  const SetProgress({required this.setId, required this.unlockedByLevel, required this.slots});

  Map<String, Object?> toJson() => {
        'setId': setId,
        'unlockedByLevel': unlockedByLevel,
        'slots': slots.map((e) => e.toJson()).toList(),
      };

  static SetProgress fromJson(Map<String, Object?> json) => SetProgress(
        setId: (json['setId'] as int?) ?? 0,
        unlockedByLevel: (json['unlockedByLevel'] as int?) ?? 0,
        slots: ((json['slots'] as List?) ?? const []).cast<Map<String, Object?>>().map(SetSlot.fromJson).toList(),
      );
}

