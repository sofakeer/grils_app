import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import '../../generated/assets.dart';

/// 黑色文字按钮组件
class BlackTextButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool isSelected;
  final bool useImageBackground;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final double? iconSize;

  const BlackTextButton({
    super.key,
    required this.text,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.width,
    this.height,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.borderRadius,
    this.isSelected = false,
    this.useImageBackground = false,
    this.leftIcon,
    this.rightIcon,
    this.iconSize,
  });

  @override
  State<BlackTextButton> createState() => _BlackTextButtonState();
}

class _BlackTextButtonState extends State<BlackTextButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: _isPressed ? (Matrix4.identity()..scale(0.95)) : Matrix4.identity(),
        child: widget.useImageBackground
            ? _buildImageBackgroundButton()
            : _buildColorBackgroundButton(),
      ),
    );
  }

  Widget _buildImageBackgroundButton() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(25),
              child: Image.asset(
                (widget.isSelected || _isPressed)
                    ? Assets.assetsIcLongBtnBgSelected2x
                    : Assets.assetsIcLongBtnBg2x,
                fit: BoxFit.contain, // 改为 contain 避免裁切
                width: widget.width,
                height: widget.height,
              ),
            ),
          ),
          // 文字内容
          Positioned.fill(
            child: Center(
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 左侧图标
                    if (widget.leftIcon != null) ...[
                      widget.leftIcon!,
                      const SizedBox(width: 8),
                    ],
                    // 文字
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: widget.fontSize ?? 16,
                        fontWeight: widget.fontWeight ?? FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // 右侧图标
                    if (widget.rightIcon != null) ...[
                      const SizedBox(width: 8),
                      widget.rightIcon!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorBackgroundButton() {
    return Container(
      width: widget.width,
      height: widget.height ?? 50,
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(25),
        border: widget.borderColor != null
            ? Border.all(
                color: widget.borderColor!,
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 左侧图标
            if (widget.leftIcon != null) ...[
              widget.leftIcon!,
              const SizedBox(width: 8),
            ],
            // 文字
            Text(
              widget.text,
              style: TextStyle(
                color: Colors.black,
                fontSize: widget.fontSize ?? 16,
                fontWeight: widget.fontWeight ?? FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            // 右侧图标
            if (widget.rightIcon != null) ...[
              const SizedBox(width: 8),
              widget.rightIcon!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 预设样式的黑色文字按钮
class BlackTextButtonStyle {
  // 基础样式
  static Widget basic({
    required String text,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return BlackTextButton(
      text: text,
      onTap: onTap,
      width: width,
      height: height,
    );
  }

  // 带边框样式
  static Widget outlined({
    required String text,
    VoidCallback? onTap,
    Color borderColor = Colors.black,
    double? width,
    double? height,
  }) {
    return BlackTextButton(
      text: text,
      onTap: onTap,
      backgroundColor: Colors.transparent,
      borderColor: borderColor,
      width: width,
      height: height,
    );
  }

  // 绿色背景样式
  static Widget green({
    required String text,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return BlackTextButton(
      text: text,
      onTap: onTap,
      backgroundColor: HexColor('#00ff88'),
      width: width,
      height: height,
    );
  }

  // 蓝色背景样式
  static Widget blue({
    required String text,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return BlackTextButton(
      text: text,
      onTap: onTap,
      backgroundColor: HexColor('#4ECDC4'),
      width: width,
      height: height,
    );
  }

  // 橙色背景样式
  static Widget orange({
    required String text,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return BlackTextButton(
      text: text,
      onTap: onTap,
      backgroundColor: HexColor('#FF6B6B'),
      width: width,
      height: height,
    );
  }

  // 紫色背景样式
  static Widget purple({
    required String text,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return BlackTextButton(
      text: text,
      onTap: onTap,
      backgroundColor: HexColor('#9370DB'),
      width: width,
      height: height,
    );
  }

  // 小尺寸样式
  static Widget small({
    required String text,
    VoidCallback? onTap,
    Color? backgroundColor,
    double? width,
  }) {
    return BlackTextButton(
      text: text,
      onTap: onTap,
      backgroundColor: backgroundColor,
      width: width,
      height: 32,
      fontSize: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    );
  }

  // 大尺寸样式
  static Widget large({
    required String text,
    VoidCallback? onTap,
    Color? backgroundColor,
    double? width,
  }) {
    return BlackTextButton(
      text: text,
      onTap: onTap,
      backgroundColor: backgroundColor,
      width: width,
      height: 60,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );
  }

  // 圆形样式
  static Widget circular({
    required String text,
    VoidCallback? onTap,
    Color? backgroundColor,
    double size = 50,
  }) {
    return BlackTextButton(
      text: text,
      onTap: onTap,
      backgroundColor: backgroundColor,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }

  // 方形样式
  static Widget square({
    required String text,
    VoidCallback? onTap,
    Color? backgroundColor,
    double size = 50,
  }) {
    return BlackTextButton(
      text: text,
      onTap: onTap,
      backgroundColor: backgroundColor,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(8),
    );
  }

  // 使用背景图片的样式
  static Widget withImageBackground({
    required String text,
    VoidCallback? onTap,
    bool isSelected = false,
    double? width,
    double? height,
  }) {
    return BlackTextButton(
      text: text,
      onTap: onTap,
      useImageBackground: true,
      isSelected: isSelected,
      width: width,
      height: height,
    );
  }

  // 选中状态的图片背景按钮
  static Widget selectedImageBackground({
    required String text,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return BlackTextButton(
      text: text,
      onTap: onTap,
      useImageBackground: true,
      isSelected: true,
      width: width,
      height: height,
    );
  }

  // 普通状态的图片背景按钮
  static Widget normalImageBackground({
    required String text,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return BlackTextButton(
      text: text,
      onTap: onTap,
      useImageBackground: true,
      isSelected: false,
      width: width,
      height: height,
    );
  }

  // 带播放图标的图片背景按钮
  static Widget withPlayIcon({
    required String text,
    VoidCallback? onTap,
    double? width,
    double? height,
    double? iconSize,
  }) {
    return BlackTextButton(
      text: text,
      onTap: onTap,
      useImageBackground: true,
      isSelected: false,
      width: width,
      height: height,
      leftIcon: Image.asset(
        Assets.assetsIcPlayBlack2x,
        width: iconSize ?? 24,
        height: iconSize ?? 24,
      ),
    );
  }
}
