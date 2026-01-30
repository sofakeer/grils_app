import 'package:flutter/services.dart';

/// 震动服务
class VibrationService {
  static const MethodChannel _channel = MethodChannel('vibration');
  static bool _hasVibrator = true;

  /// 检查设备是否支持震动
  static Future<bool> get hasVibrator async {
    try {
      final bool? result = await _channel.invokeMethod('hasVibrator');
      _hasVibrator = result ?? true;
      return _hasVibrator;
    } catch (e) {
      _hasVibrator = false;
      return false;
    }
  }

  /// 震动
  /// [duration] 震动持续时间（毫秒）
  static Future<void> vibrate({int duration = 100}) async {
    if (!_hasVibrator) return;

    try {
      await _channel.invokeMethod('vibrate', {'duration': duration});
    } catch (e) {
      print('震动失败: $e');
    }
  }

  /// 长震动
  static Future<void> vibrateLong() async {
    if (!_hasVibrator) return;

    try {
      await _channel.invokeMethod('vibrate');
    } catch (e) {
      print('长震动失败: $e');
    }
  }

  /// 模式震动（例如：成功、失败、警告等）
  /// [pattern] 震动模式数组，[等待时间, 震动时间, 等待时间, 震动时间, ...]
  static Future<void> vibratePattern(List<int> pattern) async {
    if (!_hasVibrator) return;

    try {
      await _channel.invokeMethod('vibratePattern', {'pattern': pattern});
    } catch (e) {
      print('模式震动失败: $e');
    }
  }

  /// 取消震动
  static Future<void> cancel() async {
    if (!_hasVibrator) return;

    try {
      await _channel.invokeMethod('cancel');
    } catch (e) {
      print('取消震动失败: $e');
    }
  }

  /// 点击震动（短震动）
  static Future<void> vibrateClick() async {
    await vibrate(duration: 50);
  }

  /// 成功震动（短-长-短）
  static Future<void> vibrateSuccess() async {
    await vibratePattern([0, 50, 100, 150, 100, 50]);
  }

  /// 失败震动（长震动）
  static Future<void> vibrateFail() async {
    await vibrate(duration: 300);
  }

  /// 警告震动（短-短-长）
  static Future<void> vibrateWarning() async {
    await vibratePattern([0, 50, 50, 50, 50, 200]);
  }
}