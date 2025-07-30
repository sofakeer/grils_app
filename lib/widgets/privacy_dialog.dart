import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';

class PrivacyDialog extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const PrivacyDialog({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<PrivacyDialog> createState() => _PrivacyDialogState();
}

class _PrivacyDialogState extends State<PrivacyDialog>
    with SingleTickerProviderStateMixin {
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
    _animationController.reverse().then((_) {
      widget.onAccept();
    });
  }

  void _handleDecline() {
    _animationController.reverse().then((_) {
      widget.onDecline();
    });
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
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(Assets.imagesPopPopFrameMiddle),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),

                // 内容
                Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Column(
                    children: [
                      // 标题
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          '隐私协议',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: HexColor("#8B4513"),
                          ),
                        ),
                      ),

                      // 内容区域
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '欢迎使用我们的应用！',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: HexColor("#4A4A4A"),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  '为了提供更好的服务体验，我们需要收集并使用您的一些信息。请仔细阅读以下条款：',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: HexColor("#666666"),
                                    height: 1.5,
                                  ),
                                ),
                                SizedBox(height: 15),
                                Text(
                                  '• 我们会收集设备信息以优化游戏性能\n'
                                  '• 游戏进度和设置会保存在本地\n'
                                  '• 我们不会收集个人敏感信息\n'
                                  '• 您可以随时在设置中管理隐私选项',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: HexColor("#666666"),
                                    height: 1.5,
                                  ),
                                ),
                                SizedBox(height: 20),
                                
                                // 链接区域
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GestureDetector(
                                      onTap: _launchPrivacyPolicy,
                                      child: Text(
                                        '隐私协议',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _launchTeamStatement,
                                      child: Text(
                                        '团队声明',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 按钮区域
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 拒绝按钮
                            GestureDetector(
                              onTap: _handleDecline,
                              child: Container(
                                width: 100,
                                height: 40,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(Assets.imagesPopPopBtnBlue),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '拒绝',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(Assets.imagesPopPopBtnGreen),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '同意',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
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