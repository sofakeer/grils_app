import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/locator.dart';
import '../services/remote_config/remote_config_service.dart';
import '../services/storage/prefs_service.dart';
import '../services/storage/shared_prefs_service.dart';
import '../services/assets/assets_service.dart';
import '../services/ads/ads_service.dart';
import '../services/audio/audio_service.dart';
import '../services/audio/default_audio_service.dart';

class Bootstrap {
  Future<void> init() async {
    // Register core services
    final sp = await SharedPreferences.getInstance();
    ServiceLocator.instance
      ..register<GlobalKey<NavigatorState>>(GlobalKey<NavigatorState>())
      ..register<PrefsService>(SharedPrefsService(sp))
      ..register<RemoteConfigService>(InMemoryRemoteConfigService(defaults: RemoteConfigDefaults.defaultMap))
      ..register<AssetsService>(DefaultAssetsService())
      ..register<AdsService>(DummyAdsService())
      ..register<AudioService>(DefaultAudioService());

    // Preload or warm up services if needed.
    await ServiceLocator.instance.get<RemoteConfigService>().ensureLoaded();
  }
}

class RemoteConfigDefaults {
  static Map<String, Object> get defaultMap => {
        'ab_user_group': 'organic',
        'feature.enable_select_character': true,
        'feature.select_anim_prob': 0.3,
        'feature.album_order': 'desc',
        'ads.provider': 'none',
        'ads.rv_cooldown_sec': 15,
        'ads.inter_interval_sec': 90,
        'ads.cap.rv_daily': 50,
        'ads.cap.inter_daily': 50,
        'ads.banner_enabled': true,
        'ads.claim_x3_enabled': true,
        'limits.spin_daily_limit': 5,
        'limits.treasure_max_boxes': 30,
        'assets.base_url': 'https://example.invalid/',
        // User type configuration
        'user.is_paid_user': true, // true=买量用户（显示3选1弹窗），false=自然用户（直接进入下一关）
        // Score system defaults
        'score.enabled': true,
        'score.grade_thresholds.S': 90,
        'score.grade_thresholds.A': 70,
        'score.grade_thresholds.B': 0,
        'score.perf_mult.S': 1.2,
        'score.perf_mult.A': 1.0,
        'score.perf_mult.B': 0.8,
        'score.base_coins.formula': '10+0.5*level',
        'score.base_coins.cap': 100,
        // Sign-in defaults
        'signin.enabled': true,
        'signin.popup_on_launch': true,
        'signin.double_rv_enabled': true,
        'signin.timezone': 'local',
        // Audio settings defaults
        'audio.sound_enabled': true,
        'audio.music_enabled': true,
        'audio.sound_volume': 1.0,
        'audio.music_volume': 0.5,
        // Treasure defaults (30 cards minimal schema)
        'treasure.table_version': 1,
        'treasure.order': 'asc',
      };
}
