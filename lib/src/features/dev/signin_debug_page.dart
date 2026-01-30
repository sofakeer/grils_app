import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/small_button.dart';
import '../signin/signin_dialog.dart';
import '../signin/signin_providers.dart';
import '../../utils/treasure_debug.dart';

class SignInDebugPage extends ConsumerWidget {
  const SignInDebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(signInProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign-In Debug')), 
      body: s.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (st) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('状态: 今天第 ${st.dayIndex}/7 天, 今日${st.claimedToday ? '已签' : '未签'}，累计 ${st.totalSignInDays} 天',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Row(children: [
                  ElevatedButton(onPressed: () => showSignInDialog(context), child: const Text('打开签到弹窗')),
                ]),
                const SizedBox(height: 12),
                const Text('今日状态', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  SmallButton(text: '重置', style: SmallButtonStyle.blue, size: SmallButtonSize.small, onPressed: () => ref.read(signInProvider.notifier).resetSignIn()),
                  SmallButton(text: '今日未签', style: SmallButtonStyle.blue, size: SmallButtonSize.small, onPressed: () => ref.read(signInProvider.notifier).debugSetClaimedToday(false)),
                  SmallButton(text: '今日已签', style: SmallButtonStyle.blue, size: SmallButtonSize.small, onPressed: () => ref.read(signInProvider.notifier).debugSetClaimedToday(true)),
                  SmallButton(text: '补签最早', style: SmallButtonStyle.green, size: SmallButtonSize.small, onPressed: () async {
                    final s = ref.read(signInProvider).value;
                    if (s != null) {
                      final cycleClaimed = s.totalSignInDays % 7;
                      // 找到第一个漏签天（cycleClaimed + 1 到 dayIndex - 1 之间的第一个）
                      for (int day = cycleClaimed + 1; day < s.dayIndex; day++) {
                        if (day >= 1 && day <= 7) {
                          await ref.read(signInProvider.notifier).claimMissed(day);
                          break;
                        }
                      }
                    }
                  }),
                  SmallButton(text: '领取日常', style: SmallButtonStyle.green, size: SmallButtonSize.small, onPressed: () => ref.read(signInProvider.notifier).claimDaily()),
                  SmallButton(
                    text: '模拟7天已领',
                    style: SmallButtonStyle.blue,
                    size: SmallButtonSize.small,
                    onPressed: () => ref.read(signInProvider.notifier).debugSimulateFullWeek(),
                  ),
                ]),
                const SizedBox(height: 12),
                const Text('今天是第 N 天', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final d in [1, 2, 3, 4, 5, 6, 7])
                    SmallButton(text: '第${d}天', style: SmallButtonStyle.blue, size: SmallButtonSize.small,
                      onPressed: () => ref.read(signInProvider.notifier).debugSetTodayIndex(d)),
                ]),
                const SizedBox(height: 12),
                const Text('累计天数定位', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final m in [0, 13, 14, 20, 21, 27, 28])
                    SmallButton(text: '$m天', style: SmallButtonStyle.blue, size: SmallButtonSize.small,
                      onPressed: () => ref.read(signInProvider.notifier).debugSetTotalDays(m)),
                ]),
                const SizedBox(height: 12),
                const Text('累计快捷操作', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  SmallButton(text: '累计+1天', style: SmallButtonStyle.green, size: SmallButtonSize.small,
                    onPressed: () => ref.read(signInProvider.notifier).debugAddTotalDays(1)),
                  SmallButton(text: '累计+7天', style: SmallButtonStyle.blue, size: SmallButtonSize.small,
                    onPressed: () => ref.read(signInProvider.notifier).debugAddTotalDays(7)),
                  SmallButton(text: '累计=14天', style: SmallButtonStyle.blue, size: SmallButtonSize.small,
                    onPressed: () => ref.read(signInProvider.notifier).debugSetTotalDays(14)),
                ]),
                const SizedBox(height: 12),
                const Text('领取里程碑', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  SmallButton(text: '领14天', style: SmallButtonStyle.blue, size: SmallButtonSize.small, onPressed: () => ref.read(signInProvider.notifier).claimCumulative(14)),
                  SmallButton(text: '领21天', style: SmallButtonStyle.blue, size: SmallButtonSize.small, onPressed: () => ref.read(signInProvider.notifier).claimCumulative(21)),
                  SmallButton(text: '领28天', style: SmallButtonStyle.blue, size: SmallButtonSize.small, onPressed: () => ref.read(signInProvider.notifier).claimCumulative(28)),
                ]),
                const SizedBox(height: 12),
                const Text('宝箱调试', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('测试宝箱重置：1.重置宝箱 2.模拟领卡0,1 3.系统时间+1天 4.刷新宝箱查看是否重置', 
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  SmallButton(
                    text: '重置宝箱',
                    style: SmallButtonStyle.blue,
                    size: SmallButtonSize.small,
                    onPressed: () => TreasureDebug.resetTreasure(ref),
                  ),
                  SmallButton(
                    text: '刷新宝箱',
                    style: SmallButtonStyle.blue,
                    size: SmallButtonSize.small,
                    onPressed: () => TreasureDebug.forceRefresh(ref),
                  ),
                  SmallButton(
                    text: '模拟领卡0',
                    style: SmallButtonStyle.green,
                    size: SmallButtonSize.small,
                    onPressed: () => TreasureDebug.simulateClaimCard(ref, 0),
                  ),
                  SmallButton(
                    text: '模拟领卡1',
                    style: SmallButtonStyle.green,
                    size: SmallButtonSize.small,
                    onPressed: () => TreasureDebug.simulateClaimCard(ref, 1),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }
}
