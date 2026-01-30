import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/image_item.dart';
import '../../models/photo_set_progress.dart';
import '../../providers/app_providers.dart';
import '../../services/ads/ads_service.dart';
import '../../services/storage/prefs_service.dart';
import '../../services/firebase_config_service.dart';
import '../../providers/user_type_provider.dart';
import '../../utils/game_logger.dart';
import '../../utils/secret_image_utils.dart';

class PhotoSetController extends AsyncNotifier<List<PhotoSetProgress>> {
  static const _prefsKey = 'photo_set_progress_v5'; // 修复套图文件夹映射问题，强制重新生成

  late PrefsService _prefs;
  late AdsService _ads;

  @override
  Future<List<PhotoSetProgress>> build() async {
    try {
      _prefs = ref.read(prefsServiceProvider);
      _ads = ref.read(adsServiceProvider);

    // 等待用户进度数据加载完成
    GameLogger.log(GameLogger.tagPhotoSet, '等待userProgressProvider数据加载...');
    await ref.read(userProgressProvider.future);
    GameLogger.log(GameLogger.tagPhotoSet, 'userProgressProvider数据加载完成');
    
    // 等待Firebase配置数据加载完成
    GameLogger.log(GameLogger.tagPhotoSet, '等待firebaseConfigProvider数据加载...');
    // 简单等待一下，让Firebase配置有时间加载
    await Future.delayed(const Duration(milliseconds: 500));
    GameLogger.log(GameLogger.tagPhotoSet, 'firebaseConfigProvider数据加载完成');

    final saved = _prefs.getJson(_prefsKey);
    GameLogger.log(GameLogger.tagPhotoSet, '读取保存的数据: ${saved != null ? "找到数据" : "没有数据"}');
    
    if (saved != null && saved['sets'] is List) {
      GameLogger.log(GameLogger.tagPhotoSet, '解析套图数据...');
      final parsed = (saved['sets'] as List)
          .map((e) =>
              PhotoSetProgress.fromJson((e as Map).cast<String, Object?>()))
          .toList();
      GameLogger.success(GameLogger.tagPhotoSet, '成功解析${parsed.length}个套图');
      
      // 检查是否需要更新配置（从旧版本升级）
      final needsUpdate = _needsConfigUpdate(parsed);
      if (needsUpdate) {
        GameLogger.log(GameLogger.tagPhotoSet, '检测到旧配置，重新生成数据');
        final updated = _updateConfig(parsed);
        await _save(updated);
        return _normalize(updated);
      }
      
      return _normalize(parsed);
    }

    final defaults = _defaultSets();
    await _save(defaults);
    return _normalize(defaults);
    } catch (e) {
      GameLogger.error(GameLogger.tagPhotoSet, '构建套图数据时发生异常: $e');
      // 返回基本的默认配置
      final basicDefaults = _createBasicDefaultSets();
      try {
        await _save(basicDefaults);
        return _normalize(basicDefaults);
      } catch (saveError) {
        GameLogger.error(GameLogger.tagPhotoSet, '保存基本配置时发生异常: $saveError');
        return basicDefaults;
      }
    }
  }

  bool _needsConfigUpdate(List<PhotoSetProgress> sets) {
    if (sets.isEmpty) return true;
    
    final firstSet = sets.first;
    if (firstSet.slots.length < 2) return true;
    // 新配置要求每套至少9张图片
    if (firstSet.slots.length < 9) return true;

    // 如果当前保存的套图数量或槽位数量与默认配置不一致，需要更新
    final defaults = _defaultSets();
    for (final defaultSet in defaults) {
      final savedSet = sets.firstWhere(
        (set) => set.setId == defaultSet.setId,
        orElse: () => defaultSet,
      );
      if (savedSet.slots.length != defaultSet.slots.length) {
        return true;
      }
    }
    
    final slot2 = firstSet.slots[1]; // 图片2
    // 检查needRv配置
    if (slot2.needRv != 2) return true;
    
    // 检查图片路径是否正确（套图1应该使用文件夹a，正确的命名模式）
    const expectedPath = 'assets/pic_secret/a/secret_1_b_2.png';
    if (slot2.assetPath != expectedPath) return true;
    
    return false;
  }

