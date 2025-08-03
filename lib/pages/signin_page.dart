import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  // 添加静态方法用于显示弹窗
  static Future<void> showSignInDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false, // 点击背景不关闭
      builder: (BuildContext context) {
        return const SignInPage();
      },
    );
  }

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _rewardAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rewardScaleAnimation;
  
  int _currentDay = 1; // 当前签到天数 (1-7)
  List<bool> _signedDays = List.filled(7, false); // 签到状态
  DateTime? _lastSignInDate;
  bool _canSignToday = true;
  bool _showRewardDialog = false;
  
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
  
  int _rewardCoins = 0;
  int _rewardHearts = 0;
  bool _isDoubleReward = false;

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
    
    _rewardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _rewardScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rewardAnimationController,
      curve: Curves.bounceOut,
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
    final prefs = await SharedPreferences.getInstance();
    final currentCoins = prefs.getInt('coin_count') ?? 1000;
    final currentHearts = prefs.getInt('heart_count') ?? 50;
    
    await prefs.setInt('coin_count', currentCoins + coins);
    await prefs.setInt('heart_count', currentHearts + hearts);
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
      _rewardCoins = coins;
      _rewardHearts = hearts;
      _isDoubleReward = doubleReward;
      _showRewardDialog = true;
    });
    
    // 更新货币
    await _updateUserCurrency(coins, hearts);
    
    // 保存签到数据
    await _saveSignInData();
    
    // 显示奖励动画
    _rewardAnimationController.forward();
    
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
  }

  void _closeRewardDialog() {
    _rewardAnimationController.reverse().then((_) {
      setState(() {
        _showRewardDialog = false;
      });
    });
  }

  void _close() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rewardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // 主签到界面
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 背景
                      Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.8,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(Assets.signSignFrameBg),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),

                      // 内容
                      Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Column(
                          children: [
                            // 标题
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 35),
                              child: Text(
                                'SIGN',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      offset: Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 签到格子
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  children: [
                                    // 前6天，每行3个
                                    Expanded(
                                      flex: 2,
                                      child: GridView.builder(
                                        physics: NeverScrollableScrollPhysics(),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                                    
                                    SizedBox(height: 20),
                                    
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

                            // 签到按钮区域
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: _canSignToday 
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // 普通签到
                                      GestureDetector(
                                        onTap: () => _signIn(doubleReward: false),
                                        child: Container(
                                          width: 120,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: AssetImage(Assets.popPopBtnGreen),
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'GET',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // 双倍签到
                                      GestureDetector(
                                        onTap: () => _signIn(doubleReward: true),
                                        child: Container(
                                          width: 120,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: AssetImage(Assets.signSignBtnDouble),
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 5),
                                                Text(
                                                  'x2',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(
                                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Text(
                                      '今日已签到',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                            ),
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
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(Assets.signSignBtnClose),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 奖励弹窗
          if (_showRewardDialog) _buildRewardDialog(),
        ],
      ),
    );
  }

  Widget _buildSignInDay(int day) {
    final reward = _rewards[day - 1];
    final isSigned = _signedDays[day - 1];
    final isToday = day == _currentDay;
    final isDay7 = day == 7;
    
    String frameAsset;
    if (isDay7) {
      if (isSigned) {
        frameAsset = Assets.signSignFrameDay7Finish;
      } else if (isToday) {
        frameAsset = Assets.signSignFrameDay7Selected;
      } else {
        frameAsset = Assets.signSignFrameDay7Normal;
      }
    } else {
      if (isSigned) {
        frameAsset = Assets.signSignFrameDayFinish;
      } else if (isToday) {
        frameAsset = Assets.signSignFrameDaySelected;
      } else {
        frameAsset = Assets.signSignFrameDayNormal;
      }
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(frameAsset),
          fit: BoxFit.fill,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        if (!isDay7)
          // 天数
          Text(
            'Day $day',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.white : Colors.black,
            ),
          ),
          
          SizedBox(height: 5),
          
          // 第7天特殊布局 - 水平展示双奖励，宽度匹配
          if (isDay7 && reward['coins'] > 0 && reward['hearts'] > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 金币奖励
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(Assets.mainMainIconCoin, height: 45),
                    SizedBox(width: 3),
                    Text(
                      'X${reward['coins']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: HexColor("#FBFF1D"),
                      ),
                    ),
                  ],
                ),
                
                // 爱心奖励
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(Assets.imagesIconHeart2x, height: 35),
                    SizedBox(width: 3),
                    Text(
                      'X${reward['hearts']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: HexColor("#FBFF1D"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            // 普通天的奖励显示
            if (reward['coins'] > 0) ...[
              Image.asset(
                Assets.mainMainIconCoin,
                height: 20,
              ),
              Text(
                'X${reward['coins']}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: HexColor("#FF9B9B"),
                ),
              ),
            ],
            
            if (reward['hearts'] > 0) ...[
              Image.asset(
                Assets.imagesIconHeart2x,
                height: 20,
              ),
              Text(
                '+${reward['hearts']}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.white : Colors.black,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRewardDialog() {
    return AnimatedBuilder(
      animation: _rewardScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _rewardScaleAnimation.value,
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Assets.popPopBtnBlue),
                  fit: BoxFit.fill,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 标题
                  Text(
                    _isDoubleReward ? '双倍奖励!' : '签到成功!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: HexColor("#8B4513"),
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // 奖励显示
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_rewardCoins > 0) ...[
                        Image.asset(Assets.mainMainIconCoin, height: 50),
                        SizedBox(width: 10),
                        Text(
                          '+$_rewardCoins',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: HexColor("#FFD700"),
                          ),
                        ),
                        if (_rewardHearts > 0) SizedBox(width: 30),
                      ],
                      
                      if (_rewardHearts > 0) ...[
                        Image.asset(Assets.imagesIconHeart2x, height: 50),
                        SizedBox(width: 10),
                        Text(
                          '+$_rewardHearts',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: HexColor("#FF69B4"),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  SizedBox(height: 40),
                  
                  // 确认按钮
                  GestureDetector(
                    onTap: _closeRewardDialog,
                    child: Container(
                      width: 120,
                      height: 50,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(Assets.popPopBtnGreen),
                          fit: BoxFit.fill,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '确认',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}