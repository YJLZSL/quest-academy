import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'theme_flavor_provider.dart';

/// 动效 Token 扩展。
///
/// 除原有的风味化参数外，额外提供**统一的时长与缓动曲线**，供页面切换、
/// 弹窗、侧边栏、列表展开收起、按钮与卡片交互共同消费，保证全局节奏一致。
///
/// 时长规范（单次动效控制在 200–300ms）：
/// - [durationShort]：200ms —— 按压反馈、小元素切换、聚焦/悬停态
/// - [durationMedium]：250ms —— 卡片/列表项、展开收起、弹窗入场
/// - [durationLong]：300ms —— 页面切换、侧边栏、大位移
///
/// 曲线规范：
/// - [curveStandard]：标准减速（easeOutCubic），用于大多数入场
/// - [curveEmphasized]：强调减速（M3 emphasizedDecelerate），用于大位移
/// - [curveExit]：加速离场（easeInCubic），用于退场/反向动画
class MotionTokens extends ThemeExtension<MotionTokens> {
  const MotionTokens({
    required this.pageEntranceDelay,
    required this.listStaggerDelay,
    required this.cardHoverScale,
    required this.buttonPressedScale,
    required this.enableParticles,
    this.durationShort = const Duration(milliseconds: 200),
    this.durationMedium = const Duration(milliseconds: 250),
    this.durationLong = const Duration(milliseconds: 300),
    this.curveStandard = Curves.easeOutCubic,
    this.curveEmphasized = Easing.emphasizedDecelerate,
    this.curveExit = Curves.easeInCubic,
  });

  /// 页面级元素入场间隔。
  final Duration pageEntranceDelay;

  /// 列表 stagger 间隔。
  final Duration listStaggerDelay;

  /// 卡片 hover 缩放比例。
  final double cardHoverScale;

  /// 按钮按压缩放比例。
  final double buttonPressedScale;

  /// 是否启用粒子效果。
  final bool enableParticles;

  /// 短时长（200ms）：按压反馈、小元素切换、聚焦/悬停态。
  final Duration durationShort;

  /// 中等时长（250ms）：卡片/列表项、展开收起、弹窗入场。
  final Duration durationMedium;

  /// 长时长（300ms）：页面切换、侧边栏、大位移。
  final Duration durationLong;

  /// 标准减速曲线（入场通用）。
  final Curve curveStandard;

  /// 强调减速曲线（大位移 / 页面级）。
  final Curve curveEmphasized;

  /// 加速离场曲线（退场 / 反向）。
  final Curve curveExit;

  static MotionTokens forFlavor(ThemeFlavor flavor) {
    return switch (flavor) {
      ThemeFlavor.standard => const MotionTokens(
          pageEntranceDelay: Duration(milliseconds: 80),
          listStaggerDelay: Duration(milliseconds: 60),
          cardHoverScale: 1.02,
          buttonPressedScale: 0.95,
          enableParticles: true,
        ),
      ThemeFlavor.minimal => const MotionTokens(
          pageEntranceDelay: Duration.zero,
          listStaggerDelay: Duration.zero,
          cardHoverScale: 1.0,
          buttonPressedScale: 1.0,
          enableParticles: false,
        ),
      ThemeFlavor.minecraft => const MotionTokens(
          pageEntranceDelay: Duration(milliseconds: 50),
          listStaggerDelay: Duration(milliseconds: 40),
          cardHoverScale: 1.0,
          buttonPressedScale: 0.9,
          enableParticles: true,
        ),
    };
  }

  static const MotionTokens standard = MotionTokens(
    pageEntranceDelay: Duration(milliseconds: 80),
    listStaggerDelay: Duration(milliseconds: 60),
    cardHoverScale: 1.02,
    buttonPressedScale: 0.95,
    enableParticles: true,
  );

  @override
  MotionTokens copyWith({
    Duration? pageEntranceDelay,
    Duration? listStaggerDelay,
    double? cardHoverScale,
    double? buttonPressedScale,
    bool? enableParticles,
    Duration? durationShort,
    Duration? durationMedium,
    Duration? durationLong,
    Curve? curveStandard,
    Curve? curveEmphasized,
    Curve? curveExit,
  }) {
    return MotionTokens(
      pageEntranceDelay: pageEntranceDelay ?? this.pageEntranceDelay,
      listStaggerDelay: listStaggerDelay ?? this.listStaggerDelay,
      cardHoverScale: cardHoverScale ?? this.cardHoverScale,
      buttonPressedScale: buttonPressedScale ?? this.buttonPressedScale,
      enableParticles: enableParticles ?? this.enableParticles,
      durationShort: durationShort ?? this.durationShort,
      durationMedium: durationMedium ?? this.durationMedium,
      durationLong: durationLong ?? this.durationLong,
      curveStandard: curveStandard ?? this.curveStandard,
      curveEmphasized: curveEmphasized ?? this.curveEmphasized,
      curveExit: curveExit ?? this.curveExit,
    );
  }

  @override
  MotionTokens lerp(MotionTokens? other, double t) {
    if (other == null) return this;
    return MotionTokens(
      pageEntranceDelay: t < 0.5 ? pageEntranceDelay : other.pageEntranceDelay,
      listStaggerDelay: t < 0.5 ? listStaggerDelay : other.listStaggerDelay,
      cardHoverScale: lerpDouble(cardHoverScale, other.cardHoverScale, t)!,
      buttonPressedScale:
          lerpDouble(buttonPressedScale, other.buttonPressedScale, t)!,
      enableParticles: t < 0.5 ? enableParticles : other.enableParticles,
      durationShort: t < 0.5 ? durationShort : other.durationShort,
      durationMedium: t < 0.5 ? durationMedium : other.durationMedium,
      durationLong: t < 0.5 ? durationLong : other.durationLong,
      curveStandard: t < 0.5 ? curveStandard : other.curveStandard,
      curveEmphasized: t < 0.5 ? curveEmphasized : other.curveEmphasized,
      curveExit: t < 0.5 ? curveExit : other.curveExit,
    );
  }
}

/// 便捷扩展：从 [BuildContext] 获取 [MotionTokens]。
extension MotionTokensX on BuildContext {
  MotionTokens get motionTokens =>
      Theme.of(this).extension<MotionTokens>() ?? MotionTokens.standard;
}
