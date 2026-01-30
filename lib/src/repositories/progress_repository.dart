import '../services/storage/prefs_service.dart';
import '../core/locator.dart';
import '../models/user_progress.dart';

class ProgressRepository {
  static const _key = 'user_progress';

  final PrefsService _prefs = ServiceLocator.instance.get<PrefsService>();

  Future<UserProgress> load() async {
    final json = _prefs.getJson(_key);
    if (json == null) return const UserProgress();
    return UserProgress.fromJson(json);
  }

  Future<void> save(UserProgress progress) async {
    await _prefs.setJson(_key, progress.toJson());
  }
}

