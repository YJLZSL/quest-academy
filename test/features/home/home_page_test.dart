import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_academy/core/providers/app_providers.dart';
import 'package:quest_academy/core/theme/app_theme.dart';
import 'package:quest_academy/data/db/database.dart';
import 'package:quest_academy/data/models/course_content.dart';
import 'package:quest_academy/data/providers/course_providers.dart';
import 'package:quest_academy/data/providers/db_providers.dart';
import 'package:quest_academy/data/repositories/course_repository.dart';
import 'package:quest_academy/features/home/home_page.dart';
import 'package:quest_academy/shared/widgets/streak_flame_badge.dart';
import 'package:quest_academy/shared/widgets/xp_progress_ring.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 返回空课程列表的测试仓库。
class _EmptyCourseRepository implements CourseRepository {
  @override
  Future<List<Course>> getAllCourses() async => <Course>[];

  @override
  Future<Course?> getCourse(String courseId) async => null;

  @override
  Future<List<Course>> getCoursesByLevel(CourseLevel level) async => <Course>[];

  @override
  Future<KnowledgePoint?> getKnowledgePoint(
    String courseId,
    String lessonId,
    String knowledgePointId,
  ) async => null;

  @override
  List<CourseLoadError> get loadErrors => <CourseLoadError>[];

  @override
  void clearCache() {}
}

void main() {
  late SharedPreferences prefs;
  late QuestDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_completed': true,
    });
    prefs = await SharedPreferences.getInstance();
    db = QuestDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrapWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
          courseRepositoryProvider.overrideWithValue(_EmptyCourseRepository()),
        ],
        child: child,
      ),
    );
  }

  group('HomePage 游戏化组件', () {
    testWidgets('渲染 XP 进度环', (tester) async {
      await tester.pumpWidget(wrapWidget(const HomePage()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(XpProgressRing), findsOneWidget);
    });

    testWidgets('渲染 streak 火焰徽章', (tester) async {
      await tester.pumpWidget(wrapWidget(const HomePage()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(StreakFlameBadge), findsWidgets);
    });

    testWidgets('显示欢迎标题与快捷入口', (tester) async {
      await tester.pumpWidget(wrapWidget(const HomePage()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('欢迎来到问学'), findsOneWidget);
      expect(find.text('继续学习'), findsOneWidget);
      expect(find.text('AI 对话'), findsOneWidget);
      expect(find.text('我的笔记'), findsOneWidget);
      expect(find.text('成就'), findsOneWidget);
      expect(find.text('统计'), findsOneWidget);
    });

    testWidgets('课程为空时显示提示', (tester) async {
      await tester.pumpWidget(wrapWidget(const HomePage()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('暂无课程，请稍后再来'), findsOneWidget);
    });
  });

  group('HomePage 去吉祥物', () {
    testWidgets('页面中不存在 MascotWidget / MascotOverlay / MascotHero', (
      tester,
    ) async {
      await tester.pumpWidget(wrapWidget(const HomePage()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('AI 导师'), findsNothing);
      // 通过类型名检查 mascot 相关 Widget 不存在
      final mascotTypes = <Type>[];
      for (final element in tester.allElements) {
        final type = element.widget.runtimeType;
        final name = type.toString().toLowerCase();
        if (name.contains('mascot')) {
          mascotTypes.add(type);
        }
      }
      expect(mascotTypes, isEmpty);
    });
  });
}
