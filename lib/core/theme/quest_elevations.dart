import 'package:flutter/material.dart';

import 'color_utils.dart';
import 'theme_flavor_provider.dart';

/// 灵犀学院阴影层级。
///
/// 提供语义阴影（subtle/elevated/highlighted）与静态层级（level0~level4）。
/// 阴影颜色可随 [seedColor] 色调微调，并支持三种主题风味切换。
class QuestElevations extends ThemeExtension<QuestElevations> {
  const QuestElevations({
    required this.subtle,
    required this.elevated,
    required this.highlighted,
    required this.pixelBorder,
  });

  /// Subtle：平铺卡片（1px blur，opacity 0.04，offset (0,1)）
  final List<BoxShadow> subtle;

  /// Elevated：悬浮卡片（6px blur，opacity 0.08，offset (0,2)）
  final List<BoxShadow> elevated;

  /// Highlighted：强调卡片/对话框（12px blur，opacity 0.12，offset (0,4)）
  final List<BoxShadow> highlighted;

  /// Minecraft 彩蛋的像素厚边（模拟体素挤出）。
  final List<BoxShadow> pixelBorder;

  /// 根据 [seedColor]、[brightness] 与 [flavor] 生成阴影。
  factory QuestElevations.fromSeed(
    Color seed,
    Brightness brightness,
    ThemeFlavor flavor,
  ) {
    final isDark = brightness == Brightness.dark;
    final isMinimal = flavor == ThemeFlavor.minimal;

    // 阴影底色：亮色用黑色，暗色用 seedColor 色调的白色，避免脏感。
    final shadowBase = isDark
        ? withSaturation(seed, 0.3).withValues(alpha: 1.0)
        : Colors.black;

    double opacity(double lightValue) {
      if (isMinimal) return lightValue * 0.3;
      return isDark ? (lightValue * 1.5).clamp(0.0, 0.35) : lightValue;
    }

    BoxShadow buildShadow({
      required double alpha,
      required double blur,
      required Offset offset,
    }) {
      return BoxShadow(
        color: shadowBase.withValues(alpha: alpha),
        blurRadius: blur,
        offset: offset,
      );
    }

    return QuestElevations(
      subtle: [
        buildShadow(alpha: opacity(0.04), blur: 1, offset: const Offset(0, 1)),
      ],
      elevated: [
        buildShadow(alpha: opacity(0.08), blur: 6, offset: const Offset(0, 2)),
      ],
      highlighted: [
        buildShadow(
          alpha: opacity(0.12),
          blur: 12,
          offset: const Offset(0, 4),
        ),
      ],
      pixelBorder: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
          blurRadius: 0,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
          blurRadius: 0,
          spreadRadius: 0,
          offset: const Offset(4, 0),
        ),
      ],
    );
  }

  /// 亮色模式实例（默认种子色）。
  static final QuestElevations light = QuestElevations.fromSeed(
    const Color(0xFF6750A4),
    Brightness.light,
    ThemeFlavor.standard,
  );

  /// 暗色模式实例（默认种子色）。
  static final QuestElevations dark = QuestElevations.fromSeed(
    const Color(0xFF6750A4),
    Brightness.dark,
    ThemeFlavor.standard,
  );

  /// 极简模式实例（默认种子色）。
  static final QuestElevations minimal = QuestElevations.fromSeed(
    const Color(0xFF6750A4),
    Brightness.light,
    ThemeFlavor.minimal,
  );

  @override
  QuestElevations copyWith({
    List<BoxShadow>? subtle,
    List<BoxShadow>? elevated,
    List<BoxShadow>? highlighted,
    List<BoxShadow>? pixelBorder,
  }) {
    return QuestElevations(
      subtle: subtle ?? this.subtle,
      elevated: elevated ?? this.elevated,
      highlighted: highlighted ?? this.highlighted,
      pixelBorder: pixelBorder ?? this.pixelBorder,
    );
  }

  @override
  QuestElevations lerp(QuestElevations? other, double t) {
    if (other == null) {
      return this;
    }
    return QuestElevations(
      subtle: BoxShadow.lerpList(subtle, other.subtle, t)!,
      elevated: BoxShadow.lerpList(elevated, other.elevated, t)!,
      highlighted: BoxShadow.lerpList(highlighted, other.highlighted, t)!,
      pixelBorder: BoxShadow.lerpList(pixelBorder, other.pixelBorder, t)!,
    );
  }

  // ============== 静态层级（向下兼容）==============

  /// Level 0：无阴影（0dp）
  static const List<BoxShadow> level0 = <BoxShadow>[];

  /// Level 1：轻微阴影（1dp）
  static const List<BoxShadow> level1 = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F000000), // 黑色 6% 透明度
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Level 2：低海拔阴影（3dp）
  static const List<BoxShadow> level2 = <BoxShadow>[
    BoxShadow(
      color: Color(0x14000000), // 黑色 8% 透明度
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Level 3：中海拔阴影（6dp）
  static const List<BoxShadow> level3 = <BoxShadow>[
    BoxShadow(
      color: Color(0x1A000000), // 黑色 10% 透明度
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Level 4：高海拔阴影（12dp）
  static const List<BoxShadow> level4 = <BoxShadow>[
    BoxShadow(
      color: Color(0x1F000000), // 黑色 12% 透明度
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// 解析 Level 0 阴影（始终返回空列表）
  static List<BoxShadow> level0BoxShadow(BuildContext context) => level0;

  /// 解析 Level 1 阴影（暗色模式下使用白色阴影）
  static List<BoxShadow> level1BoxShadow(BuildContext context) {
    return _resolveShadows(context, level1, 0.06);
  }

  /// 解析 Level 2 阴影（暗色模式下使用白色阴影）
  static List<BoxShadow> level2BoxShadow(BuildContext context) {
    return _resolveShadows(context, level2, 0.08);
  }

  /// 解析 Level 3 阴影（暗色模式下使用白色阴影）
  static List<BoxShadow> level3BoxShadow(BuildContext context) {
    return _resolveShadows(context, level3, 0.10);
  }

  /// 解析 Level 4 阴影（暗色模式下使用白色阴影）
  static List<BoxShadow> level4BoxShadow(BuildContext context) {
    return _resolveShadows(context, level4, 0.12);
  }

  /// 便捷方法：根据 [level] 返回对应层级的阴影
  static List<BoxShadow> of(BuildContext context, {int level = 1}) {
    switch (level) {
      case 0:
        return level0BoxShadow(context);
      case 1:
        return level1BoxShadow(context);
      case 2:
        return level2BoxShadow(context);
      case 3:
        return level3BoxShadow(context);
      case 4:
        return level4BoxShadow(context);
      default:
        return level1BoxShadow(context);
    }
  }

  /// 根据主题亮度将预定义黑色阴影转换为适配当前模式的阴影
  static List<BoxShadow> _resolveShadows(
    BuildContext context,
    List<BoxShadow> shadows,
    double darkOpacity,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) {
      return shadows;
    }
    return shadows
        .map(
          (BoxShadow s) => BoxShadow(
            color: Colors.white.withValues(alpha: darkOpacity),
            blurRadius: s.blurRadius,
            spreadRadius: s.spreadRadius,
            offset: s.offset,
            blurStyle: s.blurStyle,
          ),
        )
        .toList(growable: false);
  }
}

/// 便捷扩展：从 [BuildContext] 获取 [QuestElevations]
extension QuestElevationsX on BuildContext {
  /// 获取当前主题中注册的灵犀阴影扩展；未注册时回退到亮色实例
  QuestElevations get questElevations =>
      Theme.of(this).extension<QuestElevations>() ?? QuestElevations.light;
}
