// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grils_app/widgets/common_header.dart';
import 'package:grils_app/services/user_service.dart';

void main() {
  testWidgets('CommonHeader displays coin and heart count', (WidgetTester tester) async {
    // 初始化用户服务
    await UserService.instance.initialize();
    
    // Build our CommonHeader widget and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const CommonHeader( ),
        ),
      ),
    );

    // Verify that the coin count is displayed (默认值1000)
    expect(find.text('1000'), findsOneWidget);
    
    // Verify that the heart count is displayed (默认值50)
    expect(find.text('50'), findsOneWidget);
    
    // Verify that the title is displayed
    expect(find.text('测试标题'), findsOneWidget);
  });
}
