import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/widgets/common_header.dart';
import 'package:grils_app/pages/new_photo_page.dart';
import 'package:grils_app/pages/win_heart_page.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:spine_flutter/spine_flutter.dart' hide Animation;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/coin_calculator.dart';
import '../managers/audio_manager.dart';
import '../widgets/outlined_text_widget.dart';
import '../services/user_service.dart';

class WinPage extends StatefulWidget {
  final int level;
  
  const WinPage({super.key, this.level = 1});

  @override
  State<WinPage> createState() => _WinPageState();
}

class _WinPageState extends State<WinPage> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  // Spine animation controller
  SpineWidgetController? _spineController;
  // 全屏特效 Overlay
  OverlayEntry? _spineOverlayEntry;
  // 保留占位：未来若需要基于初始化完成再做UI切换可恢复使用
  // bool _isSpineReady = false;
  int _coinReward = 0;
  bool _isClaimingReward = false;

  @override
  void initState() {
    super.initState();
    
    // 立即播放结算音效，避免延迟
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioManager().playSettlementCoin();
    });
    
    _initializeAnimations();
    _initializeSpine();
    _calculateCoinReward();

    // 在首帧后插入全屏 Overlay，不参与排版
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insertSpineOverlay();
    });
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
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

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
  }

  void _initializeSpine() {
    try {
      _spineController = SpineWidgetController(onInitialized: (controller) {
        try {
          final data = controller.skeleton.getData();
          final animations = data?.getAnimations() ?? [];

          // 设置默认混合，避免切换生硬
          try {
            controller.animationState.getData().setDefaultMix(0.2);
          } catch (_) {}

          // 已不依赖 _isSpineReady 控制渲染，避免初始化死锁

          // 打印所有可用动画名称进行调试
          print('Available animations: ${animations.map((a) => a.getName()).toList()}');

          if (animations.isNotEmpty) {
            // 延迟播放动画，确保控件已经渲染
            Future.delayed(const Duration(milliseconds: 200), () async {
              if (!mounted) return;

              // 先找精确名，再用包含匹配兜底
              String? bornName = animations
                  .map((a) => a.getName())
                  .firstWhere((n) => n == 'CoinWin_Eff_born', orElse: () => '')
                  .isNotEmpty
                  ? 'CoinWin_Eff_born'
                  : null;
              bornName ??= animations
                  .map((a) => a.getName())
                  .firstWhere((n) => n.toLowerCase().contains('born'), orElse: () => '');
              if (bornName.isEmpty) bornName = null;

              // 专门查找散花效果动画
              String? winbornName = animations
                  .map((a) => a.getName())
                  .firstWhere((n) => n == 'winborn', orElse: () => '')
                  .isNotEmpty
                  ? 'winborn'
                  : null;
              winbornName ??= animations
                  .map((a) => a.getName())
                  .firstWhere((n) => n.toLowerCase().contains('winborn'), orElse: () => '');
              if (winbornName.isEmpty) winbornName = null;

              String? idleName = animations
                  .map((a) => a.getName())
                  .firstWhere((n) => n == 'CoinWin_Eff_idle', orElse: () => '')
                  .isNotEmpty
                  ? 'CoinWin_Eff_idle'
                  : null;
              idleName ??= animations
                  .map((a) => a.getName())
                  .firstWhere((n) => n.toLowerCase().contains('idle'), orElse: () => '');
              if (idleName.isEmpty) idleName = null;

              try {
                controller.animationState.clearTracks();
                
                // 优先播放winborn散花效果
                if (winbornName != null && data?.findAnimation(winbornName) != null) {
                  // 播放 winborn 散花效果一次
                  controller.animationState.setAnimationByName(0, winbornName, false);
                  final duration = (data?.findAnimation(winbornName)?.getDuration() ?? 1.0);
                  print('✓ Playing winborn confetti effect: $winbornName, duration: $duration s');
                  // 等 winborn 结束后切 idle 循环
                  await Future.delayed(Duration(milliseconds: (duration * 1000).toInt()));
                  if (!mounted) return;
                  final next = idleName ?? animations.first.getName();
                  if (next.isNotEmpty && data?.findAnimation(next) != null) {
                    controller.animationState.setAnimationByName(0, next, true);
                    print('→ Switched to idle loop after winborn: $next');
                  } else {
                    print('✗ Idle animation not found after winborn');
                  }
                } else if (bornName != null && data?.findAnimation(bornName) != null) {
                  // 播放 born 一次
                  controller.animationState.setAnimationByName(0, bornName, false);
                  final duration = (data?.findAnimation(bornName)?.getDuration() ?? 1.0);
                  print('✓ Playing born once: $bornName, duration: $duration s');
                  // 等 born 结束后切 idle 循环；若无 idle 则停留在 born 的最终帧
                  await Future.delayed(Duration(milliseconds: (duration * 1000).toInt()));
                  if (!mounted) return;
                  final next = idleName ?? animations.first.getName();
                  if (next.isNotEmpty && data?.findAnimation(next) != null) {
                    controller.animationState.setAnimationByName(0, next, true);
                    print('→ Switched to idle loop: $next');
                  } else {
                    print('✗ Idle animation not found, staying after born');
                  }
                } else {
                  // 没有 winborn 或 born，直接 idle 循环；再没有就用第一条循环
                  final next = idleName ?? animations.first.getName();
                  if (next.isNotEmpty && data?.findAnimation(next) != null) {
                    controller.animationState.setAnimationByName(0, next, true);
                    print('✓ Started idle loop directly: $next');
                  } else {
                    print('✗ No playable animation found');
                  }
                }
              } catch (e) {
                print('Failed to play animations: $e');
              }
            });
          } else {
            print('No animations found in spine file!');
          }
        } catch (e) {
          print('Spine animation initialization failed: $e');
        }
      });
    } catch (e) {
      print('Spine controller creation failed: $e');
    }
  }

  void _insertSpineOverlay() {
    if (!mounted || _spineOverlayEntry != null) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _spineOverlayEntry = OverlayEntry(
      builder: (context) {
        return IgnorePointer(
          ignoring: true, // 仅展示特效，点击穿透
          child: Positioned.fill(
            child: _spineController == null
                ? const SizedBox.shrink()
                : Center(
                  child: Transform.translate(
                     offset:Offset(0,-150),
                    child: SizedBox(

                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: SpineWidget.fromAsset(
                        "assets/spine/CoinWin_Eff.atlas",
                        "assets/spine/CoinWin_Eff.skel",
                        _spineController!,
                        boundsProvider: const SetupPoseBounds(),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
            ),
          ),
        );
      },
    );

    overlay.insert(_spineOverlayEntry!);
  }

  void _removeSpineOverlay() {
    try {
      _spineOverlayEntry?.remove();
      _spineOverlayEntry = null;
    } catch (_) {}
  }

  void _calculateCoinReward() {
    _coinReward = CoinCalculator.calculateCoinsForLevel(widget.level);
    if (mounted) {
      setState(() {});
    }
  }

  void _getReward() async {
    if (_isClaimingReward) return;
    setState(() {
      _isClaimingReward = true;
    });

    // 播放获得金币特效音效
    await AudioManager().playCoinEffect();

    // 增加金币到用户数据
    await UserService.instance.initialize();
    if (_coinReward > 0) {
      await UserService.instance.addCoins(_coinReward);
      print('WinPage: Added coin reward $_coinReward');
    }
    
    // 检查是否所有80张照片都已解锁
    final prefs = await SharedPreferences.getInstance();
    final allPhotosUnlocked = prefs.getBool('all_photos_unlocked') ?? false;
    
    if (allPhotosUnlocked) {
      // 如果所有照片都解锁了，直接跳转到爱心货币界面
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const WinHeartPage(),
        ),
      );
    } else {
      // 跳转到新照片页面
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => NewPhotoPage(level: widget.level),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _removeSpineOverlay();
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
            image: AssetImage(Assets.wincoinWinCoinBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // 背景装饰
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.purple.withOpacity(0.3),
                            Colors.blue.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const CommonHeader(showBackButton: false),
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
                        // WIN 标题特效改为 Overlay，全屏渲染且不参与排版
                        const SizedBox(height: 50),

                        // 奖励信息
                        Container(
                          margin: const EdgeInsets.only(bottom: 80),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                Assets.wincoinWinCoinIconCoin,
                                width: 80,
                                height: 80,
                              ),
                              const SizedBox(width: 10),
                              OutlinedTextWidget(
                                text: '+$_coinReward',
                                fontSize: 42,
                                textColor: HexColor("#ffe239"),
                                strokeColor: HexColor("#d44c0a"),
                                strokeWidth: 8,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(
                                    offset: Offset(2, 2),
                                    blurRadius: 4,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 底部按钮已移至 Stack 的 Positioned，不再参与列排版
                      ],
                    ),
                  );
                },
              ),
            ),

            // 底部 GET 按钮（固定在底部居中，考虑安全区）
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: SafeArea(
                minimum: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: GestureDetector(
                    onTap: _isClaimingReward ? null : _getReward,
                    child: Container(
                      width: 220,
                      height: 74,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(Assets.wincoinWinCoinBtnGreen),
                          fit: BoxFit.fill,
                        ),
                      ),
                      child: const Center(
                        child: OutlinedTextWidget(
                          text: 'GET',
                          fontSize: 28,
                          textColor: Colors.white,
                          strokeColor: Colors.black,
                          strokeWidth: 2.0,
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
                    ),
                  ),
                ),
              ),
            ),

            // // 装饰性星星
            // ...List.generate(8, (index) {
            //   return Positioned(
            //     left: (index * 50.0) % MediaQuery.of(context).size.width,
            //     top: (index * 60.0) % MediaQuery.of(context).size.height,
            //     child: AnimatedBuilder(
            //       animation: _fadeAnimation,
            //       builder: (context, child) {
            //         return Opacity(
            //           opacity: _fadeAnimation.value,
            //           child: const Icon(
            //             Icons.star,
            //             color: Colors.yellow,
            //             size: 20,
            //           ),
            //         );
            //       },
            //     ),
            //   );
            // }),
          ],
        ),
      ),
    );
  }
}
