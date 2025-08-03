import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _switchAnimationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _switchAnimation;
  
  bool _isTubeSelected = true; // true为TUBE标签，false为BALL标签
  int _selectedItemIndex = -1; // 当前选中的商品索引
  
  int _coinCount = 1000;
  
  // 瓶子皮肤配置 (按照你的要求排列)
  final List<Map<String, dynamic>> _tubeSkins = [
    {'id': 'tube1', 'name': 'Tube 1', 'price': 0, 'unlocked': true},
    {'id': 'tube2', 'name': 'Tube 2', 'price': 100, 'unlocked': false},
    {'id': 'tube3', 'name': 'Tube 3', 'price': 300, 'unlocked': false},
    {'id': 'tube4', 'name': 'Tube 4', 'price': 500, 'unlocked': false},
    {'id': 'tube5', 'name': 'Tube 5', 'price': 1000, 'unlocked': false},
    {'id': 'tube6', 'name': 'Tube 6', 'price': 800, 'unlocked': false},
  ];
  
  // 小球皮肤配置 (按照你的要求排列)
  final List<Map<String, dynamic>> _ballSkins = [
    {'id': 'ball1', 'name': 'Ball 1', 'price': 0, 'unlocked': true},
    {'id': 'ball2', 'name': 'Ball 2', 'price': 50, 'unlocked': false},
    {'id': 'ball3', 'name': 'Ball 3', 'price': 300, 'unlocked': false},
    {'id': 'ball4', 'name': 'Ball 4', 'price': 200, 'unlocked': false},
    {'id': 'ball5', 'name': 'Ball 5', 'price': 800, 'unlocked': false},
    {'id': 'ball6', 'name': 'Ball 6', 'price': 500, 'unlocked': false},
    {'id': 'ball7', 'name': 'Ball 7', 'price': 1000, 'unlocked': false},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
    _loadPurchaseData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _switchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _switchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _switchAnimationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _coinCount = prefs.getInt('coin_count') ?? 1000;
      });
    }
  }

  Future<void> _loadPurchaseData() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (mounted) {
      setState(() {
        // 加载瓶子皮肤解锁状态
        for (int i = 0; i < _tubeSkins.length; i++) {
          final skinId = _tubeSkins[i]['id'];
          _tubeSkins[i]['unlocked'] = prefs.getBool('skin_unlocked_$skinId') ?? (i == 0);
        }
        
        // 加载小球皮肤解锁状态
        for (int i = 0; i < _ballSkins.length; i++) {
          final skinId = _ballSkins[i]['id'];
          _ballSkins[i]['unlocked'] = prefs.getBool('skin_unlocked_$skinId') ?? (i == 0);
        }
      });
    }
  }

  Future<void> _savePurchaseData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 保存瓶子皮肤解锁状态
    for (var skin in _tubeSkins) {
      await prefs.setBool('skin_unlocked_${skin['id']}', skin['unlocked']);
    }
    
    // 保存小球皮肤解锁状态
    for (var skin in _ballSkins) {
      await prefs.setBool('skin_unlocked_${skin['id']}', skin['unlocked']);
    }
  }

  Future<void> _updateCoinCount(int newCount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coin_count', newCount);
    setState(() {
      _coinCount = newCount;
    });
  }

  void _switchTab(bool isTube) {
    if (_isTubeSelected != isTube) {
      setState(() {
        _isTubeSelected = isTube;
        _selectedItemIndex = -1; // 重置选中状态
      });
      
      _switchAnimationController.forward().then((_) {
        _switchAnimationController.reset();
      });
    }
  }

  void _selectItem(int index) {
    setState(() {
      _selectedItemIndex = index;
    });
  }

  void _purchaseItem(int index) async {
    final currentSkins = _isTubeSelected ? _tubeSkins : _ballSkins;
    final skin = currentSkins[index];
    final price = skin['price'] as int;
    
    if (skin['unlocked']) {
      // 已经解锁的皮肤
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('该皮肤已解锁'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_coinCount < price) {
      // 金币不足
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('金币不足！需要 $price 金币'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // 执行购买
    setState(() {
      skin['unlocked'] = true;
    });
    
    await _updateCoinCount(_coinCount - price);
    await _savePurchaseData();
    
    // 显示购买成功
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('购买成功！${skin['name']} 已解锁'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _close() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _switchAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, MediaQuery.of(context).size.height * _slideAnimation.value),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Assets.shopShopBg),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // 主要内容区域
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 20,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Column(
                      children: [
                        // 标题和金币显示
                        _buildHeader(),
                        
                        SizedBox(height: 20),
                        
                        // 切换标签
                        _buildTabSwitch(),
                        
                        SizedBox(height: 20),
                        
                        // 商品网格
                        Expanded(
                          child: _buildItemGrid(),
                        ),
                      ],
                    ),
                  ),

                  // 关闭按钮
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    right: 20,
                    child: GestureDetector(
                      onTap: _close,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 标题
          Container(
            height: 60,
            child: Image.asset(
              Assets.shopShopTitle,
              fit: BoxFit.contain,
            ),
          ),
          
          // 金币显示
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: HexColor("#FFD700"),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  Assets.mainMainIconCoin,
                  height: 30,
                ),
                SizedBox(width: 8),
                Text(
                  '$_coinCount',
                  style: TextStyle(
                    color: HexColor("#8B4513"),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitch() {
    return Container(
      width: 300,
      height: 60,
      child: Stack(
        children: [
          // 背景
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(Assets.shopShopSwitchBg),
                fit: BoxFit.fill,
              ),
            ),
          ),
          
          // 滑动条
          AnimatedBuilder(
            animation: _switchAnimation,
            builder: (context, child) {
              return AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                left: _isTubeSelected ? 10 : 160,
                top: 5,
                child: Container(
                  width: 130,
                  height: 50,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(Assets.shopShopSwitchBar),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // 按钮
          Row(
            children: [
              // TUBE标签
              Expanded(
                child: GestureDetector(
                  onTap: () => _switchTab(true),
                  child: Container(
                    height: double.infinity,
                    child: Center(
                      child: Image.asset(
                        _isTubeSelected 
                          ? Assets.shopShopSwitchTextTubeSelected
                          : Assets.shopShopSwitchTextTubeUnselected,
                        height: 30,
                      ),
                    ),
                  ),
                ),
              ),
              
              // BALL标签
              Expanded(
                child: GestureDetector(
                  onTap: () => _switchTab(false),
                  child: Container(
                    height: double.infinity,
                    child: Center(
                      child: Image.asset(
                        _isTubeSelected 
                          ? Assets.shopShopSwitchTextBallUnselected
                          : Assets.shopShopSwitchTextBallSelected,
                        height: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemGrid() {
    final currentSkins = _isTubeSelected ? _tubeSkins : _ballSkins;
    
    return AnimatedBuilder(
      animation: _switchAnimation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: currentSkins.length,
            itemBuilder: (context, index) {
              return _buildShopItem(index, currentSkins[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildShopItem(int index, Map<String, dynamic> skinData) {
    final isSelected = _selectedItemIndex == index;
    final isUnlocked = skinData['unlocked'] as bool;
    final price = skinData['price'] as int;
    final skinId = skinData['id'] as String;
    
    return GestureDetector(
      onTap: () => _selectItem(index),
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Assets.shopShopFrame),
            fit: BoxFit.fill,
          ),
        ),
        child: Stack(
          children: [
            // 皮肤图片
            Center(
              child: Container(
                width: 80,
                height: 80,
                margin: EdgeInsets.only(top: 10),
                child: Image.asset(
                  _getSkinImagePath(skinId),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[600],
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // 选中边框
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(Assets.shopShopImgSelected),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            
            // 价格标签
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUnlocked ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isUnlocked) ...[
                        Image.asset(
                          Assets.mainMainIconCoin,
                          height: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '$price',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '已拥有',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            // 购买按钮 (只有选中且未解锁时显示)
            if (isSelected && !isUnlocked)
              Positioned(
                bottom: -10,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _purchaseItem(index),
                    child: Container(
                      width: 80,
                      height: 30,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(Assets.shopShopBtnBuy),
                          fit: BoxFit.fill,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'BUY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getSkinImagePath(String skinId) {
    // 根据皮肤ID返回对应的图片路径
    if (skinId.startsWith('tube')) {
      final tubeNumber = skinId.replaceAll('tube', '');
      return 'assets/images/ball_bottle/${tubeNumber}_1.png';
    } else if (skinId.startsWith('ball')) {
      final ballNumber = skinId.replaceAll('ball', '');
      return 'assets/images/ball_bottle/ball${ballNumber}_1.png';
    }
    
    return 'assets/images/ball_bottle/1_1.png'; // 默认图片
  }
}