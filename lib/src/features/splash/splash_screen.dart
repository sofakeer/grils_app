import 'dart:math';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:game_image_app/src/features/home/home_page.dart';
import 'package:game_image_app/src/features/splash/web_view_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/analytics_manager.dart';
import '../../services/firebase_config_service.dart';
import '../../services/level_image_sequence_service.dart';
import '../../providers/user_type_provider.dart';
import '../../services/logger.dart';
import '../../services/image_preloader_service.dart';
import '../../widgets/small_button.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  bool _isDataLoaded = false;
  bool _isAgreementChecked = true;
  bool _isPaused = false; // 添加暂停状态
  bool _isImagePreloaded = false; // 图片预加载状态
  
  // 配置加载计时器
  late DateTime _configLoadStartTime;

  // 背景图片列表
  static const List<String> _backgroundImages = [
    'assets/splash_backgrounds/bg_1.png',
    'assets/splash_backgrounds/bg_2.png',
    'assets/splash_backgrounds/bg_3.png',
    'assets/splash_backgrounds/bg_4.png',
    'assets/splash_backgrounds/bg_5.png',
    'assets/splash_backgrounds/bg_6.png',
    'assets/splash_backgrounds/bg_7.png',
    'assets/splash_backgrounds/bg_8.png',
    'assets/splash_backgrounds/bg_9.png',
    'assets/splash_backgrounds/bg_10.png',
    'assets/splash_backgrounds/bg_11.png',
    'assets/splash_backgrounds/bg_12.png',
    'assets/splash_backgrounds/bg_13.png',
  ];

  late String _selectedBackground;

  @override
  void initState() {
    super.initState();

    // 随机选择背景图片
    _selectedBackground = _backgroundImages[Random().nextInt(_backgroundImages.length)];

    // 记录进入loading页面埋点
    AnalyticsManager().logLoading();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    _initializeAppData();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  double _progressValue = 0.0;

  Future<void> _initializeAppData() async {
    try {
      // 记录配置加载开始时间
      _configLoadStartTime = DateTime.now();
      Log.game('🚀 开始应用初始化 - 配置加载开始');
      
      // 并行加载配置、数据和预加载图片，提高启动速度
      await Future.wait([
        _loadConfig(),
        _initializeData(),
        _preloadImages(),
      ], eagerError: false); // 即使配置加载失败，也不影响整体流程

      // 计算配置加载耗时
      final configLoadDuration = DateTime.now().difference(_configLoadStartTime);
      Log.game('✅ 应用初始化完成 - 总耗时: ${configLoadDuration.inMilliseconds}ms');

      // 所有数据加载完成
      setState(() {
        _isDataLoaded = true;
        _isImagePreloaded = true; // 图片预加载现在是异步的，不影响启动
      });

      // 数据加载完后，让进度条动画到100%
      setState(() {
        _progressValue = 1.0;
      });

      // 启动进度条动画
      await _progressController.forward();

    } catch (e) {
      Log.e('SPLASH', '应用初始化异常: $e');
      // 即使出错，也要确保数据已加载，避免卡住
      if (!_isDataLoaded) {
        await _initializeData();
      }
      // 图片预加载现在是异步的，不需要等待
    }
  }

  Future<void> _initializeData() async {
    try {
      // 模拟数据加载（可以替换为实际的数据加载逻辑）
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _isDataLoaded = true;
      });

    } catch (e) {
      print('Error loading user stats: $e');
    }
  }

  Future<void> _preloadImages() async {
    try {
      Log.game('🖼️ 开始预加载图片...');
      
      // 获取图片预加载服务
      final preloaderService = ref.read(imagePreloaderServiceProvider);
      
      // 完全异步预加载，不阻塞启动
      unawaited(_preloadImagesAsync(preloaderService));
      
      Log.game('✅ 图片预加载启动完成');
      
    } catch (e) {
      Log.e('SPLASH', '图片预加载异常: $e');
    }
  }

  Future<void> _preloadImagesAsync(ImagePreloaderService preloaderService) async {
    try {
      // 先预加载四选一弹窗第一组 4 张图（不消费序列）
      final configService = ref.read(firebaseConfigServiceProvider);
      final userType = ref.read(userTypeProvider);
      final config = configService.getDefaultConfig(userType);
      final bTotal = configService.getTotalCountForLevelType('b', config);
      final cTotal = configService.getTotalCountForLevelType('c', config);
      final firstGroupIndices = LevelImageSequenceService().peekNextGroup(bTotal, cTotal);
      final firstGroupImageIds = [
        for (var i = 0; i < firstGroupIndices.length; i++)
          i < 2 ? 'level_b_${firstGroupIndices[i] + 1}' : 'level_c_${firstGroupIndices[i] + 1}',
      ];
      await preloaderService.preloadSpecificImages(ref, firstGroupImageIds, context);

      // 再预加载必需图片（高优先级）
      await preloaderService.preloadRequiredImages(ref, context);
      
      // 然后预加载所有图片
      await preloaderService.preloadAllImages(ref, context);
      
    } catch (e) {
      Log.e('SPLASH', '异步图片预加载异常: $e');
    }
  }

  Future<void> _loadConfig() async {
    Log.game('🔄 开始加载配置...');
    
    // 检查网络连接状态
    final connectivityStartTime = DateTime.now();
    final connectivityResult = await Connectivity().checkConnectivity();
    final connectivityDuration = DateTime.now().difference(connectivityStartTime);
    
    Log.network('网络连接检查完成 - 耗时: ${connectivityDuration.inMilliseconds}ms, 状态: $connectivityResult');
    
    if (connectivityResult.contains(ConnectivityResult.none)) {
      Log.network('❌ 无网络连接，将使用本地配置');
      Log.game('📱 使用本地默认配置 - 无网络环境');
      return;
    }
    
    Log.network('✅ 网络连接正常，尝试获取远程配置');
    
    try {
      // 添加超时机制，防止无网络时长时间等待
      await Future.any([
        _loadRemoteConfig(),
        Future.delayed(const Duration(seconds: 3), () => throw TimeoutException('Config loading timeout')),
      ]);
      
    } catch (e) {
      Log.e('CONFIG', '❌ 远程配置加载失败: $e');
      Log.game('📱 远程配置加载失败，将使用本地配置');
      // 失败时不设置任何内容，让系统使用本地默认配置
    }
  }

  Future<void> _loadRemoteConfig() async {
    Log.game('🌐 尝试获取远程配置...');
    
    try {
      final remoteConfigStartTime = DateTime.now();
      
      // 获取用户类型
      final userType = ref.read(userTypeProvider);
      Log.game('👤 用户类型: $userType');
      
      // 获取Firebase配置服务
      final configService = FirebaseConfigService();
      
      // 获取配置
      final config = await configService.fetchConfig(userType);
      final remoteConfigDuration = DateTime.now().difference(remoteConfigStartTime);
      
      if (config != null) {
        Log.game('✅ 远程配置获取成功 - 耗时: ${remoteConfigDuration.inMilliseconds}ms');
        Log.game('📦 配置版本: ${config.version}');
        Log.game('📦 配置更新时间: ${config.lastUpdated}');
        Log.game('📦 LevelA图片总数: ${config.images.levelA.totalCount}');
        Log.game('📦 LevelB图片总数: ${config.images.levelB.totalCount}');
        Log.game('📦 LevelC图片总数: ${config.images.levelC.totalCount}');
        Log.game('📦 套图数量: ${config.secrets.sets.length}');
        Log.game('📦 宝藏图片总数: ${config.treasure.totalCount}');
      } else {
        Log.w('CONFIG', '⚠️ 远程配置为空，使用默认配置');
        Log.game('📱 远程配置为空，使用本地默认配置');
      }
      
    } catch (e) {
      Log.e('CONFIG', '❌ 远程配置获取异常: $e');
      Log.game('📱 远程配置获取异常，将使用本地配置');
      rethrow;
    }
  }

  Future<bool?> _showConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // 防止点击外部关闭对话框
      builder: (BuildContext context) {
        return WillPopScope(
          // 防止返回键关闭对话框
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/diaog_bg_big.png'),
                  fit: BoxFit.fill,
                ),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 20),
                  const Text(
                    'Login to the App?',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: "After agreeing to the ",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          TextSpan(
                            text: "Privacy Policy",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              decoration: TextDecoration.underline, // 添加下划线
                              decorationColor: Colors.white, // 下划线颜色（可选）
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // 点击事件处理
                                print('Privacy Policy clicked');
                                // 可以打开链接或新页面
                                // launchUrl(Uri.parse('https://your-privacy-policy-url'));
                                // 或者导航到新页面
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WebViewScreen(
                                      title: 'Privacy Agreement',
                                      url: 'https://fantasy-ball-quest.web.app/privacy.html',
                                    ),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(
                            text: " & ",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: "User Agreement",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              decoration: TextDecoration.underline, // 添加下划线
                              decorationColor: Colors.white70, // 下划线颜色（可选）
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WebViewScreen(
                                      title: 'User Agreement',
                                      url: 'https://fantasy-ball-quest.web.app/terms.html',
                                    ),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(
                            text: ' can we provide you with game services, Confirm the agreement?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // HOME 按钮（蓝色图片背景）
                      SmallButtonHelper.blueImageBackground(
                        text: 'NO',
                        height: 35,
                        width: 100,
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      const SizedBox(width: 10),
                      // RESTART 按钮（绿色图片背景）
                      SmallButtonHelper.greenImageBackground(
                        text: 'YES',
                        height: 35,
                        width: 100,
                        iconSize: 16,
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 30)
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToHome() async {
    // 检查是否首次启动
    final prefs = await SharedPreferences.getInstance();
    final tutorialShown = prefs.getBool('tutorial_shown') ?? false;
    
    if (!tutorialShown) {
      // 首次启动，进入教程页面
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    } else {
      // 非首次启动，直接进入主页
      Navigator.pushNamed(context, '/main');
    }
  }

  // 修改复选框的处理逻辑
  Widget _buildCheckbox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _isAgreementChecked,
              onChanged: (bool? value) async {
                if (value == false) {
                  // 先更新复选框状态和暂停进度
                  setState(() {
                    _isAgreementChecked = false;
                    _isPaused = true;
                  });
                  _progressController.stop(); // 暂停动画

                  // 显示确认对话框
                  final result = await _showConfirmationDialog();
                  if (result == true) {
                    // 用户点击 Yes，恢复勾选状态并继续加载
                    setState(() {
                      _isAgreementChecked = true;
                      _isPaused = false;
                      _progressValue = 1.0;
                    });

                    // 重置动画控制器
                    _progressController.reset();

                    // 设置新的动画持续时间
                    final remainingDuration = Duration(milliseconds: ((1 - _progressController.value) * 5000).round());
                    _progressController.duration = remainingDuration;

                    // 确保动画从当前进度开始
                    _progressController.value = _progressController.value;

                    // 启动动画并等待完成
                    await _progressController.forward();

                    // 检查是否需要导航
                    if (_isDataLoaded && _isImagePreloaded && _isAgreementChecked && !_isPaused && mounted) {
                      _navigateToHome();
                    }
                  } else {
                    // 用户点击 No，退出应用
                    SystemNavigator.pop();
                  }
                }
              },
              fillColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white;
                  }
                  return Colors.white.withOpacity(0.5);
                },
              ),
              checkColor: const Color(0xff4b00ff),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WebViewScreen(
                        title: 'Privacy Agreement',
                        url: 'https://fantasy-ball-quest.web.app/privacy.html',
                      ),
                    ),
                  );
                },
                child: Text(
                  'Privacy Agreement',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                    decorationThickness: 1.5,
                    height: 1.5,
                    // 增加行高，让下划线和文字有间距
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                ' & ',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WebViewScreen(
                        title: 'User Agreement',
                        url: 'https://fantasy-ball-quest.web.app/terms.html',
                      ),
                    ),
                  );
                },
                child: Text(
                  'User Agreement',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                    decorationThickness: 1.5,
                    height: 1.5,
                    // 增加行高，让下划线和文字有间距
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 背景图
      body: Stack(
        children: [
          // 随机背景图片
          Positioned.fill(
            child: Image.asset(
              _selectedBackground,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // 主内容
          Center(
            child: Column(
              children: [
                const SizedBox(
                  height: 150,
                ),
                // Image.asset(
                //   fit: BoxFit.cover,
                //   width: 155,
                //   height: 155,
                // ),
                const SizedBox(height: 33),
                // 可以在这里添加游戏logo或标题
                // const Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Text(
                //       'Relax Your Brain ',
                //       style: TextStyle(
                //         fontSize: 32,
                //         color: Colors.white,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 30),
              ],
            ),
          ),

          // 底部进度条和协议
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 5000),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(
                      begin: 0,
                      end: _isPaused ? _progressController.value : _progressValue,
                    ),
                    onEnd: () {
                      // 当动画完成且满足条件时导航
                      if (_isDataLoaded && _isImagePreloaded && _isAgreementChecked && !_isPaused && mounted) {
                        _navigateToHome();
                      }
                    },
                    builder: (context, double value, _) {
                      return SizedBox(
                        height: 8,
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.white,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF36FF9B),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildCheckbox(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}