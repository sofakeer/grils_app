import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../providers/level_providers.dart';
import '../../providers/album_providers.dart';
import '../../providers/background_providers.dart';
import '../../services/ads/ads_service.dart';
import '../../services/storage/prefs_service.dart';

enum TreasureRewardType { image, coin, undo, reminder, pipe }

enum TreasureCardState { locked, progressNeeded, rvNeeded, claimable, claimed }

class TreasureCard {
  final int index;
  final TreasureRewardType type;
  final int amount;
  final int? needLevel;
  final int? needRv;
  final int rvProgress;
  final TreasureCardState state;
  final int? imageSequence;

  const TreasureCard({
    required this.index,
    required this.type,
    required this.amount,
    this.needLevel,
    this.needRv,
    this.rvProgress = 0,
    this.state = TreasureCardState.locked,
    this.imageSequence,
  });

  TreasureCard copyWith({
    int? rvProgress,
    TreasureCardState? state,
    int? imageSequence,
  }) =>
      TreasureCard(
        index: index,
        type: type,
        amount: amount,
        needLevel: needLevel,
        needRv: needRv,
        rvProgress: rvProgress ?? this.rvProgress,
        state: state ?? this.state,
        imageSequence: imageSequence ?? this.imageSequence,
      );

  Map<String, Object?> toJson() => {
        'index': index,
        'type': type.name,
        'amount': amount,
        'needLevel': needLevel,
        'needRv': needRv,
        'rvProgress': rvProgress,
        'state': state.name,
        'imageSequence': imageSequence,
      };

  static TreasureCard fromJson(Map<String, Object?> json) => TreasureCard(
        index: json['index'] as int,
        type:
            TreasureRewardType.values.firstWhere((e) => e.name == json['type']),
        amount: (json['amount'] as int?) ?? 0,
        needLevel: json['needLevel'] as int?,
        needRv: json['needRv'] as int?,
        rvProgress: (json['rvProgress'] as int?) ?? 0,
        state: TreasureCardState.values.firstWhere(
            (e) => e.name == json['state'],
            orElse: () => TreasureCardState.locked),
        imageSequence: json['imageSequence'] as int?,
      );
}

class TreasureState {
  final List<TreasureCard> cards;
  const TreasureState(this.cards);
}

class TreasureController extends AsyncNotifier<TreasureState> {
  static const _key = 'treasure_cards_v2';
  late final PrefsService _prefs;
  late final AdsService _ads;

  @override
  Future<TreasureState> build() async {
    _prefs = ref.read(prefsServiceProvider);
    _ads = ref.read(adsServiceProvider);
    final currentLevel = ref.read(levelProvider).currentLevel;
    
    if (kDebugMode) {
      print('\n╔═══════════════════════════════════════════════════════╗');
      print('║       🏗️  Treasure Provider Build 开始              ║');
      print('╚═══════════════════════════════════════════════════════╝');
      print('[Treasure] 📊 当前游戏关卡: LEVEL $currentLevel');
    }
    
    final saved = _prefs.getString(_key);
    if (saved != null) {
      if (kDebugMode) {
        print('[Treasure] 💾 从存储加载宝藏数据...');
      }
      final list = (jsonDecode(saved) as List)
          .map((e) => TreasureCard.fromJson((e as Map).cast<String, Object?>()))
          .toList();
      if (kDebugMode) {
        print('[Treasure] ✅ 成功加载 ${list.length} 张卡片');
        print('[Treasure] 🔄 开始重新计算所有卡片状态 (基于当前关卡: $currentLevel)');
        print('[Treasure] ─────────────────────────────────────────────');
      }
      final normalized = _recalcStates(list);
      if (kDebugMode) {
        print('[Treasure] ─────────────────────────────────────────────');
        print('[Treasure] ✅ 状态计算完成！前5张卡片最终状态:');
        for (var card in normalized.take(5)) {
          final stateIcon = {
            TreasureCardState.claimed: '✅',
            TreasureCardState.claimable: '🎁',
            TreasureCardState.locked: '🔒',
            TreasureCardState.rvNeeded: '📺',
            TreasureCardState.progressNeeded: '⏳',
          }[card.state] ?? '❓';
          print('  $stateIcon 卡片${card.index}: ${card.state.name.padRight(15)} | type=${card.type.name.padRight(8)} | needLevel=${(card.needLevel?.toString() ?? "无").padRight(3)} | needRv=${(card.needRv?.toString() ?? "无").padRight(3)}');
        }
        print('╚═══════════════════════════════════════════════════════╝\n');
      }
      // ✅ 保存重新计算后的状态，确保下次加载时状态是最新的
      await _save(normalized);
      return TreasureState(normalized);
    }
    if (kDebugMode) {
      print('[Treasure] ⚠️  没有存储数据，创建默认配置...');
    }
    final defaults = _defaultCards();
    if (kDebugMode) {
      print('[Treasure] ✅ 默认配置创建完成，共 ${defaults.length} 张卡片');
      print('╚═══════════════════════════════════════════════════════╝\n');
    }
    await _save(defaults);
    return TreasureState(defaults);
  }

