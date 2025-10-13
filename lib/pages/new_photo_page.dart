import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/pages/win_heart_page.dart';
import 'package:spine_flutter/spine_flutter.dart' as spine;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../utils/energy_calculator.dart';
import '../managers/audio_manager.dart';
import '../widgets/outlined_text_widget.dart';
import '../widgets/photo_unlock_effect_widget.dart';

class NewPhotoPage extends StatefulWidget {
  final int level;

  const NewPhotoPage({super.key, this.level = 1});

  @override
  State<NewPhotoPage> createState() => _NewPhotoPageState();
}

class _NewPhotoPageState extends State<NewPhotoPage>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  double _progress = 0.0;
  double _startProgress = 0.0;
  double _targetProgress = 0.0;
  double? _debugProgress;
  double _currentEnergy = 0.0;
  bool _isUnlocked = false;
  bool _showUnlockEffect = false;
  bool _pendingUnlockEffect = false;

  // Spine controllers
  spine.SpineWidgetController? _titleSpineController;
  OverlayEntry? _titleSpineOverlayEntry;
  bool _isTitleSpineReady = false;

  // 解锁特效Widget引用
  final GlobalKey _unlockEffectKey = GlobalKey();

  int _currentPhotoIndex = 0; // 当前照片索引 (0-79)
  static const int maxPhotos = 80; // 总共80张照片

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSpineControllers();
    _initAsync();

    // 在首帧后插入标题 Overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insertTitleSpineOverlay();
    });
  }

  Future<void> _initAsync() async {
    await _findNextUnlockedPhoto();
    await _loadPhotoProgress();
    if (!mounted) return;
    await _calculateNewProgress();
  }

  String _getCurrentPhotoAsset() {
    final imageNumber = (_currentPhotoIndex + 1).toString().padLeft(2, '0');
    return 'assets/images/grils_list/Bg_$imageNumber.png';
  }

  Future<void> _findNextUnlockedPhoto() async {
    final prefs = await SharedPreferences.getInstance();

    // 从当前照片开始查找下一张未解锁的照片
    for (int i = _currentPhotoIndex; i < maxPhotos; i++) {
      final photoKey = 'photo_${i}_energy';
      final storedEnergy = prefs.getDouble(photoKey) ?? 0.0;
      final isCompleted = EnergyCalculator.isCompleted(storedEnergy);

      if (!isCompleted) {
        // 找到未解锁的照片，设置为当前照片
        if (mounted) {
          setState(() {
            _currentPhotoIndex = i;
          });
        }
        return;
      }
    }

    // 如果所有照片都已解锁，回到第一张
    if (mounted) {
      setState(() {
        _currentPhotoIndex = 0;
      });
    }
  }

  void _initializeSpineControllers() {
    // 初始化标题Spine控制器
    try {
      _titleSpineController =
          spine.SpineWidgetController(onInitialized: (controller) {
        try {
          controller.animationState.getData().setDefaultMix(0.2);
          final animations =
              controller.skeleton.getData()?.getAnimations() ?? [];
          print(
              "NewPhoto_Eff animations: ${animations.map((a) => a.getName()).toList()}");

          if (mounted) {
            setState(() {
              _isTitleSpineReady = true;
            });
          }

          // 延迟播放动画，确保控件已渲染
          Future.delayed(const Duration(milliseconds: 200), () async {
            if (!mounted) return;

            final data = controller.skeleton.getData();
            String? bornName = animations
                    .map((a) => a.getName())
                    .firstWhere((n) => n == 'NewPhoto_Eff_born',
                        orElse: () => '')
                    .isNotEmpty
                ? 'NewPhoto_Eff_born'
                : null;
            bornName ??= animations.map((a) => a.getName()).firstWhere(
                (n) => n.toLowerCase().contains('born'),
                orElse: () => '');
            if (bornName.isEmpty) bornName = null;

            String? idleName = animations
                    .map((a) => a.getName())
                    .firstWhere((n) => n == 'NewPhoto_Eff_idle',
                        orElse: () => '')
                    .isNotEmpty
                ? 'NewPhoto_Eff_idle'
                : null;
            idleName ??= animations.map((a) => a.getName()).firstWhere(
                (n) => n.toLowerCase().contains('idle'),
                orElse: () => '');
            if (idleName.isEmpty) idleName = null;

            try {
              controller.animationState.clearTracks();
              if (bornName != null && data?.findAnimation(bornName) != null) {
                controller.animationState
                    .setAnimationByName(0, bornName, false);
                final duration =
                    (data?.findAnimation(bornName)?.getDuration() ?? 1.0);
                print('✓ NewPhoto born once: $bornName, duration: $duration s');
                await Future.delayed(
                    Duration(milliseconds: (duration * 1000).toInt()));
                if (!mounted) return;
                final next = idleName ?? animations.first.getName();
                if (next.isNotEmpty && data?.findAnimation(next) != null) {
                  controller.animationState.setAnimationByName(0, next, true);
                  print('→ NewPhoto idle loop: $next');
                } else {
                  print('✗ NewPhoto idle not found');
                }
              } else {
                final next = idleName ?? animations.first.getName();
                if (next.isNotEmpty && data?.findAnimation(next) != null) {
                  controller.animationState.setAnimationByName(0, next, true);
                  print('✓ NewPhoto idle directly: $next');
                } else {
                  print('✗ NewPhoto no playable animation');
                }
              }
            } catch (e) {
              print('NewPhoto animations play failed: $e');
            }
          });
        } catch (e) {
          print('Title spine animation initialization failed: $e');
        }
      });
    } catch (e) {
      print('Title spine controller creation failed: $e');
    }
  }

  void _insertTitleSpineOverlay() {
    if (!mounted || _titleSpineOverlayEntry != null) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _titleSpineOverlayEntry = OverlayEntry(
      builder: (context) {
        return IgnorePointer(
          ignoring: true, // 仅展示特效，点击穿透
          child: Transform.translate(
            offset: Offset(0, -350),
            child: Positioned(
              top: MediaQuery.of(context).padding.top + 20, // 更靠近顶部
              left: 0,
              right: 0,
              child: _titleSpineController == null
                  ? const SizedBox.shrink()
                  : SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 180, // 限制高度，避免占用过多空间
                      child: spine.SpineWidget.fromAsset(
                        "assets/spine/NewPhoto_Eff.atlas",
                        "assets/spine/NewPhoto_Eff.skel",
                        _titleSpineController!,
                        boundsProvider: const spine.SetupPoseBounds(),
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
          ),
        );
      },
    );

    overlay.insert(_titleSpineOverlayEntry!);
  }

  void _removeTitleSpineOverlay() {
    try {
      _titleSpineOverlayEntry?.remove();
      _titleSpineOverlayEntry = null;
    } catch (_) {}
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
      final t = _progressAnimation.value;
      final interpolated =
          ui.lerpDouble(_startProgress, _targetProgress, t) ?? _targetProgress;
      final nextProgress = interpolated.clamp(0.0, 1.0).toDouble();

      if (mounted) {
        setState(() {
          _progress = nextProgress;
        });
      }

      if (_progress >= 1.0 && !_isUnlocked && !_showUnlockEffect) {
        _triggerUnlockEffect();
      }
    });
  }

  Future<void> _loadPhotoProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final photoKey = 'photo_${_currentPhotoIndex}_energy';
    // final allPhotosUnlocked = prefs.getBool('all_photos_unlocked') ?? false;

    final storedEnergy = prefs.getDouble(photoKey) ?? 0.0;
    final storedProgress = EnergyCalculator.calculateProgress(storedEnergy);
    final unlocked = EnergyCalculator.isCompleted(storedEnergy);

    if (mounted) {
      setState(() {
        _currentEnergy = storedEnergy;
        _progress = storedProgress;
        _startProgress = storedProgress;
        _targetProgress = storedProgress;
        _isUnlocked = unlocked;
      });
    }
  }

  Future<void> _calculateNewProgress() async {
    final addedEnergy = EnergyCalculator.calculateEnergyForLevel(widget.level);
    final newEnergy = EnergyCalculator.addEnergy(_currentEnergy, addedEnergy);
    final newProgress = EnergyCalculator.calculateProgress(newEnergy);
    final startProgress =
        (_debugProgress ?? _progress).clamp(0.0, 1.0).toDouble();

    await _savePhotoProgress(newEnergy);

    if (!mounted) {
      return;
    }

    setState(() {
      _currentEnergy = newEnergy;
      _startProgress = startProgress;
      _targetProgress = newProgress;
      _progress = startProgress;
    });

    _progressController
      ..stop()
      ..reset()
      ..forward();
  }

  Future<void> _savePhotoProgress(double energy) async {
    final prefs = await SharedPreferences.getInstance();
    final photoKey = 'photo_${_currentPhotoIndex}_energy';
    await prefs.setDouble(photoKey, energy);
  }

  void _setDebugProgress(double value) {
    final clamped = value.clamp(0.0, 1.0);
    setState(() {
      _debugProgress = clamped.toDouble();
    });
  }

  void _adjustDebugProgress(double delta) {
    final base = _debugProgress ?? _progress;
    final next = (base + delta).clamp(0.0, 1.0);
    setState(() {
      _debugProgress = next.toDouble();
    });
  }

  void _clearDebugProgress() {
    setState(() {
      _debugProgress = null;
    });
    if (!_progressController.isAnimating && _progressController.value < 1.0) {
      _progressController.forward();
    }
  }

  void _triggerUnlockEffect() {
    if (!mounted) return;

    if (!_isUnlocked) {
      setState(() {
        _isUnlocked = true;
      });
    }

    // 触发解锁特效
    final unlockEffectWidget = _unlockEffectKey.currentState as PhotoUnlockEffectWidgetState?;
    unlockEffectWidget?.showEffect();
  }

  
  void _downloadPhoto() {
    if (!_isUnlocked) return;
    _saveCurrentPhotoToGallery();
  }

  Future<void> _saveCurrentPhotoToGallery() async {
    try {
      // 权限申请（iOS 照片、Android 存储/媒体库）
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        // Android 13 及以上可能需要更细权限
        final imagesStatus = await Permission.photos.request();
        if (!imagesStatus.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请授予相册权限以保存图片')),
          );
          return;
        }
      }

      // 读取当前展示的原图资源（无水印）
      final assetPath = _getCurrentPhotoAsset();
      final byteData = await rootBundle.load(assetPath);
      final Uint8List bytes = byteData.buffer.asUint8List();

      // 保存到相册
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: 'NewPhoto_${_currentPhotoIndex + 1}',
      );

      final isSuccess = (result is Map &&
              (result['isSuccess'] == true || result['isSuccess'] == 'true')) ||
          (result is bool && result == true);

      if (isSuccess) {
        AudioManager().playCoinEffect();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存到相册')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请重试')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存出错: $e')),
      );
    }
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
    _removeTitleSpineOverlay();
    _titleSpineController = null;
    super.dispose();
  }

  Widget _buildDebugControls(double revealProgress) {
    final sliderValue = _debugProgress ?? revealProgress;
    return Column(
      children: [
        Slider(
          value: sliderValue,
          min: 0,
          max: 1,
          divisions: 20,
          label: '${(sliderValue * 100).toStringAsFixed(0)}%',
          onChanged: _setDebugProgress,
        ),
      ],
    );
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
                  final revealProgress =
                      ((_debugProgress ?? _progress).clamp(0.0, 1.0))
                          .toDouble();
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // NEW PHOTO 标题特效改为 Overlay，全屏渲染且不参与排版
                        const SizedBox(height: 50),

                        // 照片框架
                        Container(
                          margin: const EdgeInsets.only(
                              bottom: 10, right: 30, left: 30),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: SizedBox(
                                  height: 400,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.asset(
                                                _getCurrentPhotoAsset(),
                                                fit: BoxFit.cover,
                                              ),
                                              if (revealProgress < 1)
                                                Align(
                                                  alignment:
                                                      Alignment.topCenter,
                                                  child: FractionallySizedBox(
                                                    heightFactor:
                                                        1 - revealProgress,
                                                    widthFactor: 1,
                                                    child: const ColoredBox(
                                                      color: Color(0xE6000000),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (revealProgress < 1)
                                        Align(
                                          alignment: Alignment.topCenter,
                                          child: FractionallySizedBox(
                                            heightFactor: 1 - revealProgress,
                                            widthFactor: 1,
                                            child: Image.asset(
                                              Assets.gallaryGallaryFrameLock,
                                              fit: BoxFit.cover,
                                              alignment: Alignment.topCenter,
                                            ),
                                          ),
                                        ),
                                      if (!_isUnlocked && revealProgress < 1)
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: (() {
                                            const double frameHeight = 400;
                                            const double lineH = 20;
                                            final double raw =
                                                frameHeight * revealProgress -
                                                    (lineH / 2);
                                            return raw.clamp(
                                                0.0, frameHeight - lineH);
                                          })(),
                                          child: Image.asset(
                                            Assets.newPhotoNewPhotoHighline,
                                            height: 20,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 20,
                                left: 20,
                                child: Image.asset(
                                  Assets.newPhotoNewPhotoIconNew,
                                  width: 50,
                                ),
                              )
                            ],
                          ),
                        ),

                        // 进度条
                        Stack(
                          children: [
                            Container(
                              margin:
                                  const EdgeInsets.only(bottom: 30, top: 10),
                              child: Column(
                                children: [
                                  // 进度条背景
                                  Container(
                                    width: 300,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.pink.withOpacity(0.3),
                                    ),
                                    child: Stack(
                                      children: [
                                        // 进度条填充
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 500),
                                          width: 300 * revealProgress,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            gradient: LinearGradient(
                                              colors: _isUnlocked
                                                  ? [
                                                      Colors.green,
                                                      Colors.lightGreen
                                                    ]
                                                  : [
                                                      Colors.pink,
                                                      Colors.pinkAccent
                                                    ],
                                            ),
                                          ),
                                        ),
                                        // 进度文字
                                        Center(
                                          child: OutlinedTextWidget(
                                            text:
                                                '${(revealProgress * 100).toInt()}%',
                                            fontSize: 14,
                                            textColor: Colors.white,
                                            strokeColor: Colors.black,
                                            strokeWidth: 1.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 0,
                              child: Image.asset(
                                Assets.newPhotoNewPhotoIconSlider,
                                width: 50,
                                height: 50,
                              ),
                            ),
                          ],
                        ),

                        // const SizedBox(height: 10),
                        // _buildDebugControls(revealProgress),

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
                                      : Assets
                                          .newPhotoNewPhotoBtnBlueBig, // TODO: 更换为 DownButton_Lock 资源
                                ),
                                fit: BoxFit.fill,
                              ),
                            ),
                            child: Stack(
                              children: [
                                // 按钮内容
                                Padding(
                                  padding: const EdgeInsets.only(top: 13),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // 相机图标
                                      Image.asset(
                                        Assets.newPhotoNewPhotoIconAd,
                                        height: 30,
                                      ),
                                      //color: Colors.grey,
                                      const SizedBox(width: 10),
                                      OutlinedTextWidget(
                                        text: 'DOWNLOAD',
                                        fontSize: 20,
                                        textColor: _isUnlocked
                                            ? Colors.white
                                            : Colors.grey,
                                        strokeColor: Colors.black,
                                        strokeWidth: 1.5,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: const Offset(1, 1),
                                            blurRadius: 2,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // 锁定覆盖层
                                if (!_isUnlocked)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
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
                          child: const OutlinedTextWidget(
                            text: 'NEXT',
                            fontSize: 16,
                            textColor: Colors.white,
                            strokeColor: Colors.black,
                            strokeWidth: 1.0,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 解锁特效 Widget
            PhotoUnlockEffectWidget(key: _unlockEffectKey),
          ],
        ),
      ),
    );
  }
}
