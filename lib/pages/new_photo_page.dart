import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/widgets/common_header.dart';
import 'package:grils_app/pages/win_heart_page.dart';
import 'package:spine_flutter/spine_flutter.dart' as spine;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/energy_calculator.dart';
import '../managers/audio_manager.dart';

class NewPhotoPage extends StatefulWidget {
  final int level;
  
  const NewPhotoPage({super.key, this.level = 1});

  @override
  State<NewPhotoPage> createState() => _NewPhotoPageState();
}

class _NewPhotoPageState extends State<NewPhotoPage> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  double _progress = 0.0;
  double _currentEnergy = 0.0;
  bool _isUnlocked = false;
  bool _showUnlockEffect = false;
  
  // Spine controllers
  spine.SpineWidgetController? _titleSpineController;
  spine.SpineWidgetController? _unlockEffectController;
  bool _isTitleSpineReady = false;
  bool _isUnlockEffectReady = false;
  
  int _currentPhotoIndex = 0; // 当前照片索引 (0-79)
  static const int maxPhotos = 80; // 总共80张照片

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSpineControllers();
    _loadPhotoProgress();
    _calculateNewProgress();
  }

  void _initializeSpineControllers() {
    // 初始化标题Spine控制器
    try {
      _titleSpineController = spine.SpineWidgetController(onInitialized: (controller) {
        try {
          final animations = controller.skeleton.getData()?.getAnimations();
          if (animations != null && animations.isNotEmpty) {
            if (mounted) {
              setState(() {
                _isTitleSpineReady = true;
              });
            }

            // 先播放 NewPhoto_Eff_Born 动画
            final bornAnim = animations.firstWhere(
              (anim) => anim.getName().toLowerCase().contains('born'),
              orElse: () => animations.first,
            );
            
            if (bornAnim != null) {
              final duration = bornAnim.getDuration();
              controller.animationState.setAnimationByName(0, bornAnim.getName(), false);
              
              // born 动画播完后循环播放 idle 动画
              Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
                if (mounted && _titleSpineController != null) {
                  final idleAnim = animations.firstWhere(
                    (anim) => anim.getName().toLowerCase().contains('idle'),
                    orElse: () => animations.last,
                  );
                  
                  if (idleAnim != null) {
                    controller.animationState.setAnimationByName(0, idleAnim.getName(), true);
                  }
                }
              });
            }
          }
        } catch (e) {
          print('Title spine animation initialization failed: $e');
        }
      });
    } catch (e) {
      print('Title spine controller creation failed: $e');
    }
    
    // 初始化解锁特效Spine控制器
    try {
      _unlockEffectController = spine.SpineWidgetController(onInitialized: (controller) {
        if (mounted) {
          setState(() {
            _isUnlockEffectReady = true;
          });
        }
      });
    } catch (e) {
      print('Unlock effect spine controller creation failed: $e');
    }
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.1,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // 启动动画序列
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _scaleController.forward();
      }
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _progressController.forward();
      }
    });

    // 监听进度动画
    _progressController.addListener(() {
      final newProgress = EnergyCalculator.calculateProgress(_currentEnergy);
      setState(() {
        _progress = _progressAnimation.value * newProgress;
      });
      
      // 当达到30%时检查是否解锁
      if (_progress >= 1.0 && !_isUnlocked && !_showUnlockEffect) {
        _triggerUnlockEffect();
      }
    });
  }

  Future<void> _loadPhotoProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final photoKey = 'photo_${_currentPhotoIndex}_energy';
    final allPhotosUnlocked = prefs.getBool('all_photos_unlocked') ?? false;
    
    if (mounted) {
      setState(() {
        _currentEnergy = prefs.getDouble(photoKey) ?? 0.0;
        _progress = EnergyCalculator.calculateProgress(_currentEnergy);
        _isUnlocked = EnergyCalculator.isCompleted(_currentEnergy);
      });
    }
  }
  
  void _calculateNewProgress() {
    final addedEnergy = EnergyCalculator.calculateEnergyForLevel(widget.level);
    final newEnergy = EnergyCalculator.addEnergy(_currentEnergy, addedEnergy);
    final newProgress = EnergyCalculator.calculateProgress(newEnergy);
    
    // 保存新的能量值
    _savePhotoProgress(newEnergy);
    
    // 启动进度条动画
    if (mounted) {
      setState(() {
        _currentEnergy = newEnergy;
      });
      _progressController.forward();
    }
  }
  
  Future<void> _savePhotoProgress(double energy) async {
    final prefs = await SharedPreferences.getInstance();
    final photoKey = 'photo_${_currentPhotoIndex}_energy';
    await prefs.setDouble(photoKey, energy);
  }
  
  void _triggerUnlockEffect() {
    if (_unlockEffectController != null && _isUnlockEffectReady) {
      setState(() {
        _showUnlockEffect = true;
        _isUnlocked = true;
      });
      
      // 播放解锁特效动画
      try {
        final animations = _unlockEffectController!.skeleton.getData()?.getAnimations();
        if (animations != null && animations.isNotEmpty) {
          final effectAnim = animations.first;
          final duration = effectAnim.getDuration();
          _unlockEffectController!.animationState.setAnimationByName(0, effectAnim.getName(), false);
          
          // 动画播完后隐藏特效
          Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
            if (mounted) {
              setState(() {
                _showUnlockEffect = false;
              });
            }
          });
        }
      } catch (e) {
        print('Unlock effect play failed: $e');
      }
      
      // 播放解锁音效
      AudioManager().playSettlementCoin();
    }
  }
  
  void _downloadPhoto() {
    if (!_isUnlocked) return;
    
    // 这里可以添加下载照片的逻辑
    print('下载新照片');
    AudioManager().playCoinEffect();
    
    // 移除水印，下载到相册
    // TODO: 实现下载逻辑
  }

  void _nextPhoto() async {
    await AudioManager().playExit();
    
    // 跳转到爱心货币界面
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const WinHeartPage(),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _progressController.dispose();
    _titleSpineController = null;
    _unlockEffectController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Assets.wincoinWinCoinBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // 主要内容
            Center(
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // NEW PHOTO 标题 - 使用Spine动画
                        Container(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 原始标题作为备用
                              if (!_isTitleSpineReady)
                                Image.asset(
                                  Assets.newPhotoNewPhotoTitle,
                                  height: 130,
                                ),
                              // NewPhoto_Eff Spine动画
                              if (_titleSpineController != null && _isTitleSpineReady)
                                SizedBox(
                                  width: 300,
                                  height: 130,
                                  child: spine.SpineWidget.fromAsset(
                                    "assets/spine/NewPhoto_Eff.atlas",
                                    "assets/spine/NewPhoto_Eff.skel",
                                    _titleSpineController!,
                                    boundsProvider: const spine.SetupPoseBounds(),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // 照片框架
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 照片框架背景
                              Image.asset(
                                Assets.newPhotoNewPhotoFrame,
                                height: 400,
                              ),
                              // 高亮线效果 - 只在未解锁时显示
                              if (!_isUnlocked)
                                Positioned(
                                  top: 150,
                                  child: Image.asset(
                                    Assets.newPhotoNewPhotoHighline,
                                    height: 20,
                                  ),
                                ),
                              // 解锁特效动画
                              if (_showUnlockEffect && _unlockEffectController != null && _isUnlockEffectReady)
                                Positioned.fill(
                                  child: SizedBox(
                                    child: spine.SpineWidget.fromAsset(
                                      "assets/spine/PhotoUnlock_Eff.atlas",
                                      "assets/spine/PhotoUnlock_Eff.skel",
                                      _unlockEffectController!,
                                      boundsProvider: const spine.SetupPoseBounds(),
                                    ),
                                  ),
                                ),
                              // NEW 图标
                              Positioned(
                                top: 20,
                                left: 20,
                                child: Image.asset(Assets.newPhotoNewPhotoIconNew,width: 50,),
                              )
                            ],
                          ),
                        ),

                        // 进度条
                        Container(
                          margin: const EdgeInsets.only(bottom: 30),
                          child: Column(
                            children: [
                              // 进度条背景
                              Container(
                                width: 300,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.pink.withOpacity(0.3),
                                ),
                                child: Stack(
                                  children: [
                                    // 进度条填充
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      width: 300 * _progress,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        gradient: LinearGradient(
                                          colors: _isUnlocked 
                                              ? [Colors.green, Colors.lightGreen]
                                              : [Colors.pink, Colors.pinkAccent],
                                        ),
                                      ),
                                    ),
                                    // 进度文字
                                    Center(
                                      child: Text(
                                        '${(_progress * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              // 进度条图标
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    Assets.newPhotoNewPhotoIconSlider,
                                    width: 20,
                                    height: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // DOWNLOAD 按钮 - 锁定/解锁状态
                        GestureDetector(
                          onTap: _isUnlocked ? _downloadPhoto : null,
                          child: Container(
                            width: 250,
                            height: 60,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                  _isUnlocked 
                                      ? Assets.newPhotoNewPhotoBtnBlueBig
                                      : Assets.newPhotoNewPhotoBtnBlueBig, // TODO: 更换为 DownButton_Lock 资源
                                ),
                                fit: BoxFit.fill,
                              ),
                            ),
                            child: Stack(
                              children: [
                                // 按钮内容
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // 相机图标
                                    Image.asset(
                                      Assets.newPhotoNewPhotoIconAd,
                                      height: 30,
                                      color: _isUnlocked ? null : Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Download',
                                      style: TextStyle(
                                        color: _isUnlocked ? Colors.white : Colors.grey,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: const Offset(1, 1),
                                            blurRadius: 2,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // 锁定覆盖层
                                if (!_isUnlocked)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.lock,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // NEXT 按钮
                        GestureDetector(
                          onTap: _nextPhoto,
                          child: const Text(
                            'NEXT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
