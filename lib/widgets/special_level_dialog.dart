import 'package:flutter/material.dart';
import 'package:spine_flutter/spine_flutter.dart' hide Animation;
import '../generated/assets.dart';
import '../managers/audio_manager.dart';
import '../widgets/outlined_text_widget.dart';
import '../pages/special_game_page.dart';
import '../pages/win_heart_page.dart';

class SpecialLevelDialog extends StatefulWidget {
  final VoidCallback? onSkip;
  final int currentLevel;
  
  const SpecialLevelDialog({
    super.key,
    this.onSkip,
    required this.currentLevel,
  });

  @override
  State<SpecialLevelDialog> createState() => _SpecialLevelDialogState();
}

class _SpecialLevelDialogState extends State<SpecialLevelDialog> with TickerProviderStateMixin {
  // Spine动画控制器
  SpineWidgetController? _spineController;
  bool _isSpineReady = false;
  
  // 动画控制器
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // 广告状态
  bool _isShowingAd = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSpineController();
    
    // 播放特殊关卡音效
    AudioManager().playSpecialEffect();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // 启动动画
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _scaleController.forward();
      }
    });
  }

  void _initializeSpineController() {
    try {
      _spineController = SpineWidgetController(onInitialized: (controller) {
        if (!mounted) return;
        
        try {
          controller.animationState.getData().setDefaultMix(0.2);
          
          // 获取所有动画
          final animations = controller.skeleton.getData()?.getAnimations();
          if (animations != null && animations.isNotEmpty) {
            setState(() {
              _isSpineReady = true;
            });
            
            // 播放 Special_Eff_born 动画
            _playBornAnimation();
          }
        } catch (e) {
          print("Special spine initialization failed: $e");
        }
      });
    } catch (e) {
      print("Special spine controller creation failed: $e");
    }
  }
  
  void _playBornAnimation() async {
    if (_spineController == null || !_isSpineReady) return;
    
    try {
      // 尝试播放 born 动画
      final animations = _spineController!.skeleton.getData()?.getAnimations();
      String? bornAnimName;
      String? idleAnimName;
      
      // 查找 born 和 idle 动画
      for (var anim in animations!) {
        String? name = anim.getName();
        if (name != null) {
          if (name.toLowerCase().contains('born')) {
            bornAnimName = name;
          } else if (name.toLowerCase().contains('idle')) {
            idleAnimName = name;
          }
        }
      }
      
      if (bornAnimName != null) {
        // 播放 born 动画
        _spineController!.animationState.setAnimationByName(0, bornAnimName, false);
        
        // 获取动画时长
        final animation = _spineController!.skeleton.getData()?.findAnimation(bornAnimName);
        double duration = 1.0;
        if (animation != null) {
          duration = animation.getDuration();
        }
        
        // 等待 born 动画完成后播放 idle
        await Future.delayed(Duration(milliseconds: (duration * 1000).toInt()));
        
        if (mounted && idleAnimName != null) {
          _playIdleAnimation(idleAnimName);
        }
      } else if (idleAnimName != null) {
        // 如果没有 born 动画，直接播放 idle
        _playIdleAnimation(idleAnimName);
      }
    } catch (e) {
      print("Failed to play born animation: $e");
    }
  }
  
  void _playIdleAnimation(String animName) {
    if (_spineController == null || !_isSpineReady) return;
    
    try {
      // 循环播放 idle 动画
      _spineController!.animationState.setAnimationByName(0, animName, true);
    } catch (e) {
      print("Failed to play idle animation: $e");
    }
  }

  void _onPlayPressed() async {
    if (_isShowingAd) return;
    
    setState(() {
      _isShowingAd = true;
    });
    
    // 播放按钮音效
    await AudioManager().playPopupOpen();
    
    // TODO: 这里应该播放真实的视频广告
    // 目前使用模拟广告
    bool adCompleted = await _showMockVideoAd();
    
    if (adCompleted && mounted) {
      // 关闭弹窗
      Navigator.of(context).pop();
      
      // 进入特殊关卡
      final bool? won = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const SpecialGamePage(),
        ),
      );
      
      // 如果赢了特殊关卡，显示心形奖励页面
      if (won == true && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WinHeartPage(
              currentLevel: widget.currentLevel,
            ),
          ),
        );
      }
    }
    
    if (mounted) {
      setState(() {
        _isShowingAd = false;
      });
    }
  }
  
  // 模拟视频广告
  Future<bool> _showMockVideoAd() async {
    // 模拟广告播放时间
    await Future.delayed(const Duration(seconds: 2));
    // 直接返回 true 表示广告播放完成
    return true;
  }

  void _onSkipPressed() {
    AudioManager().playExit();
    Navigator.of(context).pop();
    widget.onSkip?.call();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _spineController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                      maxHeight: 600,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.purple.shade900,
                          Colors.purple.shade700,
                          Colors.pink.shade600,
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          // 背景装饰
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _StarsPainter(),
                            ),
                          ),
                          
                          // 主要内容
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 标题
                                const OutlinedTextWidget(
                                  text: 'SPECIAL LEVEL',
                                  fontSize: 32,
                                  textColor: Colors.white,
                                  strokeColor: Colors.purple,
                                  strokeWidth: 3,
                                  fontWeight: FontWeight.bold,
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Spine动画
                                if (_isSpineReady && _spineController != null)
                                  SizedBox(
                                    height: 200,
                                    child: SpineWidget.fromAsset(
                                      "assets/spine/Special_Eff.atlas",
                                      "assets/spine/Special_Eff.skel",
                                      _spineController!,
                                      boundsProvider: SetupPoseBounds(),
                                    ),
                                  )
                                else
                                  const SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                
                                const SizedBox(height: 20),
                                
                                // 说明文字
                                const OutlinedTextWidget(
                                  text: 'Complete special level\nto earn BONUS hearts!',
                                  fontSize: 18,
                                  textColor: Colors.white,
                                  strokeColor: Colors.black,
                                  strokeWidth: 1.5,
                                  fontWeight: FontWeight.normal,
                                  textAlign: TextAlign.center,
                                ),
                                
                                const SizedBox(height: 30),
                                
                                // Play按钮
                                GestureDetector(
                                  onTap: _isShowingAd ? null : _onPlayPressed,
                                  child: Opacity(
                                    opacity: _isShowingAd ? 0.5 : 1.0,
                                    child: Container(
                                      width: 200,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green.shade400,
                                            Colors.green.shade600,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.shade800,
                                            offset: const Offset(0, 3),
                                            blurRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.play_circle_filled,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          const OutlinedTextWidget(
                                            text: 'PLAY',
                                            fontSize: 24,
                                            textColor: Colors.white,
                                            strokeColor: Colors.black,
                                            strokeWidth: 1.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 15),
                                
                                // Skip按钮
                                GestureDetector(
                                  onTap: _isShowingAd ? null : _onSkipPressed,
                                  child: Opacity(
                                    opacity: _isShowingAd ? 0.5 : 1.0,
                                    child: const OutlinedTextWidget(
                                      text: 'SKIP',
                                      fontSize: 20,
                                      textColor: Colors.white70,
                                      strokeColor: Colors.black,
                                      strokeWidth: 1.0,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// 星星背景绘制器
class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // 绘制一些装饰性的星星
    final stars = [
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.9, size.height * 0.15),
      Offset(size.width * 0.15, size.height * 0.8),
      Offset(size.width * 0.85, size.height * 0.85),
      Offset(size.width * 0.5, size.height * 0.05),
    ];
    
    for (var star in stars) {
      _drawStar(canvas, star, 8, paint);
    }
  }
  
  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90) * 3.14159 / 180;
      final x = center.dx + radius * (i.isEven ? 1 : 0.3) * (i < 2 ? 1 : -1);
      final y = center.dy + radius * (i.isOdd ? 1 : 0.3) * (i == 1 || i == 2 ? 1 : -1);
      if (i == 0) {
        path.moveTo(x, center.dy);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
