import 'package:flutter/material.dart';

class CustomImageButton extends StatefulWidget {
  final String normalImagePath;
  final String pressedImagePath;
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Duration animationDuration;

  const CustomImageButton({
    super.key,
    required this.normalImagePath,
    required this.pressedImagePath,
    required this.child,
    this.onPressed,
    this.width,
    this.height,
    this.padding,
    this.animationDuration = const Duration(milliseconds: 100),
  });

  @override
  State<CustomImageButton> createState() => _CustomImageButtonState();
}

class _CustomImageButtonState extends State<CustomImageButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
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

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: widget.padding,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    _isPressed ? widget.pressedImagePath : widget.normalImagePath,
                  ),
                  fit: BoxFit.fill,
                ),
              ),
              child: Center(child: widget.child),
            ),
          );
        },
      ),
    );
  }
}
