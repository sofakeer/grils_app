import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:grils_app/services/user_service.dart';

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

  const CommonHeader({
    super.key,
    this.onBackPressed,
    this.showBackButton = true,
  });

  @override
  State<CommonHeader> createState() => _CommonHeaderState();
}

class _CommonHeaderState extends State<CommonHeader> {
  late UserService _userService;

  @override
  void initState() {
    super.initState();
    _userService = UserService.instance;
    _userService.addListener(_onUserDataChanged);
  }

  @override
  void dispose() {
    _userService.removeListener(_onUserDataChanged);
    super.dispose();
  }

  void _onUserDataChanged() {
    if (mounted) {
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
                    // 金币显示
                    Stack(
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
                                Text(
                                  '${_userService.coinCount}',
                                  style: TextStyle(
                                    color: HexColor("#95756A"),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                Text(
                                  '${_userService.heartCount}',
                                  style: TextStyle(
                                    color: HexColor("#95756A"),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                // 返回按钮 - 使用指定图片
                if (widget.showBackButton)
                  GestureDetector(
                    onTap: widget.onBackPressed ?? () => Navigator.of(context).pop(),
                    child: Image.asset(
                      Assets.imagesBtnHeartBack,
                      height: 50,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 