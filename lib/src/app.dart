import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_image_app/src/features/splash/splash_screen.dart';
import 'providers/app_providers.dart';
import 'providers/user_type_provider.dart';
import 'features/spin/spin_page.dart';
import 'features/photo_album/photo_album_page.dart';
// import 'features/splash/splash_page.dart';
import 'features/signin/signin_dialog.dart';
import 'features/dev/signin_debug_page.dart';
import 'features/game_result/game_success_page.dart';
import 'features/game_result/game_fail_page.dart';
import 'features/home/home_page.dart';
import 'features/treasure/treasure_page.dart';
import 'widgets/button_demo_page.dart';
import 'core/locator.dart';
import 'providers/level_providers.dart';
import 'providers/audio_providers.dart';
import 'providers/background_providers.dart';
import 'services/image_download_service.dart';

class GameImageApp extends StatelessWidget {
  const GameImageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: _LifecycleWrapper(
        child: MaterialApp(
      navigatorKey: ServiceLocator.instance.get<GlobalKey<NavigatorState>>(),
      title: 'Game Image App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomePage(),
        '/main': (context) => const _BootstrapOkPage(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
        ),
      ),
    );
  }
}

/// App lifecycle listener to pause/resume background music
class _LifecycleWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const _LifecycleWrapper({required this.child});

  @override
  ConsumerState<_LifecycleWrapper> createState() => _LifecycleWrapperState();
}

class _LifecycleWrapperState extends ConsumerState<_LifecycleWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audio = ref.read(audioStateProvider.notifier);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        audio.pauseBackgroundMusic();
        break;
      case AppLifecycleState.resumed:
        audio.resumeBackgroundMusic();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

Future<void> _showCustomNumberDialog({
  required BuildContext context,
  required String title,
  required ValueChanged<int> onConfirm,
}) async {
  final controller = TextEditingController();
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  final result = await showDialog<int>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: '输入正整数',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value <= 0) {
                scaffoldMessenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('请输入大于 0 的整数'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                return;
              }
              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('确定'),
          ),
        ],
      );
    },
  );

  controller.dispose();

  if (result != null) {
    onConfirm(result);
  }
}

class _BootstrapOkPage extends ConsumerWidget {
  const _BootstrapOkPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final up = ref.watch(userProgressProvider);
    final level = ref.watch(levelProvider);
    final userType = ref.watch(userTypeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('测试配置')),
      body: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              const SizedBox(height: 8),
              up.when(
                data: (value) => Text('金币：${value.coins}'),
                loading: () => const Text('加载中...'),
                error: (e, _) => Text('错误：$e'),
              ),
              const SizedBox(height: 8),
              Text('当前关卡：${level.currentLevel}'),
              const SizedBox(height: 8),
              // 用户类型显示和配置
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: userType == UserType.paid
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: userType == UserType.paid
                        ? Colors.orange
                        : Colors.green,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          userType == UserType.paid
                              ? Icons.monetization_on
                              : Icons.person,
                          color: userType == UserType.paid
                              ? Colors.orange
                              : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '用户类型: ${userType == UserType.paid ? "买量用户" : "自然用户"}',
                          style: TextStyle(
                            color: userType == UserType.paid
                                ? Colors.orange
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userType == UserType.paid
                          ? '买量用户: 关卡后显示3选1弹窗'
                          : '自然用户: 关卡后直接进入下一关',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 用户类型切换按钮 - 在release包中也可用
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  // 用户类型切换按钮
                  OutlinedButton.icon(
                    onPressed: () async {
                      // 显示确认对话框
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: const Text('切换用户类型'),
                            content: const Text(
                              '切换用户类型将清空所有数据并重启应用，是否继续？',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(true),
                                child: const Text('确定'),
                              ),
                            ],
                          );
                        },
                      );
                      
                      if (confirmed != true) return;
                      
                      // 显示加载提示
                      if (!context.mounted) return;
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('正在清空数据并重启...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      
                      // 切换用户类型（内部会清空所有数据）
                      await ref.read(userTypeProvider.notifier).toggleUserType();
                      
                      // 清空图片缓存文件
                      await ref.read(imageDownloadServiceProvider.notifier).clearCache();
                      
                      // 重新初始化背景图片（根据新的用户类型）
                      await ref.read(backgroundImageProvider.notifier).forceRandomBackground();
                      
                      // 重启 app
                      if (!context.mounted) return;
                      await Future.delayed(const Duration(milliseconds: 300));
                      
                      // 使用 Navigator 重启到首页
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home',
                        (route) => false,
                      );
                      
                      // 提示用户
                      if (!context.mounted) return;
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            '已切换为${ref.read(userTypeProvider) == UserType.paid ? "买量用户" : "自然用户"}，数据已清空',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(
                      userType == UserType.paid
                          ? Icons.monetization_on
                          : Icons.person,
                      size: 16,
                    ),
                    label: Text(
                      '切换用户类型\n(${userType == UserType.paid ? "买量" : "自然"})',
                      textAlign: TextAlign.center,
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: userType == UserType.paid
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      foregroundColor: userType == UserType.paid
                          ? Colors.orange
                          : Colors.green,
                      side: BorderSide(
                        color: userType == UserType.paid
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInDebugPage())),
                child: const Text('开发调试：签到面板'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TreasurePage())),
                child: const Text('测试：宝藏页面'),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: () => ref.read(userProgressProvider.notifier).addCoins(100),
                    child: const Text('金币 +100'),
                  ),
                  OutlinedButton(
                    onPressed: () => ref.read(userProgressProvider.notifier).addCoins(500),
                    child: const Text('金币 +500'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await ref.read(levelProvider.notifier).addLevels(1);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('当前关卡: ${ref.read(levelProvider).currentLevel}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text('完成 +1 关'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await ref.read(levelProvider.notifier).addLevels(5);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('当前关卡: ${ref.read(levelProvider).currentLevel}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text('完成 +5 关'),
                  ),
                  OutlinedButton(
                    onPressed: () => _showCustomNumberDialog(
                      context: context,
                      title: '自定义增加金币',
                      onConfirm: (value) => ref.read(userProgressProvider.notifier).addCoins(value),
                    ),
                    child: const Text('金币 +自定义'),
                  ),
                  OutlinedButton(
                    onPressed: () => _showCustomNumberDialog(
                      context: context,
                      title: '自定义完成关卡',
                      onConfirm: (value) => ref.read(levelProvider.notifier).addLevels(value),
                    ),
                    child: const Text('完成 +自定义关'),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ButtonDemoPage())),
                  child: const Text('小按钮组件示例'),
                ),
              ],
            )
          ),
        ),
      ),
    );
  }
}
