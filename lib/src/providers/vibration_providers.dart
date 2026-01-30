import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/vibration_service.dart';

/// 震动状态管理器
class VibrationNotifier extends StateNotifier<bool> {
  VibrationNotifier() : super(true) {
    _loadVibrationState();
  }

  void _loadVibrationState() {
    // TODO: 从SharedPreferences读取状态
    // 这里先使用默认值true
  }

  void toggleVibration() {
    state = !state;
    _saveVibrationState();
  }

  void _saveVibrationState() {
    // TODO: 保存到SharedPreferences
  }

  /// 震动（如果启用）
  Future<void> vibrate() async {
    if (state) {
      await VibrationService.vibrateClick();
    }
  }

  /// 成功震动
  Future<void> vibrateSuccess() async {
    if (state) {
      await VibrationService.vibrateSuccess();
    }
  }

  /// 失败震动
  Future<void> vibrateFail() async {
    if (state) {
      await VibrationService.vibrateFail();
    }
  }

  /// 警告震动
  Future<void> vibrateWarning() async {
    if (state) {
      await VibrationService.vibrateWarning();
    }
  }

  /// 短震动
  Future<void> vibrateShort() async {
    if (state) {
      await VibrationService.vibrate(duration: 50);
    }
  }

  /// 长震动
  Future<void> vibrateLong() async {
    if (state) {
      await VibrationService.vibrateLong();
    }
  }
}

/// 震动状态 Provider
final vibrationProvider = StateNotifierProvider<VibrationNotifier, bool>((ref) {
  return VibrationNotifier();
});

/// 震动操作便捷类
class VibrationActions {
  static Future<void> vibrate(WidgetRef ref) async {
    await ref.read(vibrationProvider.notifier).vibrate();
  }

  static Future<void> vibrateSuccess(WidgetRef ref) async {
    await ref.read(vibrationProvider.notifier).vibrateSuccess();
  }

  static Future<void> vibrateFail(WidgetRef ref) async {
    await ref.read(vibrationProvider.notifier).vibrateFail();
  }

  static Future<void> vibrateWarning(WidgetRef ref) async {
    await ref.read(vibrationProvider.notifier).vibrateWarning();
  }

  static Future<void> vibrateShort(WidgetRef ref) async {
    await ref.read(vibrationProvider.notifier).vibrateShort();
  }

  static Future<void> vibrateLong(WidgetRef ref) async {
    await ref.read(vibrationProvider.notifier).vibrateLong();
  }

  static Future<void> toggleVibration(WidgetRef ref) async {
    ref.read(vibrationProvider.notifier).toggleVibration();
    await ref.read(vibrationProvider.notifier).vibrate();
  }
}