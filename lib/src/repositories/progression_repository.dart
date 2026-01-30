import '../services/storage/prefs_service.dart';
import '../core/locator.dart';

/// 进度管理仓库
/// 统一管理四选一轮询、遮罩解锁、引导弹窗等状态
class ProgressionRepository {
  static const String _keyAlbumGuideShown = 'album_guide_shown_v1';
  static const String _keyPassGuideShown = 'pass_guide_shown_v1';
  static const String _keyHasEnteredCardMode = 'has_entered_card_mode_v1';
  
  final PrefsService _prefs = ServiceLocator.instance.get<PrefsService>();

  /// 检查是否已展示过套图引导
  bool hasShownAlbumGuide() {
    return _prefs.getBool(_keyAlbumGuideShown) ?? false;
  }

  /// 标记套图引导已展示
  Future<void> markAlbumGuideShown() async {
    await _prefs.setBool(_keyAlbumGuideShown, true);
  }

  /// 检查是否已展示过通行证引导
  bool hasShownPassGuide() {
    return _prefs.getBool(_keyPassGuideShown) ?? false;
  }

  /// 标记通行证引导已展示
  Future<void> markPassGuideShown() async {
    await _prefs.setBool(_keyPassGuideShown, true);
  }

  /// 检查是否有进入卡模式记录
  bool hasEnteredCardMode() {
    return _prefs.getBool(_keyHasEnteredCardMode) ?? false;
  }

  /// 标记已进入卡模式
  Future<void> markEnteredCardMode() async {
    await _prefs.setBool(_keyHasEnteredCardMode, true);
  }

  /// 检查是否访问过套图页面
  bool hasVisitedAlbumPage() {
    // 通过检查是否有解锁的套图图片来判断
    // 或者使用单独的标记
    return _prefs.getBool('has_visited_album_page_v1') ?? false;
  }

  /// 标记已访问套图页面
  Future<void> markVisitedAlbumPage() async {
    await _prefs.setBool('has_visited_album_page_v1', true);
  }

  /// 检查是否访问过通行证页面
  bool hasVisitedPassPage() {
    return _prefs.getBool('has_visited_pass_page_v1') ?? false;
  }

  /// 标记已访问通行证页面
  Future<void> markVisitedPassPage() async {
    await _prefs.setBool('has_visited_pass_page_v1', true);
  }
}
