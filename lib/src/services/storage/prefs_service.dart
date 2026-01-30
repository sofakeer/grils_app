abstract class PrefsService {
  Future<void> setString(String key, String value);
  Future<void> setInt(String key, int value);
  Future<void> setBool(String key, bool value);
  Future<void> setJson(String key, Map<String, Object?> value);
  Future<void> remove(String key);

  String? getString(String key);
  int? getInt(String key);
  bool? getBool(String key);
  Map<String, Object?>? getJson(String key);
}

class InMemoryPrefsService implements PrefsService {
  final Map<String, Object?> _store = {};

  @override
  Future<void> setString(String key, String value) async => _store[key] = value;

  @override
  Future<void> setInt(String key, int value) async => _store[key] = value;

  @override
  Future<void> setBool(String key, bool value) async => _store[key] = value;

  @override
  Future<void> setJson(String key, Map<String, Object?> value) async => _store[key] = value;

  @override
  Future<void> remove(String key) async => _store.remove(key);

  @override
  String? getString(String key) => _store[key] as String?;

  @override
  int? getInt(String key) => _store[key] as int?;

  @override
  bool? getBool(String key) => _store[key] as bool?;

  @override
  Map<String, Object?>? getJson(String key) => _store[key] as Map<String, Object?>?;
}

