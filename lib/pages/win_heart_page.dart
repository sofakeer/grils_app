import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/widgets/common_header.dart';
import 'package:grils_app/pages/special_page.dart';
import 'package:spine_flutter/spine_flutter.dart' hide Animation;
import '../widgets/outlined_text_widget.dart';
import '../managers/game_state_manager.dart';
import '../managers/audio_manager.dart';

class WinHeartPage extends StatefulWidget {
  final int currentLevel;
  
  const WinHeartPage({
    super.key,
    this.currentLevel = 1,
  });

  @override
  State<WinHeartPage> createState() => _WinHeartPageState();
}

class _WinHeartPageState extends State<WinHeartPage> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _heartAnimation;
  
  // Spine animation controller
  SpineWidgetController? _spineController;
  bool _isSpineReady = false;
  bool _showButtons = false;
  
  // Heart rewards
  int _baseHeartReward = 0;
  int _totalHeartReward = 0;
  bool _hasDoubled = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _calculateHeartReward();
    _initializeSpineController();
  }
  
  // Calculate heart reward based on current level
  void _calculateHeartReward() {
    int level = widget.currentLevel;
    
    if (level <= 10) {
      _baseHeartReward = 5;
    } else if (level <= 30) {
      _baseHeartReward = 8;
    } else if (level <= 100) {
      _baseHeartReward = 10;
    } else if (level <= 200) {
      _baseHeartReward = 12;
    } else if (level <= 300) {
      _baseHeartReward = 15;
    } else if (level <= 400) {
      _baseHeartReward = 18;
    } else {
      _baseHeartReward = 20;
    }
    
    _totalHeartReward = _baseHeartReward;
  }
  
  // Initialize Spine controller
  void _initializeSpineController() {
    try {
      _spineController = SpineWidgetController(onInitialized: (controller) {
        if (!mounted) return;
        
        try {
          controller.animationState.getData().setDefaultMix(0.2);
          
          setState(() {
            _isSpineReady = true;
          });
          
          // Play born animation first
          _playBornAnimation();
        } catch (e) {
          print("Spine initialization failed: $e");
        }
      });
    } catch (e) {
      print("Spine controller creation failed: $e");
    }
  }
  
  // Play the born animation
  void _playBornAnimation() async {
    if (_spineController == null || !_isSpineReady) return;
    
    try {
      // Play HeartGetPage_Eff_born animation
      _spineController!.animationState.setAnimationByName(0, "HeartGetPage_Eff_born", false);
      
      // Get animation duration
      final animation = _spineController!.skeleton.getData()?.findAnimation("HeartGetPage_Eff_born");
      double duration = 1.0; // Default 1 second
      if (animation != null) {
        duration = animation.getDuration();
      }
      
      // Wait for born animation to complete
      await Future.delayed(Duration(milliseconds: (duration * 1000).toInt()));
      
      // Show buttons and heart value after born animation
      if (mounted) {
        setState(() {
          _showButtons = true;
        });
        
        // Start playing idle animation loop
        _playIdleAnimation();
      }
    } catch (e) {
      print("Failed to play born animation: $e");
      // Fallback to idle animation
      _playIdleAnimation();
    }
  }
  
  // Play the idle animation loop
  void _playIdleAnimation() {
    if (_spineController == null || !_isSpineReady) return;
    
    try {
      // Play HeartGetPage_Eff_idle animation in loop
      _spineController!.animationState.setAnimationByName(0, "HeartGetPage_Eff_idle", true);
    } catch (e) {
      print("Failed to play idle animation: $e");
    }
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.3,
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

    _heartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeInOut,
    ));

    // 启动动画序列
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _scaleController.forward();
      }
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _heartController.forward();
      }
    });
  }

  void _getReward() async {
    // Add hearts to player's inventory
    await GameStateManager().addHearts(_totalHeartReward);
    
    // Play reward sound
    await AudioManager().playHeartEffect();
    
    // Close the page
    Navigator.of(context).pop();
  }
  
  void _doubleReward() async {
    if (_hasDoubled) return;
    
    // TODO: Show ad here
    // For now, just double the reward
    
    setState(() {
      _hasDoubled = true;
      _totalHeartReward = _baseHeartReward * 2;
    });
    
    // Play double reward sound
    await AudioManager().playHeartEffect();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _heartController.dispose();
    _spineController = null;
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
            image: AssetImage(Assets.winHeartWinHeartBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // 头部
            const CommonHeader(
              showBackButton: false,
            ),

            // 主要内容
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // VICTORY 标题
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Image.asset(
                            Assets.winHeartWinHeartTitle,
                            height: 150,
                          ),
                        ),
                      );
                    },
                  ),

                  // Spine动画区域
                  Container(
                    height: 350,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Spine animation
                        if (_spineController != null && _isSpineReady)
                          SizedBox(
                            width: 350,
                            height: 350,
                            child: SpineWidget.fromAsset(
                              "assets/spine/HeartGetPage_Eff.atlas",
                              "assets/spine/HeartGetPage_Eff.skel",
                              _spineController!,
                              boundsProvider: SetupPoseBounds(),
                            ),
                          ),
                        
                        // Heart reward display (shows after born animation)
                        if (_showButtons)
                          Positioned(
                            top: 140,
                            child: AnimatedBuilder(
                              animation: _scaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Heart icon
                                      Image.asset(
                                        Assets.imagesIconHeart2x,
                                        height: 80,
                                      ),
                                      // Heart count
                                      Positioned(
                                        bottom: 10,
                                        child: OutlinedTextWidget(
                                          text: '+$_totalHeartReward',
                                          fontSize: 24,
                                          textColor: Colors.white,
                                          strokeColor: Colors.red,
                                          strokeWidth: 2,
                                          fontWeight: FontWeight.bold,
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

                  // Buttons (show after born animation)
                  if (_showButtons) ...[
                    // Double reward button
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: GestureDetector(
                            onTap: !_hasDoubled ? _doubleReward : null,
                            child: Container(
                              width: 200,
                              height: 60,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                    _hasDoubled 
                                      ? Assets.newPhotoNewPhotoBtnBlueBig
                                      : Assets.newPhotoNewPhotoBtnBlueBig,
                                  ),
                                  fit: BoxFit.fill,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Ad icon
                                  Image.asset(
                                    Assets.newPhotoNewPhotoIconAd,
                                    height: 30,
                                    color: _hasDoubled ? Colors.grey : null,
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedTextWidget(
                                    text: '+100',
                                    fontSize: 20,
                                    textColor: _hasDoubled ? Colors.grey : Colors.white,
                                    strokeColor: Colors.black,
                                    strokeWidth: 1.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // GET button
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: GestureDetector(
                            onTap: _getReward,
                            child: Container(
                              width: 150,
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
                              child: const Center(
                                child: OutlinedTextWidget(
                                  text: 'GET',
                                  fontSize: 28,
                                  textColor: Colors.white,
                                  strokeColor: Colors.black,
                                  strokeWidth: 2.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            // 装饰性光效
            ...List.generate(6, (index) {
              return Positioned(
                left: (index * 80.0) % MediaQuery.of(context).size.width,
                top: (index * 100.0) % MediaQuery.of(context).size.height,
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value * 0.6,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.yellow.withOpacity(0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.yellow.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
