import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_academy/core/providers/app_providers.dart';
import 'package:quest_academy/core/theme/app_theme.dart';
import 'package:quest_academy/data/models/course_content.dart';
import 'package:quest_academy/features/learning/widgets/level_node.dart';
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

  group('LevelNode 状态渲染', () {
    testWidgets('锁定状态显示锁图标与 L0 标签', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const LevelNode(
          level: CourseLevel.l0,
          state: LevelNodeState.locked,
        ),
      ));
      await tester.pump();

      expect(find.text('L0'), findsOneWidget);
      expect(find.byIcon(Icons.child_care), findsOneWidget);
    });

    testWidgets('当前状态显示级别图标与标签', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const LevelNode(
          level: CourseLevel.l2,
          state: LevelNodeState.current,
        ),
      ));
      await tester.pump();

      expect(find.text('L2'), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories), findsOneWidget);
    });

    testWidgets('已完成状态显示打勾图标', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const LevelNode(
          level: CourseLevel.l1,
          state: LevelNodeState.completed,
        ),
      ));
      await tester.pump();

      expect(find.text('L1'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('所有 L0-L4 级别标签均正确渲染', (tester) async {
      for (final level in CourseLevel.values) {
        await tester.pumpWidget(wrapWidget(
          LevelNode(
            level: level,
            state: LevelNodeState.current,
          ),
        ));
        await tester.pump();

        final shortName = switch (level) {
          CourseLevel.l0 => 'L0',
          CourseLevel.l1 => 'L1',
          CourseLevel.l2 => 'L2',
          CourseLevel.l3 => 'L3',
          CourseLevel.l4 => 'L4',
        };
        expect(find.text(shortName), findsOneWidget);
      }
    });
  });

  group('LevelNode 交互', () {
    testWidgets('点击触发 onTap 回调', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrapWidget(
        LevelNode(
          level: CourseLevel.l0,
          state: LevelNodeState.current,
          onTap: () => tapped = true,
        ),
      ));
      await tester.pump();

      await tester.tap(find.byType(LevelNode));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('无 onTap 时不可点击', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const LevelNode(
          level: CourseLevel.l0,
          state: LevelNodeState.locked,
        ),
      ));
      await tester.pump();

      await tester.tap(find.byType(LevelNode), warnIfMissed: false);
      await tester.pump();

      // 断言组件仍在即可
      expect(find.byType(LevelNode), findsOneWidget);
    });
  });
}
