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
    final topPadding = MediaQuery.of(context).padding.top;
    
    if (coins > 0) {
      // 金币图标位置精确计算：
      // 外层容器左边距: 20px
      // 金币图标直接在Stack顶层，无额外边距
      // 金币图标大小: 50px，中心位置: 20 + 25 = 45px
      // 顶部位置: 外层容器顶部(topPadding + 10) + 金币图标中心(25) = topPadding + 35px
      final coinPosition = Offset(45, topPadding + 35);
      print("金币特效目标位置: $coinPosition");
      EffectManager.instance.playCoinEffect(context, targetPosition: coinPosition);
      await AudioManager().playCoinEffect();
      
      // 调试: 显示红点标记目标位置
      _showDebugDot(context, coinPosition, Colors.red);
    }
    if (hearts > 0) {
      // 爱心图标位置计算：
      // 金币完整宽度: 50px
      // 中间间距: 10px
      // 爱心Stack左边距: 10px (padding)
      // 爱心图标大小: 45px，中心位置: 20 + 50 + 10 + 10 + 22.5 = 112.5px
      // 顶部位置: 外层容器顶部(topPadding + 10) + 爱心padding(8) + 爱心图标中心(22.5) = topPadding + 40.5px
      final heartPosition = Offset(112.5, topPadding + 40.5);
      print("爱心特效目标位置: $heartPosition");
      EffectManager.instance.playHeartEffect(context, targetPosition: heartPosition);
      await AudioManager().playHeartEffect();
      
      // 调试: 显示蓝点标记目标位置
      _showDebugDot(context, heartPosition, Colors.blue);
    }
  }
  
  /// 调试用：显示目标位置红点
  static void _showDebugDot(BuildContext context, Offset position, Color color) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 5,
        top: position.dy - 5,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // 3秒后移除调试点
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
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
                    // // 特效测试按钮
                    // GestureDetector(
                    //   onTap: () {
                    //     // 测试特效
                    //     CommonHeader.playSignInEffects(context, 100, 10);
                    //   },
                    //   child: Container(
                    //     width: 30,
                    //     height: 30,
                    //     decoration: BoxDecoration(
                    //       color: Colors.green,
                    //       borderRadius: BorderRadius.circular(15),
                    //     ),
                    //     child: const Icon(
                    //       Icons.star,
                    //       color: Colors.white,
                    //       size: 16,
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(width: 5),
                    //
                    // // 调试按钮（临时添加）
                    // GestureDetector(
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => const UserServiceTestPage(),
                    //       ),
                    //     );
                    //   },
                    //   child: Container(
                    //     width: 30,
                    //     height: 30,
                    //     decoration: BoxDecoration(
                    //       color: Colors.blue,
                    //       borderRadius: BorderRadius.circular(15),
                    //     ),
                    //     child: const Icon(
                    //       Icons.bug_report,
                    //       color: Colors.white,
                    //       size: 16,
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(width: 10),
                    
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