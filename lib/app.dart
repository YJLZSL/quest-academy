import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest_academy/core/providers/app_providers.dart';
import 'package:quest_academy/core/router/app_router.dart';
import 'package:quest_academy/core/theme/app_theme.dart';
import 'package:quest_academy/core/theme/motion_tokens.dart';
import 'package:quest_academy/core/theme/theme_flavor_provider.dart';
import 'package:quest_academy/features/progress/celebration_service.dart';
import 'package:quest_academy/features/update/update_controller.dart';
import 'package:quest_academy/features/update/update_dialog.dart';
import 'package:quest_academy/features/update/update_state.dart';

/// 问学应用根 Widget。
///
/// 使用 `MaterialApp.router`，路由配置由 [goRouterProvider] 提供，
/// 主题由 [AppTheme.themeFor] 根据当前主题模式、主题风味与种子色动态生成。
/// 外层包裹 [GlobalCelebrationLayer] 支持全局粒子庆祝。
class QuestApp extends ConsumerStatefulWidget {
  const QuestApp({super.key});

  @override
  ConsumerState<QuestApp> createState() => _QuestAppState();
}

class _QuestAppState extends ConsumerState<QuestApp> {
  /// 防止更新弹窗重复弹出（同一会话只弹一次）。
  bool _updateDialogShown = false;

  /// 主题缓存：键为 (brightness, flavor, seedColor)，避免每次 build 重新
  /// 计算 ThemeData（ColorScheme.fromSeed 开销较大），同时保证主题切换时
  /// 复用同一实例，减少不必要的重绘。
  final Map<(Brightness, ThemeFlavor, Color), ThemeData> _themeCache = {};

  /// 获取（或构建并缓存）指定参数的主题。
  ThemeData _themeFor(Brightness brightness, ThemeFlavor flavor, Color seed) {
    final key = (brightness, flavor, seed);
    return _themeCache.putIfAbsent(
      key,
      () => AppTheme.themeFor(brightness, seed: seed, flavor: flavor),
    );
  }

  @override
  void initState() {
    super.initState();
    // 启动后延迟 3 秒静默检查更新（避免与首屏渲染争抢资源）。
    // 节流逻辑由 UpdateController 内部处理（24 小时窗口）。
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      ref.read(updateControllerProvider.notifier).checkForUpdates(
            force: false,
            silent: true,
          );
    });
  }

  void _maybeShowUpdateDialog(UpdateState state) {
    // 仅在后台静默检查发现新版本时自动弹窗（同一会话只弹一次）
    if (state.status == UpdateStatus.available &&
        state.fromBackground &&
        !_updateDialogShown) {
      _updateDialogShown = true;
      final context = this.context;
      if (context.mounted) {
        UpdateDialog.show(context, force: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听更新状态：后台检查发现新版本时自动弹窗
    ref.listen<UpdateState>(updateControllerProvider, (previous, next) {
      _maybeShowUpdateDialog(next);
    });

    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(goRouterProvider);
    final flavor = ref.watch(themeFlavorProvider);
    final seedColor = ref.watch(seedColorProvider);

    final brightness = _resolveBrightness(themeMode);
    final theme = _themeFor(brightness, flavor, seedColor);
    final darkTheme = _themeFor(Brightness.dark, flavor, seedColor);
    // 主题切换动画：与全局动效节奏一致（250ms / 标准减速曲线）。
    // reduceMotion 时降级为即时切换，避免出现闪烁式跳变。
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final motionTokens = theme.extension<MotionTokens>() ?? MotionTokens.standard;

    return GlobalCelebrationLayer(
      child: MaterialApp.router(
        title: '问学',
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        // 主题切换（浅色 ⇄ 深色）时对所有 ThemeData 属性做插值过渡，
        // 避免颜色/圆角/阴影瞬间跳变造成闪烁。
        themeAnimationDuration:
            reduceMotion ? Duration.zero : motionTokens.durationMedium,
        themeAnimationCurve: motionTokens.curveStandard,
        locale: locale,
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }

  Brightness _resolveBrightness(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context);
    }
  }
}
