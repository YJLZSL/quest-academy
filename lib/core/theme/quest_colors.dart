import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'color_utils.dart';
import 'theme_flavor_provider.dart';

/// 问学自定义颜色扩展。
///
/// 通过 [ThemeExtension] 注册到主题中，用于扩展 Material 3 [ColorScheme]，
/// 提供品牌、Streak、成就、对话、Pixel MC 等场景的语义化颜色。
///
/// 所有颜色均可从 [seedColor] 与 [ThemeFlavor] 动态派生，避免硬编码。
class QuestColors extends ThemeExtension<QuestColors> {
  const QuestColors({
    required this.brandPrimary,
    required this.brandSecondary,
    required this.streakFire,
    required this.achievementGold,
    required this.socraticBlue,
    required this.misconceptionRed,
    required this.successGreen,
    required this.infoTeal,
    required this.chatUserBubble,
    required this.chatAssistantBubble,
    required this.highlightYellow,
    required this.xpBlue,
    required this.pixelGrass,
    required this.pixelDirt,
    required this.pixelStone,
    required this.pixelWood,
  });

  /// 品牌主色 - 从 seedColor 派生，偏亮。
  final Color brandPrimary;

  /// 品牌辅色 - seedColor 的邻近色，用于高光、强调。
  final Color brandSecondary;

  /// Streak 火焰红 - 固定高饱和，保证激励感。
  final Color streakFire;

  /// 成就金 - 固定金色，保证识别度。
  final Color achievementGold;

  /// 苏格拉底引导蓝 - seedColor 的冷色分裂互补色。
  final Color socraticBlue;

  /// 常见误解红 - 固定红色。
  final Color misconceptionRed;

  /// 成功绿 - 固定绿色。
  final Color successGreen;

  /// 信息青蓝 - seedColor 调和后的青蓝。
  final Color infoTeal;

  /// 用户消息气泡背景。
  final Color chatUserBubble;

  /// AI 消息气泡背景。
  final Color chatAssistantBubble;

  /// 高亮标记黄 - 固定黄色。
  final Color highlightYellow;

  /// XP 经验值蓝。
  final Color xpBlue;

  /// Pixel MC 草地绿。
  final Color pixelGrass;

  /// Pixel MC 泥土棕。
  final Color pixelDirt;

  /// Pixel MC 石头灰。
  final Color pixelStone;

  /// Pixel MC 木头棕。
  final Color pixelWood;

  /// 根据 [seedColor] 与 [flavor] 动态生成颜色实例。
  factory QuestColors.fromSeed(Color seed, ThemeFlavor flavor) {
    final isMinimal = flavor == ThemeFlavor.minimal;

    Color derive(Color color, double desaturateAmount) {
      final adjusted = isMinimal ? desaturate(color, desaturateAmount) : color;
      return adjusted;
    }

    final brandPrimary = derive(withLightness(seed, 0.55), 0.0);
    final brandSecondary = derive(harmonyAnalogous(seed, left: false), 0.0);
    final socraticBlue =
        derive(harmonySplitComplementary(seed, left: true), 0.0);
    final infoTeal = derive(
      _blendHue(seed, const Color(0xFF26C6DA)),
      0.0,
    );
    final chatUserBubble = derive(
      ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light)
          .primaryContainer,
      0.35,
    );

