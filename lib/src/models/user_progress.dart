import 'dart:convert';

class UserProgress {
  final int level;
  final int coins;
  final int undo; // 撤销道具
  final int reminder; // 提醒道具
  final int pipe; // 管子道具
  final DateTime? lastSignin;
  final int signinStreak;
  final Map<String, int> unlockedSecrets; // 已解锁的套图

  const UserProgress({
    this.level = 0,
    this.coins = 0,
    this.undo = 0,
    this.reminder = 0,
    this.pipe = 0,
    this.lastSignin,
    this.signinStreak = 0,
    this.unlockedSecrets = const {},
  });

  UserProgress copyWith({
    int? level,
    int? coins,
    int? undo,
    int? reminder,
    int? pipe,
    DateTime? lastSignin,
    int? signinStreak,
    Map<String, int>? unlockedSecrets,
  }) =>
      UserProgress(
        level: level ?? this.level,
        coins: coins ?? this.coins,
        undo: undo ?? this.undo,
        reminder: reminder ?? this.reminder,
        pipe: pipe ?? this.pipe,
        lastSignin: lastSignin ?? this.lastSignin,
        signinStreak: signinStreak ?? this.signinStreak,
        unlockedSecrets: unlockedSecrets ?? this.unlockedSecrets,
      );

  Map<String, Object?> toJson() => {
        'level': level,
        'coins': coins,
        'undo': undo,
        'reminder': reminder,
        'pipe': pipe,
        'last_signin': lastSignin?.toIso8601String(),
        'signin_streak': signinStreak,
        'unlocked_secrets': unlockedSecrets,
      };

  static UserProgress fromJson(Map<String, Object?> json) => UserProgress(
        level: (json['level'] as int?) ?? 0,
        coins: (json['coins'] as int?) ?? 0,
        undo: (json['undo'] as int?) ?? 0,
        reminder: (json['reminder'] as int?) ?? 0,
        pipe: (json['pipe'] as int?) ?? 0,
        lastSignin: (json['last_signin'] as String?) != null ? DateTime.tryParse(json['last_signin'] as String) : null,
        signinStreak: (json['signin_streak'] as int?) ?? 0,
        unlockedSecrets: _parseUnlockedSecrets(json['unlocked_secrets']),
      );

  /// 解析unlocked_secrets字段，处理不同的数据格式
  static Map<String, int> _parseUnlockedSecrets(dynamic data) {
    if (data == null) return {};

    // 如果已经是正确的Map格式
    if (data is Map<String, int>) {
      return data;
    }

    // 如果是Map<String, dynamic>格式
    if (data is Map<String, dynamic>) {
      final Map<String, int> result = {};
      for (final entry in data.entries) {
        if (entry.value is int) {
          result[entry.key] = entry.value as int;
        } else if (entry.value is String) {
          // 尝试将字符串转换为整数
          final intValue = int.tryParse(entry.value as String);
          if (intValue != null) {
            result[entry.key] = intValue;
          }
        }
      }
      return result;
    }

    // 如果是字符串格式，尝试解析JSON
    if (data is String) {
      try {
        final dynamic parsed = jsonDecode(data as String);
        if (parsed is Map) {
          return _parseUnlockedSecrets(parsed);
        }
      } catch (e) {
        print('解析unlocked_secrets失败: $e');
      }
    }

    return {};
  }
}
