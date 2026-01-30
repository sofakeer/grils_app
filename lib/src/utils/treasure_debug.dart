import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/treasure/treasure_providers.dart';
import '../providers/level_providers.dart';

/// 宝藏调试工具类
class TreasureDebug {
  /// 打印当前宝藏完整状态
  static void printFullState(WidgetRef ref) {
    if (!kDebugMode) return;
    
    final treasureAsync = ref.read(treasureProvider);
    final currentLevel = ref.read(levelProvider).currentLevel;
    
    print('\n╔════════════════════════════════════════════════════════════════╗');
    print('║                  🔍 宝藏完整状态诊断                           ║');
    print('╚════════════════════════════════════════════════════════════════╝');
    print('⏰ 诊断时间: ${DateTime.now()}');
    print('📊 当前游戏关卡: LEVEL $currentLevel');
    print('');
    
    treasureAsync.when(
      loading: () => print('⏳ 宝藏数据加载中...'),
      error: (e, st) => print('❌ 宝藏数据加载错误: $e'),
      data: (state) {
        print('📦 宝藏卡片总数: ${state.cards.length}');
        print('');
        print('═══════════════════ 所有卡片详细信息 ═══════════════════');
        print('');
        
        for (var i = 0; i < state.cards.length; i++) {
          final card = state.cards[i];
          final stateIcon = _getStateIcon(card.state);
          
          print('┌─ 卡片 ${card.index} $stateIcon ─────────────────────────────');
          print('│ 类型: ${card.type.name}');
          if (card.type == TreasureRewardType.image) {
            print('│ 图片序号: ${card.imageSequence}');
          } else {
            print('│ 数量: ${card.amount}');
          }
          print('│ 状态: ${card.state.name} $stateIcon');
          print('│ 等级要求: ${card.needLevel ?? "无"}');
          print('│ 视频要求: ${card.needRv ?? "无"}');
          if (card.needRv != null) {
            print('│ 视频进度: ${card.rvProgress}/${card.needRv}');
          }
          
          // 分析为什么是当前状态
          print('│ 状态分析:');
          if (card.state == TreasureCardState.claimed) {
            print('│   ✅ 已领取');
          } else if (card.state == TreasureCardState.progressNeeded) {
            print('│   ⏳ 等待前置卡片完成');
            if (i > 0) {
              final prev = state.cards[i - 1];
              print('│   → 前置卡片${prev.index}状态: ${prev.state.name}');
            }
          } else if (card.state == TreasureCardState.locked) {
            print('│   🔒 已锁定');
            if (card.needLevel != null) {
              print('│   → 等级不足: 当前$currentLevel < 需要${card.needLevel}');
            }
          } else if (card.state == TreasureCardState.rvNeeded) {
            print('│   📺 需要观看视频');
            print('│   → 进度: ${card.rvProgress}/${card.needRv}');
          } else if (card.state == TreasureCardState.claimable) {
            print('│   🎁 可以领取！');
          }
          
          print('└──────────────────────────────────────────────────');
          print('');
        }
        
        // 统计信息
        final claimedCount = state.cards.where((c) => c.state == TreasureCardState.claimed).length;
        final claimableCount = state.cards.where((c) => c.state == TreasureCardState.claimable).length;
        final lockedCount = state.cards.where((c) => c.state == TreasureCardState.locked).length;
        final progressNeededCount = state.cards.where((c) => c.state == TreasureCardState.progressNeeded).length;
        final rvNeededCount = state.cards.where((c) => c.state == TreasureCardState.rvNeeded).length;
        
        print('═══════════════════ 统计摘要 ═══════════════════');
        print('✅ 已领取: $claimedCount');
        print('🎁 可领取: $claimableCount');
        print('🔒 已锁定: $lockedCount');
        print('⏳ 等待前置: $progressNeededCount');
        print('📺 需要视频: $rvNeededCount');
        print('');
        
        // 重点关注：找出第3张卡片（需要10级）
        final card3 = state.cards.firstWhere((c) => c.index == 3, orElse: () => state.cards.first);
        print('═══════════════════ 🔍 重点关注：卡片3 ═══════════════════');
        print('状态: ${card3.state.name} ${_getStateIcon(card3.state)}');
        print('类型: ${card3.type.name}');
        print('需要等级: ${card3.needLevel}');
        print('当前等级: $currentLevel');
        if (card3.needLevel != null) {
          if (currentLevel >= card3.needLevel!) {
            print('✅ 等级条件满足');
          } else {
            print('❌ 等级条件不满足 (差${card3.needLevel! - currentLevel}级)');
          }
        }
        
        // 检查前置卡片
        if (state.cards.length >= 2) {
          final card2 = state.cards.firstWhere((c) => c.index == 2, orElse: () => state.cards[1]);
          print('前置卡片2状态: ${card2.state.name} ${_getStateIcon(card2.state)}');
          if (card2.state == TreasureCardState.claimed) {
            print('✅ 前置条件满足');
          } else {
            print('❌ 前置条件不满足 (卡片2未完成)');
          }
        }
        print('');
      },
    );
    
    print('╚════════════════════════════════════════════════════════════════╝\n');
  }
  