  List<PhotoSetProgress> _updateConfig(List<PhotoSetProgress> oldSets) {
    GameLogger.log(GameLogger.tagPhotoSet, '开始更新配置，保留用户解锁状态');
    
    try {
      // 获取新的默认配置作为模板
      final newDefaults = _defaultSets();
      
      return oldSets.map((oldSet) {
      // 找到对应的新配置
      final newSet = newDefaults.firstWhere(
        (set) => set.setId == oldSet.setId,
        orElse: () => oldSet, // 如果找不到，使用旧配置
      );
      
      final updatedMap = <int, PhotoSetSlot>{};
      
      // 先使用旧数据覆盖默认值，保留已有进度
      for (final oldSlot in oldSet.slots) {
        final newSlot = newSet.slots.firstWhere(
          (slot) => slot.index == oldSlot.index,
          orElse: () => oldSlot,
        );
        updatedMap[oldSlot.index] = oldSlot.copyWith(
          needRv: newSlot.needRv,
          assetPath: newSlot.assetPath,
          type: newSlot.type,
          imageId: 'secret_${oldSet.setId}_${oldSlot.index}',
        );
      }
      
      // 再补齐新配置中新增的槽位
      for (final newSlot in newSet.slots) {
        updatedMap.putIfAbsent(
          newSlot.index,
          () => newSlot.copyWith(
            imageId: 'secret_${newSet.setId}_${newSlot.index}',
          ),
        );
      }
      
      // 按照新配置的顺序生成最终列表，保证数量与顺序一致
      final updatedSlots = newSet.slots
          .map((slot) => updatedMap[slot.index] ?? slot)
          .toList();
      
      return oldSet.copyWith(slots: updatedSlots);
    }).toList();
    } catch (e) {
      GameLogger.error(GameLogger.tagPhotoSet, '更新配置时发生异常: $e');
      // 如果更新失败，返回原始数据
      return oldSets;
    }
  }

  Future<void> watchSlot(int setId, int slotIndex) async {
    final current = state.value ?? const <PhotoSetProgress>[];
    final list = List<PhotoSetProgress>.of(current);
    final setPos = list.indexWhere((set) => set.setId == setId);
    if (setPos < 0) return;

    final set = list[setPos];
    final slotPos = slotIndex - 1;
    if (slotPos < 0 || slotPos >= set.slots.length) return;

    final slot = set.slots[slotPos];
    if (slot.state != PhotoSetSlotState.rvNeeded) return;

    final result = await _ads.showRewarded(
        placement: 'secret_set_${setId}_slot_$slotIndex');
    if (result != AdResult.completed) return;

    final nextProgress = slot.rvProgress + 1;
    final reached = nextProgress >= slot.needRv;
    final updatedSlot = slot.copyWith(
      rvProgress: nextProgress,
      state: reached ? PhotoSetSlotState.playable : PhotoSetSlotState.rvNeeded,
    );

    final updatedSlots = [...set.slots];
    updatedSlots[slotPos] = updatedSlot;
    list[setPos] = set.copyWith(slots: updatedSlots);

    await _save(list);
    state = AsyncData(list);
  }

  Future<void> acquireSlot(int setId, int slotIndex) async {
    GameLogger.divider(GameLogger.tagPhotoSet, 'acquireSlot');
    GameLogger.log(GameLogger.tagPhotoSet, 'setId=$setId, slotIndex=$slotIndex');
    
    final current = state.value ?? const <PhotoSetProgress>[];
    final list = List<PhotoSetProgress>.of(current);
    final setPos = list.indexWhere((set) => set.setId == setId);
    if (setPos < 0) {
      GameLogger.error(GameLogger.tagPhotoSet, '套图不存在: setId=$setId');
      return;
    }

    final set = list[setPos];
    final slotPos = slotIndex - 1;
    if (slotPos < 0 || slotPos >= set.slots.length) {
      GameLogger.error(GameLogger.tagPhotoSet, '槽位索引超出范围: slotIndex=$slotIndex');
      return;
    }

    final slot = set.slots[slotPos];
    GameLogger.log(GameLogger.tagPhotoSet, '当前图片状态: ${slot.state.name}');
    
    if (slot.state != PhotoSetSlotState.playable) {
      GameLogger.error(GameLogger.tagPhotoSet, '图片不是可玩状态，无法获取');
      return;
    }

    final updatedSlots = [...set.slots];
    updatedSlots[slotPos] = slot.copyWith(state: PhotoSetSlotState.acquired);
    GameLogger.success(GameLogger.tagPhotoSet, '图片${slot.index}已获取');

    // 只解锁下一张图片（严格顺序解锁）
    if (slotPos + 1 < updatedSlots.length) {
      final nextSlot = updatedSlots[slotPos + 1];
      GameLogger.log(GameLogger.tagPhotoSet, '下一张图片${nextSlot.index}当前状态: ${nextSlot.state.name}');
      
      if (nextSlot.state == PhotoSetSlotState.locked) {
        final newState = nextSlot.needRv > 0
            ? PhotoSetSlotState.rvNeeded
            : PhotoSetSlotState.playable;
        
        updatedSlots[slotPos + 1] = nextSlot.copyWith(
          state: newState,
          rvProgress: 0,
        );
        
        GameLogger.success(GameLogger.tagPhotoSet, 
          '图片${nextSlot.index}解锁: ${newState.name} (needRv=${nextSlot.needRv})');
      }
    }

    list[setPos] = set.copyWith(slots: updatedSlots);

    await _save(list);
    state = AsyncData(list);
    GameLogger.success(GameLogger.tagPhotoSet, '数据已保存');
  }

