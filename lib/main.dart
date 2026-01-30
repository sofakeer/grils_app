import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'src/bootstrap/bootstrap.dart';
import 'src/app.dart';
import 'src/services/analytics_manager.dart';
import 'src/services/play_time_reporter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Bootstrap().init();

  // 记录应用启动埋点
  final analytics = AnalyticsManager();
  await analytics.logUser();
  await analytics.logUserVc1();

  // 启动游戏时长上报
  PlayTimeReporter().startReporting();

  runApp(const ProviderScope(child: GameImageApp()));
}
