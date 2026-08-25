import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/app_providers.dart';

/// 主题风味枚举。
///
/// - [standard]：活泼完整风格（默认）。
/// - [minimal]：低饱和、低动效、高信息密度的专注模式。
/// - [minecraft]：像素块/体素彩蛋主题。
enum ThemeFlavor {
  standard,
  minimal,
  minecraft;

  /// 将字符串解析为 [ThemeFlavor]，无法解析时回退 [standard]。
  static ThemeFlavor fromString(String? value) {
    return switch (value) {
      'minimal' => ThemeFlavor.minimal,
      'minecraft' => ThemeFlavor.minecraft,
      _ => ThemeFlavor.standard,
    };
  }
}

/// 当前主题风味提供者。
///
/// 从 [sharedPreferencesProvider] 读取持久化值，键为 `theme_flavor`。
/// 修改后自动持久化。
///
/// v0.5.0 起将旧的 `minimal_mode` 开关合并为 [ThemeFlavor.minimal]，
/// 启动时会自动做一次迁移。
final themeFlavorProvider =
    StateNotifierProvider<ThemeFlavorNotifier, ThemeFlavor>(
  (ref) => ThemeFlavorNotifier(ref.read(sharedPreferencesProvider)),
);

/// [themeFlavorProvider] 的状态管理器。
class ThemeFlavorNotifier extends StateNotifier<ThemeFlavor> {
  ThemeFlavorNotifier(this._prefs)
      : super(_migrateLegacyMinimalMode(_prefs));

  static const _key = 'theme_flavor';

  /// 旧版极简模式开关的持久化键（v0.5.0 之前）。
  static const _legacyMinimalModeKey = 'minimal_mode';

  final SharedPreferences _prefs;

  /// 将旧版 `minimal_mode` 开关迁移为 [ThemeFlavor.minimal]。
  static ThemeFlavor _migrateLegacyMinimalMode(SharedPreferences prefs) {
    final flavor = ThemeFlavor.fromString(prefs.getString(_key));
    final legacyMinimal = prefs.getBool(_legacyMinimalModeKey);
    if (legacyMinimal == true && flavor != ThemeFlavor.minimal) {
      prefs
        ..setString(_key, ThemeFlavor.minimal.name)
        ..remove(_legacyMinimalModeKey);
      return ThemeFlavor.minimal;
    }
    // 无论是否迁移，清理旧键。
    if (legacyMinimal != null) {
      prefs.remove(_legacyMinimalModeKey);
    }
    return flavor;
  }

  /// 切换为指定风味并持久化。
  void setFlavor(ThemeFlavor flavor) {
    _prefs.setString(_key, flavor.name);
    state = flavor;
  }

  /// 切换为下一个风味（standard -> minimal -> minecraft -> standard）。
  void cycle() {
    final next = ThemeFlavor.values[(state.index + 1) % ThemeFlavor.values.length];
    setFlavor(next);
  }
}

/// 当前种子色提供者。
///
/// 从 [sharedPreferencesProvider] 读取持久化整数值，键为 `seed_color`。
/// 默认使用 Material 3 紫色调 `#6750A4`。
final seedColorProvider = StateNotifierProvider<SeedColorNotifier, Color>(
  (ref) => SeedColorNotifier(ref.read(sharedPreferencesProvider)),
);

/// [seedColorProvider] 的状态管理器。
class SeedColorNotifier extends StateNotifier<Color> {
  SeedColorNotifier(this._prefs)
      : super(Color(_prefs.getInt(_key) ?? 0xFF6750A4));

  static const _key = 'seed_color';

  final SharedPreferences _prefs;

  /// 设置种子色并持久化。
  void set(Color color) {
    _prefs.setInt(_key, color.value);
    state = color;
  }
}

/// 预设种子色，可在设置页快速切换。
abstract final class SeedColorPresets {
  const SeedColorPresets._();

  /// 怀旧星空紫（原灵犀主色）。
  static const Color starlightPurple = Color(0xFF6750A4);

  /// 活泼珊瑚红。
  static const Color playfulCoral = Color(0xFFFF6B6B);

  /// 活泼青绿。
  static const Color playfulAqua = Color(0xFF4ECDC4);

  /// 活泼柠黄绿。
  static const Color playfulLime = Color(0xFFA8E063);

  /// 所有预设列表。
  static const List<Color> all = [
    starlightPurple,
    playfulCoral,
    playfulAqua,
    playfulLime,
  ];
}
