import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'outlined_text_widget.dart';

class GrilWaitingDialog extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  
  // 静态方法，方便直接调用
  static Future<bool?> show({
    required BuildContext context,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GrilWaitingDialog(
        onAccept: onAccept,
        onDecline: onDecline,
      ),
    );
  }

  const GrilWaitingDialog({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<GrilWaitingDialog> createState() => _GrilWaitingDialogState();
}

class _GrilWaitingDialogState extends State<GrilWaitingDialog> with SingleTickerProviderStateMixin {
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
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  Future<void> _launchPrivacyPolicy() async {
    const url = 'https://example.com/privacy-policy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchTeamStatement() async {
    const url = 'https://example.com/team-statement';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _handleAccept() {
    widget.onAccept();
  }

  void _handleDecline() {
    widget.onDecline();
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
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 背景
                Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(Assets.popPopAsk),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),

                // 内容
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Column(
                    children: [
                      // 标题
                      Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                          ),
                          child:  OutlinedTextWidget(
                            text: 'The girls are waiting',
                            fontSize: 34,
                            strokeColor: HexColor("#EA00FF"),
                            textColor: Colors.white,
                            strokeWidth: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // 内容区域
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 30),
                                OutlinedTextWidget(
                                  text: 'Spend hearts to hangout with them. Don\'t keep them waiting!',
                                  fontSize: 20,
                                  textColor: HexColor("#8C5D00"),
                                  strokeColor: Colors.transparent,
                                  strokeWidth: 1,
                                  fontWeight: FontWeight.normal,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.visible,
                                ),

                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 按钮区域
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 拒绝按钮
                            GestureDetector(
                              onTap: _handleDecline,
                              child: Container(
                                width: 100,
                                height: 40,
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(Assets.popPopBtnBlue),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                child: const Center(
                                  child: OutlinedTextWidget(
                                    text: 'NOT NOW',
                                    fontSize: 16,
                                    textColor: Colors.white,
                                    strokeColor: Colors.black,
                                    strokeWidth: 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            // 同意按钮
                            GestureDetector(
                              onTap: _handleAccept,
                              child: Container(
                                width: 100,
                                height: 40,
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(Assets.popPopBtnGreen),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                child: const Center(
                                  child: OutlinedTextWidget(
                                    text: 'GO!',
                                    fontSize: 16,
                                    textColor: Colors.white,
                                    strokeColor: Colors.black,
                                    strokeWidth: 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
