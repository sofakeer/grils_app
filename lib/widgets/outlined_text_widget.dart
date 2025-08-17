import 'package:flutter/material.dart';

/// 可自定义描边的文字组件
/// 支持自定义字体、颜色、大小、描边宽度等
class OutlinedTextWidget extends StatelessWidget {
  /// 要显示的文字内容
  final String text;

  /// 文字大小
  final double fontSize;

  /// 文字颜色（填充颜色）
  final Color textColor;

  /// 描边颜色
  final Color strokeColor;

  /// 描边宽度
  final double strokeWidth;

  /// 字体粗细
  final FontWeight fontWeight;

  /// 文字对齐方式
  final TextAlign textAlign;

  /// 最大行数
  final int? maxLines;

  /// 文字溢出处理
  final TextOverflow overflow;

  /// 字体家族（默认使用Anja-Eliane字体）
  final String fontFamily;

  /// 文字阴影效果
  final List<Shadow>? shadows;

  /// 字母间距
  final double? letterSpacing;

  /// 行高
  final double? height;

  /// 文字装饰（如下划线）
  final TextDecoration? decoration;

  /// 装饰颜色
  final Color? decorationColor;

  /// 装饰样式
  final TextDecorationStyle? decorationStyle;

  /// 装饰粗细
  final double? decorationThickness;

  const OutlinedTextWidget({
    super.key,
    required this.text,
    this.fontSize = 24.0,
    this.textColor = Colors.white,
    this.strokeColor = Colors.black,
    this.strokeWidth = 2.0,
    this.fontWeight = FontWeight.bold,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.fontFamily = 'Anja-Eliane',
    this.shadows,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.decorationThickness,
  });

  /// 创建发光效果的文字
  factory OutlinedTextWidget.glow({
    required String text,
    double fontSize = 24.0,
    Color textColor = Colors.white,
    Color glowColor = Colors.blue,
    double glowRadius = 10.0,
    FontWeight fontWeight = FontWeight.bold,
    TextAlign textAlign = TextAlign.center,
    int? maxLines,
    String fontFamily = 'Anja-Eliane',
  }) {
    return OutlinedTextWidget(
      text: text,
      fontSize: fontSize,
      textColor: textColor,
      strokeColor: Colors.transparent,
      strokeWidth: 0,
      fontWeight: fontWeight,
      textAlign: textAlign,
      maxLines: maxLines,
      fontFamily: fontFamily,
      shadows: [
        Shadow(
          color: glowColor,
          offset: const Offset(0, 0),
          blurRadius: glowRadius,
        ),
        Shadow(
          color: glowColor.withOpacity(0.8),
          offset: const Offset(0, 0),
          blurRadius: glowRadius * 0.7,
        ),
        Shadow(
          color: glowColor.withOpacity(0.6),
          offset: const Offset(0, 0),
          blurRadius: glowRadius * 0.4,
        ),
      ],
    );
  }

