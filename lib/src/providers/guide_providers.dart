import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage/prefs_service.dart';
import '../providers/app_providers.dart';

/// 引导弹窗状态
class GuideState {
  final bool hasSeenPhotoSetGuide;
  final bool hasSeenTreasureGuide;
  final bool hasEnteredPhotoSetPage;
  final bool hasEnteredTreasurePage;

  const GuideState({
    this.hasSeenPhotoSetGuide = false,
    this.hasSeenTreasureGuide = false,
    this.hasEnteredPhotoSetPage = false,
    this.hasEnteredTreasurePage = false,
  });

  GuideState copyWith({
    bool? hasSeenPhotoSetGuide,
    bool? hasSeenTreasureGuide,
    bool? hasEnteredPhotoSetPage,
    bool? hasEnteredTreasurePage,
  }) =>
      GuideState(
        hasSeenPhotoSetGuide: hasSeenPhotoSetGuide ?? this.hasSeenPhotoSetGuide,
        hasSeenTreasureGuide: hasSeenTreasureGuide ?? this.hasSeenTreasureGuide,
        hasEnteredPhotoSetPage: hasEnteredPhotoSetPage ?? this.hasEnteredPhotoSetPage,
        hasEnteredTreasurePage: hasEnteredTreasurePage ?? this.hasEnteredTreasurePage,
      );
}

/// 引导弹窗状态管理
class GuideController extends StateNotifier<GuideState> {
  GuideController(this._prefs) : super(const GuideState()) {
    _loadState();
  }

  final PrefsService _prefs;
  static const String _keyPhotoSetGuide = 'guide_photo_set_shown_v1';
  static const String _keyTreasureGuide = 'guide_treasure_shown_v1';
  static const String _keyPhotoSetEntered = 'guide_photo_set_entered_v1';
  static const String _keyTreasureEntered = 'guide_treasure_entered_v1';

  /// 加载状态
  Future<void> _loadState() async {
    final hasSeenPhotoSetGuide = _prefs.getBool(_keyPhotoSetGuide) ?? false;
    final hasSeenTreasureGuide = _prefs.getBool(_keyTreasureGuide) ?? false;
    final hasEnteredPhotoSetPage = _prefs.getBool(_keyPhotoSetEntered) ?? false;
    final hasEnteredTreasurePage = _prefs.getBool(_keyTreasureEntered) ?? false;

    state = GuideState(
      hasSeenPhotoSetGuide: hasSeenPhotoSetGuide,
      hasSeenTreasureGuide: hasSeenTreasureGuide,
      hasEnteredPhotoSetPage: hasEnteredPhotoSetPage,
      hasEnteredTreasurePage: hasEnteredTreasurePage,
    );
  }

  /// 标记已看过套图引导
  Future<void> markPhotoSetGuideShown() async {
    await _prefs.setBool(_keyPhotoSetGuide, true);
    state = state.copyWith(hasSeenPhotoSetGuide: true);
  }

  /// 标记已看过通行证引导
  Future<void> markTreasureGuideShown() async {
    await _prefs.setBool(_keyTreasureGuide, true);
    state = state.copyWith(hasSeenTreasureGuide: true);
  }

  /// 标记已进入套图页面
  Future<void> markPhotoSetPageEntered() async {
    await _prefs.setBool(_keyPhotoSetEntered, true);
    state = state.copyWith(hasEnteredPhotoSetPage: true);
  }

  /// 标记已进入通行证页面
  Future<void> markTreasurePageEntered() async {
    await _prefs.setBool(_keyTreasureEntered, true);
    state = state.copyWith(hasEnteredTreasurePage: true);
  }

  /// 检查是否应该显示套图引导
  bool shouldShowPhotoSetGuide(int currentLevel) {
    // 完成第2关后，且未看过套图引导，且未进入过套图页面
    return currentLevel > 2 &&
        !state.hasSeenPhotoSetGuide &&
        !state.hasEnteredPhotoSetPage;
  }

  /// 检查是否应该显示通行证引导
  bool shouldShowTreasureGuide(int currentLevel) {
    // 完成第2关后，且已看过套图引导或已进入过套图页面，且未看过通行证引导，且未进入过通行证页面
    return currentLevel > 2 &&
        (state.hasSeenPhotoSetGuide || state.hasEnteredPhotoSetPage) &&
        !state.hasSeenTreasureGuide &&
        !state.hasEnteredTreasurePage;
  }
}

/// 引导弹窗状态 Provider
final guideProvider = StateNotifierProvider<GuideController, GuideState>((ref) {
  final prefs = ref.read(prefsServiceProvider);
  return GuideController(prefs);
});
