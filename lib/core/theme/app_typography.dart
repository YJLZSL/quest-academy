import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_flavor_provider.dart';

/// 应用字体族扩展。
///
/// 通过 [ThemeExtension] 注册到主题中，支持按主题风味切换装饰字体。
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.fontFamilyDisplay,
    required this.fontFamilyBody,
    required this.fontFamilyMono,
  });

  /// 标题/展示字体族名称。
  final String fontFamilyDisplay;

  /// 正文字体族名称。
  final String fontFamilyBody;

  /// 等宽字体族名称（代码块、日志等）。
  final String fontFamilyMono;

  /// 活泼模式字体：中文快乐体 + 英文圆润体。
  static const AppTypography playful = AppTypography(
    fontFamilyDisplay: 'ZCOOLKuaiLe',
    fontFamilyBody: 'NotoSansSC',
    fontFamilyMono: 'RobotoMono',
  );

  /// 极简模式字体：无装饰，全部回退系统字体。
  static const AppTypography minimal = AppTypography(
    fontFamilyDisplay: 'NotoSansSC',
    fontFamilyBody: 'NotoSansSC',
    fontFamilyMono: 'RobotoMono',
  );

  /// Minecraft 彩蛋模式字体：中文保持快乐体，英文使用像素字体。
  static const AppTypography minecraft = AppTypography(
    fontFamilyDisplay: 'PressStart2P',
    fontFamilyBody: 'NotoSansSC',
    fontFamilyMono: 'VT323',
  );

  /// 根据 [ThemeFlavor] 返回对应字体配置。
  static AppTypography forFlavor(ThemeFlavor flavor) {
    return switch (flavor) {
      ThemeFlavor.standard => playful,
      ThemeFlavor.minimal => minimal,
      ThemeFlavor.minecraft => minecraft,
    };
  }

  @override
  AppTypography copyWith({
    String? fontFamilyDisplay,
    String? fontFamilyBody,
    String? fontFamilyMono,
  }) {
    return AppTypography(
      fontFamilyDisplay: fontFamilyDisplay ?? this.fontFamilyDisplay,
      fontFamilyBody: fontFamilyBody ?? this.fontFamilyBody,
      fontFamilyMono: fontFamilyMono ?? this.fontFamilyMono,
    );
  }

  @override
  AppTypography lerp(AppTypography? other, double t) {
    if (other == null) return this;
    // 字体族为离散值，不支持插值，直接切换。
    return t < 0.5 ? this : other;
  }
}

/// 便捷扩展：从 [BuildContext] 获取 [AppTypography]。
extension AppTypographyX on BuildContext {
  /// 获取当前主题中注册的字体配置。
  AppTypography get appTypography =>
      Theme.of(this).extension<AppTypography>() ?? AppTypography.playful;
}

/// 根据 [ThemeFlavor] 构建完整 [TextTheme]。
///
/// [brightness] 用于 Material 3 基础文本主题；[baseTextTheme] 为中文正文基础。
TextTheme buildTextTheme({
  required Brightness brightness,
  required ThemeFlavor flavor,
  TextTheme? baseTextTheme,
}) {
  final bodyBase = baseTextTheme ??
      GoogleFonts.notoSansScTextTheme(
        ThemeData(brightness: brightness, useMaterial3: true).textTheme,
      );

  switch (flavor) {
    case ThemeFlavor.minimal:
      return bodyBase;
    case ThemeFlavor.minecraft:
      return _applyDisplayFont(
        bodyBase,
        GoogleFonts.pressStart2p,
      );
    case ThemeFlavor.standard:
      return _applyDisplayFont(
        bodyBase,
        GoogleFonts.zcoolKuaiLe,
      );
  }
}

TextTheme _applyDisplayFont(
  TextTheme base,
  TextStyle Function({TextStyle? textStyle}) font,
) {
  return base.copyWith(
    displayLarge: font(textStyle: base.displayLarge),
    displayMedium: font(textStyle: base.displayMedium),
    displaySmall: font(textStyle: base.displaySmall),
    headlineLarge: font(textStyle: base.headlineLarge),
    headlineMedium: font(textStyle: base.headlineMedium),
    headlineSmall: font(textStyle: base.headlineSmall),
    titleLarge: font(textStyle: base.titleLarge),
    titleMedium: font(textStyle: base.titleMedium),
    titleSmall: font(textStyle: base.titleSmall),
  );
}
