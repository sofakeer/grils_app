import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/widgets/animated_popup.dart';
import 'package:grils_app/services/user_service.dart';
import 'package:grils_app/managers/audio_manager.dart';
import 'package:hexcolor/hexcolor.dart';
import 'outlined_text_widget.dart';

/// 金币不足弹窗组件
class InsufficientCoinsDialog extends StatefulWidget {
  final String title;
  final int requiredCoins;
  final VoidCallback? onGetPressed;

  const InsufficientCoinsDialog({
    super.key,
    this.title = 'More Coin',
    required this.requiredCoins,
    this.onGetPressed,
  });

  /// 显示金币不足弹窗
  static Future<bool?> show({
    required BuildContext context,
    String title = 'More Coin',
    required int requiredCoins,
    VoidCallback? onGetPressed,
  }) {
    return AnimatedPopup.show<bool>(
      context: context,
      child: InsufficientCoinsDialog(
        title: title,
        requiredCoins: requiredCoins,
        onGetPressed: onGetPressed,
      ),
      barrierDismissible: true,
    );
  }

  @override
  State<InsufficientCoinsDialog> createState() => _InsufficientCoinsDialogState();
}

class _InsufficientCoinsDialogState extends State<InsufficientCoinsDialog> with SingleTickerProviderStateMixin {
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

  void _closeDialog() async {
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 300,
                height: 250,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(Assets.imagesPopBack),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    OutlinedTextWidget(
                      text: widget.title,
                      fontSize: 24,
                      textColor: Colors.white,
                      strokeColor: Colors.black,
                      strokeWidth: 3,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 200,
                      padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: HexColor("#f0dab6"),
                          width: 2,
                        ),
                        color: HexColor("#ecdabc"),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            Assets.mainMainIconCoin,
                            height: 50,
                          ),
                          const SizedBox(width: 10),
                          OutlinedTextWidget(
                            text: 'X 100',
                            fontSize: 25,
                            textColor: Colors.white,
                            strokeColor: HexColor("#760E0E"),
                            strokeWidth: 4,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: () async {
                        // 播放金币获得音效
                        await AudioManager().playCoinEffect();
                        
                        // 固定增加100金币（观看广告奖励）
                        final userService = UserService.instance;
                        await userService.addCoins(100);
                        
                        // 返回true表示获得了金币，可以尝试购买
                        Navigator.of(context).pop(true);
                        widget.onGetPressed?.call();
                      },
                      child: Container(
                        width: 120,
                        height: 50,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(Assets.shopShopBtnBuy),
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              Assets.imagesLabelAd,
                              height: 30,
                            ),
                            const SizedBox(width: 10),
                            OutlinedTextWidget(
                              text: 'GET',
                              fontSize: 16,
                              textColor: Colors.white,
                              strokeColor: Colors.black,
                              strokeWidth: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 右上角关闭按钮
              Positioned(
                top: -30,
                right: -25,
                child: GestureDetector(
                  onTap: _closeDialog,
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
          ),
        );
      },
    );
  }
}
