import 'package:flutter/foundation.dart';

/// 日志级别枚举
enum LogLevel {
  debug,   // 调试信息
  info,    // 一般信息
  warning, // 警告信息
  error,   // 错误信息
}

/// 统一日志管理工具
class Logger {
  // 私有构造函数，单例模式
  Logger._();
  static final Logger _instance = Logger._();
  factory Logger() => _instance;

  /// 是否启用日志（默认只在调试模式下启用）
  static bool _isEnabled = true;
  
  /// 当前日志级别（默认为debug级别，显示所有日志）
  static LogLevel _currentLevel = LogLevel.debug;
  
  /// 设置是否启用日志
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }
  
  /// 设置日志级别
  static void setLevel(LogLevel level) {
    _currentLevel = level;
  }
  
  /// 检查是否应该输出指定级别的日志
  static bool _shouldLog(LogLevel level) {
    if (!_isEnabled) return false;
    return level.index >= _currentLevel.index;
  }
  
  /// 获取日志级别前缀
  static String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '[DEBUG]';
      case LogLevel.info:
        return '[INFO]';
      case LogLevel.warning:
        return '[WARNING]';
      case LogLevel.error:
        return '[ERROR]';
    }
  }
  
  /// 格式化日志消息
  static String _formatMessage(String tag, String message, LogLevel level) {
    final timestamp = DateTime.now().toString().substring(11, 23); // HH:mm:ss.SSS
    final prefix = _getLevelPrefix(level);
    return '$timestamp $prefix [$tag] $message';
  }
  
  /// 调试日志
  static void d(String tag, String message) {
    if (_shouldLog(LogLevel.debug)) {
      debugPrint(_formatMessage(tag, message, LogLevel.debug));
    }
  }
  
  /// 信息日志
  static void i(String tag, String message) {
    if (_shouldLog(LogLevel.info)) {
      debugPrint(_formatMessage(tag, message, LogLevel.info));
    }
  }
  
  /// 警告日志
  static void w(String tag, String message) {
    if (_shouldLog(LogLevel.warning)) {
      debugPrint(_formatMessage(tag, message, LogLevel.warning));
    }
  }
  
  /// 错误日志
  static void e(String tag, String message) {
    if (_shouldLog(LogLevel.error)) {
      debugPrint(_formatMessage(tag, message, LogLevel.error));
    }
  }
  
  /// 便捷方法：游戏相关日志
  static void game(String message) {
    d('GAME', message);
  }
  
  /// 便捷方法：挑战相关日志
  static void challenge(String message) {
    d('CHALLENGE', message);
  }
  
  /// 便捷方法：分数相关日志
  static void score(String message) {
    d('SCORE', message);
  }
  
  /// 便捷方法：状态管理相关日志
  static void state(String message) {
    d('STATE', message);
  }
  
  /// 便捷方法：网络相关日志
  static void network(String message) {
    i('NETWORK', message);
  }
  
  /// 便捷方法：数据库相关日志
  static void database(String message) {
    d('DATABASE', message);
  }
  
  /// 便捷方法：UI相关日志
  static void ui(String message) {
    d('UI', message);
  }
  
  /// 便捷方法：广告相关日志
  static void ad(String message) {
    i('AD', message);
  }
  
  /// 打印分隔线（用于重要日志的分组）
  static void separator(String title) {
    if (_shouldLog(LogLevel.debug)) {
      debugPrint('');
      debugPrint('${'=' * 20} $title ${'=' * 20}');
    }
  }
  
  /// 结束分隔线
  static void endSeparator() {
    if (_shouldLog(LogLevel.debug)) {
      debugPrint('${'=' * 50}');
      debugPrint('');
    }
  }
}

/// 全局日志函数的简化调用
class Log {
  /// 调试日志
  static void d(String tag, String message) => Logger.d(tag, message);
  
  /// 信息日志
  static void i(String tag, String message) => Logger.i(tag, message);
  
  /// 警告日志
  static void w(String tag, String message) => Logger.w(tag, message);
  
  /// 错误日志
  static void e(String tag, String message) => Logger.e(tag, message);
  
  /// 游戏日志
  static void game(String message) => Logger.game(message);
  
  /// 挑战日志
  static void challenge(String message) => Logger.challenge(message);
  
  /// 分数日志
  static void score(String message) => Logger.score(message);
  
  /// 状态日志
  static void state(String message) => Logger.state(message);
  
  /// 网络日志
  static void network(String message) => Logger.network(message);
  
  /// 数据库日志
  static void database(String message) => Logger.database(message);
  
  /// UI日志
  static void ui(String message) => Logger.ui(message);
  
  /// 广告日志
  static void ad(String message) => Logger.ad(message);
  
  /// 分隔线
  static void separator(String title) => Logger.separator(title);
  
  /// 结束分隔线
  static void endSeparator() => Logger.endSeparator();
} 