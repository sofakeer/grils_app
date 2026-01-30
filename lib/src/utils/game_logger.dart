/// 游戏日志工具类
/// 
/// 提供统一的日志格式和模块标签，方便日志筛选
class GameLogger {
  // 公共前缀
  static const String _prefix = '[GameApp]';
  
  // 模块标签
  static const String tagPhotoSet = '套图';
  static const String tagGame = '游戏';
  static const String tagPhotoUnlock = '解锁';
  static const String tagBackground = '背景';
  static const String tagLevel = '关卡';
  static const String tagScore = '评分';
  static const String tagTreasure = '宝藏';
  static const String tagAlbum = '相册';
  static const String tagSpin = '转盘';
  static const String tagSignIn = '签到';
  
  /// 打印日志
  /// [tag] 模块标签
  /// [message] 日志内容
  static void log(String tag, String message) {
    print('$_prefix[$tag] $message');
  }
  
  /// 打印调试日志（带更多上下文）
  /// [tag] 模块标签
  /// [method] 方法名
  /// [message] 日志内容
  static void debug(String tag, String method, String message) {
    print('$_prefix[$tag].$method: $message');
  }
  
  /// 打印错误日志
  /// [tag] 模块标签
  /// [message] 错误信息
  /// [error] 错误对象（可选）
  static void error(String tag, String message, [Object? error]) {
    print('$_prefix[$tag] ❌ $message${error != null ? ': $error' : ''}');
  }
  
  /// 打印成功日志
  /// [tag] 模块标签
  /// [message] 成功信息
  static void success(String tag, String message) {
    print('$_prefix[$tag] ✅ $message');
  }
  
  /// 打印分隔线（用于标记重要流程）
  /// [tag] 模块标签
  /// [title] 标题
  static void divider(String tag, String title) {
    print('$_prefix[$tag] ========== $title ==========');
  }
}

