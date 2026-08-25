import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_academy/core/providers/app_providers.dart';
import 'package:quest_academy/core/theme/app_theme.dart';
import 'package:quest_academy/shared/widgets/xp_progress_ring.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  Widget wrapWidget(Widget child, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: Scaffold(
          body: Center(child: child),
        ),
      ),
    );
  }

  group('XpProgressRing 渲染', () {
    testWidgets('显示等级、XP 进度与 XP 标签', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const XpProgressRing(
          currentXp: 30,
          xpToNextLevel: 100,
          level: 2,
        ),
      ));
      await tester.pump();

      expect(find.text('Lv.2'), findsOneWidget);
      expect(find.text('30/100'), findsOneWidget);
      expect(find.text('XP'), findsOneWidget);
    });

    testWidgets('包含 CustomPaint 绘制圆环', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const XpProgressRing(
          currentXp: 50,
          xpToNextLevel: 100,
          level: 1,
        ),
      ));
      await tester.pump();

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('进度为 0 时显示 0/100', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const XpProgressRing(
          currentXp: 0,
          xpToNextLevel: 100,
          level: 0,
        ),
      ));
      await tester.pump();

      expect(find.text('Lv.0'), findsOneWidget);
      expect(find.text('0/100'), findsOneWidget);
    });

    testWidgets('进度达到上限时显示 100/100', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const XpProgressRing(
          currentXp: 150,
          xpToNextLevel: 100,
          level: 3,
        ),
      ));
      await tester.pump();

      expect(find.text('Lv.3'), findsOneWidget);
      expect(find.text('150/100'), findsOneWidget);
    });
  });

  group('XpProgressRing 交互', () {
    testWidgets('点击触发 onTap 回调', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrapWidget(
        XpProgressRing(
          currentXp: 40,
          xpToNextLevel: 100,
          level: 1,
          onTap: () => tapped = true,
        ),
      ));
      await tester.pump();

      await tester.tap(find.byType(XpProgressRing));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('无 onTap 时不响应点击', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const XpProgressRing(
          currentXp: 40,
          xpToNextLevel: 100,
          level: 1,
        ),
      ));
      await tester.pump();

      // 不应抛出异常
      await tester.tap(find.byType(XpProgressRing));
      await tester.pump();
    });
  });
}
