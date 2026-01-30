import 'package:flutter/material.dart';
import '../../generated/assets.dart';

/// 自定义小按钮组件
/// 支持图标、文字、不同样式和点击效果
class SmallButton extends StatefulWidget {
  /// 按钮文字
  final String? text;

  /// 图标路径
  final String? iconPath;

  /// 图标大小
  final double iconSize;

  /// 自定义宽度
  final double? width;

  /// 自定义高度
  final double? height;

  /// 按钮样式
  final SmallButtonStyle style;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 是否启用
  final bool enabled;

  /// 按钮大小
  final SmallButtonSize size;

  /// 自定义背景色
  final Color? backgroundColor;

  /// 自定义文字颜色
  final Color? textColor;

  /// 自定义图标颜色
  final Color? iconColor;

  /// 是否显示加载状态
  final bool isLoading;

  /// 圆角大小
  final double borderRadius;

  /// 是否使用图片背景
  final bool useImageBackground;

  /// 背景图片路径
  final String? backgroundImagePath;

  const SmallButton({
    super.key,
    this.text,
    this.iconPath,
    this.iconSize = 16.0,
    this.width,
    this.height,
    this.style = SmallButtonStyle.green,
    this.onPressed,
    this.enabled = true,
    this.size = SmallButtonSize.medium,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.isLoading = false,
    this.borderRadius = 8.0,
    this.useImageBackground = false,
    this.backgroundImagePath,
  });

  @override
  State<SmallButton> createState() => _SmallButtonState();
}