  Future<void> watchRv(int idx) async {
    final list =
        List<TreasureCard>.of(state.value?.cards ?? const <TreasureCard>[]);
    final i = list.indexWhere((e) => e.index == idx);
    if (i < 0) return;
    var card = list[i];
    if (card.needRv == null) return; // 非视频卡
    final res = await _ads.showRewarded(placement: 'treasure_card_$idx');
    if (res != AdResult.completed) return;
    final next = ((card.rvProgress + 1).clamp(0, card.needRv!) as num).toInt();
    card = card.copyWith(rvProgress: next);
    list[i] = card;
    final normalized = _recalcStates(list);
    await _save(normalized);
    state = AsyncData(TreasureState(normalized));
  }

  Future<void> claim(int idx) async {
    final list =
        List<TreasureCard>.of(state.value?.cards ?? const <TreasureCard>[]);
    final i = list.indexWhere((e) => e.index == idx);
    if (i < 0) return;
    var card = list[i];
    if (card.state != TreasureCardState.claimable) return;
    await _applyReward(card);
    card = card.copyWith(state: TreasureCardState.claimed);
    list[i] = card;
    final normalized = _recalcStates(list);
    await _save(normalized);
    state = AsyncData(TreasureState(normalized));
  }

  Future<void> completeImageBySequence(int sequence) async {
    if (sequence <= 0) return;
    final list =
        List<TreasureCard>.of(state.value?.cards ?? const <TreasureCard>[]);
    if (list.isEmpty) return;

    final index = list.indexWhere((card) =>
        card.type == TreasureRewardType.image &&
        (card.imageSequence ?? 0) == sequence);
    if (index < 0) return;

    var card = list[index];
    if (card.state == TreasureCardState.claimed) {
      return;
    }

    await _applyReward(card);
    card = card.copyWith(state: TreasureCardState.claimed);
    list[index] = card;

    final normalized = _recalcStates(list);
    await _save(normalized);
    state = AsyncData(TreasureState(normalized));
  }

