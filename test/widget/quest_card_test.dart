// ignore_for_file: lines_longer_than_80_lines

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_academy/core/providers/app_providers.dart';
import 'package:quest_academy/core/theme/quest_elevations.dart';
import 'package:quest_academy/shared/widgets/quest_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// QuestCard 组件测试。
///
/// 覆盖 elevation=0/1/2 阴影层级（subtle/elevated/highlighted）、
/// 可点击卡片按压时 AnimatedScale 存在且 scale=0.99、
/// 不可点击卡片无按压动画、点击触发 onTap 回调、
/// child Widget 正确渲染。
///
/// 所有被测组件均包装在 [ProviderScope] 中，以满足主题风味 Provider 的依赖。
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  Widget wrapWidget(Widget child) {
    return MaterialApp(
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

  group('QuestCard 阴影层级', () {
    testWidgets('elevation=0 时使用 subtle 阴影', (tester) async {
      await tester.pumpWidget(wrapWidget(
        QuestCard(
          elevation: 0,
          child: const Text('elevation 0'),
        ),
      ));
      await tester.pump();

      final ink = tester.widget<Ink>(
        find.descendant(
          of: find.byType(QuestCard),
          matching: find.byType(Ink),
        ),
      );
      final decoration = ink.decoration as BoxDecoration;
      expect(
        decoration.boxShadow,
        equals(QuestElevations.light.subtle),
        reason: 'elevation=0 应使用 subtle 阴影',
      );
    });

    testWidgets('elevation=1 时使用 elevated 阴影', (tester) async {
      await tester.pumpWidget(wrapWidget(
        QuestCard(
          elevation: 1,
          child: const Text('elevation 1'),
        ),
      ));
      await tester.pump();

      final ink = tester.widget<Ink>(
        find.descendant(
          of: find.byType(QuestCard),
          matching: find.byType(Ink),
        ),
      );
      final decoration = ink.decoration as BoxDecoration;
      expect(
        decoration.boxShadow,
        equals(QuestElevations.light.elevated),
        reason: 'elevation=1 应使用 elevated 阴影',
      );
    });

    testWidgets('elevation=2 时使用 highlighted 阴影', (tester) async {
      await tester.pumpWidget(wrapWidget(
        QuestCard(
          elevation: 2,
          child: const Text('elevation 2'),
        ),
      ));
      await tester.pump();

      final ink = tester.widget<Ink>(
        find.descendant(
          of: find.byType(QuestCard),
          matching: find.byType(Ink),
        ),
      );
      final decoration = ink.decoration as BoxDecoration;
      expect(
        decoration.boxShadow,
        equals(QuestElevations.light.highlighted),
        reason: 'elevation=2 应使用 highlighted 阴影',
      );
    });

    testWidgets('默认 elevation 为 1（elevated 阴影）', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const QuestCard(
          child: Text('default elevation'),
        ),
      ));
      await tester.pump();

      final ink = tester.widget<Ink>(
        find.descendant(
          of: find.byType(QuestCard),
          matching: find.byType(Ink),
        ),
      );
      final decoration = ink.decoration as BoxDecoration;
      expect(
        decoration.boxShadow,
        equals(QuestElevations.light.elevated),
        reason: '默认 elevation=1 应使用 elevated 阴影',
      );
    });
  });

  group('QuestCard 按压动画', () {
    testWidgets('可点击卡片（onTap 不为 null）存在 AnimatedScale',
        (tester) async {
      await tester.pumpWidget(wrapWidget(
        QuestCard(
          onTap: () {},
          child: const Text('可点击'),
        ),
      ));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(QuestCard),
          matching: find.byType(AnimatedScale),
        ),
        findsOneWidget,
        reason: '可点击卡片应有 AnimatedScale',
      );
    });

    testWidgets('不可点击卡片（onTap 为 null）无按压动画', (tester) async {
      await tester.pumpWidget(wrapWidget(
        QuestCard(
          child: const Text('不可点击'),
        ),
      ));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(QuestCard),
          matching: find.byType(AnimatedScale),
        ),
        findsNothing,
        reason: '不可点击卡片不应有 AnimatedScale',
      );
    });

    testWidgets('可点击卡片按压时 scale 值为 0.99', (tester) async {
      await tester.pumpWidget(wrapWidget(
        QuestCard(
          onTap: () {},
          child: const Text('按压测试'),
        ),
      ));
      await tester.pump();

      // 初始状态 scale 为 1.0
      var animatedScale = tester.widget<AnimatedScale>(
        find.descendant(
          of: find.byType(QuestCard),
          matching: find.byType(AnimatedScale),
        ),
      );
      expect(animatedScale.scale, 1.0, reason: '初始状态 scale 应为 1.0');

      // 按下
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(QuestCard)),
      );
      await tester.pump();

      animatedScale = tester.widget<AnimatedScale>(
        find.descendant(
          of: find.byType(QuestCard),
          matching: find.byType(AnimatedScale),
        ),
      );
      expect(
        animatedScale.scale,
        0.99,
        reason: '按压时 scale 应为 0.99',
      );

      await gesture.up();
      await tester.pump();
    });

    testWidgets('可点击卡片释放后 scale 回到 1.0', (tester) async {
      await tester.pumpWidget(wrapWidget(
        QuestCard(
          onTap: () {},
          child: const Text('释放测试'),
        ),
      ));
      await tester.pump();

      // 按下
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(QuestCard)),
      );
      await tester.pump();

      // 释放
      await gesture.up();
      await tester.pump();

      final animatedScale = tester.widget<AnimatedScale>(
        find.descendant(
          of: find.byType(QuestCard),
          matching: find.byType(AnimatedScale),
        ),
      );
      expect(
        animatedScale.scale,
        1.0,
        reason: '释放后 scale 应回到 1.0',
      );
    });
  });

  group('QuestCard 点击', () {
    testWidgets('点击触发 onTap 回调', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrapWidget(
        QuestCard(
          onTap: () => tapped = true,
          child: const Text('点击我'),
        ),
      ));
      await tester.pump();

      await tester.tap(find.byType(QuestCard));
      await tester.pump();

      expect(tapped, isTrue, reason: '点击后 onTap 应被触发');
    });

    testWidgets('不可点击卡片点击不触发回调', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrapWidget(
        QuestCard(
          child: const Text('不可点击'),
        ),
      ));
      await tester.pump();

      // 尝试点击（warnIfMissed: false 因为无 InkWell 不响应点击）
      await tester.tap(find.byType(QuestCard), warnIfMissed: false);
      await tester.pump();

      expect(tapped, isFalse, reason: '不可点击卡片不应触发回调');
    });
  });

  group('QuestCard 渲染', () {
    testWidgets('child Widget 正确渲染', (tester) async {
      await tester.pumpWidget(wrapWidget(
        QuestCard(
          child: const Text('卡片内容'),
        ),
      ));
      await tester.pump();

      expect(find.text('卡片内容'), findsOneWidget);
    });

    testWidgets('默认内边距为 16', (tester) async {
      await tester.pumpWidget(wrapWidget(
        QuestCard(
          child: const Text('padding 测试'),
        ),
      ));
      await tester.pump();

      // Padding 应存在且为 16
      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(QuestCard),
          matching: find.byType(Padding),
        ),
      );
      expect(
        padding.padding,
        const EdgeInsets.all(16),
        reason: '默认内边距应为 EdgeInsets.all(16)',
      );
    });
  });
}
