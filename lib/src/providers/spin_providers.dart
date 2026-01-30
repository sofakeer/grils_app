import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/spin_repository.dart';
import '../services/ads/ads_service.dart';
import 'app_providers.dart';

enum SpinPrizeType {
  coin80,
  coin100,
  coin120,
  undo1,
  reminder1,
  pipe1,
}

class SpinPrize {
  final SpinPrizeType type;
  final int weight; // 权重（和不必为 100）
  final String label;
  const SpinPrize(this.type, this.weight, this.label);
}

// 从顶部（指针方向）开始，按顺时针的默认顺序：
// 金币 → 撤销 → 金币 → 管子 → 金币 → 提示
final spinPrizesProvider = Provider<List<SpinPrize>>((ref) => const [
      SpinPrize(SpinPrizeType.coin80, 25, '+80'),        // 顶部
      SpinPrize(SpinPrizeType.undo1, 15, 'Undo +1'),     // 右上
      SpinPrize(SpinPrizeType.coin100, 20, '+100'),      // 右侧
      SpinPrize(SpinPrizeType.pipe1, 15, 'Pipe +1'),     // 右下
      SpinPrize(SpinPrizeType.coin120, 10, '+120'),      // 下方
      SpinPrize(SpinPrizeType.reminder1, 15, 'Reminder +1'), // 左下
    ]);

class SpinState {
  final int used;
  final int limit;
  final bool busy;
  final SpinPrizeType? last;
  const SpinState({required this.used, required this.limit, this.busy = false, this.last});

  SpinState copyWith({int? used, int? limit, bool? busy, SpinPrizeType? last}) =>
      SpinState(used: used ?? this.used, limit: limit ?? this.limit, busy: busy ?? this.busy, last: last ?? this.last);
}

class SpinController extends AsyncNotifier<SpinState> {
  late final SpinRepository _repo;
  late final AdsService _ads;
  final _rand = Random();

  @override
  Future<SpinState> build() async {
    _repo = SpinRepository();
    _ads = ref.read(adsServiceProvider);
    final used = await _repo.getUsedCount();
    final limit = _repo.getDailyLimit();
    return SpinState(used: used, limit: limit);
  }

  bool get canSpin => (state.value?.used ?? 0) < (state.value?.limit ?? 0);

  /// 调用激励视频并返回本次抽中的奖品下标（用于指针落点）。
  Future<int?> startSpin() async {
    final s = state.value;
    if (s == null) return null;
    if (s.used >= s.limit) return null;

    state = AsyncData(s.copyWith(busy: true));

    final res = await _ads.showRewarded(placement: 'spin');
    if (res != AdResult.completed) {
      state = AsyncData(s.copyWith(busy: false));
      return null;
    }

    final prizes = ref.read(spinPrizesProvider);
    final index = _pickIndexByWeight(prizes.map((e) => e.weight).toList());
    final prize = prizes[index];

    // 发奖
    await _applyReward(prize.type);
    await _repo.incrementUsed();
    final used = s.used + 1;
    state = AsyncData(SpinState(used: used, limit: s.limit, busy: false, last: prize.type));
    return index;
  }

  /// 调试：重置当天可用次数（将已用置 0）。
  Future<void> resetUsedCount() async {
    await _repo.resetForToday();
    final s = state.value;
    if (s != null) {
      state = AsyncData(SpinState(used: 0, limit: s.limit, busy: false, last: s.last));
    }
  }

  Future<void> _applyReward(SpinPrizeType t) async {
    final up = ref.read(userProgressProvider.notifier);
    switch (t) {
      case SpinPrizeType.coin80:
        await up.addCoins(80);
        break;
      case SpinPrizeType.coin100:
        await up.addCoins(100);
        break;
      case SpinPrizeType.coin120:
        await up.addCoins(120);
        break;
      case SpinPrizeType.undo1:
        await up.addUndo(1);
        break;
      case SpinPrizeType.reminder1:
        await up.addReminder(1);
        break;
      case SpinPrizeType.pipe1:
        await up.addPipe(1);
        break;
    }
  }

  // 移除重复定义的 resetUsedCount，统一使用上述方法。

  int _pickIndexByWeight(List<int> weights) {
    final total = weights.fold<int>(0, (a, b) => a + b);
    final r = _rand.nextInt(total);
    var acc = 0;
    for (var i = 0; i < weights.length; i++) {
      acc += weights[i];
      if (r < acc) return i;
    }
    return weights.length - 1;
  }
}

final spinControllerProvider = AsyncNotifierProvider<SpinController, SpinState>(() => SpinController());
