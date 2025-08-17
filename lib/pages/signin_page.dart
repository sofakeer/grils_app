import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../widgets/animated_popup.dart';
import '../widgets/effect_animations.dart';
import '../widgets/outlined_text_widget.dart';
import '../widgets/common_header.dart';
import '../managers/audio_manager.dart';
import '../managers/ad_manager.dart';
import '../managers/effect_manager.dart';
import '../services/user_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  // 添加静态方法用于显示弹窗
  static Future<void> showSignInDialog(BuildContext context) async {
    await AudioManager().playCheckIn();
    return AnimatedPopup.show(
      context: context,
      child: const SignInPage(),
      barrierDismissible: false, // 点击背景不关闭
    );
  }

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  int _currentDay = 1; // 当前签到天数 (1-7)
  List<bool> _signedDays = List.filled(7, false); // 签到状态
  DateTime? _lastSignInDate;
  bool _canSignToday = true;
  bool _showSuccessOverlay = false; // 是否显示签到成功覆盖层
  int _successDay = 0; // 签到成功的天数
  // 奖励配置
  final List<Map<String, dynamic>> _rewards = [
    {'day': 1, 'coins': 100, 'hearts': 0},
    {'day': 2, 'coins': 150, 'hearts': 0},
    {'day': 3, 'coins': 0, 'hearts': 10},
    {'day': 4, 'coins': 200, 'hearts': 0},
    {'day': 5, 'coins': 0, 'hearts': 15},
    {'day': 6, 'coins': 300, 'hearts': 0},
    {'day': 7, 'coins': 500, 'hearts': 20}, // 第7天双奖励
  ];
  

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSignInData();
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

  Future<void> _loadSignInData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final lastSignInDateString = prefs.getString('last_signin_date');
    
    if (mounted) {
      setState(() {
        _currentDay = prefs.getInt('signin_current_day') ?? 1;
        
        if (lastSignInDateString != null) {
          _lastSignInDate = DateTime.parse(lastSignInDateString);
          
          // 检查是否是新的一天
          if (_lastSignInDate != null) {
            final daysDifference = today.difference(_lastSignInDate!).inDays;
            
            if (daysDifference == 0) {
              // 今天已经签到过了
              _canSignToday = false;
              _signedDays[_currentDay - 1] = true;
            } else if (daysDifference > 1) {
              // 断签了，重置到第1天
              _currentDay = 1;
              _signedDays = List.filled(7, false);
              _canSignToday = true;
            }
          }
        }
        
        // 加载已签到的天数状态
        for (int i = 0; i < 7; i++) {
          _signedDays[i] = prefs.getBool('signed_day_$i') ?? false;
        }
      });
    }
  }

  Future<void> _saveSignInData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    
    await prefs.setInt('signin_current_day', _currentDay);
    await prefs.setString('last_signin_date', today.toIso8601String());
    
    // 保存每天的签到状态
    for (int i = 0; i < 7; i++) {
      await prefs.setBool('signed_day_$i', _signedDays[i]);
    }
  }

  Future<void> _updateUserCurrency(int coins, int hearts) async {
    final userService = UserService.instance;
    if (coins > 0) {
      await userService.addCoins(coins);
    }
    if (hearts > 0) {
      await userService.addHearts(hearts);
    }
  }

  void _signIn({bool doubleReward = false}) async {
    if (!_canSignToday) return;
    
    final reward = _rewards[_currentDay - 1];
    int coins = reward['coins'] as int;
    int hearts = reward['hearts'] as int;
    
    if (doubleReward) {
      coins *= 2;
      hearts *= 2;
    }
    
    setState(() {
      _signedDays[_currentDay - 1] = true;
      _canSignToday = false;
      _showSuccessOverlay = true; // 显示成功覆盖层
      _successDay = _currentDay; // 记录签到成功的天数
    });
    
    // 更新货币
    await _updateUserCurrency(coins, hearts);
    
    // 保存签到数据
    await _saveSignInData();
    
    // 延迟2秒后隐藏覆盖层并关闭弹窗
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _showSuccessOverlay = false;
      });
      
      // 如果是第7天，重置到第1天
      if (_currentDay == 7) {
        setState(() {
          _currentDay = 1;
          _signedDays = List.filled(7, false);
        });
      } else {
        setState(() {
          _currentDay++;
        });
      }
      
      // 关闭签到弹窗
      Navigator.of(context).pop();
      
      // 延迟播放特效，确保弹窗已关闭
      await Future.delayed(const Duration(milliseconds: 100));
      _playSignInEffects(coins, hearts);
    }
  }

  void _signInWithAd() async {
    if (!_canSignToday) return;

    // 显示广告
    final adSuccess = await AdManager.instance.showRewardedAd(
      context: context,
      onAdCompleted: () {
        print("签到广告播放完成");
      },
      onAdFailed: () {
        print("签到广告播放失败");
      },
    );

    if (adSuccess) {
      // 广告播放成功，给予双倍奖励
      _signIn(doubleReward: true);
    }
  }

  void _playSignInEffects(int coins, int hearts) async {
    // 使用CommonHeader的静态方法播放特效
    await CommonHeader.playSignInEffects(context, coins, hearts);
  }

  void _close() async {
    await AudioManager().playExit();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 主签到界面
        AnimatedBuilder(
          animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Center(
                  child: Stack(
                    children: [
                      // 背景
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: 530,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(Assets.signSignFrameBg),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                      // 内容
                      Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 465,
                        child: Column(
                          children: [
                            const SizedBox(height: 30,),
                            // 标题
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 35),
                              child: OutlinedTextWidget(
                                text: 'SIGN',
                                fontSize: 25,
                                textColor: Colors.white,
                                strokeColor: HexColor("#D802E4"),
                                strokeWidth: 6,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // 签到格子
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  children: [
                                    // 前6天，每行3个
                                    Expanded(
                                      flex: 2,
                                      child: GridView.builder(
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          childAspectRatio: 0.9,
                                          crossAxisSpacing: 15,
                                          mainAxisSpacing: 15,
                                        ),
                                        itemCount: 6,
                                        itemBuilder: (context, index) {
                                          return _buildSignInDay(index + 1);
                                        },
                                      ),
                                    ),
                                    // 第7天单独一行，宽度匹配
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        width: double.infinity,
                                        child: _buildSignInDay(7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // // 签到按钮区域
                            // Container(
                            //   padding: EdgeInsets.symmetric(vertical: 30),
                            //   child: _canSignToday
                            //     ? Row(
                            //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            //         children: [
                            //           // 普通签到
                            //           GestureDetector(
                            //             onTap: () => _signIn(doubleReward: false),
                            //             child: Container(
                            //               width: 120,
                            //               height: 50,
                            //               decoration: BoxDecoration(
                            //                 image: DecorationImage(
                            //                   image: AssetImage(Assets.popPopBtnGreen),
                            //                   fit: BoxFit.fill,
                            //                 ),
                            //               ),
                            //               child: Center(
                            //                 child: OutlinedTextWidget(
                            //                   text: 'GET',
                            //                   fontSize: 18,
                            //                   textColor: Colors.white,
                            //                   strokeColor: Colors.black,
                            //                   strokeWidth: 1.5,
                            //                   fontWeight: FontWeight.bold,
                            //                 ),
                            //               ),
                            //             ),
                            //           ),
                            //
                            //           // 双倍签到
                            //           GestureDetector(
                            //             onTap: () => _signIn(doubleReward: true),
                            //             child: Container(
                            //               width: 120,
                            //               height: 50,
                            //               decoration: BoxDecoration(
                            //                 image: DecorationImage(
                            //                   image: AssetImage(Assets.signSignBtnDouble),
                            //                   fit: BoxFit.fill,
                            //                 ),
                            //               ),
                            //               child: Center(
                            //                 child: Row(
                            //                   mainAxisAlignment: MainAxisAlignment.center,
                            //                   children: [
                            //                     Icon(
                            //                       Icons.play_arrow,
                            //                       color: Colors.white,
                            //                       size: 16,
                            //                     ),
                            //                     SizedBox(width: 5),
                            //                     OutlinedTextWidget(
                            //                       text: 'x2',
                            //                       fontSize: 16,
                            //                       textColor: Colors.white,
                            //                       strokeColor: Colors.black,
                            //                       strokeWidth: 1.0,
                            //                       fontWeight: FontWeight.bold,
                            //                     ),
                            //                   ],
                            //                 ),
                            //               ),
                            //             ),
                            //           ),
                            //         ],
                            //       )
                            //     : Container(
                            //         padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            //         decoration: BoxDecoration(
                            //           color: Colors.grey,
                            //           borderRadius: BorderRadius.circular(25),
                            //         ),
                            //         child: OutlinedTextWidget(
                            //           text: '今日已签到',
                            //           fontSize: 18,
                            //           textColor: Colors.white,
                            //           strokeColor: Colors.grey,
                            //           strokeWidth: 1.0,
                            //           fontWeight: FontWeight.bold,
                            //         ),
                            //       ),
                            // ),
                          ],
                        ),
                      ),

                      // 关闭按钮
                      Positioned(
                        top: MediaQuery.of(context).size.height * 0.1 - 20,
                        right: MediaQuery.of(context).size.width * 0.05 - 20,
                        child: GestureDetector(
                          onTap: _close,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(Assets.signSignBtnClose),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 签到按钮区域
                      if (_canSignToday)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // DOUBLE按钮（看广告获得双倍奖励）
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: _signInWithAd,
                                    child: Container(
                                      width: 150,
                                      height: 60,
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
                                          const OutlinedTextWidget(
                                            text: 'DOUBLE',
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
                              const SizedBox(height: 10),
                              // GET按钮（单倍奖励）
                              GestureDetector(
                                onTap: () => _signIn(doubleReward: false),
                                child: const OutlinedTextWidget(
                                  text: 'GET',
                                  fontSize: 16,
                                  textColor: Colors.white,
                                  strokeColor: Colors.black,
                                  strokeWidth: 2,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                  decorationThickness: 5,
                                ),
                              ),
                            ],
                          ),
                        )
                        // 已签到状态
                        // Positioned(
                        //   bottom: 20,
                        //   left: 0,
                        //   right: 0,
                        //   child: Center(
                        //     child: Container(
                        //       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        //       decoration: BoxDecoration(
                        //         color: Colors.grey,
                        //         borderRadius: BorderRadius.circular(25),
                        //       ),
                        //       child: const OutlinedTextWidget(
                        //         text: '今日已签到',
                        //         fontSize: 18,
                        //         textColor: Colors.white,
                        //         strokeColor: Colors.grey,
                        //         strokeWidth: 1.0,
                        //         fontWeight: FontWeight.bold,
                        //       ),
                        //     ),
                        //   ),
                        // ),

                    ],
                  ),
                ),
              );
            },
          ),

        ],
    );
  }

  Widget _buildSignInDay(int day) {
    final reward = _rewards[day - 1];
    final isSigned = _signedDays[day - 1];
    final isToday = day == _currentDay;
    final isDay7 = day == 7;
    final isShowingSuccess = _showSuccessOverlay && _successDay == day;
    
    // 基础背景框架
    String baseFrameAsset;
    if (isDay7) {
      if (isToday) {
        baseFrameAsset = Assets.signSignFrameDay7Selected;
      } else {
        baseFrameAsset = Assets.signSignFrameDay7Normal;
      }
    } else {
      if (isToday) {
        baseFrameAsset = Assets.signSignFrameDaySelected;
      } else {
        baseFrameAsset = Assets.signSignFrameDayNormal;
      }
    }

    return Stack(
      children: [
        // 基础背景
        Container(
          width: isDay7 ? double.infinity: 110,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(baseFrameAsset),
              fit: BoxFit.fill,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 8,),
            if (!isDay7)
              // 天数
              OutlinedTextWidget(
                text: 'Day $day',
                fontSize: 12,
                textColor: Colors.white,
                strokeColor: Colors.black,
                strokeWidth: 2,
                fontWeight: FontWeight.bold,
              ),

              const SizedBox(height: 5),

              // 第7天特殊布局 - 水平展示双奖励，宽度匹配
              if (isDay7 && reward['coins'] > 0 && reward['hearts'] > 0) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 金币奖励
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(Assets.mainMainIconCoin, height: 55),
                          const SizedBox(width: 3),
                          OutlinedTextWidget(
                            text: 'X${reward['coins']}',
                            fontSize: 18,
                            textColor: HexColor("#FBFF1D"),
                            strokeColor: Colors.black,
                            strokeWidth: 3.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),

                      // 爱心奖励
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(Assets.imagesIconHeart2x, height: 55),
                          const SizedBox(width: 3),
                          OutlinedTextWidget(
                            text: 'X${reward['hearts']}',
                            fontSize: 18,
                            textColor: HexColor("#FBFF1D"),
                            strokeColor: Colors.black,
                            strokeWidth: 3.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // 普通天的奖励显示
                if (reward['coins'] > 0) ...[
                  Image.asset(
                    Assets.mainMainIconCoin,
                    height: 30,
                  ),
                  const SizedBox(
                    height: 5
                  ),
                  OutlinedTextWidget(
                    text: 'X${reward['coins']}',
                    fontSize: 15,
                    textColor: HexColor("#FF9B9B"),
                    strokeColor: Colors.black,
                    strokeWidth: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ],

                if (reward['hearts'] > 0) ...[
                  Image.asset(
                    Assets.imagesIconHeart2x,
                    height: 30,
                  ),
                  const SizedBox(
                    height: 5
                  ),
                  OutlinedTextWidget(
                    text: 'X${reward['hearts']}',
                    fontSize: 15,
                    textColor: HexColor("#FF9B9B"),
                    strokeColor: Colors.black,
                    strokeWidth: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ],
            ],
          ),
        ),
        
        // 签到成功覆盖层
        if (isSigned || isShowingSuccess)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    isDay7 ? Assets.signSignFrameDay7Finish : Assets.signSignFrameDayFinish
                  ),
                  fit: BoxFit.fitWidth, // 使用fitWidth适配宽度
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

}