  // ---- helpers ----
  List<TreasureCard> _defaultCards() {
    final List<TreasureCard> xs = [];
    var imageSeq = 0;

    void addImage(int index, {int? needLevel, int? needRv}) {
      imageSeq += 1;
      if (kDebugMode) {
        print('[Treasure] 添加图片: index=$index, imageSeq=$imageSeq');
      }
      xs.add(TreasureCard(
        index: index,
        type: TreasureRewardType.image,
        amount: 1,
        needLevel: needLevel,
        needRv: needRv,
        imageSequence: imageSeq,
      ));
    }

    void addReward(int index, TreasureRewardType type, int amount,
        {int? needLevel, int? needRv}) {
      xs.add(TreasureCard(
        index: index,
        type: type,
        amount: amount,
        needLevel: needLevel,
        needRv: needRv,
      ));
    }

    // 根据表格配置：1-28号是图片和道具交替，29-30号是连续图片
    addImage(1, needLevel: 3);
    addReward(2, TreasureRewardType.coin, 100, needRv: 3);
    addImage(3, needLevel: 10);
    addReward(4, TreasureRewardType.undo, 3, needRv: 3);
    addImage(5, needLevel: 20);
    addReward(6, TreasureRewardType.reminder, 3, needRv: 3);
    addImage(7, needLevel: 30);
    addReward(8, TreasureRewardType.pipe, 3, needRv: 3);
    addImage(9, needLevel: 40);
    addReward(10, TreasureRewardType.coin, 100, needRv: 3);
    addImage(11, needLevel: 50);
    addReward(12, TreasureRewardType.undo, 3, needRv: 3);
    addImage(13, needLevel: 80);
    addReward(14, TreasureRewardType.reminder, 3, needRv: 3);
    addImage(15, needLevel: 100);
    addReward(16, TreasureRewardType.pipe, 3, needRv: 3);
    addImage(17, needLevel: 150);
    addReward(18, TreasureRewardType.coin, 100, needRv: 3);
    addImage(19, needLevel: 200);
    addReward(20, TreasureRewardType.undo, 3, needRv: 3);
    addImage(21, needLevel: 300);
    addReward(22, TreasureRewardType.reminder, 3, needRv: 3);
    addImage(23, needRv: 5);
    addReward(24, TreasureRewardType.pipe, 3, needRv: 3);
    addImage(25, needRv: 5);
    addReward(26, TreasureRewardType.coin, 100, needRv: 3);
    addImage(27, needRv: 5);
    addReward(28, TreasureRewardType.undo, 3, needRv: 3);
    // 最后两个是连续图片
    addImage(29, needRv: 3);
    addImage(30, needLevel: 300);

    return _recalcStates(xs);
  }

  List<TreasureCard> _recalcStates(List<TreasureCard> xs) {
    if (xs.isEmpty) return xs;

    final currentLevel = ref.read(levelProvider).currentLevel;
    final sorted = List<TreasureCard>.of(xs)
      ..sort((a, b) => a.index.compareTo(b.index));

    final result = <TreasureCard>[];
    var imageSeq = 0;
    for (final raw in sorted) {
      TreasureCard card = raw;
      if (card.type == TreasureRewardType.image) {
        imageSeq += 1;
        if (card.imageSequence != imageSeq) {
          card = card.copyWith(imageSequence: imageSeq);
        }
        if (kDebugMode) {
          print('[Treasure] 重新计算图片序列: index=${card.index}, imageSeq=$imageSeq, original=${raw.imageSequence}');
        }
      }

      final previous = result.isEmpty ? null : result.last;
      result.add(_deriveState(card, previous, currentLevel));
    }
    return result;
  }