    return QuestColors(
      brandPrimary: brandPrimary,
      brandSecondary: brandSecondary,
      streakFire: derive(const Color(0xFFFF5722), 0.0),
      achievementGold: derive(const Color(0xFFFFD700), 0.0),
      socraticBlue: socraticBlue,
      misconceptionRed: derive(const Color(0xFFEF5350), 0.0),
      successGreen: derive(const Color(0xFF66BB6A), 0.0),
      infoTeal: infoTeal,
      chatUserBubble: chatUserBubble,
      chatAssistantBubble: const Color(0xFFF5F5F5),
      highlightYellow: derive(const Color(0xFFFFEB3B), 0.0),
      xpBlue: derive(const Color(0xFF1CB0F6), 0.0),
      pixelGrass: const Color(0xFF5D8C22),
      pixelDirt: const Color(0xFF8B5A2B),
      pixelStone: const Color(0xFF707070),
      pixelWood: const Color(0xFF6B4226),
    );
  }

  /// 暗色模式实例。
  ///
  /// 在 OLED trueBlack 背景下，对派生色进行提亮以满足对比度。
  QuestColors toDark() {
    return copyWith(
      brandPrimary: withLightness(brandPrimary, 0.65),
      brandSecondary: withLightness(brandSecondary, 0.70),
      socraticBlue: withLightness(socraticBlue, 0.65),
      infoTeal: withLightness(infoTeal, 0.60),
      chatUserBubble: withLightness(chatUserBubble, 0.35),
      chatAssistantBubble: const Color(0xFF2D2D2D),
    );
  }

  /// 亮色模式实例（基于默认种子色，兼容旧代码直接访问）。
  static final QuestColors light =
      QuestColors.fromSeed(const Color(0xFF3D5AFE), ThemeFlavor.standard);

  /// 暗色模式实例（基于默认种子色）。
  static final QuestColors dark = light.toDark();

  /// 极简模式实例（基于默认种子色）。
  static final QuestColors minimal =
      QuestColors.fromSeed(const Color(0xFF3D5AFE), ThemeFlavor.minimal);

  @override
  QuestColors copyWith({
    Color? brandPrimary,
    Color? brandSecondary,
    Color? streakFire,
    Color? achievementGold,
    Color? socraticBlue,
    Color? misconceptionRed,
    Color? successGreen,
    Color? infoTeal,
    Color? chatUserBubble,
    Color? chatAssistantBubble,
    Color? highlightYellow,
    Color? xpBlue,
    Color? pixelGrass,
    Color? pixelDirt,
    Color? pixelStone,
    Color? pixelWood,
  }) {
    return QuestColors(
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandSecondary: brandSecondary ?? this.brandSecondary,
      streakFire: streakFire ?? this.streakFire,
      achievementGold: achievementGold ?? this.achievementGold,
      socraticBlue: socraticBlue ?? this.socraticBlue,
      misconceptionRed: misconceptionRed ?? this.misconceptionRed,
      successGreen: successGreen ?? this.successGreen,
      infoTeal: infoTeal ?? this.infoTeal,
      chatUserBubble: chatUserBubble ?? this.chatUserBubble,
      chatAssistantBubble: chatAssistantBubble ?? this.chatAssistantBubble,
      highlightYellow: highlightYellow ?? this.highlightYellow,
      xpBlue: xpBlue ?? this.xpBlue,
      pixelGrass: pixelGrass ?? this.pixelGrass,
      pixelDirt: pixelDirt ?? this.pixelDirt,
      pixelStone: pixelStone ?? this.pixelStone,
      pixelWood: pixelWood ?? this.pixelWood,
    );
  }

  @override
  QuestColors lerp(QuestColors? other, double t) {
    if (other == null) {
      return this;
    }
    return QuestColors(
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandSecondary: Color.lerp(brandSecondary, other.brandSecondary, t)!,
      streakFire: Color.lerp(streakFire, other.streakFire, t)!,
      achievementGold: Color.lerp(achievementGold, other.achievementGold, t)!,
      socraticBlue: Color.lerp(socraticBlue, other.socraticBlue, t)!,
      misconceptionRed: Color.lerp(misconceptionRed, other.misconceptionRed, t)!,
      successGreen: Color.lerp(successGreen, other.successGreen, t)!,
      infoTeal: Color.lerp(infoTeal, other.infoTeal, t)!,
      chatUserBubble: Color.lerp(chatUserBubble, other.chatUserBubble, t)!,
      chatAssistantBubble:
          Color.lerp(chatAssistantBubble, other.chatAssistantBubble, t)!,
      highlightYellow: Color.lerp(highlightYellow, other.highlightYellow, t)!,
      xpBlue: Color.lerp(xpBlue, other.xpBlue, t)!,
      pixelGrass: Color.lerp(pixelGrass, other.pixelGrass, t)!,
      pixelDirt: Color.lerp(pixelDirt, other.pixelDirt, t)!,
      pixelStone: Color.lerp(pixelStone, other.pixelStone, t)!,
      pixelWood: Color.lerp(pixelWood, other.pixelWood, t)!,
    );
  }
}

/// 将 [seedColor] 与 [target] 按色相平均混合，保留 seed 的饱和度与亮度。
Color _blendHue(Color seed, Color target) {
  final seedHsl = _toHsl(seed);
  final targetHsl = _toHsl(target);
  final blendedHue = (seedHsl[0] + targetHsl[0]) / 2;
  return _fromHsl([blendedHue, seedHsl[1], seedHsl[2]]);
}

// 复用 color_utils.dart 的私有辅助，避免重复导出。
List<double> _toHsl(Color color) {
  final seedHsl = <double>[];
  // 使用 HSL 转换的简化实现：通过 HSV 中转。
  final hsv = HSVColor.fromColor(color);
  final l = hsv.value * (1 - hsv.saturation / 2);
  var s = 0.0;
  if (l != 0 && l != 1) {
    s = (hsv.value - l) / math.min(l, 1 - l);
  }
  seedHsl.addAll([hsv.hue, s, l]);
  return seedHsl;
}

Color _fromHsl(List<double> hsl) {
  final h = hsl[0];
  final s = hsl[1].clamp(0.0, 1.0);
  final l = hsl[2].clamp(0.0, 1.0);

  final a = s * math.min(l, 1 - l);
  final v = l + a;
  final sat = l == 0 ? 0.0 : 2 * (1 - l / v);

  return HSVColor.fromAHSV(1, h, sat, v).toColor();
}

/// 便捷扩展：从 [BuildContext] 获取 [QuestColors]。
extension QuestColorsX on BuildContext {
  /// 获取当前主题中注册的灵犀自定义颜色；未注册时回退到亮色实例。
  QuestColors get questColors =>
      Theme.of(this).extension<QuestColors>() ?? QuestColors.light;
}
