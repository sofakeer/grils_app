import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:grils_app/services/user_service.dart';
import 'package:grils_app/debug/user_service_test.dart';
import 'package:grils_app/managers/effect_manager.dart';
import 'package:grils_app/managers/audio_manager.dart';

import 'outlined_text_widget.dart';

/// 公共头部组件
/// 
/// 使用示例:
/// ```dart
/// CommonHeader(
///   title: '相册',
///   onBackPressed: () => Navigator.pop(context),
/// )
/// ```
/// 
/// 参数说明:
/// - title: 页面标题（可选）
/// - onBackPressed: 返回按钮回调（可选，默认调用Navigator.pop）
/// - showBackButton: 是否显示返回按钮（默认为true）
class CommonHeader extends StatefulWidget {
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final bool settingsButton;

  const CommonHeader({
    super.key,
    this.onBackPressed,
    this.showBackButton = true,
    this.settingsButton = false,
  });

  /// 播放签到奖励特效
  static Future<void> playSignInEffects(BuildContext context, int coins, int hearts) async {
    if (coins > 0) {
      EffectManager.instance.playCoinEffect(context);
      await AudioManager().playCoinEffect();
    }
    if (hearts > 0) {
      EffectManager.instance.playHeartEffect(context);
      await AudioManager().playHeartEffect();
    }
  }

  @override
  State<CommonHeader> createState() => _CommonHeaderState();
}

class _CommonHeaderState extends State<CommonHeader> with TickerProviderStateMixin {
  late UserService _userService;
  late AnimationController _coinAnimationController;
  late Animation<double> _coinScaleAnimation;
  int _previousCoinCount = 0;

  @override
  void initState() {
    super.initState();
    _userService = UserService.instance;
    _initializeUserService();
    
    // 初始化金币动画
    _coinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _coinScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _coinAnimationController,
      curve: Curves.elasticOut,
    ));
  }
  
  void _initializeUserService() async {
    print("CommonHeader: 初始化UserService");
    await _userService.initialize();
    _previousCoinCount = _userService.coinCount;
    _userService.addListener(_onUserDataChanged);
    print("CommonHeader: 初始金币数量: $_previousCoinCount");
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _userService.removeListener(_onUserDataChanged);
    _coinAnimationController.dispose();
    super.dispose();
  }

  void _onUserDataChanged() {
    print("CommonHeader: _onUserDataChanged called");
    if (mounted) {
      final currentCoinCount = _userService.coinCount;
      print("CommonHeader: 当前金币: $currentCoinCount, 之前金币: $_previousCoinCount");
      
      // 如果金币数量变化，触发动画
      if (currentCoinCount != _previousCoinCount) {
        print("CommonHeader: 金币数量变化: $_previousCoinCount -> $currentCoinCount");
        _coinAnimationController.forward().then((_) {
          _coinAnimationController.reverse();
        });
        _previousCoinCount = currentCoinCount;
      }
      
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 10,
      ),
      child: Stack(
        children: [
          // 内容层 - 调整位置让图标盖住顶部横条
          Positioned(
            top: 0, // 让内容稍微向上，盖住顶部横条
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // 金币显示 - 添加动画
                    AnimatedBuilder(
                      animation: _coinScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _coinScaleAnimation.value,
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 15,top: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: HexColor("#FFF5E5"),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(width: 30,),
                                      OutlinedTextWidget(
                                       text: '${_userService.coinCount}',
                                        textColor: HexColor("#95756A"),
                                        strokeWidth: 0,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Image.asset(
                                Assets.mainMainIconCoin,
                                height: 50,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 10),

                    // 爱心显示
                    Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10, top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 2),
                            decoration: BoxDecoration(
                              color: HexColor("#FFF5E5"),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 30,),
                                OutlinedTextWidget(
                                  text:'${_userService.heartCount}',
                                  textColor: HexColor("#95756A"),
                                  fontSize: 18,
                                  strokeWidth: 0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Image.asset(
                          Assets.imagesIconHeart2x,
                          height: 45,
                        ),
                      ],
                    ),
                  ],
                ),
                // 按钮区域
                Row(
                  children: [
                    // 调试按钮（临时添加）
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserServiceTestPage(),
                          ),
                        );
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.bug_report,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    
                    // 返回按钮 - 使用指定图片
                    if (widget.showBackButton)
                      GestureDetector(
                        onTap: widget.onBackPressed ?? () => Navigator.of(context).pop(),
                        child: Image.asset(
                         widget.settingsButton ? Assets.mainMainBtnSetting : Assets.imagesBtnHeartBack,
                          height: 50,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 