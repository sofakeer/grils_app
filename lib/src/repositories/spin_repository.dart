import '../core/locator.dart';
import '../services/remote_config/remote_config_service.dart';
import '../services/storage/prefs_service.dart';

class SpinRepository {
  static const _prefsKey = 'spin_daily_v1';

  final PrefsService _prefs = ServiceLocator.instance.get<PrefsService>();
  final RemoteConfigService _rc = ServiceLocator.instance.get<RemoteConfigService>();

  int getDailyLimit() => _rc.getInt('limits.spin_daily_limit', defaultValue: 5);

  /// 返回今日已用次数；如非同一天则自动重置为 0。
  Future<int> getUsedCount({DateTime? now}) async {
    now ??= DateTime.now();
    final today = _dayKey(now);
    final json = _prefs.getJson(_prefsKey);
    if (json == null || json['day'] != today) {
      await _prefs.setJson(_prefsKey, {'day': today, 'used': 0});
      return 0;
    }
    return (json['used'] as int?) ?? 0;
  }

  Future<void> incrementUsed({DateTime? now}) async {
    now ??= DateTime.now();
    final today = _dayKey(now);
    final used = await getUsedCount(now: now);
    await _prefs.setJson(_prefsKey, {'day': today, 'used': used + 1});
  }

  /// 调试用途：重置当天已用次数为 0。
  Future<void> resetForToday({DateTime? now}) async {
    now ??= DateTime.now();
    final today = _dayKey(now);
    await _prefs.setJson(_prefsKey, {'day': today, 'used': 0});
  }

  // 仅保留 resetForToday 作为对外重置入口（测试用）。

  String _dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
