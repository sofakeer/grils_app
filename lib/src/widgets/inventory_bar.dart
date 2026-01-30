import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

typedef ItemUseCallback = Future<bool> Function();

class InventoryBar extends ConsumerWidget {
  final ItemUseCallback? onUndo;
  final ItemUseCallback? onReminder;
  final ItemUseCallback? onPipe;
  const InventoryBar({super.key, this.onUndo, this.onReminder, this.onPipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final up = ref.watch(userProgressProvider);
    return up.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (u) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ItemChip(
                icon: 'assets/spin/undo_small.png',
                count: u.undo,
                onTap: onUndo,
              ),
              const SizedBox(width: 8),
              _ItemChip(
                icon: 'assets/spin/reminder_small.png',
                count: u.reminder,
                onTap: onReminder,
              ),
              const SizedBox(width: 8),
              _ItemChip(
                icon: 'assets/spin/tube_small.png',
                count: u.pipe,
                onTap: onPipe,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemChip extends StatelessWidget {
  final String icon;
  final int count;
  final ItemUseCallback? onTap;
  const _ItemChip({required this.icon, required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = count <= 0 || onTap == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: InkWell(
        onTap: disabled
            ? null
            : () async {
                final ok = await onTap!();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? '使用成功' : '不可使用'),
                ));
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withOpacity(0.1)),
          child: Row(
            children: [
              Image.asset(icon, width: 20, height: 20),
              const SizedBox(width: 6),
              Text('x$count', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

