import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_typography.dart';
import 'background_textures.dart';
import 'motion_tokens.dart';
import 'quest_colors.dart';
import 'quest_elevations.dart';
import 'quest_gradients.dart';
import 'quest_spacing.dart';
import 'shape_tokens.dart';
import 'shape_variants.dart';
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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

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
}
