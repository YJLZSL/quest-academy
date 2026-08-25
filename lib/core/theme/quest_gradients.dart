import 'package:flutter/material.dart';

import 'color_utils.dart';
import 'quest_colors.dart';
import 'theme_flavor_provider.dart';

/// 问学自定义渐变扩展。
///
/// 通过 [ThemeExtension] 注册到主题中，提供品牌辉光、Streak 火焰、
/// 成就徽章、庆祝动画、成功状态等场景的语义化渐变。
///
/// 渐变颜色从 [seedColor] 与 [ThemeFlavor] 动态派生。
class QuestGradients extends ThemeExtension<QuestGradients> {
  const QuestGradients({
    required this.brandGlow,
    required this.streakFire,
    required this.achievementGold,
    required this.primarySurface,
    required this.celebration,
    required this.success,
  });

  /// 品牌区域的径向辉光渐变。
  final RadialGradient brandGlow;

  /// Streak 连续学习火焰渐变（橙 → 红），对角线方向。
  final LinearGradient streakFire;

  /// 成就金色渐变（金 → 琥珀）。
  final LinearGradient achievementGold;

  /// 主色表面渐变（主色 → 透明），从上到下。
  final LinearGradient primarySurface;

  /// 庆祝渐变（主色 → 粉 → 橙）。
  final LinearGradient celebration;

  /// 成功绿色渐变（绿 → 深绿）。
  final LinearGradient success;

  /// 根据 [seedColor]、[colors] 与 [flavor] 动态生成渐变。
  factory QuestGradients.fromSeed(
    Color seed,
    QuestColors colors,
    ThemeFlavor flavor,
  ) {
    final isMinimal = flavor == ThemeFlavor.minimal;
    final isMinecraft = flavor == ThemeFlavor.minecraft;

    Color tint(Color color, double alpha) {
      return color.withValues(alpha: alpha);
    }

    final seedLight = withLightness(seed, 0.60);
    final surfaceMuted = tint(seed, isMinimal ? 0.02 : 0.05);
    final complementary = harmonyComplementary(seed);

    final brandGlow = RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: <Color>[
        tint(seedLight, isMinecraft ? 0.20 : 0.10),
        tint(seedLight, 0.0),
      ],
      stops: const <double>[0.0, 1.0],
    );

