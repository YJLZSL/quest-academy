import 'package:flutter/material.dart';

import 'theme_flavor_provider.dart';

/// 动效 Token 扩展。
class MotionTokens extends ThemeExtension<MotionTokens> {
  const MotionTokens({
    required this.pageEntranceDelay,
    required this.listStaggerDelay,
    required this.cardHoverScale,
    required this.buttonPressedScale,
    required this.enableParticles,
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
  }) {
    return MotionTokens(
      pageEntranceDelay: pageEntranceDelay ?? this.pageEntranceDelay,
      listStaggerDelay: listStaggerDelay ?? this.listStaggerDelay,
      cardHoverScale: cardHoverScale ?? this.cardHoverScale,
      buttonPressedScale: buttonPressedScale ?? this.buttonPressedScale,
      enableParticles: enableParticles ?? this.enableParticles,
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
    );
  }
}

/// 便捷扩展：从 [BuildContext] 获取 [MotionTokens]。
extension MotionTokensX on BuildContext {
  MotionTokens get motionTokens =>
      Theme.of(this).extension<MotionTokens>() ?? MotionTokens.standard;
}
