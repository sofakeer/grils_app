import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_service.dart';

class SharedPrefsService implements PrefsService {
  final SharedPreferences _prefs;

  SharedPrefsService(this._prefs);

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  @override
  Future<void> setJson(String key, Map<String, Object?> value) async {
    await _prefs.setString(key, _encodeJson(value));
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  int? getInt(String key) => _prefs.getInt(key);

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  Map<String, Object?>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return _decodeJson(raw);
  }

  String _encodeJson(Map<String, Object?> value) {
    try {
      return jsonEncode(value);
    } catch (e) {
      print('[SharedPrefsService] JSON编码失败: $e');
      // 回退到 toString 方案（虽然不完美，但至少不会崩溃）
      return value.toString();
    }
  }

  Map<String, Object?>? _decodeJson(String str) {
    try {
      // 首先尝试标准 JSON 解码
      final decoded = jsonDecode(str);
      if (decoded is Map<String, Object?>) {
        return decoded;
      } else if (decoded is Map) {
        return decoded.cast<String, Object?>();
      }
      print('[SharedPrefsService] JSON解码失败: 返回类型不是 Map');
      return null;
    } catch (e) {
      // 如果标准解码失败，尝试旧的简单解析器（兼容旧数据）
      print('[SharedPrefsService] 标准JSON解码失败，尝试简单解析器: $e');
      return _legacyDecodeJson(str);
    }
  }

  /// 旧的简单 JSON 解析器（用于兼容旧数据）
  Map<String, Object?>? _legacyDecodeJson(String str) {
    try {
      final result = <String, Object?>{};
      var s = str.trim();
      if (s.startsWith('{') && s.endsWith('}')) {
        s = s.substring(1, s.length - 1).trim();
        if (s.isEmpty) return result;
        final parts = s.split(',');
        for (final p in parts) {
          final idx = p.indexOf(':');
          if (idx <= 0) continue;
          final k = p.substring(0, idx).trim();
          final v = p.substring(idx + 1).trim();
          final key = k.startsWith("'") && k.endsWith("'") ? k.substring(1, k.length - 1) : k;
          final val = _parsePrimitive(v);
          result[key] = val;
        }
      }
      return result;
    } catch (e) {
      print('[SharedPrefsService] 简单解析器也失败: $e');
      return null;
    }
  }

  Object? _parsePrimitive(String v) {
    if (v == 'null') return null;
    if (v == 'true') return true;
    if (v == 'false') return false;
    final asInt = int.tryParse(v);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(v);
    if (asDouble != null) return asDouble;
    if ((v.startsWith("'") && v.endsWith("'")) || (v.startsWith('"') && v.endsWith('"'))) {
      return v.substring(1, v.length - 1);
    }
    return v;
  }
}