    final primarySurface = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[surfaceMuted, tint(seed, 0.0)],
    );

    final celebration = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        seedLight,
        complementary,
        colors.streakFire,
      ],
      stops: const <double>[0.0, 0.5, 1.0],
    );

    return QuestGradients(
      brandGlow: brandGlow,
      streakFire: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[colors.streakFire, colors.misconceptionRed],
      ),
      achievementGold: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[colors.achievementGold, tint(colors.achievementGold, 0.6)],
      ),
      primarySurface: primarySurface,
      celebration: celebration,
      success: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[colors.successGreen, tint(colors.successGreen, 0.6)],
      ),
    );
  }

  /// 暗色模式调整。
  QuestGradients toDark() {
    return copyWith(
      brandGlow: _darkenRadial(brandGlow),
      primarySurface: _darkenLinear(primarySurface),
      celebration: _darkenLinear(celebration),
    );
  }

  /// 亮色模式实例（基于默认种子色）。
  static final QuestGradients light = QuestGradients.fromSeed(
    const Color(0xFF3D5AFE),
    QuestColors.light,
    ThemeFlavor.standard,
  );

  /// 暗色模式实例（基于默认种子色）。
  static final QuestGradients dark = light.toDark();

  /// 极简模式实例（基于默认种子色）。
  static final QuestGradients minimal = QuestGradients.fromSeed(
    const Color(0xFF3D5AFE),
    QuestColors.minimal,
    ThemeFlavor.minimal,
  );

  @override
  QuestGradients copyWith({
    RadialGradient? brandGlow,
    LinearGradient? streakFire,
    LinearGradient? achievementGold,
    LinearGradient? primarySurface,
    LinearGradient? celebration,
    LinearGradient? success,
  }) {
    return QuestGradients(
      brandGlow: brandGlow ?? this.brandGlow,
      streakFire: streakFire ?? this.streakFire,
      achievementGold: achievementGold ?? this.achievementGold,
      primarySurface: primarySurface ?? this.primarySurface,
      celebration: celebration ?? this.celebration,
      success: success ?? this.success,
    );
  }

  @override
  QuestGradients lerp(QuestGradients? other, double t) {
    if (other == null) {
      return this;
    }
    return QuestGradients(
      brandGlow: _lerpRadialGradient(brandGlow, other.brandGlow, t),
      streakFire: _lerpLinearGradient(streakFire, other.streakFire, t),
      achievementGold:
          _lerpLinearGradient(achievementGold, other.achievementGold, t),
      primarySurface:
          _lerpLinearGradient(primarySurface, other.primarySurface, t),
      celebration: _lerpLinearGradient(celebration, other.celebration, t),
      success: _lerpLinearGradient(success, other.success, t),
    );
  }

  static RadialGradient _darkenRadial(RadialGradient gradient) {
    return RadialGradient(
      center: gradient.center,
      radius: gradient.radius,
      colors: gradient.colors
          .map((c) => c.withValues(alpha: (c.a * 1.4).clamp(0.0, 1.0)))
          .toList(),
      stops: gradient.stops,
      tileMode: gradient.tileMode,
      focal: gradient.focal,
      focalRadius: gradient.focalRadius,
    );
  }

  static LinearGradient _darkenLinear(LinearGradient gradient) {
    return LinearGradient(
      begin: gradient.begin,
      end: gradient.end,
      colors: gradient.colors
          .map((c) => c.withValues(alpha: (c.a * 1.4).clamp(0.0, 1.0)))
          .toList(),
      stops: gradient.stops,
      tileMode: gradient.tileMode,
    );
  }

  static RadialGradient _lerpRadialGradient(
    RadialGradient a,
    RadialGradient b,
    double t,
  ) {
    return RadialGradient(
      center: Alignment.lerp(a.center as Alignment, b.center as Alignment, t)!,
      radius: a.radius + (b.radius - a.radius) * t,
      colors: _lerpColorList(a.colors, b.colors, t),
      stops: _lerpStops(a.stops, b.stops, t),
      tileMode: t < 0.5 ? a.tileMode : b.tileMode,
      focal: t < 0.5 ? a.focal : b.focal,
      focalRadius: a.focalRadius + (b.focalRadius - a.focalRadius) * t,
    );
  }

  static LinearGradient _lerpLinearGradient(
    LinearGradient a,
    LinearGradient b,
    double t,
  ) {
    return LinearGradient(
      begin: Alignment.lerp(a.begin as Alignment, b.begin as Alignment, t)!,
      end: Alignment.lerp(a.end as Alignment, b.end as Alignment, t)!,
      colors: _lerpColorList(a.colors, b.colors, t),
      stops: _lerpStops(a.stops, b.stops, t),
      tileMode: t < 0.5 ? a.tileMode : b.tileMode,
    );
  }

  static List<Color> _lerpColorList(List<Color> a, List<Color> b, double t) {
    assert(a.length == b.length, '渐变颜色列表长度必须一致才能插值');
    return <Color>[
      for (int i = 0; i < a.length; i++) Color.lerp(a[i], b[i], t)!,
    ];
  }

  static List<double>? _lerpStops(List<double>? a, List<double>? b, double t) {
    if (a == null || b == null) {
      return a ?? b;
    }
    assert(a.length == b.length, '渐变 stops 列表长度必须一致才能插值');
    return <double>[
      for (int i = 0; i < a.length; i++) a[i] + (b[i] - a[i]) * t,
    ];
  }
}

/// 便捷扩展：从 [BuildContext] 获取 [QuestGradients]
extension QuestGradientsX on BuildContext {
  /// 获取当前主题中注册的问学自定义渐变；未注册时回退到亮色实例
  QuestGradients get questGradients =>
      Theme.of(this).extension<QuestGradients>() ?? QuestGradients.light;
}
