import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_academy/core/theme/theme_flavor_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeFlavor', () {
    test('fromString 正确解析三个风味', () {
      expect(ThemeFlavor.fromString('standard'), ThemeFlavor.standard);
      expect(ThemeFlavor.fromString('minimal'), ThemeFlavor.minimal);
      expect(ThemeFlavor.fromString('minecraft'), ThemeFlavor.minecraft);
    });

    test('fromString 对空/未知值回退到 standard', () {
      expect(ThemeFlavor.fromString(null), ThemeFlavor.standard);
      expect(ThemeFlavor.fromString(''), ThemeFlavor.standard);
      expect(ThemeFlavor.fromString('unknown'), ThemeFlavor.standard);
    });

    test('values 顺序为 standard -> minimal -> minecraft', () {
      expect(ThemeFlavor.values, [
        ThemeFlavor.standard,
        ThemeFlavor.minimal,
        ThemeFlavor.minecraft,
      ]);
    });
  });

  group('ThemeFlavorNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('初始状态从 theme_flavor 读取', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'theme_flavor': 'minimal',
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeFlavorNotifier(prefs);
      expect(notifier.state, ThemeFlavor.minimal);
    });

    test('无持久化值时默认 standard', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeFlavorNotifier(prefs);
      expect(notifier.state, ThemeFlavor.standard);
    });

    test('setFlavor 更新状态并持久化', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeFlavorNotifier(prefs);

      notifier.setFlavor(ThemeFlavor.minecraft);

      expect(notifier.state, ThemeFlavor.minecraft);
      expect(prefs.getString('theme_flavor'), 'minecraft');
    });

    test('cycle 按顺序循环风味', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeFlavorNotifier(prefs);

      notifier.cycle();
      expect(notifier.state, ThemeFlavor.minimal);

      notifier.cycle();
      expect(notifier.state, ThemeFlavor.minecraft);

      notifier.cycle();
      expect(notifier.state, ThemeFlavor.standard);
    });

    test('旧 minimal_mode=true 迁移为 ThemeFlavor.minimal', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'minimal_mode': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeFlavorNotifier(prefs);

      expect(notifier.state, ThemeFlavor.minimal);
      expect(prefs.getString('theme_flavor'), 'minimal');
      expect(prefs.containsKey('minimal_mode'), isFalse);
    });

    test('旧 minimal_mode=false 不覆盖已有 theme_flavor', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'minimal_mode': false,
        'theme_flavor': 'minecraft',
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeFlavorNotifier(prefs);

      expect(notifier.state, ThemeFlavor.minecraft);
      expect(prefs.containsKey('minimal_mode'), isFalse);
    });
  });

  group('SeedColorNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('默认使用问学品牌色求知靛蓝 #3D5AFE', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = SeedColorNotifier(prefs);
      expect(notifier.state, const Color(0xFF3D5AFE));
    });

    test('set 更新状态并持久化', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = SeedColorNotifier(prefs);

      notifier.set(const Color(0xFF009688));

      expect(notifier.state, const Color(0xFF009688));
      expect(prefs.getInt('seed_color'), 0xFF009688);
    });
  });
}