  List<PhotoSetProgress> _defaultSets() {
    try {
      // 获取Firebase配置
      final firebaseConfig = ref.read(firebaseConfigProvider).valueOrNull;
      final userType = ref.read(userTypeProvider);

      GameLogger.log(GameLogger.tagPhotoSet, '开始生成套图数据，用户类型: ${userType.name}');
      GameLogger.log(GameLogger.tagPhotoSet, 'Firebase配置: ${firebaseConfig != null ? "已加载" : "未加载"}');
    
    if (firebaseConfig != null) {
      GameLogger.log(GameLogger.tagPhotoSet, 'Firebase配置详情:');
      GameLogger.log(GameLogger.tagPhotoSet, '  - 版本: ${firebaseConfig.version}');
      GameLogger.log(GameLogger.tagPhotoSet, '  - 套图数量: ${firebaseConfig.secrets.sets.length}');
      GameLogger.log(GameLogger.tagPhotoSet, '  - 套图baseUrl: ${firebaseConfig.secrets.baseUrl}');
      for (final set in firebaseConfig.secrets.sets) {
        GameLogger.log(GameLogger.tagPhotoSet, '  - 套图${set.setId}: ${set.title}, 解锁等级${set.unlockLevel}, slot数量${set.slotCount}');
      }
    }

    // 如果Firebase配置可用，使用配置文件中的数据
    if (firebaseConfig != null && firebaseConfig.secrets.sets.isNotEmpty) {
      GameLogger.log(GameLogger.tagPhotoSet, '使用Firebase配置生成套图，共${firebaseConfig.secrets.sets.length}个套图');
      return firebaseConfig.secrets.sets.map((secretSet) {
        final slots = List<PhotoSetSlot>.generate(secretSet.slotCount, (slotIdx) {
          final index = slotIdx + 1;
          final needRv = index == 1
              ? 0
              : index <= 3
                  ? 2  // 图片2-3：看2个视频解锁
                  : index <= 6
                      ? 3  // 图片4-6：看3个视频解锁
                      : 4; // 图片7-9：看4个视频解锁
          final type = SecretImageUtils.imageType(index);
          final typeLetter = SecretImageUtils.typeLetter(index);
          
          final assetPath = secretSet.localPathPattern
              .replaceAll('{slot}', index.toString())
              .replaceAll('{setId}', secretSet.setId.toString())
              .replaceAll('{type}', typeLetter);
          final imageId =
              userType == UserType.paid ? 'secret_${secretSet.setId}_$index' : null;

          // 严格顺序解锁：只有第一张图片可玩，其他初始都为锁定状态
          final initialState = index == 1
              ? PhotoSetSlotState.playable
              : PhotoSetSlotState.locked;

          GameLogger.log(GameLogger.tagPhotoSet, '生成套图${secretSet.setId} 图片$index: $assetPath, imageId=$imageId, 状态=${initialState.name}');

          return PhotoSetSlot(
            index: index,
            needRv: needRv,
            rvProgress: 0,
            state: initialState,
            assetPath: assetPath,
            type: type,
            imageId: imageId,
          );
        });

        return PhotoSetProgress(
          setId: secretSet.setId,
          title: secretSet.title,
          unlockLevel: secretSet.unlockLevel,
          slots: slots,
        );
      }).toList();
    }

    // 如果Firebase配置不可用，使用默认硬编码配置（向后兼容）
    GameLogger.log(GameLogger.tagPhotoSet, 'Firebase配置不可用，使用默认硬编码配置');
    const unlockLevels = [3, 10, 20, 50, 70, 90, 110, 130, 150];
    const folders = ['a', 'b', 'c', 'd', 'e', 'f', 'j', 'h', 'i'];

    return List.generate(unlockLevels.length, (setIdx) {
      final setId = setIdx + 1;
      final folder = folders[setIdx % folders.length];
      final slots = List<PhotoSetSlot>.generate(9, (slotIdx) {
        final index = slotIdx + 1;
        final needRv = index == 1
            ? 0
            : index <= 3
                ? 2  // 图片2-3：看2个视频解锁
                : index <= 6
                    ? 3  // 图片4-6：看3个视频解锁
                    : 4; // 图片7-9：看4个视频解锁
        final type = SecretImageUtils.imageType(index);
        
        final typeLetter = SecretImageUtils.typeLetter(index);
        final assetPath =
            'assets/pic_secret/$folder/secret_${setId}_${typeLetter}_$index.png';
        final imageId = userType == UserType.paid ? 'secret_${setId}_$index' : null;

        // 严格顺序解锁：只有第一张图片可玩，其他初始都为锁定状态
        final initialState = index == 1
            ? PhotoSetSlotState.playable
            : PhotoSetSlotState.locked;

        GameLogger.log(GameLogger.tagPhotoSet, '生成套图$setId 图片$index: $assetPath, imageId=$imageId, 状态=${initialState.name}');

        return PhotoSetSlot(
          index: index,
          needRv: needRv,
          rvProgress: 0,
          state: initialState,
          assetPath: assetPath,
          type: type,
          imageId: imageId,
        );
      });

      return PhotoSetProgress(
        setId: setId,
        title: '套图 ${setId.toString().padLeft(2, '0')}',
        unlockLevel: unlockLevels[setIdx],
        slots: slots,
      );
    });
    } catch (e) {
      GameLogger.error(GameLogger.tagPhotoSet, '生成默认套图数据时发生异常: $e');
      // 返回一个基本的默认套图配置
      return _createBasicDefaultSets();
    }
  }

