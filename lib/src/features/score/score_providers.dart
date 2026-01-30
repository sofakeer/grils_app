import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../services/ads/ads_service.dart';
import '../../utils/game_logger.dart';

class ScoreConfig {
  final bool enabled;
  final int sThreshold;
  final int aThreshold;
  final int bThreshold;
  final double sMult;
  final double aMult;
  final double bMult;
  final String baseFormula; // e.g., 10+0.5*level
  final int baseCap;

  const ScoreConfig({
    required this.enabled,
    required this.sThreshold,
    required this.aThreshold,
    required this.bThreshold,
    required this.sMult,
    required this.aMult,
    required this.bMult,
    required this.baseFormula,
    required this.baseCap,
  });
}

final scoreConfigProvider = Provider<ScoreConfig>((ref) {
  final rc = ref.read(remoteConfigProvider);
  return ScoreConfig(
    enabled: rc.getBool('score.enabled', defaultValue: true),
    sThreshold: rc.getInt('score.grade_thresholds.S', defaultValue: 90),
    aThreshold: rc.getInt('score.grade_thresholds.A', defaultValue: 70),
    bThreshold: rc.getInt('score.grade_thresholds.B', defaultValue: 0),
    sMult: rc.getDouble('score.perf_mult.S', defaultValue: 1.2),
    aMult: rc.getDouble('score.perf_mult.A', defaultValue: 1.0),
    bMult: rc.getDouble('score.perf_mult.B', defaultValue: 0.8),
    baseFormula: rc.getString('score.base_coins.formula', defaultValue: '10+0.5*level'),
    baseCap: rc.getInt('score.base_coins.cap', defaultValue: 100),
  );
});

enum Grade { none, S, A, B }

class LevelScoreResult {
  final Grade grade;
  final int baseCoins;
  final int totalCoins;
  const LevelScoreResult({required this.grade, required this.baseCoins, required this.totalCoins});
}

class LevelScoreController extends StateNotifier<LevelScoreResult> {
  LevelScoreController(this.ref) : super(const LevelScoreResult(grade: Grade.none, baseCoins: 0, totalCoins: 0)) {
    _cfg = ref.read(scoreConfigProvider);
    _ads = ref.read(adsServiceProvider);
    GameLogger.log(GameLogger.tagLevel, 'LevelScoreController 初始化');
  }
  
  final Ref ref;
  late final ScoreConfig _cfg;
  late final AdsService _ads;

  /// 计算关卡奖励
  Future<void> compute({required int level, int? percent}) async {
    GameLogger.divider(GameLogger.tagLevel, '计算奖励');
    GameLogger.log(GameLogger.tagLevel, 'level=$level, percent=$percent, enabled=${_cfg.enabled}');
    
    final grade = _cfg.enabled ? _gradeFromPercent(percent) : Grade.none;
    final base = _computeBaseCoins(level);
    final mult = _perfMult(grade);
    final total = (base * mult).floor();
    
    final result = LevelScoreResult(grade: grade, baseCoins: base, totalCoins: total);
    GameLogger.success(GameLogger.tagLevel, '设置状态: base=$base, grade=${grade.name}, mult=$mult, total=$total');
    state = result;
    
    // 验证状态是否设置成功
    GameLogger.log(GameLogger.tagLevel, '验证状态: totalCoins=${state.totalCoins}, baseCoins=${state.baseCoins}');
  }

  /// 直接领取或看广告三倍领取
  Future<bool> claim({bool triple = false}) async {
    final s = state;
    int coins = s.totalCoins;
    if (triple) {
      final res = await _ads.showRewarded(placement: 'level_claim_x3');
      if (res != AdResult.completed) return false;
      coins *= 3;
    }
    await ref.read(userProgressProvider.notifier).addCoins(coins);
    return true;
  }

  // ---- helpers ----
  Grade _gradeFromPercent(int? p) {
    if (p == null) return Grade.none;
    if (p >= _cfg.sThreshold) return Grade.S;
    if (p >= _cfg.aThreshold) return Grade.A;
    return Grade.B;
  }

  double _perfMult(Grade g) {
    switch (g) {
      case Grade.S:
        return _cfg.sMult;
      case Grade.A:
        return _cfg.aMult;
      case Grade.B:
        return _cfg.bMult;
      case Grade.none:
        return 1.0;
    }
  }

  int _computeBaseCoins(int level) {
    // Very small expression evaluator: supports pattern like "10+0.5*level"
    final expr = _cfg.baseFormula;
    GameLogger.log(GameLogger.tagLevel, '基础金币计算: formula=$expr, level=$level');
    
    double val = 0;
    // Split by '+' and '-'
    final tokens = expr.replaceAll('-', '+-').split('+');
    for (final t in tokens) {
      final tok = t.trim();
      if (tok.isEmpty) continue;
      if (tok.contains('level')) {
        final parts = tok.split('*');
        if (parts.length == 2 && parts[1].trim() == 'level') {
          final k = double.tryParse(parts[0]) ?? 0.0;
          val += k * level;
          GameLogger.log(GameLogger.tagLevel, '  解析: ${parts[0]} * level = $k * $level = ${k * level}');
        } else if (tok == 'level') {
          val += level.toDouble();
          GameLogger.log(GameLogger.tagLevel, '  解析: level = $level');
        }
      } else {
        final num = double.tryParse(tok) ?? 0.0;
        val += num;
        GameLogger.log(GameLogger.tagLevel, '  解析: 常数 = $num');
      }
    }
    GameLogger.log(GameLogger.tagLevel, '  总计: $val');
    final capped = math.min(_cfg.baseCap, val.floor());
    final result = math.max(0, capped);
    GameLogger.log(GameLogger.tagLevel, '  最终: $result (cap=${_cfg.baseCap})');
    return result;
  }
}

final levelScoreProvider = StateNotifierProvider<LevelScoreController, LevelScoreResult>((ref) => LevelScoreController(ref));

