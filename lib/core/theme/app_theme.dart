import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'background_textures.dart';
import 'motion_tokens.dart';
import 'quest_colors.dart';
import 'quest_elevations.dart';
import 'quest_gradients.dart';
import 'quest_spacing.dart';
import 'shape_tokens.dart';
import 'theme_flavor_provider.dart';

/// 问学 Material 3 Expressive 主题。
///
/// 支持三种主题风味（standard / minimal / minecraft）与可配置种子色。
/// 注册 [QuestColors]、[QuestGradients]、[QuestElevations]、
/// [AppTypography]、[BackgroundTextures]、[ShapeTokens]、[MotionTokens]
/// 等 ThemeExtension。
class AppTheme {
  const AppTheme._();

  /// 默认主题种子色 - 求知靛蓝（问学品牌色）。
  static const Color seedColor = Color(0xFF3D5AFE);

  /// 暗色模式 OLED trueBlack 背景。
  static const Color darkTrueBlack = Color(0xFF000000);

  /// 亮色主题（默认种子色、standard 风味）。
  static ThemeData get lightTheme => themeFor(
        Brightness.light,
        seed: seedColor,
        flavor: ThemeFlavor.standard,
      );

  /// 暗色主题（默认种子色、standard 风味）。
  static ThemeData get darkTheme => themeFor(
        Brightness.dark,
        seed: seedColor,
        flavor: ThemeFlavor.standard,
      );

  /// 根据亮度、种子色与主题风味生成主题。
  static ThemeData themeFor(
    Brightness brightness, {
    required Color seed,
    required ThemeFlavor flavor,
  }) {
    final colorScheme = _buildColorScheme(seed, brightness);

    final isMinimal = flavor == ThemeFlavor.minimal;
    final isMinecraft = flavor == ThemeFlavor.minecraft;

    final textTheme = buildTextTheme(brightness: brightness, flavor: flavor);

    final shapeTokens = ShapeTokens.forFlavor(flavor);
    final motionTokens = MotionTokens.forFlavor(flavor);
    final questColors = QuestColors.fromSeed(seed, flavor);
    final questColorsResolved =
        brightness == Brightness.dark ? questColors.toDark() : questColors;
    final questGradients = QuestGradients.fromSeed(
      seed,
      questColorsResolved,
      flavor,
    );
    final questGradientsResolved =
        brightness == Brightness.dark ? questGradients.toDark() : questGradients;
    final questElevations = QuestElevations.fromSeed(seed, brightness, flavor);
    final typography = AppTypography.forFlavor(flavor);
    final textures = BackgroundTextures.forFlavor(flavor, brightness);

    final scaffoldColor = brightness == Brightness.dark
        ? darkTrueBlack
        : colorScheme.surface;

    final appBarBackground = isMinecraft
        ? const Color(0xFF5D8C22)
        : colorScheme.surface;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scaffoldColor,
      appBarTheme: AppBarThemeData(
        centerTitle: !isMinimal,
        backgroundColor: appBarBackground,
        foregroundColor: isMinecraft ? Colors.white : colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: colorScheme.surfaceTint.withValues(alpha: 0.03),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapeTokens.cardRadius),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapeTokens.chipRadius),
        ),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapeTokens.inputRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapeTokens.inputRadius),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapeTokens.inputRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      navigationRailTheme: NavigationRailThemeData(
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: colorScheme.surface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapeTokens.buttonRadius),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapeTokens.dialogRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapeTokens.chipRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapeTokens.buttonRadius),
        ),
      ),
      // ── 交互态（悬停 / 聚焦 / 水波纹）────────────────────────
      // 统一 hover / focus / splash 颜色，保证桌面端与移动端都有清晰的
      // 悬停与聚焦反馈，且颜色随主题（明/暗）与种子色自动适配。
      hoverColor: colorScheme.primary.withValues(alpha: 0.08),
      focusColor: colorScheme.primary.withValues(alpha: 0.12),
      highlightColor: colorScheme.primary.withValues(alpha: 0.10),
      splashColor: colorScheme.primary.withValues(alpha: 0.10),

      // ── 列表 / 折叠面板 ───────────────────────────────────
      // 统一列表项与展开收起的圆角、内边距与选中态底色。
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapeTokens.chipRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 12,
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        selectedColor: colorScheme.primary,
        selectedTileColor: colorScheme.primary.withValues(alpha: 0.12),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const Border(),
        collapsedShape: const Border(),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: colorScheme.onSurfaceVariant,
        collapsedIconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        collapsedTextColor: colorScheme.onSurface,
      ),

      // ── 表单控件 ──────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.38);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.outline;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.24),
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimary,
        ),
      ),

      // ── 浮层与弹层 ────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapeTokens.cardRadius / 2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        modalBackgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(shapeTokens.dialogRadius),
          ),
        ),
        showDragHandle: true,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(shapeTokens.dialogRadius),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(shapeTokens.chipRadius),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),

      // ── 分隔线与进度 ──────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withValues(alpha: 0.16),
        circularTrackColor: colorScheme.primary.withValues(alpha: 0.16),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
      extensions: <ThemeExtension<dynamic>>[
        questColorsResolved,
        questGradientsResolved,
        questElevations,
        typography,
        textures,
        shapeTokens,
        motionTokens,
        QuestSpacing.standard,
      ],
    );
  }

  /// 构建色彩方案，并对深色模式做纯黑背景（OLED）适配。
  ///
  /// 深色模式下 [scaffoldBackgroundColor] 为纯黑 [darkTrueBlack]，若继续使用
  /// M3 默认 surface 容器色（本身已接近黑色），卡片/弹层与背景将几乎没有层次。
  /// 这里显式抬升各级 surface 容器，使其与纯黑背景形成可辨识的层级，
  /// 同时保留 M3 生成的 `onSurface*` 前景色——它们在更亮的容器上对比度
  /// 仍远高于 WCAG AA 要求的 4.5:1（实测均 ≥ 7:1）。
  static ColorScheme _buildColorScheme(Color seed, Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    if (brightness == Brightness.light) {
      return base;
    }

    return base.copyWith(
      surface: const Color(0xFF0E0E10),
      surfaceContainerLowest: const Color(0xFF0A0A0C),
      surfaceContainerLow: const Color(0xFF16161A),
      surfaceContainer: const Color(0xFF1C1C21),
      surfaceContainerHigh: const Color(0xFF242429),
      surfaceContainerHighest: const Color(0xFF2E2E34),
      // 深色下抬高 outline 亮度，保证描边与分隔线在纯黑背景上可见。
      outline: const Color(0xFF8E8E96),
      outlineVariant: const Color(0xFF45454D),
    );
  }
}
