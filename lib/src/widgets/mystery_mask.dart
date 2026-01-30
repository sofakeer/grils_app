import 'package:flutter/material.dart';

/// 神秘遮罩组件
/// 用于通行证和套图弹窗，遮盖未解锁的图片
class MysteryMask extends StatelessWidget {
  final Widget child;
  final bool showMask;
  final String? maskText;

  const MysteryMask({
    super.key,
    required this.child,
    required this.showMask,
    this.maskText,
  });

  @override
  Widget build(BuildContext context) {
    if (!showMask) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Colors.white.withOpacity(0.8),
                    size: 40,
                  ),
                  if (maskText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      maskText!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
