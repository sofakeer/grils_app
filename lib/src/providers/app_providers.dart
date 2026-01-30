import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locator.dart';
import '../repositories/progress_repository.dart';
import '../services/assets/assets_service.dart';
import '../services/remote_config/remote_config_service.dart';
import '../services/storage/prefs_service.dart';
import '../services/ads/ads_service.dart';
import '../models/user_progress.dart';
import '../utils/game_logger.dart';

// Bridge existing ServiceLocator services into Riverpod.
final prefsServiceProvider = Provider<PrefsService>(
    (ref) => ServiceLocator.instance.get<PrefsService>());
final remoteConfigProvider = Provider<RemoteConfigService>(
    (ref) => ServiceLocator.instance.get<RemoteConfigService>());
final assetsServiceProvider = Provider<AssetsService>(
    (ref) => ServiceLocator.instance.get<AssetsService>());
final adsServiceProvider =
    Provider<AdsService>((ref) => ServiceLocator.instance.get<AdsService>());

final progressRepositoryProvider =
    Provider<ProgressRepository>((ref) => ProgressRepository());

class UserProgressNotifier extends AsyncNotifier<UserProgress> {
  @override
  Future<UserProgress> build() async {
    final repo = ref.read(progressRepositoryProvider);
    return repo.load();
  }

  Future<void> set(UserProgress next) async {
    state = AsyncData(next);
    await ref.read(progressRepositoryProvider).save(next);
  }

  Future<void> addCoins(int delta) async {
    final current = state.value ?? const UserProgress();
    await set(current.copyWith(coins: current.coins + delta));
  }

  Future<bool> consumeCoins(int amount) async {
    final current = state.value;
    if (current == null || current.coins < amount) {
      return false;
    }
    await set(current.copyWith(coins: current.coins - amount));
    return true;
  }

  Future<void> addUndo(int delta) async {
    final current = state.value ?? const UserProgress();
    await set(current.copyWith(undo: current.undo + delta));
  }

  Future<void> addReminder(int delta) async {
    final current = state.value ?? const UserProgress();
    await set(current.copyWith(reminder: current.reminder + delta));
  }

  Future<void> addPipe(int delta) async {
    final current = state.value ?? const UserProgress();
    await set(current.copyWith(pipe: current.pipe + delta));
  }

  Future<bool> consumeUndo(int delta) async {
    final current = state.value ?? const UserProgress();
    if (current.undo < delta) return false;
    await set(current.copyWith(undo: current.undo - delta));
    return true;
  }

  Future<bool> consumeReminder(int delta) async {
    final current = state.value ?? const UserProgress();
    if (current.reminder < delta) return false;
    await set(current.copyWith(reminder: current.reminder - delta));
    return true;
  }

  Future<bool> consumePipe(int delta) async {
    final current = state.value ?? const UserProgress();
    if (current.pipe < delta) return false;
    await set(current.copyWith(pipe: current.pipe - delta));
    return true;
  }

  Future<void> updateSecretProgress(int setId, int slotIndex) async {
    final current = state.value ?? const UserProgress();
    final currentSecrets = Map<String, int>.from(current.unlockedSecrets);
    final key = '${setId}_${slotIndex}';
    currentSecrets[key] = 1; // 标记为已解锁

    GameLogger.log(GameLogger.tagPhotoSet, 'UserProgress 更新: $key');
    await set(current.copyWith(unlockedSecrets: currentSecrets));
    GameLogger.success(GameLogger.tagPhotoSet, 'UserProgress 已保存: $currentSecrets');
  }
}

final userProgressProvider =
    AsyncNotifierProvider<UserProgressNotifier, UserProgress>(
  () => UserProgressNotifier(),
);
