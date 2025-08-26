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
      // Get all available animations
      final animations = _spineController!.skeleton.getData()?.getAnimations();
      String? bornAnimName;
      String? idleAnimName;
      
      if (animations != null) {
        print("=== Available Animations ===");
        for (var anim in animations) {
          String? name = anim.getName();
          if (name != null) {
            print("Found animation: $name");
            
            // Look for born animation (various possible names)
            if (name.toLowerCase().contains('born') || 
                name.toLowerCase().contains('start') ||
                name.toLowerCase().contains('appear')) {
              bornAnimName ??= name;
            }
            
            // Look for idle animation (various possible names)
            if (name.toLowerCase().contains('idle') || 
                name.toLowerCase().contains('loop') ||
                name.toLowerCase().contains('wait')) {
              idleAnimName ??= name;
            }
          }
        }
        print("=== End Animation List ===");
      }
      
      if (bornAnimName != null) {
        // Play born animation (non-looping)
        print("Playing born animation: $bornAnimName");
        _spineController!.animationState.setAnimationByName(0, bornAnimName, false);
        
        // Get animation duration
        final animation = _spineController!.skeleton.getData()?.findAnimation(bornAnimName);
        double duration = 2.0; // Default 2 seconds
        if (animation != null) {
          duration = animation.getDuration();
        }
        
        print("Born animation duration: ${duration}s");
        
        // Wait for born animation to complete
        await Future.delayed(Duration(milliseconds: (duration * 1000).toInt()));
        
        // Show UI elements after born animation completes
        if (mounted) {
          setState(() {
            _showButtons = true;
          });
          
          // Start playing idle animation loop
          if (idleAnimName != null) {
            _playIdleAnimation(idleAnimName);
          }
        }
      } else if (animations != null && animations.isNotEmpty) {
        // No born animation found, play first available animation
        final firstAnim = animations.first.getName();
        if (firstAnim != null) {
          print("No born animation found, playing first animation: $firstAnim");
          _spineController!.animationState.setAnimationByName(0, firstAnim, true);
        }
        
        // Show UI immediately
        setState(() {
          _showButtons = true;
        });
      } else {
        // No animations found at all
        print("No animations found in spine file!");
        setState(() {
          _showButtons = true;
        });
      }
    } catch (e) {
      print("Failed to play born animation: $e");
      // Fallback: show UI immediately
      setState(() {
        _showButtons = true;
      });
    }
  }
  
  // Play the idle animation loop
  void _playIdleAnimation([String? animName]) {
    if (_spineController == null || !_isSpineReady) return;
    
    try {
      if (animName != null) {
        // Use provided animation name
        _spineController!.animationState.setAnimationByName(0, animName, true);
        print("Playing idle animation: $animName (looping)");
      } else {
        // Try to find any idle-like animation
        final animations = _spineController!.skeleton.getData()?.getAnimations();
        if (animations != null) {
          for (var anim in animations) {
            String? name = anim.getName();
            if (name != null && (name.toLowerCase().contains('idle') || 
                                name.toLowerCase().contains('loop') ||
                                name.toLowerCase().contains('wait'))) {
              _spineController!.animationState.setAnimationByName(0, name, true);
              print("Playing idle animation: $name (looping)");
              return;
            }
          }
          
          // If no idle animation found, loop the first animation
          if (animations.isNotEmpty) {
            final firstAnim = animations.first.getName();
            if (firstAnim != null) {
              _spineController!.animationState.setAnimationByName(0, firstAnim, true);
              print("No idle animation found, looping first animation: $firstAnim");
            }
          }
        }
      }
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

    // 只启动标题的渐入动画
    _fadeController.forward();
    // UI元素将在Spine born动画完成后显示
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

                  // Spine动画区域 - 完全由Spine动画控制显示
                  Container(
                    height: 400,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Spine animation - 完全接管中间区域显示
                        if (_spineController != null && _isSpineReady)
                          SizedBox(
                            width: 400,
                            height: 400,
                            child: SpineWidget.fromAsset(
                              "assets/spine/HeartGetPage_Eff.atlas",
                              "assets/spine/HeartGetPage_Eff.skel",
                              _spineController!,
                              boundsProvider: const SetupPoseBounds(),
                              fit: BoxFit.contain,
                            ),
                          ),
                        
                        // 只显示桃心数量文字 (在born动画完成后显示)
                        if (_showButtons)
                          Positioned(
                            bottom: 50,
                            child: OutlinedTextWidget(
                              text: '+$_totalHeartReward',
                              fontSize: 32,
                              textColor: Colors.white,
                              strokeColor: Colors.red,
                              strokeWidth: 3.0,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Buttons (show after born animation completes)
                  if (_showButtons)
                    Column(
                      children: [
                        // Double reward button
                        GestureDetector(
                          onTap: !_hasDoubled ? _doubleReward : null,
                          child: Container(
                            width: 200,
                            height: 60,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(Assets.newPhotoNewPhotoBtnBlueBig),
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
                        
                        // GET button
                        GestureDetector(
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
                      ],
                    ),
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
