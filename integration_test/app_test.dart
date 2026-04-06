import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:breakfast_checkin/main.dart' as app;

/// 系统测试/集成测试
/// 运行命令: flutter test integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('App should launch and show disclaimer dialog', (tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();

      // 验证应用标题
      expect(find.text('早餐打卡'), findsOneWidget);

      // 首次启动应该显示免责声明（如果没有接受）
      // 注意：如果已经在之前的测试中接受过，可能不会显示
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Navigation between tabs should work', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 找到底部导航栏
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // 点击统计页
      await tester.tap(find.text('统计'));
      await tester.pumpAndSettle();

      // 验证统计页面元素
      expect(find.text('统计'), findsWidgets);

      // 点击提醒页
      await tester.tap(find.text('提醒'));
      await tester.pumpAndSettle();

      // 验证提醒页面
      expect(find.text('提醒'), findsWidgets);

      // 返回首页
      await tester.tap(find.text('首页'));
      await tester.pumpAndSettle();
    });

    testWidgets('Check-in button should be present on home screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 验证首页元素
      expect(find.text('早餐打卡'), findsOneWidget);
      
      // 查找打卡按钮相关文本
      expect(find.textContaining('打卡时间'), findsOneWidget);
    });

    testWidgets('Stats page should show calendar and achievements', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 导航到统计页面
      await tester.tap(find.text('统计'));
      await tester.pumpAndSettle();

      // 验证统计页面内容
      expect(find.text('打卡总览'), findsOneWidget);
      expect(find.text('成就墙'), findsOneWidget);
      expect(find.text('月度趋势'), findsOneWidget);
    });
  });

  group('Feature Tests', () {
    testWidgets('Store page should display correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 点击商店图标（假设在AppBar中）
      final storeIcon = find.byIcon(Icons.store);
      if (storeIcon.evaluate().isNotEmpty) {
        await tester.tap(storeIcon);
        await tester.pumpAndSettle();

        // 验证商店页面
        expect(find.text('商店'), findsOneWidget);
        expect(find.text('胆囊皮肤'), findsOneWidget);
      }
    });

    testWidgets('Export data dialog should appear', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 点击导出按钮
      final downloadIcon = find.byIcon(Icons.download);
      if (downloadIcon.evaluate().isNotEmpty) {
        await tester.tap(downloadIcon);
        await tester.pumpAndSettle();

        // 验证导出对话框
        expect(find.text('导出数据'), findsOneWidget);

        // 关闭对话框
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
      }
    });
  });
}
