import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// 问学间距 Token。
///
/// 通过 [ThemeExtension] 注册到主题中，提供统一的间距刻度，
/// 避免页面/组件中散落的硬编码 `SizedBox(height: 16)` 等。
class QuestSpacing extends ThemeExtension<QuestSpacing> {
  const QuestSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.x2l,
    required this.x3l,
    required this.x4l,
  });

  /// 4dp - 极小间距（图标与文字间、紧凑行距）。
  final double xs;

  /// 8dp - 小组件内部间距。
  final double sm;

  /// 12dp - 常规元素间距。
  final double md;

  /// 16dp - 卡片内边距 / 列表项间距。
  final double lg;

  /// 24dp - 区块间距。
  final double xl;

  /// 32dp - 大区块间距。
  final double x2l;

  /// 48dp - 页面级间距。
  final double x3l;

  /// 64dp - 超大间距（Hero 区等）。
  final double x4l;

  /// 默认实例（Material 3 标准刻度）。
  static const QuestSpacing standard = QuestSpacing(
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 24,
    x2l: 32,
    x3l: 48,
    x4l: 64,
  );

  @override
  QuestSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? x2l,
    double? x3l,
    double? x4l,
  }) {
    return QuestSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      x2l: x2l ?? this.x2l,
      x3l: x3l ?? this.x3l,
      x4l: x4l ?? this.x4l,
    );
  }

  @override
  QuestSpacing lerp(QuestSpacing? other, double t) {
    if (other == null) return this;
    return QuestSpacing(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      x2l: lerpDouble(x2l, other.x2l, t)!,
      x3l: lerpDouble(x3l, other.x3l, t)!,
      x4l: lerpDouble(x4l, other.x4l, t)!,
    );
  }
}

/// 便捷扩展：从 [BuildContext] 获取 [QuestSpacing]。
extension QuestSpacingX on BuildContext {
  /// 获取当前主题中注册的间距 Token；未注册时回退到标准刻度。
  QuestSpacing get questSpacing =>
      Theme.of(this).extension<QuestSpacing>() ?? QuestSpacing.standard;
}
