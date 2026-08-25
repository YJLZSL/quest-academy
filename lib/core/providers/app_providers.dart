import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_flavor_provider.dart';

/// SharedPreferences 提供者。
///
/// 在 `main()` 中通过 `overrideWithValue` 注入已初始化的实例，
/// 避免在 provider 内部异步等待，保证 UI 启动即可同步读取。
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider 必须在 main 中 override');
});

/// 应用配置快照，从 SharedPreferences 读取的初始值集合。
class AppConfig {
  const AppConfig({
    required this.themeMode,
    required this.locale,
    required this.socraticMode,
    required this.onboardingCompleted,
    required this.themeFlavor,
    required this.seedColor,
  });

  final ThemeMode themeMode;
  final Locale locale;
  final bool socraticMode;
  final bool onboardingCompleted;
  final ThemeFlavor themeFlavor;
  final Color seedColor;
}

/// 应用配置提供者，从 SharedPreferences 读取主题、语言、苏格拉底模式等默认值。
///
/// SharedPreferences 中存储的键：
/// - `theme_mode`：int (0=system, 1=light, 2=dark)
/// - `locale`：String ('zh' | 'en')
/// - `socratic_mode`：bool
/// - `onboarding_completed`：bool
/// - `theme_flavor`：String ('standard' | 'minimal' | 'minecraft')
/// - `seed_color`：int (Color.value)
final appConfigProvider = Provider<AppConfig>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final themeIndex = prefs.getInt('theme_mode') ?? 0;
  final langCode = prefs.getString('locale') ?? 'zh';
  return AppConfig(
    themeMode: ThemeMode.values[themeIndex.clamp(0, ThemeMode.values.length - 1)],
    locale: langCode == 'en'
        ? const Locale('en', 'US')
        : const Locale('zh', 'CN'),
    socraticMode: prefs.getBool('socratic_mode') ?? true,
    onboardingCompleted: prefs.getBool('onboarding_completed') ?? false,
    themeFlavor: ThemeFlavor.fromString(prefs.getString('theme_flavor')),
    seedColor: Color(prefs.getInt('seed_color') ?? 0xFF3D5AFE),
  );
});

/// 主题模式提供者（system / light / dark）。
final themeModeProvider = StateProvider<ThemeMode>(
  (ref) => ref.watch(appConfigProvider).themeMode,
);

/// 语言提供者（zh-CN / en-US）。
final localeProvider = StateProvider<Locale>(
  (ref) => ref.watch(appConfigProvider).locale,
);

/// 苏格拉底引导模式开关的 StateNotifier。
///
/// 在切换时同步写入 SharedPreferences（键 `socratic_mode`），
/// 保证下次启动恢复上一次设置。
class SocraticModeNotifier extends StateNotifier<bool> {
  SocraticModeNotifier(this._prefs)
      : super(_prefs.getBool(_key) ?? true);

  static const _key = 'socratic_mode';

  final SharedPreferences _prefs;

  /// 切换为相反值并持久化。
  void toggle() {
    final newValue = !state;
    _prefs.setBool(_key, newValue);
    state = newValue;
  }

  /// 设置指定值并持久化。
  void set(bool value) {
    _prefs.setBool(_key, value);
    state = value;
  }
}

/// 苏格拉底引导模式开关。
final socraticModeProvider = StateNotifierProvider<SocraticModeNotifier, bool>(
  (ref) => SocraticModeNotifier(ref.read(sharedPreferencesProvider)),
);

/// 引导完成标志。
final onboardingCompletedProvider = StateProvider<bool>(
  (ref) => ref.watch(appConfigProvider).onboardingCompleted,
);

/// 重新导出主题风味相关 Provider，方便统一导入。
export '../theme/theme_flavor_provider.dart'
    show
        ThemeFlavor,
        ThemeFlavorNotifier,
        themeFlavorProvider,
        SeedColorNotifier,
        seedColorProvider,
        SeedColorPresets;
