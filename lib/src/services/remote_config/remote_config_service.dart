abstract class RemoteConfigService {
  Future<void> ensureLoaded();
  bool getBool(String key, {bool defaultValue = false});
  int getInt(String key, {int defaultValue = 0});
  double getDouble(String key, {double defaultValue = 0});
  String getString(String key, {String defaultValue = ''});
  Map<String, Object?> getJson(String key, {Map<String, Object?> defaultValue = const {}});
}

class InMemoryRemoteConfigService implements RemoteConfigService {
  InMemoryRemoteConfigService({Map<String, Object>? defaults}) : _store = Map.of(defaults ?? {});

  final Map<String, Object> _store;

  @override
  Future<void> ensureLoaded() async {}

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    final v = _store[key];
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    if (v is num) return v != 0;
    return defaultValue;
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    final v = _store[key];
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  @override
  double getDouble(String key, {double defaultValue = 0}) {
    final v = _store[key];
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  @override
  String getString(String key, {String defaultValue = ''}) {
    final v = _store[key];
    if (v is String) return v;
    return v?.toString() ?? defaultValue;
  }

  @override
  Map<String, Object?> getJson(String key, {Map<String, Object?> defaultValue = const {}}) {
    final v = _store[key];
    if (v is Map<String, Object?>) return v;
    return defaultValue;
  }
}

