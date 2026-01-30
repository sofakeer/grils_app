class TreasureCardState {
  static const String locked = 'locked';
  static const String rvNeeded = 'rv_needed';
  static const String progressNeeded = 'progress_needed';
  static const String claimable = 'claimable';
  static const String claimed = 'claimed';
}

class TreasureProgressItem {
  final int index; // 1..30
  final String state; // TreasureCardState
  final int needLevel;
  final int needRv;

  const TreasureProgressItem({required this.index, required this.state, required this.needLevel, required this.needRv});

  Map<String, Object?> toJson() => {
        'index': index,
        'state': state,
        'needLevel': needLevel,
        'needRv': needRv,
      };

  static TreasureProgressItem fromJson(Map<String, Object?> json) => TreasureProgressItem(
        index: (json['index'] as int?) ?? 0,
        state: (json['state'] as String?) ?? TreasureCardState.locked,
        needLevel: (json['needLevel'] as int?) ?? 0,
        needRv: (json['needRv'] as int?) ?? 0,
      );
}

