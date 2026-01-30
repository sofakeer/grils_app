import 'dart:async';
import '../core/locator.dart';
import 'storage/prefs_service.dart';
import 'analytics_manager.dart';
import 'logger.dart';

class PlayTimeReporter {
  static final PlayTimeReporter _instance = PlayTimeReporter._internal();

  factory PlayTimeReporter() => _instance;

  PlayTimeReporter._internal();

  Timer? _timer;
  int _currentMinute = 0;
  bool _isRunning = false;

  static const String _keyPlayTime = 'analytics.play_time_minutes';

  Future<void> startReporting() async {
    if (_isRunning) {
      Log.game('PlayTimeReporter 已经在运行中');
      return;
    }

    final prefs = ServiceLocator.instance.get<PrefsService>();
    _currentMinute = prefs.getInt(_keyPlayTime) ?? 0;
    _isRunning = true;

    Log.game('PlayTimeReporter 启动，当前游戏时长: $_currentMinute 分钟');

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _currentMinute++;
      prefs.setInt(_keyPlayTime, _currentMinute);
      // 上报当前游戏时长
      _reportPlayTime();
      // 30分钟后停止
      if (_currentMinute >= 30) {
        Log.game('PlayTimeReporter 达到30分钟上限，停止上报');
        stopReporting();
      }
    });
  }

  void stopReporting() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    Log.game('PlayTimeReporter 已停止');
  }

  void _reportPlayTime() {
    // 使用新的埋点系统上报游戏时长
    Log.game('上报游戏时长: $_currentMinute 分钟');
    AnalyticsManager().logPlayTime(_currentMinute);
  }

  bool get isRunning => _isRunning;

  int get currentMinute => _currentMinute;
}