  /// 创建多层阴影效果的文字
  factory OutlinedTextWidget.multiShadow({
    required String text,
    double fontSize = 24.0,
    Color textColor = Colors.white,
    Color strokeColor = Colors.black,
    double strokeWidth = 2.0,
    FontWeight fontWeight = FontWeight.bold,
    TextAlign textAlign = TextAlign.center,
    int? maxLines,
    String fontFamily = 'Anja-Eliane',
  }) {
    return OutlinedTextWidget(
      text: text,
      fontSize: fontSize,
      textColor: textColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      fontWeight: fontWeight,
      textAlign: textAlign,
      maxLines: maxLines,
      fontFamily: fontFamily,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.8),
          offset: const Offset(2, 2),
          blurRadius: 4,
        ),
        Shadow(
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(4, 4),
          blurRadius: 8,
        ),
      ],
    );
  }

  /// 创建彩虹色描边效果
  factory OutlinedTextWidget.rainbow({
    required String text,
    double fontSize = 24.0,
    Color textColor = Colors.white,
    FontWeight fontWeight = FontWeight.bold,
    TextAlign textAlign = TextAlign.center,
    int? maxLines,
    String fontFamily = 'Anja-Eliane',
  }) {
    return OutlinedTextWidget(
      text: text,
      fontSize: fontSize,
      textColor: textColor,
      strokeColor: Colors.transparent,
      strokeWidth: 0,
      fontWeight: fontWeight,
      textAlign: textAlign,
      maxLines: maxLines,
      fontFamily: fontFamily,
      shadows: [
        Shadow(
          color: Colors.red,
          offset: const Offset(-2, -2),
          blurRadius: 3,
        ),
        Shadow(
          color: Colors.orange,
          offset: const Offset(2, -2),
          blurRadius: 3,
        ),
        Shadow(
          color: Colors.yellow,
          offset: const Offset(2, 2),
          blurRadius: 3,
        ),
        Shadow(
          color: Colors.green,
          offset: const Offset(-2, 2),
          blurRadius: 3,
        ),
        Shadow(
          color: Colors.blue,
          offset: const Offset(0, 0),
          blurRadius: 6,
        ),
      ],
    );
  }

  /// 创建带下划线的链接样式文字
  factory OutlinedTextWidget.link({
    required String text,
    double fontSize = 16.0,
    Color textColor = Colors.blue,
    Color underlineColor = Colors.blue,
    FontWeight fontWeight = FontWeight.w500,
    TextAlign textAlign = TextAlign.center,
    int? maxLines,
    String fontFamily = 'Anja-Eliane',
  }) {
    return OutlinedTextWidget(
      text: text,
      fontSize: fontSize,
      textColor: textColor,
      strokeColor: Colors.transparent,
      strokeWidth: 0,
      fontWeight: fontWeight,
      textAlign: textAlign,
      maxLines: maxLines,
      fontFamily: fontFamily,
      decoration: TextDecoration.underline,
      decorationColor: underlineColor,
      decorationStyle: TextDecorationStyle.solid,
      decorationThickness: 1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 描边层
        if (strokeWidth > 0)
          Text(
            text,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontFamily: fontFamily,
              letterSpacing: letterSpacing,
              height: height,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = strokeWidth
                ..color = strokeColor,
              decoration: decoration,
              decorationColor: decorationColor,
              decorationStyle: decorationStyle,
              decorationThickness: decorationThickness,
            ),
          ),
        
        // 文字填充层
        Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
            color: textColor,
            letterSpacing: letterSpacing,
            height: height,
            shadows: shadows,
            decoration: decoration,
            decorationColor: decorationColor,
            decorationStyle: decorationStyle,
            decorationThickness: decorationThickness,
          ),
        ),
      ],
    );
  }
}

/// 预设样式的常用文字组件
class GameTextStyles {
  static const String _fontFamily = 'Anja-Eliane';

  /// 游戏标题样式
  static OutlinedTextWidget title(String text) {
    return OutlinedTextWidget(
      text: text,
      fontSize: 36.0,
      textColor: Colors.white,
      strokeColor: Colors.black,
      strokeWidth: 3.0,
      fontWeight: FontWeight.bold,
      fontFamily: _fontFamily,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.8),
          offset: const Offset(3, 3),
          blurRadius: 6,
        ),
      ],
    );
  }

  /// 按钮文字样式
  static OutlinedTextWidget button(String text, {Color? color}) {
    return OutlinedTextWidget(
      text: text,
      fontSize: 20.0,
      textColor: color ?? Colors.white,
      strokeColor: Colors.black,
      strokeWidth: 2.0,
      fontWeight: FontWeight.bold,
      fontFamily: _fontFamily,
    );
  }

  /// 分数样式
  static OutlinedTextWidget score(String text) {
    return OutlinedTextWidget.glow(
      text: text,
      fontSize: 28.0,
      textColor: Colors.yellow,
      glowColor: Colors.orange,
      glowRadius: 8.0,
      fontFamily: _fontFamily,
    );
  }

  /// 提示文字样式
  static OutlinedTextWidget hint(String text) {
    return OutlinedTextWidget(
      text: text,
      fontSize: 16.0,
      textColor: Colors.white,
      strokeColor: Colors.black54,
      strokeWidth: 1.5,
      fontWeight: FontWeight.w600,
      fontFamily: _fontFamily,
    );
  }

  /// 错误提示样式
  static OutlinedTextWidget error(String text) {
    return OutlinedTextWidget.glow(
      text: text,
      fontSize: 18.0,
      textColor: Colors.white,
      glowColor: Colors.red,
      glowRadius: 12.0,
      fontFamily: _fontFamily,
    );
  }

  /// 成功提示样式
  static OutlinedTextWidget success(String text) {
    return OutlinedTextWidget.glow(
      text: text,
      fontSize: 18.0,
      textColor: Colors.white,
      glowColor: Colors.green,
      glowRadius: 12.0,
      fontFamily: _fontFamily,
    );
  }
}