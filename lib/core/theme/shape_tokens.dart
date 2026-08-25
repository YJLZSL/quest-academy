import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'theme_flavor_provider.dart';

/// 形状半径 Token 扩展。
class ShapeTokens extends ThemeExtension<ShapeTokens> {
  const ShapeTokens({
    required this.cardRadius,
    required this.buttonRadius,
    required this.dialogRadius,
    required this.chipRadius,
    required this.inputRadius,
    required this.avatarRadius,
  });

  final double cardRadius;
  final double buttonRadius;
  final double dialogRadius;
  final double chipRadius;
  final double inputRadius;
  final double avatarRadius;

  static ShapeTokens forFlavor(ThemeFlavor flavor) {
    final isMinimal = flavor == ThemeFlavor.minimal;
    final isMinecraft = flavor == ThemeFlavor.minecraft;

    if (isMinecraft) {
      return const ShapeTokens(
        cardRadius: 4,
        buttonRadius: 0,
        dialogRadius: 4,
        chipRadius: 0,
        inputRadius: 0,
        avatarRadius: 4,
      );
    }

    if (isMinimal) {
      return const ShapeTokens(
        cardRadius: 12,
        buttonRadius: 8,
        dialogRadius: 12,
        chipRadius: 4,
        inputRadius: 4,
        avatarRadius: 9999,
      );
    }

    return const ShapeTokens(
      cardRadius: 24,
      buttonRadius: 16,
      dialogRadius: 28,
      chipRadius: 12,
      inputRadius: 16,
      avatarRadius: 9999,
    );
  }

  static const ShapeTokens standard = ShapeTokens(
    cardRadius: 24,
    buttonRadius: 16,
    dialogRadius: 28,
    chipRadius: 12,
    inputRadius: 16,
    avatarRadius: 9999,
  );

  @override
  ShapeTokens copyWith({
    double? cardRadius,
    double? buttonRadius,
    double? dialogRadius,
    double? chipRadius,
    double? inputRadius,
    double? avatarRadius,
  }) {
    return ShapeTokens(
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      dialogRadius: dialogRadius ?? this.dialogRadius,
      chipRadius: chipRadius ?? this.chipRadius,
      inputRadius: inputRadius ?? this.inputRadius,
      avatarRadius: avatarRadius ?? this.avatarRadius,
    );
  }

  @override
  ShapeTokens lerp(ShapeTokens? other, double t) {
    if (other == null) return this;
    return ShapeTokens(
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      buttonRadius: lerpDouble(buttonRadius, other.buttonRadius, t)!,
      dialogRadius: lerpDouble(dialogRadius, other.dialogRadius, t)!,
      chipRadius: lerpDouble(chipRadius, other.chipRadius, t)!,
      inputRadius: lerpDouble(inputRadius, other.inputRadius, t)!,
      avatarRadius: lerpDouble(avatarRadius, other.avatarRadius, t)!,
    );
  }
}

/// 便捷扩展：从 [BuildContext] 获取 [ShapeTokens]。
extension ShapeTokensX on BuildContext {
  ShapeTokens get shapeTokens =>
      Theme.of(this).extension<ShapeTokens>() ?? ShapeTokens.standard;
}
