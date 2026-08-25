import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 形状变体枚举。
///
/// 参考 Material 3 Expressive 的 35 种形状，由 5 种形状模式
/// （矩形 rectangle、圆角矩形 rounded、胶囊 capsule、圆形 circle、八角形 octagon）
/// 与 7 种圆角程度（none/extraSmall/small/medium/large/extraLarge/full）组合而成，
/// 共 5 × 7 = 35 种变体。
///
/// [toShapeBorder] 统一返回 [RoundedRectangleBorder]、[CircleBorder]、
/// [StadiumBorder] 或 [OctagonBorder]。
enum ShapeVariants {
  // 矩形系列
  rectangleNone,
  rectangleExtraSmall,
  rectangleSmall,
  rectangleMedium,
  rectangleLarge,
  rectangleExtraLarge,
  rectangleFull,
  // 圆角矩形系列
  roundedNone,
  roundedExtraSmall,
  roundedSmall,
  roundedMedium,
  roundedLarge,
  roundedExtraLarge,
  roundedFull,
  // 胶囊系列
  capsuleNone,
  capsuleExtraSmall,
  capsuleSmall,
  capsuleMedium,
  capsuleLarge,
  capsuleExtraLarge,
  capsuleFull,
  // 圆形系列
  circleNone,
  circleExtraSmall,
  circleSmall,
  circleMedium,
  circleLarge,
  circleExtraLarge,
  circleFull,
  // 八角形系列
  octagonNone,
  octagonExtraSmall,
  octagonSmall,
  octagonMedium,
  octagonLarge,
  octagonExtraLarge,
  octagonFull;

  /// 圆角程度对应的半径数值
  double get _radiusValue {
    switch (this) {
      case ShapeVariants.rectangleNone:
      case ShapeVariants.roundedNone:
      case ShapeVariants.capsuleNone:
      case ShapeVariants.circleNone:
      case ShapeVariants.octagonNone:
        return 0;
      case ShapeVariants.rectangleExtraSmall:
      case ShapeVariants.roundedExtraSmall:
      case ShapeVariants.capsuleExtraSmall:
      case ShapeVariants.circleExtraSmall:
      case ShapeVariants.octagonExtraSmall:
        return 4;
      case ShapeVariants.rectangleSmall:
      case ShapeVariants.roundedSmall:
      case ShapeVariants.capsuleSmall:
      case ShapeVariants.circleSmall:
      case ShapeVariants.octagonSmall:
        return 8;
      case ShapeVariants.rectangleMedium:
      case ShapeVariants.roundedMedium:
      case ShapeVariants.capsuleMedium:
      case ShapeVariants.circleMedium:
      case ShapeVariants.octagonMedium:
        return 12;
      case ShapeVariants.rectangleLarge:
      case ShapeVariants.roundedLarge:
      case ShapeVariants.capsuleLarge:
      case ShapeVariants.circleLarge:
      case ShapeVariants.octagonLarge:
        return 16;
      case ShapeVariants.rectangleExtraLarge:
      case ShapeVariants.roundedExtraLarge:
      case ShapeVariants.capsuleExtraLarge:
      case ShapeVariants.circleExtraLarge:
      case ShapeVariants.octagonExtraLarge:
        return 28;
      case ShapeVariants.rectangleFull:
      case ShapeVariants.roundedFull:
      case ShapeVariants.capsuleFull:
      case ShapeVariants.circleFull:
      case ShapeVariants.octagonFull:
        return 9999;
    }
  }

  /// 是否属于圆形系列
  bool get _isCircle => name.startsWith('circle');

  /// 是否属于胶囊系列
  bool get _isCapsule => name.startsWith('capsule');

  /// 是否属于八角形系列
  bool get _isOctagon => name.startsWith('octagon');

  /// 返回对应的 [BorderRadius]（圆形/胶囊/八角形系列退化为 0）
  BorderRadius get borderRadius => BorderRadius.circular(_radiusValue);

  /// 返回对应的 [OutlinedBorder]
  ///
  /// 圆形系列返回 [CircleBorder]，胶囊系列返回 [StadiumBorder]，
  /// 八角形系列返回 [OctagonBorder]，其余返回带对应圆角的 [RoundedRectangleBorder]。
  OutlinedBorder toShapeBorder() {
    if (_isCircle) {
      return const CircleBorder();
    }
    if (_isCapsule) {
      return const StadiumBorder();
    }
    if (_isOctagon) {
      return OctagonBorder(cornerRadius: _radiusValue.toDouble());
    }
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radiusValue),
    );
  }
}

/// 八角形边框。
///
/// 将矩形的四个角切去，形成八边形轮廓，切角半径由 [cornerRadius] 控制。
class OctagonBorder extends OutlinedBorder {
  const OctagonBorder({
    super.side,
    this.cornerRadius = 8.0,
  });

  /// 切角半径。
  final double cornerRadius;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return _buildPath(rect.deflate(side.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _buildPath(rect);
  }

  Path _buildPath(Rect rect) {
    final maxByte = math.min(rect.width / 4, rect.height / 4);
    final r = cornerRadius.clamp(0.0, maxByte);
    final path = Path();

    path.moveTo(rect.left + r, rect.top);
    path.lineTo(rect.right - r, rect.top);
    path.lineTo(rect.right, rect.top + r);
    path.lineTo(rect.right, rect.bottom - r);
    path.lineTo(rect.right - r, rect.bottom);
    path.lineTo(rect.left + r, rect.bottom);
    path.lineTo(rect.left, rect.bottom - r);
    path.lineTo(rect.left, rect.top + r);
    path.close();

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (rect.isEmpty) return;
    final path = getOuterPath(rect, textDirection: textDirection);
    final paint = side.toPaint();
    canvas.drawPath(path, paint);
  }

  @override
  OctagonBorder copyWith({BorderSide? side, double? cornerRadius}) {
    return OctagonBorder(
      side: side ?? this.side,
      cornerRadius: cornerRadius ?? this.cornerRadius,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is OctagonBorder) {
      return OctagonBorder(
        side: BorderSide.lerp(a.side, side, t),
        cornerRadius: lerpDouble(a.cornerRadius, cornerRadius, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is OctagonBorder) {
      return OctagonBorder(
        side: BorderSide.lerp(side, b.side, t),
        cornerRadius: lerpDouble(cornerRadius, b.cornerRadius, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  OutlinedBorder scale(double t) {
    return OctagonBorder(
      side: side.scale(t),
      cornerRadius: cornerRadius * t,
    );
  }
}
