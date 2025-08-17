import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/managers/audio_manager.dart';
import 'package:grils_app/widgets/animated_popup.dart';
import 'package:grils_app/widgets/outlined_text_widget.dart';

/// 通用弹窗组件
/// 
/// 使用示例:
/// ```dart
/// CommonPopup.show(
///   context: context,
///   title: '提示',
///   content: '这是一个通用弹窗',
///   buttons: [
///     CommonPopupButton(
///       text: '确定',
///       onPressed: () => Navigator.pop(context),
///     ),
///   ],
/// );
/// ```
class CommonPopup extends StatefulWidget {
  final String title;
  final Widget? content;
  final List<CommonPopupButton> buttons;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final double? width;
  final double? height;
  final EdgeInsets? contentPadding;

  const CommonPopup({
    super.key,
    required this.title,
    this.content,
    this.buttons = const [],
    this.showCloseButton = true,
    this.onClose,
    this.width,
    this.height,
    this.contentPadding,
  });

  /// 显示通用弹窗
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    Widget? content,
    List<CommonPopupButton> buttons = const [],
    bool showCloseButton = true,
    VoidCallback? onClose,
    double? width,
    double? height,
    EdgeInsets? contentPadding,
    bool barrierDismissible = true,
  }) {
    return AnimatedPopup.show(
      context: context,
      barrierDismissible: barrierDismissible,
      child: CommonPopup(
        title: title,
        content: content,
        buttons: buttons,
        showCloseButton: showCloseButton,
        onClose: onClose,
        width: width,
        height: height,
        contentPadding: contentPadding,
      ),
    );
  }

  /// 显示确认弹窗
  static Future<bool> showConfirm({
    required BuildContext context,
    required String title,
    String content = '',
    String confirmText = '确定',
    String cancelText = '取消',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    double? width,
    double? height,
  }) async {
    bool? result = await show<bool>(
      context: context,
      title: title,
      content: content.isNotEmpty ? Text(content) : null,
      buttons: [
        CommonPopupButton(
          text: cancelText,
          type: CommonPopupButtonType.secondary,
          onPressed: () {
            Navigator.pop(context, false);
            onCancel?.call();
          },
        ),
        CommonPopupButton(
          text: confirmText,
          type: CommonPopupButtonType.primary,
          onPressed: () {
            Navigator.pop(context, true);
            onConfirm?.call();
          },
        ),
      ],
      width: width,
      height: height,
    );
    return result ?? false;
  }

  /// 显示提示弹窗
  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    String content = '',
    String buttonText = '确定',
    VoidCallback? onPressed,
    double? width,
    double? height,
  }) {
    return show(
      context: context,
      title: title,
      content: content.isNotEmpty ? Text(content) : null,
      buttons: [
        CommonPopupButton(
          text: buttonText,
          type: CommonPopupButtonType.primary,
          onPressed: () {
            Navigator.pop(context);
            onPressed?.call();
          },
        ),
      ],
      width: width,
      height: height,
    );
  }

  @override
  State<CommonPopup> createState() => _CommonPopupState();
}

class _CommonPopupState extends State<CommonPopup> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  void _closePopup() async {
    // 播放退出音效
    await AudioManager().playExit();
    
    if (mounted) {
      widget.onClose?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final popupWidth = widget.width ?? screenWidth * 0.85;
    final popupHeight = widget.height ?? screenHeight * 0.6;
    final contentPadding = widget.contentPadding ?? const EdgeInsets.all(30);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // 背景容器
        Container(
          width: popupWidth,
          height: popupHeight,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(Assets.imagesPopBack),
              fit: BoxFit.fill,
            ),
          ),
        ),

        // 内容区域
        Container(
          width: popupWidth,
          height: popupHeight,
          padding: contentPadding,
          child: Column(
            children: [
              // 标题区域
              const SizedBox(height: 40),
              OutlinedTextWidget(
                text: widget.title,
                fontSize: 30,
                textColor: Colors.white,
                strokeColor: Colors.black,
                strokeWidth: 7,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // 内容区域
              if (widget.content != null) ...[
                Expanded(
                  child: Center(
                    child: widget.content!,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 按钮区域
              if (widget.buttons.isNotEmpty) ...[
                ...widget.buttons.map((button) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: button,
                )),
              ],
            ],
          ),
        ),

        // 关闭按钮
        if (widget.showCloseButton)
          Positioned(
            top: -5,
            right: -25,
            child: GestureDetector(
              onTap: _closePopup,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 70,
                height: 70,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Center(
                  child: Image.asset(
                    Assets.imagesBtnClose,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 弹窗按钮类型
enum CommonPopupButtonType {
  primary,   // 主要按钮（绿色）
  secondary, // 次要按钮（蓝色）
  danger,    // 危险按钮（红色）
}

/// 弹窗按钮组件
class CommonPopupButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CommonPopupButtonType type;
  final double? width;
  final double? height;
  final bool enabled;

  const CommonPopupButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = CommonPopupButtonType.primary,
    this.width,
    this.height,
    this.enabled = true,
  });

  String _getButtonAsset() {
    switch (type) {
      case CommonPopupButtonType.primary:
        return Assets.settingSettingBtnGreen;
      case CommonPopupButtonType.secondary:
        return Assets.settingSettingBtnBlue;
      case CommonPopupButtonType.danger:
        return Assets.settingSettingBtnBlue; // 暂时使用蓝色，可以添加红色按钮资源
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: width ?? 200,
        height: height ?? 80,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_getButtonAsset()),
            fit: BoxFit.fill,
          ),
        ),
        child: Center(
          child: OutlinedTextWidget(
            text: text,
            fontSize: 20,
            textColor: enabled ? Colors.white : Colors.grey,
            strokeColor: Colors.black,
            strokeWidth: 5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
