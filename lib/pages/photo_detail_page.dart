import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoDetailPage extends StatefulWidget {
  final int imageIndex;
  final bool isUnlocked;
  final Function(int) onPhotoUnlocked;

  const PhotoDetailPage({
    super.key,
    required this.imageIndex,
    required this.isUnlocked,
    required this.onPhotoUnlocked,
  });

  @override
  State<PhotoDetailPage> createState() => _PhotoDetailPageState();
}

class _PhotoDetailPageState extends State<PhotoDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _unlockAnimationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isUnlocked = false;
  bool _showUnlockDialog = false;

  static const int totalImages = 75;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.imageIndex;
    _isUnlocked = widget.isUnlocked;
    _initializeAnimations();
    _setupPageController();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _unlockAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _unlockAnimationController,
      curve: Curves.bounceOut,
    ));

    _animationController.forward();
  }

  void _setupPageController() {
    _pageController = PageController(initialPage: _currentIndex);
  }

  Future<bool> _checkPhotoUnlocked(int index) async {
    if (index < 5) return true; // 前5张默认解锁
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('photo_unlocked_$index') ?? false;
  }

  Future<void> _unlockPhoto(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('photo_unlocked_$index', true);
    
    setState(() {
      _isUnlocked = true;
      _showUnlockDialog = true;
    });
    
    // 播放解锁动画
    _unlockAnimationController.forward();
    
    // 通知父页面更新
    widget.onPhotoUnlocked(index);
    
    // 3秒后自动关闭解锁弹窗
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        _closeUnlockDialog();
      }
    });
  }

  void _downloadPhoto() {
    // 模拟观看广告解锁下载
    setState(() {
      _showUnlockDialog = true;
    });
    _unlockAnimationController.forward();
    
    // 这里可以添加实际的下载逻辑
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        _closeUnlockDialog();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('图片已保存到相册'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _closeUnlockDialog() {
    _unlockAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showUnlockDialog = false;
        });
      }
    });
  }

  void _previousPhoto() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPhoto() {
    if (_currentIndex < totalImages - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _close() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _unlockAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, MediaQuery.of(context).size.height * _slideAnimation.value),
            child: Stack(
              children: [
                // 主要图片显示区域
                PageView.builder(
                  controller: _pageController,
                  itemCount: totalImages,
                  onPageChanged: (index) async {
                    setState(() {
                      _currentIndex = index;
                    });
                    
                    // 检查当前图片是否解锁
                    final unlocked = await _checkPhotoUnlocked(index);
                    setState(() {
                      _isUnlocked = unlocked;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildPhotoView(index);
                  },
                ),

                // 顶部控制栏
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // // 图片计数
                      // Container(
                      //   padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      //   decoration: BoxDecoration(
                      //     color: Colors.black.withOpacity(0.6),
                      //     borderRadius: BorderRadius.circular(20),
                      //   ),
                      //   child: Text(
                      //     '${_currentIndex + 1}/$totalImages',
                      //     style: TextStyle(
                      //       color: Colors.white,
                      //       fontSize: 16,
                      //       fontWeight: FontWeight.bold,
                      //     ),
                      //   ),
                      // ),
                      
                      // // 关闭按钮
                      // GestureDetector(
                      //   onTap: _close,
                      //   child: Container(
                      //     width: 50,
                      //     height: 50,
                      //     decoration: BoxDecoration(
                      //       color: Colors.black.withOpacity(0.6),
                      //       shape: BoxShape.circle,
                      //     ),
                      //     child: Icon(
                      //       Icons.close,
                      //       color: Colors.white,
                      //       size: 28,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),

                // 左右切换按钮
                if (_currentIndex > 0)
                  Positioned(
                    left: 20,
                    top: MediaQuery.of(context).size.height * 0.5 - 30,
                    child: GestureDetector(
                      onTap: _previousPhoto,
                      child: Container(
                        width: 35,
                        height: 60,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(Assets.gallaryGallaryBtnPrevious),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (_currentIndex < totalImages - 1)
                  Positioned(
                    right: 20,
                    top: MediaQuery.of(context).size.height * 0.5 - 30,
                    child: GestureDetector(
                      onTap: _nextPhoto,
                      child: Container(
                        width: 35,
                        height: 60,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(Assets.gallaryGallaryBtnNext),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 底部操作栏
                if (_isUnlocked)
                  Positioned(
                    bottom: 50,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _downloadPhoto,
                        child: Container(
                          width: 150,
                          height: 60,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(Assets.gallaryGallaryBtnDownload),
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
                                  size: 20,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  '下载',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 解锁成功弹窗
                if (_showUnlockDialog) _buildUnlockDialog(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoView(int index) {
    return FutureBuilder<bool>(
      future: _checkPhotoUnlocked(index),
      builder: (context, snapshot) {
        final isUnlocked = snapshot.data ?? false;
        final imageNumber = (index + 1).toString().padLeft(2, '0');
        
        return Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // 图片内容
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: isUnlocked
                    ? Image.asset(
                        'assets/images/grils_list/Bg_$imageNumber.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 300,
                            height: 400,
                            color: Colors.grey[800],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    '图片加载失败',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 300,
                        height: 400,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock,
                                color: Colors.white.withOpacity(0.8),
                                size: 80,
                              ),
                              SizedBox(height: 20),
                              Text(
                                '图片未解锁',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => _unlockPhoto(index),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        '观看广告解锁',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
              ),

              // 水印 (只有解锁的图片才显示)
              if (isUnlocked)
                Positioned(
                  top: 280,
                  right: 80,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(Assets.gallaryGallaryWatermark),
                        fit: BoxFit.contain,
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

  Widget _buildUnlockDialog() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Assets.popPopAsk),
                  fit: BoxFit.fill,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 特效图标
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(Assets.newPhotoNewPhotoIconNew),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // 解锁文字
                  Text(
                    '解锁成功!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: HexColor("#8B4513"),
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  
                  Text(
                    '图片 ${_currentIndex + 1} 已解锁',
                    style: TextStyle(
                      fontSize: 18,
                      color: HexColor("#666666"),
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // 确认按钮
                  GestureDetector(
                    onTap: _closeUnlockDialog,
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