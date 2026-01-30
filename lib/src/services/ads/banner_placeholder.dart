import 'package:flutter/material.dart';

/// 全局可用的 Banner 占位组件。
/// 用法：在页面底部/顶部放置 [DummyBannerAd] 即可。
class DummyBannerAd extends StatelessWidget {
  final double height;
  final String placement;
  const DummyBannerAd({super.key, this.height = 50, this.placement = 'banner'});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3)),
            child: const Text('AD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Text('Banner Placeholder  •  $placement', style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
}