  TreasureCard _deriveState(
      TreasureCard card, TreasureCard? previous, int currentLevel) {
    if (kDebugMode) {
      print('[Treasure] ========== 卡片${card.index} 状态计算 ==========');
      print('[Treasure] 📌 基本信息:');
      print('[Treasure]   - type=${card.type.name}');
      print('[Treasure]   - imageSeq=${card.imageSequence}');
      print('[Treasure]   - amount=${card.amount}');
      print('[Treasure] 🎯 要求条件:');
      print('[Treasure]   - currentLevel=$currentLevel');
      print('[Treasure]   - needLevel=${card.needLevel ?? "无"}');
      print('[Treasure]   - needRv=${card.needRv ?? "无"}');
      print('[Treasure]   - rvProgress=${card.rvProgress}');
      print('[Treasure] 📊 当前状态: ${card.state.name}');
      print('[Treasure] 👈 前置卡片: ${previous != null ? "index=${previous.index}, state=${previous.state.name}" : "无(这是第一张)"}');
    }
    
    // ✅ 只有已领取的状态才保持不变，其他状态都需要重新计算
    if (card.state == TreasureCardState.claimed) {
      if (kDebugMode) {
        print('[Treasure] ✅ 结论: 已领取，保持状态 claimed');
        print('[Treasure] ==========================================\n');
      }
      return card;
    }

    // 🔄 重新计算状态（忽略之前保存的状态）
    if (kDebugMode) {
      print('[Treasure] 🔄 开始重新计算状态...');
    }
    
    // 检查1：前置条件 - 前一个卡片必须已领取
    if (previous != null && previous.state != TreasureCardState.claimed) {
      if (kDebugMode) {
        print('[Treasure] ❌ 检查1: 前置条件未满足');
        print('[Treasure]   - 前置卡片${previous.index}状态: ${previous.state.name}');
        print('[Treasure]   - 需要状态: claimed');
        print('[Treasure] ⏳ 结论: progressNeeded (等待前置完成)');
        print('[Treasure] ==========================================\n');
      }
      return card.copyWith(state: TreasureCardState.progressNeeded);
    }
    if (kDebugMode && previous != null) {
      print('[Treasure] ✅ 检查1: 前置条件满足 (前置卡片${previous.index}已claimed)');
    }

    // 检查2：等级要求
    if (card.needLevel != null) {
      if (currentLevel < card.needLevel!) {
        if (kDebugMode) {
          print('[Treasure] ❌ 检查2: 等级不足');
          print('[Treasure]   - 当前等级: $currentLevel');
          print('[Treasure]   - 需要等级: ${card.needLevel}');
          print('[Treasure]   - 差距: ${card.needLevel! - currentLevel} 级');
          print('[Treasure] 🔒 结论: locked (等级未达到)');
          print('[Treasure] ==========================================\n');
        }
        return card.copyWith(state: TreasureCardState.locked);
      }
      if (kDebugMode) {
        print('[Treasure] ✅ 检查2: 等级满足 (当前$currentLevel >= 需要${card.needLevel})');
      }
    } else {
      if (kDebugMode) {
        print('[Treasure] ⏭️  跳过检查2: 无等级要求');
      }
    }

    // 检查3：视频要求
    if (card.needRv != null) {
      final nextState = card.rvProgress >= card.needRv!
          ? TreasureCardState.claimable
          : TreasureCardState.rvNeeded;
      if (kDebugMode) {
        print('[Treasure] 📺 检查3: 视频要求');
        print('[Treasure]   - 已观看: ${card.rvProgress}');
        print('[Treasure]   - 需要观看: ${card.needRv}');
        print('[Treasure]   - 进度: ${(card.rvProgress / card.needRv! * 100).toStringAsFixed(1)}%');
        print('[Treasure] ${nextState == TreasureCardState.claimable ? "✅" : "❌"} 结论: ${nextState.name}');
        print('[Treasure] ==========================================\n');
      }
      return card.copyWith(state: nextState);
    }
    if (kDebugMode) {
      print('[Treasure] ⏭️  跳过检查3: 无视频要求');
    }

    // 所有条件都满足，直接可领取
    if (kDebugMode) {
      print('[Treasure] ✅ 所有检查通过!');
      print('[Treasure] ✨ 结论: claimable (可领取)');
      print('[Treasure] ==========================================\n');
    }
    return card.copyWith(state: TreasureCardState.claimable);
  }

  Future<void> _applyReward(TreasureCard c) async {
    final up = ref.read(userProgressProvider.notifier);
    switch (c.type) {
      case TreasureRewardType.coin:
        await up.addCoins(c.amount);
        break;
      case TreasureRewardType.undo:
        await up.addUndo(c.amount);
        break;
      case TreasureRewardType.reminder:
        await up.addReminder(c.amount);
        break;
      case TreasureRewardType.pipe:
        await up.addPipe(c.amount);
        break;
      case TreasureRewardType.image:
        // TREASURE图片解锁：找到对应的宝藏图片索引并解锁
        final imageIndex = c.imageSequence ?? _getTreasureImageIndex(c.index);
        if (imageIndex > 0) {
          final imageId = 'pass_c_$imageIndex';
          if (kDebugMode) {
            print('解锁TREASURE图片: $imageId (宝藏卡片索引: ${c.index}, imageSequence: $imageIndex)');
          }

          // 使用新相册架构解锁图片
          await ref.read(albumNotifierProvider.notifier).unlockImage(imageId);
          
          // 更新首页背景为刚解锁的宝藏图片（存 imageId 以便走网络/智能加载，不存 asset 路径）
          await ref.read(backgroundImageProvider.notifier).setLastUnlockedBackground(imageId);
          
          if (kDebugMode) {
            print('TREASURE图片解锁完成: $imageId');
            print('已设置首页背景为: $imageId');
          }
        }
        break;
    }
  }