  /// 创建基本的默认套图配置（异常情况下的回退配置）
  List<PhotoSetProgress> _createBasicDefaultSets() {
    GameLogger.log(GameLogger.tagPhotoSet, '使用基本默认套图配置');
    const unlockLevels = [3, 10, 20];
    const folders = ['a', 'b', 'c'];

    return List.generate(unlockLevels.length, (setIdx) {
      final setId = setIdx + 1;
      final folder = folders[setIdx % folders.length];
      final slots = List<PhotoSetSlot>.generate(8, (slotIdx) {
        final index = slotIdx + 1;
        final needRv = index == 1
            ? 0
            : index <= 3
                ? 2
                : index <= 6
                    ? 3
                    : 4;
        final type = SecretImageUtils.imageType(index);
        
        final typeLetter = SecretImageUtils.typeLetter(index);
        return PhotoSetSlot(
          index: index,
          needRv: needRv,
          rvProgress: 0,
          state: index == 1 ? PhotoSetSlotState.playable : PhotoSetSlotState.locked,
          assetPath: 'assets/pic_secret/$folder/secret_${setId}_${typeLetter}_$index.png',
          type: type,
          imageId: 'secret_${setId}_$index',
        );
      });

      return PhotoSetProgress(
        setId: setId,
        title: '套图 ${setId.toString().padLeft(2, '0')}',
        unlockLevel: unlockLevels[setIdx],
        slots: slots,
      );
    });
  }

