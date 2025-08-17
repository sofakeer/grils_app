import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grils_app/pages/photo_detail_page.dart';
import 'package:grils_app/widgets/common_header.dart';
import 'package:grils_app/services/user_service.dart';
import 'dart:async';
import '../widgets/outlined_text_widget.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  final ScrollController _scrollController = ScrollController();
  
  // 总共75张图片 (grils_list文件夹中有Bg_01.png到Bg_75.png)
  static const int totalImages = 75;
  
  List<bool> _unlockedImages = [];
  double _scrollProgress = 0.0;
  
  // 用户服务
  late UserService _userService;
  
  // 性能优化相关
  Timer? _scrollDebounceTimer;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUnlockData();
    _setupScrollListener();
    _initializeUserService();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // 防抖处理，减少setState调用频率
      _scrollDebounceTimer?.cancel();
      _scrollDebounceTimer = Timer(Duration(milliseconds: 16), () {
        if (mounted) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final currentScroll = _scrollController.position.pixels;
          final newProgress = maxScroll > 0 ? currentScroll / maxScroll : 0.0;
          
          // 只有进度变化明显时才更新
          if ((newProgress - _scrollProgress).abs() > 0.01) {
            setState(() {
              _scrollProgress = newProgress;
            });
          }
        }
      });
    });
  }

  Future<void> _initializeUserService() async {
    _userService = UserService.instance;
    await _userService.initialize();
  }

  Future<void> _loadUnlockData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _unlockedImages = List.generate(totalImages, (index) {
          // 默认解锁前5张图片作为示例
          if (index < 5) return true;
          return prefs.getBool('photo_unlocked_$index') ?? false;
        });
      });
    }
  }

  Future<void> _saveUnlockData() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _unlockedImages.length; i++) {
      await prefs.setBool('photo_unlocked_$i', _unlockedImages[i]);
    }
  }

  void _openPhotoDetail(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoDetailPage(
          imageIndex: index,
          isUnlocked: _unlockedImages[index],
          onPhotoUnlocked: (photoIndex) {
            setState(() {
              _unlockedImages[photoIndex] = true;
            });
            _saveUnlockData();
          },
        ),
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
    _scrollController.dispose();
    _scrollDebounceTimer?.cancel();
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
                  image: AssetImage(Assets.gallaryGallaryBg),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // 公共头部
                  CommonHeader(
                    onBackPressed: _close,
                  ),

                  // 主要内容区域
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 80,
                    left: 0,
                    right: 10,
                    bottom:10,
                    child: Column(
                      children: [
                        // 图片网格
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GridView.builder(
                              controller: _scrollController,
                              // 性能优化：添加缓存扩展
                              cacheExtent: 500,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: totalImages,
                              itemBuilder: (context, index) {
                                return _buildPhotoItem(index);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 右侧滚动条
                  Positioned(
                    right: 5,
                    top: MediaQuery.of(context).size.height * 0.25,
                    bottom: MediaQuery.of(context).size.height * 0.15,
                    child: _buildScrollBar(),
                  ),

                  // 底部统计信息
                  // Positioned(
                  //   bottom: 20,
                  //   left: 0,
                  //   right: 0,
                  //   child: Container(
                  //     padding: const EdgeInsets.symmetric(horizontal: 20),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         Container(
                  //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  //           decoration: BoxDecoration(
                  //             color: Colors.black.withOpacity(0.6),
                  //             borderRadius: BorderRadius.circular(20),
                  //           ),
                  //           child: Text(
                  //             '已解锁: ${_unlockedImages.where((unlocked) => unlocked).length}/$totalImages',
                  //             style: const TextStyle(
                  //               color: Colors.white,
                  //               fontSize: 16,
                  //               fontWeight: FontWeight.bold,
                  //             ),
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    final isUnlocked = _unlockedImages[index];
    final imageNumber = (index + 1).toString().padLeft(2, '0');
    
    return GestureDetector(
      onTap: () => _openPhotoDetail(index),
      child: RepaintBoundary( // 性能优化：减少重绘
        child: Container(
          child: Stack(
            children: [
              // 背景框架
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  image: DecorationImage(
                    image: AssetImage(
                      isUnlocked 
                        ? Assets.gallaryGallaryFrameUnlock
                        : Assets.gallaryGallaryFrameLock
                    ),
                    fit: BoxFit.fill,
                  ),
                ),
              ),

              // 图片内容
              Center(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  margin: EdgeInsets.only(left: 3.5, right: 3.5, bottom: 4, top: 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: isUnlocked
                      ? Image.asset(
                          'assets/images/grils_list/Bg_$imageNumber.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        )
                      : Container(color: Colors.transparent),
                  ),
                ),
              ),

              // 新图片标识 (如果是最近解锁的)
              if (isUnlocked && index >= totalImages - 5)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(Assets.newPhotoNewPhotoIconNew),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollBar() {
    return Stack(
      children: [
        // 滚动条背景
        Container(
          width: 15,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7.5),
            image: DecorationImage(
              image: AssetImage(Assets.gallaryGallarySliderBg),
              fit: BoxFit.fill,
            ),
          ),
        ),
        // 滚动指示器 - 显示在滚动条上方
        AnimatedPositioned(
          duration: Duration(milliseconds: 100),
          top: _scrollProgress * (MediaQuery.of(context).size.height * 0.6 - 40),
          left: -2.5,
          child: Container(
            width: 20,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage(Assets.gallaryGallarySliderDot),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}