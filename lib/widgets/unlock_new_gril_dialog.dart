import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'outlined_text_widget.dart';

class UnlockNewGrilDialog extends StatefulWidget {
  final int girlIndex; // 新解锁的女生索引 (0, 1, 2)
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const UnlockNewGrilDialog({
    super.key,
    required this.girlIndex,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<UnlockNewGrilDialog> createState() => _UnlockNewGrilDialogState();
}

class _UnlockNewGrilDialogState extends State<UnlockNewGrilDialog> with SingleTickerProviderStateMixin {
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
  
  // 获取女生头像路径
  String _getGirlImagePath() {
    switch (widget.girlIndex) {
      case 0:
        return 'assets/grils/Icon_girl_01_head_unlock.png';
      case 1:
        return 'assets/grils/Icon_girl_02_head_unlock.png';
      case 2:
        return 'assets/grils/Icon_girl_03_head_unlock.png';
      default:
        return 'assets/grils/Icon_girl_01_head_unlock.png';
    }
  }
  
  // 获取女生名称
  String _getGirlName() {
    switch (widget.girlIndex) {
      case 0:
        return 'Girl 01';
      case 1:
        return 'Girl 02';
      case 2:
        return 'Girl 03';
      default:
        return 'Girl';
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
                            text: 'Unlock New Girl!',
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
                                // 新解锁的女生头像
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: HexColor("#EA00FF"),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: HexColor("#EA00FF").withOpacity(0.5),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      _getGirlImagePath(),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // 女生名称
                                OutlinedTextWidget(
                                  text: _getGirlName(),
                                  fontSize: 28,
                                  textColor: Colors.yellow,
                                  strokeColor: HexColor("#8C5D00"),
                                  strokeWidth: 2,
                                  fontWeight: FontWeight.bold,
                                ),
                                const SizedBox(height: 20),
                                OutlinedTextWidget(
                                  text: 'By clicking Yes, you acknowledge and agree to our',
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
                                    text: 'GO！',
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