  List<PhotoSetProgress> _normalize(List<PhotoSetProgress> input) {
    final userProgressAsync = ref.read(userProgressProvider);
    GameLogger.log(GameLogger.tagPhotoSet, '_normalize: userProgressAsync状态=${userProgressAsync.runtimeType}');
    
    if (!userProgressAsync.hasValue) {
      GameLogger.log(GameLogger.tagPhotoSet, '_normalize: userProgressProvider数据未加载，使用默认状态');
      return input; // 如果用户进度数据未加载，返回原始数据
    }
    
    final userProgress = userProgressAsync.value!;
    final unlockedSecrets = userProgress.unlockedSecrets;
    GameLogger.log(GameLogger.tagPhotoSet, '_normalize: unlockedSecrets=$unlockedSecrets');

    return input.map((set) {
      if (set.slots.isEmpty) return set;

      final normalizedSlots = <PhotoSetSlot>[];

      for (int i = 0; i < set.slots.length; i++) {
        var slot = set.slots[i];
        final canonicalId = SecretImageUtils.canonicalId(set.setId, slot.index);
        if (slot.imageId != canonicalId) {
          slot = slot.copyWith(imageId: canonicalId);
        }
        final key = '${set.setId}_${slot.index}';

        // 如果已经解锁，保持acquired状态
        if (unlockedSecrets.containsKey(key) && unlockedSecrets[key] == 1) {
          normalizedSlots.add(slot.copyWith(state: PhotoSetSlotState.acquired));
          GameLogger.log(GameLogger.tagPhotoSet, '图片${slot.index}: acquired (从userProgress)');
          continue;
        }

        // 如果已经是acquired状态，保持
        if (slot.state == PhotoSetSlotState.acquired) {
          normalizedSlots.add(slot);
          GameLogger.log(GameLogger.tagPhotoSet, '图片${slot.index}: acquired (从本地状态)');
          continue;
        }

        // 第1张图片始终为可玩状态（如果没有acquired）
        if (slot.index == 1) {
          normalizedSlots.add(slot.copyWith(state: PhotoSetSlotState.playable));
          GameLogger.log(GameLogger.tagPhotoSet, '图片${slot.index}: playable (第1张)');
          continue;
        }

        // 严格检查前置条件：前一张图片是否已获得
        if (i > 0) {
          final prevSlot = normalizedSlots[i - 1]; // ⚠️ 使用已处理的前一张状态
          final prevKey = '${set.setId}_${prevSlot.index}';

          // 检查前一张图片是否真的已经解锁
          bool prevIsAcquired = false;
          if (unlockedSecrets.containsKey(prevKey) && unlockedSecrets[prevKey] == 1) {
            prevIsAcquired = true;
          } else if (prevSlot.state == PhotoSetSlotState.acquired) {
            prevIsAcquired = true;
          }

          if (!prevIsAcquired) {
            // 前一张图片未完成，保持锁定状态
            normalizedSlots.add(slot.copyWith(state: PhotoSetSlotState.locked));
            GameLogger.log(GameLogger.tagPhotoSet, '图片${slot.index}: locked (前置未完成)');
            continue;
          }
        }

        // 前置条件满足，根据视频进度和需求设置状态
        if (slot.needRv > 0 && slot.rvProgress < slot.needRv) {
          // 需要看视频解锁
          normalizedSlots.add(slot.copyWith(state: PhotoSetSlotState.rvNeeded));
          GameLogger.log(GameLogger.tagPhotoSet, '图片${slot.index}: rvNeeded (${slot.rvProgress}/${slot.needRv})');
        } else if (slot.needRv > 0 && slot.rvProgress >= slot.needRv) {
          // 视频进度满足，变为可玩状态
          normalizedSlots.add(slot.copyWith(state: PhotoSetSlotState.playable));
          GameLogger.log(GameLogger.tagPhotoSet, '图片${slot.index}: playable (视频已满足)');
        } else {
          // 不需要视频，直接可玩
          normalizedSlots.add(slot.copyWith(state: PhotoSetSlotState.playable));
          GameLogger.log(GameLogger.tagPhotoSet, '图片${slot.index}: playable (无需视频)');
        }
      }

      return set.copyWith(slots: normalizedSlots);
    }).toList();
  }

  Future<void> _save(List<PhotoSetProgress> sets) async {
    final data = {
      'sets': sets.map((set) => set.toJson()).toList(),
    };
    GameLogger.log(GameLogger.tagPhotoSet, '保存套图数据: ${sets.length}个套图');
    await _prefs.setJson(_prefsKey, data);
    GameLogger.success(GameLogger.tagPhotoSet, '套图数据已保存到磁盘');
    
    // 验证保存是否成功
    final saved = _prefs.getJson(_prefsKey);
    if (saved != null && saved['sets'] is List) {
      GameLogger.success(GameLogger.tagPhotoSet, '验证: 数据保存成功，可以读取');
    } else {
      GameLogger.error(GameLogger.tagPhotoSet, '验证: 数据保存失败！');
    }
  }
}

final photoSetProvider =
    AsyncNotifierProvider<PhotoSetController, List<PhotoSetProgress>>(
  () => PhotoSetController(),
);

class SelectedPhotoSlot {
  final int setId;
  final int slotIndex;
  final String assetPath;
  final ImageType type;

  const SelectedPhotoSlot({
    required this.setId,
    required this.slotIndex,
    required this.assetPath,
    required this.type,
  });
}

final photoSetGameSelectionProvider =
    StateProvider<SelectedPhotoSlot?>((ref) => null);

final photoUnlockSelectionProvider =
    StateProvider<SelectedPhotoSlot?>((ref) => null);
