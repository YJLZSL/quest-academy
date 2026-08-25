// ignore_for_file: lines_longer_than_80_lines

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_academy/core/theme/quest_colors.dart';
import 'package:quest_academy/data/models/course_content.dart';
import 'package:quest_academy/features/learning/course_level_extensions.dart';

void main() {
  group('CourseLevel.levelColor light 实例映射', () {
    const colors = QuestColors.light;

    test('L0 → brandSecondary（温暖橙，入门）', () {
      expect(CourseLevel.l0.levelColor(colors), colors.brandSecondary);
    });

    test('L1 → socraticBlue（苏格拉底蓝，基础）', () {
      expect(CourseLevel.l1.levelColor(colors), colors.socraticBlue);
    });

    test('L2 → brandPrimary（星空紫，进阶）', () {
      expect(CourseLevel.l2.levelColor(colors), colors.brandPrimary);
    });

    test('L3 → achievementGold（成就金，高级）', () {
      expect(CourseLevel.l3.levelColor(colors), colors.achievementGold);
    });

    test('L4 → streakFire（火焰红，专家）', () {
      expect(CourseLevel.l4.levelColor(colors), colors.streakFire);
    });
  });

  group('CourseLevel.levelColor dark 实例映射', () {
    const colors = QuestColors.dark;

    test('L0 → brandSecondary', () {
      expect(CourseLevel.l0.levelColor(colors), colors.brandSecondary);
    });

    test('L1 → socraticBlue', () {
      expect(CourseLevel.l1.levelColor(colors), colors.socraticBlue);
    });

    test('L2 → brandPrimary', () {
      expect(CourseLevel.l2.levelColor(colors), colors.brandPrimary);
    });

    test('L3 → achievementGold', () {
      expect(CourseLevel.l3.levelColor(colors), colors.achievementGold);
    });

    test('L4 → streakFire', () {
      expect(CourseLevel.l4.levelColor(colors), colors.streakFire);
    });
  });

  group('CourseLevel.levelColor 语义色对应', () {
    test('每个级别在 light 下映射到不同语义色', () {
      const colors = QuestColors.light;
      final mapped = <CourseLevel, Color>{
        for (final level in CourseLevel.values)
          level: level.levelColor(colors),
      };
      final uniqueColors = mapped.values.toSet();
      expect(uniqueColors.length, CourseLevel.values.length,
          reason: 'L0-L4 应映射到 5 个互不相同的语义色');
    });

    test('每个级别在 dark 下映射到不同语义色', () {
      const colors = QuestColors.dark;
      final mapped = <CourseLevel, Color>{
        for (final level in CourseLevel.values)
          level: level.levelColor(colors),
      };
      final uniqueColors = mapped.values.toSet();
      expect(uniqueColors.length, CourseLevel.values.length,
          reason: 'dark 实例下 L0-L4 也应映射到 5 个互不相同的语义色');
    });

    test('L0-L4 顺序与文档约定一致', () {
      const colors = QuestColors.light;
      expect(CourseLevel.l0.levelColor(colors), colors.brandSecondary);
      expect(CourseLevel.l1.levelColor(colors), colors.socraticBlue);
      expect(CourseLevel.l2.levelColor(colors), colors.brandPrimary);
      expect(CourseLevel.l3.levelColor(colors), colors.achievementGold);
      expect(CourseLevel.l4.levelColor(colors), colors.streakFire);
    });

    test('全部 5 个级别遍历均可正确返回颜色', () {
      const colors = QuestColors.light;
      for (final level in CourseLevel.values) {
        final color = level.levelColor(colors);
        expect(color, isNotNull);
      }
    });
  });

  group('CourseLevel.levelColor 与枚举值', () {
    test('CourseLevel.fromValue 正确反查各级别', () {
      expect(CourseLevel.fromValue('l0'), CourseLevel.l0);
      expect(CourseLevel.fromValue('l1'), CourseLevel.l1);
      expect(CourseLevel.fromValue('l2'), CourseLevel.l2);
      expect(CourseLevel.fromValue('l3'), CourseLevel.l3);
      expect(CourseLevel.fromValue('l4'), CourseLevel.l4);
    });

    test('未知值回退到 l0', () {
      expect(CourseLevel.fromValue('unknown'), CourseLevel.l0);
      expect(CourseLevel.fromValue(''), CourseLevel.l0);
    });
  });
}