  /// 根据宝藏卡片索引获取对应的宝藏图片索引
  int _getTreasureImageIndex(int cardIndex) {
    // 根据新的配置：图片卡片索引
    const imageIndices = [
      1,   // 图片1
      3,   // 图片2
      5,   // 图片3
      7,   // 图片4
      9,   // 图片5
      11,  // 图片6
      13,  // 图片7
      15,  // 图片8
      17,  // 图片9
      19,  // 图片10
      21,  // 图片11
      23,  // 图片12
      25,  // 图片13
      27,  // 图片14
      29,  // 图片15
      30,  // 图片16
    ];
    final imageIndex = imageIndices.indexOf(cardIndex);
    return imageIndex >= 0 ? imageIndex + 1 : 0;
  }

  /// 刷新宝藏状态，用于外部触发状态更新
  Future<void> refresh() async {
    final currentLevel = ref.read(levelProvider).currentLevel;
    final currentCards = state.value?.cards ?? [];
    
    if (kDebugMode) {
      print('\n╔═══════════════════════════════════════════════════════╗');
      print('║       🔄 Treasure Refresh 触发                       ║');
      print('╚═══════════════════════════════════════════════════════╝');
      print('[Treasure] 📊 当前游戏关卡: LEVEL $currentLevel');
      print('[Treasure] 📋 刷新前状态 (前5张):');
      for (var card in currentCards.take(5)) {
        final stateIcon = {
          TreasureCardState.claimed: '✅',
          TreasureCardState.claimable: '🎁',
          TreasureCardState.locked: '🔒',
          TreasureCardState.rvNeeded: '📺',
          TreasureCardState.progressNeeded: '⏳',
        }[card.state] ?? '❓';
        print('  $stateIcon 卡片${card.index}: ${card.state.name.padRight(15)} | needLevel=${(card.needLevel?.toString() ?? "无").padRight(3)}');
      }
      print('[Treasure] ─────────────────────────────────────────────');
      print('[Treasure] 🔄 开始重新计算...');
    }
    
    final normalized = _recalcStates(currentCards);
    
    if (kDebugMode) {
      print('[Treasure] ─────────────────────────────────────────────');
      print('[Treasure] 📋 刷新后状态 (前5张):');
      for (var card in normalized.take(5)) {
        final stateIcon = {
          TreasureCardState.claimed: '✅',
          TreasureCardState.claimable: '🎁',
          TreasureCardState.locked: '🔒',
          TreasureCardState.rvNeeded: '📺',
          TreasureCardState.progressNeeded: '⏳',
        }[card.state] ?? '❓';
        print('  $stateIcon 卡片${card.index}: ${card.state.name.padRight(15)} | needLevel=${(card.needLevel?.toString() ?? "无").padRight(3)}');
      }
      
      // 检测状态变化
      var changedCount = 0;
      for (var i = 0; i < currentCards.length && i < normalized.length; i++) {
        if (currentCards[i].state != normalized[i].state) {
          changedCount++;
          if (changedCount <= 3) {  // 只显示前3个变化
            print('[Treasure] 🔄 卡片${normalized[i].index}状态变化: ${currentCards[i].state.name} -> ${normalized[i].state.name}');
          }
        }
      }
      if (changedCount > 0) {
        print('[Treasure] ✅ 共有 $changedCount 张卡片状态发生变化');
      } else {
        print('[Treasure] ℹ️  没有卡片状态发生变化');
      }
      print('╚═══════════════════════════════════════════════════════╝\n');
    }
    
    await _save(normalized);
    state = AsyncData(TreasureState(normalized));
  }
  
  /// 重置所有宝藏数据（调试用）
  Future<void> resetAll() async {
    if (kDebugMode) {
      print('[Treasure] 重置所有宝藏数据');
    }
    await _prefs.remove(_key);
    final defaults = _defaultCards();
    await _save(defaults);
    state = AsyncData(TreasureState(defaults));
  }

  Future<void> _save(List<TreasureCard> xs) async {
    final json = jsonEncode(xs.map((e) => e.toJson()).toList());
    await _prefs.setString(_key, json);
  }
}

final treasureProvider =
    AsyncNotifierProvider<TreasureController, TreasureState>(
        () => TreasureController());