class _SmallButtonState extends State<SmallButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && !widget.isLoading) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonConfig = _getButtonConfig();

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.enabled && !widget.isLoading ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height ?? buttonConfig.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: widget.useImageBackground
                  ? _buildImageBackgroundButton(buttonConfig)
                  : _buildColorBackgroundButton(buttonConfig),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageBackgroundButton(ButtonConfig buttonConfig) {
    return Stack(
      children: [
        // 背景图片
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Image.asset(
              widget.backgroundImagePath ?? _getDefaultBackgroundImage(),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // 内容
        Positioned.fill(
          child: Padding(
            padding: buttonConfig.padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: widget.iconSize,
                    height: widget.iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.textColor ?? buttonConfig.textColor,
                      ),
                    ),
                  ),
                  if (widget.text != null) const SizedBox(width: 6),
                ] else if (widget.iconPath != null) ...[
                  Image.asset(
                    widget.iconPath!,
                    width: widget.iconSize,
                    height: widget.iconSize,
                    color: widget.iconColor,
                  ),
                  if (widget.text != null) const SizedBox(width: 2),
                ],
                if (widget.text != null)
                  Flexible(
                    child: Text(
                      widget.text!,
                      style: TextStyle(
                        color: widget.textColor ?? _getTextColor(),
                        fontSize: buttonConfig.fontSize,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorBackgroundButton(ButtonConfig buttonConfig) {
    return Container(
      padding: buttonConfig.padding,
      decoration: BoxDecoration(
        color: _isPressed
            ? buttonConfig.pressedColor
            : buttonConfig.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.isLoading) ...[
            SizedBox(
              width: widget.iconSize,
              height: widget.iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.textColor ?? buttonConfig.textColor,
                ),
              ),
            ),
            if (widget.text != null) const SizedBox(width: 6),
          ] else if (widget.iconPath != null) ...[
            Image.asset(
              widget.iconPath!,
              width: widget.iconSize,
              height: widget.iconSize,
              color: widget.iconColor,
            ),
            if (widget.text != null) const SizedBox(width: 3),
          ],
          if (widget.text != null)
            Flexible(
              child: Text(
                widget.text!,
                style: TextStyle(
                  color: widget.textColor ?? _getTextColor(),
                  fontSize: buttonConfig.fontSize,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }

  String _getDefaultBackgroundImage() {
    switch (widget.style) {
      case SmallButtonStyle.green:
        return Assets.assetsIcBtnSmallGreen2x; // 绿色小按钮图片
      case SmallButtonStyle.blue:
        return Assets.assetsIcBtnSmallBlue2x; // 蓝色小按钮图片
      case SmallButtonStyle.completed:
        return Assets.assetsIcBtnSmallGreen2x;
      case SmallButtonStyle.claimable:
        return Assets.assetsIcBtnSmallGreen2x;
    }
  }

  ButtonConfig _getButtonConfig() {
    switch (widget.size) {
      case SmallButtonSize.small:
        return ButtonConfig(
          height: 27,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          fontSize: 12,
          backgroundColor: _getBackgroundColor(),
          pressedColor: _getPressedColor(),
          textColor: _getTextColor(),
        );
      case SmallButtonSize.medium:
        return ButtonConfig(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          fontSize: 14,
          backgroundColor: _getBackgroundColor(),
          pressedColor: _getPressedColor(),
          textColor: _getTextColor(),
        );
      case SmallButtonSize.large:
        return ButtonConfig(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          fontSize: 16,
          backgroundColor: _getBackgroundColor(),
          pressedColor: _getPressedColor(),
          textColor: _getTextColor(),
        );
    }
  }

  Color _getBackgroundColor() {
    if (widget.backgroundColor != null) return widget.backgroundColor!;

    switch (widget.style) {
      case SmallButtonStyle.green:
        return const Color(0xFF4CAF50); // 绿色
      case SmallButtonStyle.blue:
        return const Color(0xFF2196F3); // 蓝色
      case SmallButtonStyle.completed:
        return const Color(0xFF6F7374); // 已完成状态
      case SmallButtonStyle.claimable:
        return const Color(0xFF10EC9F); // 可领取状态
    }
  }

  Color _getPressedColor() {
    if (widget.backgroundColor != null) {
      // 自定义背景色时，按下去稍微加深
      return Color.lerp(widget.backgroundColor!, Colors.black, 0.2)!;
    }

    switch (widget.style) {
      case SmallButtonStyle.green:
        return const Color(0xFF388E3C); // 深绿色
      case SmallButtonStyle.blue:
        return const Color(0xFF1976D2); // 深蓝色
      case SmallButtonStyle.completed:
        return const Color(0xFF5A6268); // 深灰色
      case SmallButtonStyle.claimable:
        return const Color(0xFF388E3C); // 深绿色
    }
  }

  Color _getTextColor() {
    if (widget.textColor != null) return widget.textColor!;

    switch (widget.style) {
      case SmallButtonStyle.green:
        return Colors.white;
      case SmallButtonStyle.blue:
        return Colors.white;
      case SmallButtonStyle.completed:
        return Colors.white;
      case SmallButtonStyle.claimable:
        return Colors.black;
    }
  }
}

/// 按钮样式枚举
enum SmallButtonStyle {
  green,
  blue,
  completed, // 已完成状态
  claimable, // 可领取状态
}

/// 按钮大小枚举
enum SmallButtonSize {
  small,
  medium,
  large,
}

/// 按钮配置类
class ButtonConfig {
  final double height;
  final EdgeInsets padding;
  final double fontSize;
  final Color backgroundColor;
  final Color pressedColor;
  final Color textColor;

  const ButtonConfig({
    required this.height,
    required this.padding,
    required this.fontSize,
    required this.backgroundColor,
    required this.pressedColor,
    required this.textColor,
  });
}

/// SmallButton 便捷创建方法
class SmallButtonHelper {
  /// 创建带图片背景的蓝色按钮
  static Widget blueImageBackground({
    required String text,
    VoidCallback? onPressed,
    double? width,
    double? height,
    String? iconPath,
    double iconSize = 16.0,
    Color? textColor = Colors.white,
  }) {
    return SmallButton(
      text: text,
      onPressed: onPressed,
      width: width,
      height: height,
      iconPath: iconPath,
      iconSize: iconSize,
      textColor: textColor,
      style: SmallButtonStyle.blue,
      useImageBackground: true,
      backgroundImagePath: Assets.assetsIcBtnSmallBlue2x,
    );
  }

  /// 创建带图片背景的绿色按钮
  static Widget greenImageBackground({
    required String text,
    VoidCallback? onPressed,
    double? width,
    double? height,
    String? iconPath,
    double iconSize = 16.0,
    Color? textColor = Colors.black,
  }) {
    return SmallButton(
      text: text,
      onPressed: onPressed,
      width: width,
      height: height,
      iconPath: iconPath,
      iconSize: iconSize,
      textColor: textColor,
      style: SmallButtonStyle.green,
      useImageBackground: true,
      backgroundImagePath: Assets.assetsIcBtnSmallGreen2x,
    );
  }
}
