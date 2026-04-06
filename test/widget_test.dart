import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:breakfast_checkin/main.dart';

/// Widget 测试
void main() {
  group('Widget Tests', () {
    testWidgets('App should build without errors', (WidgetTester tester) async {
      // 构建应用
      await tester.pumpWidget(const BreakfastCheckInApp());
      
      // 等待构建完成
      await tester.pump();

      // 验证应用正常构建
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Bottom navigation should have 4 items', (WidgetTester tester) async {
      await tester.pumpWidget(const BreakfastCheckInApp());
      await tester.pump();

      final bottomNav = find.byType(BottomNavigationBar);
      expect(bottomNav, findsOneWidget);

      // 验证导航项数量
      final BottomNavigationBar navBar = tester.widget(bottomNav);
      expect(navBar.items.length, 4);
    });

    testWidgets('Navigation items should have correct labels', (WidgetTester tester) async {
      await tester.pumpWidget(const BreakfastCheckInApp());
      await tester.pump();

      expect(find.text('首页'), findsOneWidget);
      expect(find.text('健康'), findsOneWidget);
      expect(find.text('统计'), findsOneWidget);
      expect(find.text('提醒'), findsOneWidget);
    });
  });
}