  /// 测试关卡变化
  static Future<void> testLevelChange(WidgetRef ref, int newLevel) async {
    if (!kDebugMode) return;
    
    print('\n╔════════════════════════════════════════════════════════════════╗');
    print('║              🧪 测试关卡变化对宝藏的影响                       ║');
    print('╚════════════════════════════════════════════════════════════════╝');
    
    final oldLevel = ref.read(levelProvider).currentLevel;
    print('旧关卡: LEVEL $oldLevel');
    print('新关卡: LEVEL $newLevel');
    print('');
    
    print('📋 变化前的宝藏状态:');
    _printBriefState(ref);
    
    print('\n🔄 执行关卡变更...');
    final levelDelta = newLevel - oldLevel;
    if (levelDelta > 0) {
      await ref.read(levelProvider.notifier).addLevels(levelDelta);
    }
    
    print('✅ 关卡已更新到 LEVEL ${ref.read(levelProvider).currentLevel}');
    print('');
    
    print('🔄 刷新宝藏状态...');
    await ref.read(treasureProvider.notifier).refresh();
    
    print('\n📋 变化后的宝藏状态:');
    _printBriefState(ref);
    
    print('╚════════════════════════════════════════════════════════════════╝\n');
  }
  
  /// 强制刷新宝藏状态
  static Future<void> forceRefresh(WidgetRef ref) async {
    if (!kDebugMode) return;
    
    print('\n╔════════════════════════════════════════════════════════════════╗');
    print('║                  🔄 强制刷新宝藏状态                           ║');
    print('╚════════════════════════════════════════════════════════════════╝');
    
    await ref.read(treasureProvider.notifier).refresh();
    
    print('✅ 刷新完成');
    print('╚════════════════════════════════════════════════════════════════╝\n');
  }
  
  /// 重置宝藏数据
  static Future<void> resetTreasure(WidgetRef ref) async {
    if (!kDebugMode) return;
    
    print('\n╔════════════════════════════════════════════════════════════════╗');
    print('║                  ⚠️  重置宝藏数据                              ║');
    print('╚════════════════════════════════════════════════════════════════╝');
    
    await ref.read(treasureProvider.notifier).resetAll();
    
    print('✅ 重置完成，所有宝藏数据已清空并重新初始化');
    print('╚════════════════════════════════════════════════════════════════╝\n');
  }
  
  /// 模拟完成前置卡片
  static Future<void> simulateClaimCard(WidgetRef ref, int cardIndex) async {
    if (!kDebugMode) return;
    
    print('\n╔════════════════════════════════════════════════════════════════╗');
    print('║              🎁 模拟领取卡片 $cardIndex                         ║');
    print('╚════════════════════════════════════════════════════════════════╝');
    
    final treasureAsync = ref.read(treasureProvider);
    treasureAsync.whenData((state) {
      final card = state.cards.firstWhere((c) => c.index == cardIndex, orElse: () => state.cards.first);
      print('卡片状态: ${card.state.name}');
      if (card.state == TreasureCardState.claimable) {
        print('✅ 可以领取，执行领取...');
        ref.read(treasureProvider.notifier).claim(cardIndex);
      } else {
        print('❌ 不能领取，当前状态: ${card.state.name}');
      }
    });
    
    print('╚════════════════════════════════════════════════════════════════╝\n');
  }
  
  /// 打印简要状态
  static void _printBriefState(WidgetRef ref) {
    final treasureAsync = ref.read(treasureProvider);
    final currentLevel = ref.read(levelProvider).currentLevel;
    
    treasureAsync.whenData((state) {
      print('当前关卡: LEVEL $currentLevel');
      print('前5张卡片:');
      for (var card in state.cards.take(5)) {
        final icon = _getStateIcon(card.state);
        print('  $icon 卡片${card.index}: ${card.state.name.padRight(15)} | needLevel=${(card.needLevel?.toString() ?? "无").padRight(3)}');
      }
    });
  }
  
  /// 获取状态图标
  static String _getStateIcon(TreasureCardState state) {
    switch (state) {
      case TreasureCardState.claimed:
        return '✅';
      case TreasureCardState.claimable:
        return '🎁';
      case TreasureCardState.locked:
        return '🔒';
      case TreasureCardState.rvNeeded:
        return '📺';
      case TreasureCardState.progressNeeded:
        return '⏳';
    }
  }
}

