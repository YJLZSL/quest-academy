import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_academy/core/providers/app_providers.dart';
import 'package:quest_academy/shared/widgets/empty_state_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('EmptyStateWidget', () {
    testWidgets('应渲染标题和描述', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: const Scaffold(
              body: EmptyStateWidget(
                icon: Icons.chat_bubble_outline,
                title: '还没有对话历史',
                description: '开始第一次对话，让 AI 陪你学习',
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('还没有对话历史'), findsOneWidget);
      expect(find.text('开始第一次对话，让 AI 陪你学习'), findsOneWidget);
    });

    testWidgets('提供 ctaText 和 onCta 时应渲染 CTA 按钮', (tester) async {
      var tapped = false;
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: Scaffold(
              body: EmptyStateWidget(
                icon: Icons.note_alt_outlined,
                title: '还没有笔记',
                description: '在学习或对话中，重要内容可一键保存为笔记',
                ctaText: '去学习',
                onCta: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // CTA 按钮应可见
      expect(find.text('去学习'), findsOneWidget);

      // 点击 CTA 按钮
      await tester.tap(find.text('去学习'));
      await tester.pump(const Duration(milliseconds: 500));

      // 回调应被触发
      expect(tapped, isTrue);
    });

    testWidgets('未提供 ctaText 或 onCta 时不应渲染 CTA 按钮', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: const Scaffold(
              body: EmptyStateWidget(
                icon: Icons.inbox_outlined,
                title: '暂无数据',
                description: '稍后再来看看吧',
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // 标题和描述应可见
      expect(find.text('暂无数据'), findsOneWidget);
      expect(find.text('稍后再来看看吧'), findsOneWidget);

      // 不应有 CTA 按钮（无箭头图标）
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
    });

    testWidgets('应渲染中心图标', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: const Scaffold(
              body: EmptyStateWidget(
                icon: Icons.emoji_events_outlined,
                title: '成就墙空空如也',
                description: '完成课程、连续打卡，解锁专属徽章',
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // 图标与标题应可见
      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
      expect(find.text('成就墙空空如也'), findsOneWidget);
    });

    testWidgets('提供 illustration 时应优先使用自定义插图', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: const Scaffold(
              body: EmptyStateWidget(
                icon: Icons.sentiment_dissatisfied,
                title: '自定义插图测试',
                description: '应显示自定义插图而非默认图标',
                illustration: Icon(Icons.sentiment_dissatisfied, size: 120),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // 自定义插图图标应可见
      expect(find.byIcon(Icons.sentiment_dissatisfied), findsOneWidget);
      expect(find.text('自定义插图测试'), findsOneWidget);
    });

    testWidgets('点击组件不崩溃', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: const Scaffold(
              body: EmptyStateWidget(
                icon: Icons.touch_app_outlined,
                title: '点击测试',
                description: '点击组件验证交互',
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // 点击组件区域（GestureDetector）
      await tester.tap(find.text('点击测试'));
      await tester.pump(const Duration(milliseconds: 500));

      // 组件应仍然正常渲染（无崩溃）
      expect(find.text('点击测试'), findsOneWidget);
    });
  });
}
