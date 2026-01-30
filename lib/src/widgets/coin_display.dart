import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_image_app/generated/assets.dart';

import '../providers/app_providers.dart';

/// 统一金币展示组件，项目内所有金币显示应使用该组件。
class CoinDisplay extends ConsumerWidget {
  final int? coins;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final double iconSize;
  final double spacing;

  const CoinDisplay({
    super.key,
    this.coins,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.backgroundColor = const Color(0x80000000),
    this.textStyle,
    this.iconSize = 20,
    this.spacing = 4,
  });

  const CoinDisplay.plain({
    int? coins,
    TextStyle? textStyle,
    double iconSize = 20,
    double spacing = 4,
  }) : this(
          coins: coins,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.zero,
          backgroundColor: null,
          textStyle: textStyle,
          iconSize: iconSize,
          spacing: spacing,
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = coins ??
        ref.watch(userProgressProvider).maybeWhen(
              data: (progress) => progress.coins,
              orElse: () => 0,
            );

    final textStyleResolved = textStyle ??
        const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image(image: AssetImage(Assets.assetsImage36),height: 20,width: 20),
        SizedBox(width: spacing),
        Text(
          '$value',
          style: textStyleResolved,
        ),
      ],
    );

    if (backgroundColor == null) {
      return padding == EdgeInsets.zero
          ? row
          : Padding(padding: padding, child: row);
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: row,
    );
  }
}
