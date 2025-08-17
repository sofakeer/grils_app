import 'package:flutter/material.dart';
import '../widgets/outlined_text_widget.dart';

/// 文字组件演示页面
class TextDemoPage extends StatelessWidget {
  const TextDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Outlined Text Demo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 游戏标题样式
            const SizedBox(height: 20),
            GameTextStyles.title('GAME TITLE'),
            const SizedBox(height: 30),

            // 基础描边文字
            const OutlinedTextWidget(
              text: 'Basic Outlined Text',
              fontSize: 24,
              textColor: Colors.yellow,
              strokeColor: Colors.red,
              strokeWidth: 2,
            ),
            const SizedBox(height: 20),

            // 发光效果
            OutlinedTextWidget.glow(
              text: 'Glowing Text',
              fontSize: 28,
              textColor: Colors.cyan,
              glowColor: Colors.blue,
              glowRadius: 15,
            ),
            const SizedBox(height: 20),

            // 多层阴影效果
            OutlinedTextWidget.multiShadow(
              text: 'Multi Shadow Text',
              fontSize: 24,
              textColor: Colors.white,
              strokeColor: Colors.purple,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),

            // 彩虹效果
            OutlinedTextWidget.rainbow(
              text: 'Rainbow Text',
              fontSize: 26,
              textColor: Colors.white,
            ),
            const SizedBox(height: 30),

            // 预设样式演示
            const Text(
              'Preset Styles:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // 按钮样式
            GameTextStyles.button('BUTTON TEXT'),
            const SizedBox(height: 15),

            // 分数样式
            GameTextStyles.score('SCORE: 99999'),
            const SizedBox(height: 15),

            // 提示样式
            GameTextStyles.hint('This is a hint message'),
            const SizedBox(height: 15),

            // 错误样式
            GameTextStyles.error('Error Message!'),
            const SizedBox(height: 15),

            // 成功样式
            GameTextStyles.success('Success Message!'),
            const SizedBox(height: 30),

            // 自定义颜色和大小
            const Text(
              'Custom Examples:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // 大号金色文字
            const OutlinedTextWidget(
              text: 'GOLDEN TEXT',
              fontSize: 32,
              textColor: Color(0xFFFFD700),
              strokeColor: Color(0xFF8B4513),
              strokeWidth: 3,
              fontWeight: FontWeight.w900,
            ),
            const SizedBox(height: 20),

            // 小号银色文字
            const OutlinedTextWidget(
              text: 'Silver Text',
              fontSize: 18,
              textColor: Color(0xFFC0C0C0),
              strokeColor: Color(0xFF696969),
              strokeWidth: 1.5,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 20),

            // 带字母间距的文字
            const OutlinedTextWidget(
              text: 'S P A C E D   T E X T',
              fontSize: 20,
              textColor: Colors.lime,
              strokeColor: Colors.green,
              strokeWidth: 2,
              letterSpacing: 2.0,
            ),
            const SizedBox(height: 20),

            // 多行文字
            const OutlinedTextWidget(
              text: 'This is a very long text that will wrap to multiple lines to demonstrate how the component handles text overflow and line breaks',
              fontSize: 16,
              textColor: Colors.orange,
              strokeColor: Colors.red,
              strokeWidth: 1.5,
              maxLines: 3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}