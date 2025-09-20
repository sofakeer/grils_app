import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:io';
import '../managers/ad_manager.dart';

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
  late Animation<double> _slideAnimation;
  
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isUnlocked = false;
  bool _hasStoragePermission = false;

  static const int totalImages = 75;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.imageIndex;
    _isUnlocked = widget.isUnlocked;
    _initializeAnimations();
    _setupPageController();
    _checkStoragePermission();
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

  void _setupPageController() {
    _pageController = PageController(initialPage: _currentIndex);
  }

  Future<void> _checkStoragePermission() async {
    try {
      bool hasPermission = false;
      
      if (Platform.isIOS) {
        var status = await Permission.photosAddOnly.status;
        hasPermission = status.isGranted;
        if (!hasPermission) {
          status = await Permission.photos.status;
          hasPermission = status.isGranted;
        }
      } else if (Platform.isAndroid) {
        var photosStatus = await Permission.photos.status;
        hasPermission = photosStatus.isGranted;
        if (!hasPermission) {
          var storageStatus = await Permission.storage.status;
          hasPermission = storageStatus.isGranted;
        }
      }
      
      if (mounted) {
        setState(() {
          _hasStoragePermission = hasPermission;
        });
      }
    } catch (e) {
      print('检查存储权限失败: $e');
    }
  }

  Future<bool> _checkPhotoUnlocked(int index) async {
    if (index < 5) return true; // 前5张默认解锁
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('photo_unlocked_$index') ?? false;
  }


  Future<void> _downloadPhoto() async {
    try {
      print('开始下载图片流程...');
      
      // 触发视频广告
      bool adCompleted = await AdManager.instance.showRewardedAd(
        context: context,
        onAdCompleted: () async {
          print('广告播放完成，开始保存图片...');
          // 广告完成后保存无水印图片到相册
          await _saveImageToGallery();
        },
        onAdFailed: () {
          print('广告播放失败');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('广告播放失败，请重试'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
      );
      
      if (!adCompleted) {
        print('用户取消广告或广告失败');
      }
    } catch (e) {
      print('下载图片失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _requestPermission() async {
    try {
      print('开始请求存储权限...');
      
      // iOS平台
      if (Platform.isIOS) {
        var status = await Permission.photosAddOnly.status;
        if (status.isGranted) {
          return true;
        }
        status = await Permission.photosAddOnly.request();
        if (status.isGranted) {
          return true;
        }
        
        // 如果photosAddOnly权限失败，尝试photos权限
        status = await Permission.photos.status;
        if (status.isGranted) {
          return true;
        }
        status = await Permission.photos.request();
        return status.isGranted;
      }
      
      // Android平台 - 先尝试photos权限（Android 13+），再尝试storage权限
      if (Platform.isAndroid) {
        // 先尝试photos权限
        var photosStatus = await Permission.photos.status;
        if (photosStatus.isGranted) {
          return true;
        }
        
        photosStatus = await Permission.photos.request();
        if (photosStatus.isGranted) {
          return true;
        }
        
        // 如果photos权限失败，尝试storage权限（适用于Android 13以下）
        var storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) {
          return true;
        }
        
        storageStatus = await Permission.storage.request();
        return storageStatus.isGranted;
      }
      
      return false;
    } catch (e) {
      print('权限请求失败: $e');
      return false;
    }
  }
  

  Future<void> _saveImageToGallery() async {
    try {
      // 先请求权限
      bool hasPermission = await _requestPermission();
      
      // 更新权限状态
      if (mounted) {
        setState(() {
          _hasStoragePermission = hasPermission;
        });
      }
      
      if (!hasPermission) {
        print('没有存储权限');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要存储权限才能保存图片'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      final imageNumber = (_currentIndex + 1).toString().padLeft(2, '0');
      final imagePath = 'assets/images/grils_list/Bg_$imageNumber.png';
      
      print('开始保存图片到相册: $imagePath');
      
      // 加载图片数据
      final byteData = await rootBundle.load(imagePath);
      final uint8List = byteData.buffer.asUint8List();
      
      print('图片数据加载成功，大小: ${uint8List.length} bytes');
      
      // 使用image_gallery_saver保存到相册
      final result = await ImageGallerySaver.saveImage(
        uint8List,
        name: 'girl_image_${DateTime.now().millisecondsSinceEpoch}_$imageNumber',
        quality: 100,
      );
      
      print('保存结果: $result');
      
      // 显示成功消息
      if (mounted) {
        if (result != null && result['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('图片已保存到相册'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('保存失败，请重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('保存图片失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _previousPhoto() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 如果是第一张图片，跳到最后一张
      _pageController.animateToPage(
        totalImages - 1,
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
    } else {
      // 如果是最后一张图片，回到第一张
      _pageController.animateToPage(
        0,
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
                // 主要图片显示区域 - 全屏显示
                Positioned.fill(
                  child: PageView.builder(
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
                ),

                // 顶部控制栏
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 关闭按钮
                      GestureDetector(
                        onTap: _close,
                        child: Container(
                          width: 50,
                          height: 50,
                          child: Image.asset(
                            Assets.imagesBtnClose,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
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
                          width: 180,
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
                                Image(image: AssetImage(Assets.imagesLabelAd),width: 30,height: 30),
                                SizedBox(width: 5),
                                Text(
                                  'DOWNLOAD',
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
              // 图片内容 - 全屏显示
              Positioned.fill(
                child: isUnlocked
                  ? Image.asset(
                      'assets/images/grils_list/Bg_$imageNumber.png',
                      fit: BoxFit.cover, // 全屏覆盖
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
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
                      color: Colors.black87,
                      child: Center(
                        child: Container(
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
                              Text(
                                '通过过关解锁',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ),

              // 水印 (只有解锁的图片且有存储权限时才显示)
              if (isUnlocked && _hasStoragePermission)
                Positioned(
                  top: 190,
                  right: 80,
                  child: Opacity(
                    opacity: 0.3,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(Assets.gallaryGallaryWatermark),
                          fit: BoxFit.contain,
                        ),
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

}