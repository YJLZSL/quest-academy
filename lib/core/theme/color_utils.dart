import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 颜色和谐与调整工具函数。
///
/// 所有主题语义色均基于用户可配置的 [seedColor] 动态派生，
/// 避免硬编码，实现"完全自由选色"。

/// 将 [Color] 转换为 HSL 三元组。
///
/// 返回的列表为 [hue, saturation, lightness]，其中 hue 范围 0-360，
/// saturation 与 lightness 范围 0-1。
List<double> _toHsl(Color color) {
  final r = color.r;
  final g = color.g;
  final b = color.b;

  final maxChannel = math.max(r, math.max(g, b));
  final minChannel = math.min(r, math.min(g, b));
  final delta = maxChannel - minChannel;

  double hue;
  if (delta == 0) {
    hue = 0;
  } else if (maxChannel == r) {
    hue = ((g - b) / delta) % 6;
  } else if (maxChannel == g) {
    hue = ((b - r) / delta) + 2;
  } else {
    hue = ((r - g) / delta) + 4;
  }
  hue *= 60;
  if (hue < 0) hue += 360;

  final lightness = (maxChannel + minChannel) / 2;
  final saturation =
      delta == 0 ? 0.0 : delta / (1 - (2 * lightness - 1).abs());

  return [hue, saturation, lightness];
}

/// 将 HSL 三元组转换回 [Color]。
Color _fromHsl(List<double> hsl) {
  final h = hsl[0];
  final s = hsl[1].clamp(0.0, 1.0);
  final l = hsl[2].clamp(0.0, 1.0);

  final c = (1 - (2 * l - 1).abs()) * s;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = l - c / 2;

  double r;
  double g;
  double b;

  if (h < 60) {
    r = c;
    g = x;
    b = 0;
  } else if (h < 120) {
    r = x;
    g = c;
    b = 0;
  } else if (h < 180) {
    r = 0;
    g = c;
    b = x;
  } else if (h < 240) {
    r = 0;
    g = x;
    b = c;
  } else if (h < 300) {
    r = x;
    g = 0;
    b = c;
  } else {
    r = c;
    g = 0;
    b = x;
  }

  return Color.fromRGBO(
    ((r + m) * 255).round(),
    ((g + m) * 255).round(),
    ((b + m) * 255).round(),
    1,
  );
}

/// 调整 [color] 的亮度为 [lightness]（0-1），保持色相与饱和度。
Color withLightness(Color color, double lightness) {
  final hsl = _toHsl(color);
  return _fromHsl([hsl[0], hsl[1], lightness]);
}

/// 调整 [color] 的饱和度，[amount] 为乘法系数。
///
/// 例如 `withSaturation(color, 0.7)` 将饱和度降至 70%。
Color withSaturation(Color color, double amount) {
  final hsl = _toHsl(color);
  return _fromHsl([hsl[0], hsl[1] * amount, hsl[2]]);
}

/// 对 [color] 去色 [amount] 比例（0-1）。
///
/// amount=0 时不变，amount=1 时完全灰度。
Color desaturate(Color color, double amount) {
  final hsl = _toHsl(color);
  return _fromHsl([hsl[0], hsl[1] * (1 - amount), hsl[2]]);
}

/// 生成 [color] 的互补色（色相 +180°）。
Color harmonyComplementary(Color color) {
  final hsl = _toHsl(color);
  return _fromHsl([(hsl[0] + 180) % 360, hsl[1], hsl[2]]);
}

/// 生成 [color] 的分裂互补色之一。
///
/// [left] 为 true 时返回色相 -150° 的冷色分裂，
/// 为 false 时返回色相 +150° 的暖色分裂。
Color harmonySplitComplementary(Color color, {bool left = true}) {
  final hsl = _toHsl(color);
  final shift = left ? -150.0 : 150.0;
  return _fromHsl([(hsl[0] + shift) % 360, hsl[1], hsl[2]]);
}

/// 生成 [color] 的邻近色（色相 ±30°）。
///
/// [left] 控制偏移方向。
Color harmonyAnalogous(Color color, {bool left = true}) {
  final hsl = _toHsl(color);
  final shift = left ? -30.0 : 30.0;
  return _fromHsl([(hsl[0] + shift) % 360, hsl[1], hsl[2]]);
}

/// 计算两种颜色之间的对比度。
///
/// 遵循 WCAG 2.1 相对亮度公式，返回对比度比值。
/// 4.5:1 为普通文本 AA 标准，7:1 为 AAA 标准。
double contrastRatio(Color a, Color b) {
  double luminance(Color c) {
    final channels = [c.r, c.g, c.b];
    final transformed = channels.map((v) {
      if (v <= 0.03928) return v / 12.92;
      return math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }).toList();
    return 0.2126 * transformed[0] +
        0.7152 * transformed[1] +
        0.0722 * transformed[2];
  }

  final lumA = luminance(a);
  final lumB = luminance(b);
  final lighter = math.max(lumA, lumB);
  final darker = math.min(lumA, lumB);
  return (lighter + 0.05) / (darker + 0.05);
}

/// 确保 [color] 在 [background] 上达到至少 [targetRatio] 的对比度。
///
/// 通过微调亮度实现，优先保持色相与饱和度。
Color ensureContrast(Color color, Color background, {double targetRatio = 4.5}) {
  var adjusted = color;
  var hsl = _toHsl(adjusted);

  for (var i = 0; i < 20; i++) {
    if (contrastRatio(adjusted, background) >= targetRatio) break;
    final bgLum = _toHsl(background)[2];
    // 在深色背景上提亮，在浅色背景上压暗
    hsl[2] = bgLum < 0.5
        ? (hsl[2] + 0.05).clamp(0.0, 0.95)
        : (hsl[2] - 0.05).clamp(0.05, 1.0);
    adjusted = _fromHsl(hsl);
    hsl = _toHsl(adjusted);
  }

  return adjusted;
}
