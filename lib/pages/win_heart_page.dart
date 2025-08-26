import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/widgets/common_header.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:spine_flutter/spine_flutter.dart' hide Animation;
import '../widgets/outlined_text_widget.dart';
import '../managers/game_state_manager.dart';
import '../managers/audio_manager.dart';
import 'dart:async';

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
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Spine animation controller
  SpineWidgetController? _spineController;
  bool _isSpineReady = false;
  bool _showButtons = false;

  // Heart rewards
  int _baseHeartReward = 0;
  int _totalHeartReward = 0;
  bool _hasDoubled = false;

  // 动态倍数与计时
  int _currentMultiplier = 2;
  Timer? _idleTimer;
  DateTime? _idleStartTime;
  double _idleDurationSec = 3.0;

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

          // 打印可用动画
          final animations = controller.skeleton.getData()?.getAnimations() ?? [];
          print("HeartGetPage_Eff animations: ${animations.map((a) => a.getName()).toList()}");

          // 初始化后直接按 born -> idle 逻辑播放
          Future.delayed(const Duration(milliseconds: 200), () async {
            if (!mounted) return;

            final data = controller.skeleton.getData();
            String? bornName = animations
                    .map((a) => a.getName())
                    .firstWhere((n) => n == 'HeartGetPage_Eff_born', orElse: () => '')
                    .isNotEmpty
                ? 'HeartGetPage_Eff_born'
                : null;
            bornName ??= animations
                .map((a) => a.getName())
                .firstWhere((n) => n.toLowerCase().contains('born'), orElse: () => '');
            if (bornName.isEmpty) bornName = null;

            String? idleName = animations
                    .map((a) => a.getName())
                    .firstWhere((n) => n == 'HeartGetPage_Eff_idle', orElse: () => '')
                    .isNotEmpty
                ? 'HeartGetPage_Eff_idle'
                : null;
            idleName ??= animations
                .map((a) => a.getName())
                .firstWhere((n) => n.toLowerCase().contains('idle'), orElse: () => '');
            if (idleName.isEmpty) idleName = null;

            try {
              controller.animationState.clearTracks();
              if (bornName != null && data?.findAnimation(bornName) != null) {
                controller.animationState.setAnimationByName(0, bornName, false);
                final duration = (data?.findAnimation(bornName)?.getDuration() ?? 1.0);
                print('✓ Heart born once: $bornName, duration: $duration s');
                await Future.delayed(Duration(milliseconds: (duration * 1000).toInt()));
                if (!mounted) return;
                final next = idleName ?? animations.first.getName();
                if (next.isNotEmpty && data?.findAnimation(next) != null) {
                  controller.animationState.setAnimationByName(0, next, true);
                  print('→ Heart idle loop: $next');
                  _startIdleTiming(next, data);
                } else {
                  print('✗ Heart idle not found');
                }
              } else {
                final next = idleName ?? animations.first.getName();
                if (next.isNotEmpty && data?.findAnimation(next) != null) {
                  controller.animationState.setAnimationByName(0, next, true);
                  print('✓ Heart idle directly: $next');
                  _startIdleTiming(next, data);
                } else {
                  print('✗ Heart no playable animation');
                }
              }

              // 在 born 播完后显示按钮与数值
              if (mounted) {
                setState(() {
                  _isSpineReady = true;
                  _showButtons = true;
                });
              }
            } catch (e) {
              print('Heart animations play failed: $e');
              if (mounted) {
                setState(() {
                  _isSpineReady = true;
                  _showButtons = true;
                });
              }
            }
          });
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
          String name = anim.getName();
          if (name.isNotEmpty) {
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
        print("No born animation found, playing first animation: $firstAnim");
        _spineController!.animationState.setAnimationByName(0, firstAnim, true);

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
            String name = anim.getName();
            if (name.isNotEmpty &&
                (name.toLowerCase().contains('idle') ||
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
            _spineController!.animationState.setAnimationByName(0, firstAnim, true);
            print("No idle animation found, looping first animation: $firstAnim");
          }
        }
      }
    } catch (e) {
      print("Failed to play idle animation: $e");
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
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

    // 只启动标题的渐入动画
    _fadeController.forward();
    // UI元素将在Spine born动画完成后显示
  }

  // 根据 idle 动画时间启动计时，动态计算倍数
  void _startIdleTiming(String idleAnimName, SkeletonData? data) {
    try {
      final anim = data?.findAnimation(idleAnimName);
      _idleDurationSec = anim?.getDuration() ?? 3.0;
    } catch (_) {
      _idleDurationSec = 3.0;
    }
    _idleStartTime = DateTime.now();
    _idleTimer?.cancel();
    _idleTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _idleStartTime == null) return;
      final elapsed = DateTime.now().difference(_idleStartTime!).inMilliseconds / 1000.0;
      final t = _idleDurationSec > 0 ? (elapsed % _idleDurationSec) : elapsed;
      int nextMultiplier = 2;
      if (t < 0.74) {
        // 0 - 0.73
        nextMultiplier = 2;
      } else if (t < 1.0) {
        // 0.74 - 1.0
        nextMultiplier = 3;
      } else if (t < 1.9) {
        // 1.0 - 1.9
        nextMultiplier = 5;
      } else if (t < 2.26) {
        // 1.9 - 2.26
        nextMultiplier = 3;
      } else if (t < 3.0) {
        // 2.26 - 3.0
        nextMultiplier = 2;
      }
      if (nextMultiplier != _currentMultiplier) {
        setState(() {
          _currentMultiplier = nextMultiplier;
        });
      }
    });
  }

  void _getReward() async {
    // Add hearts to player's inventory
    await GameStateManager().addHearts(_baseHeartReward * _currentMultiplier);

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
    _fadeController.dispose();
    _spineController = null;
    _idleTimer?.cancel();
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
            // Spine动画区域 - 占据主要空间
            if (_spineController != null)
              Positioned(
                top: MediaQuery.of(context).padding.top-100, // 避开头部
                left: -140,
                right: 0,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height, // 占据屏幕高度的60%
                  child: SpineWidget.fromAsset(
                    "assets/spine/HeartGetPage_Eff.atlas",
                    "assets/spine/HeartGetPage_Eff.skel",
                    _spineController!,
                    boundsProvider: const SetupPoseBounds(),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

            // 桃心数量文字 (在born动画完成后显示)
            if (_showButtons)
              Positioned(
                top: 260,
                left: 0,
                right: 0,
                child: Center(
                  child: OutlinedTextWidget(
                    text: '+$_totalHeartReward',
                    fontSize: MediaQuery.of(context).size.width * 0.08,
                    textColor: HexColor("#ff2f2f"),
                    strokeColor: Colors.white,
                    strokeWidth: 10,
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
              ),

            // Buttons (show after born animation completes)
            if (_showButtons)
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.1,
                left: 0,
                right: 0,
                child: Column(
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
                            image: AssetImage(Assets.imagesPopBtnGreen),
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
                              text: '+${_baseHeartReward * _currentMultiplier}',
                              fontSize: 20,
                              textColor: Colors.red,
                              strokeColor: Colors.white,
                              strokeWidth: 6.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // GET button
                    GestureDetector(
                      onTap: _getReward,
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
                  ],
                ),
              ),

            // 头部
            const CommonHeader(
              showBackButton: false,
            ),

          ],
        ),
      ),
    );
  }
}
