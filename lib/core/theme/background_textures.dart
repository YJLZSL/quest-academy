import 'package:flutter/material.dart';

import 'theme_flavor_provider.dart';

/// 背景纹理扩展。
///
/// 通过 [ThemeExtension] 注册到主题中，提供网点、网格、Minecraft dirt 等
/// 程序生成的背景图案，避免引入大图片资源。
class BackgroundTextures extends ThemeExtension<BackgroundTextures> {
  const BackgroundTextures({
    required this.dotPattern,
    required this.gridPattern,
    required this.minecraftDirt,
    required this.minecraftGrass,
  });

  /// 极淡网点图案（亮色模式下使用）。
  final CustomPainter dotPattern;

  /// 淡网格图案（暗色模式 / 极简模式下使用）。
  final CustomPainter gridPattern;

  /// Minecraft 彩蛋 dirt 纹理。
  final CustomPainter minecraftDirt;

  /// Minecraft 彩蛋 grass 顶部纹理。
  final CustomPainter minecraftGrass;

  /// 根据主题风味返回纹理集合。
  static BackgroundTextures forFlavor(ThemeFlavor flavor, Brightness brightness) {
    return BackgroundTextures(
      dotPattern: const _DotPatternPainter(),
      gridPattern: const _GridPatternPainter(),
      minecraftDirt: const _MinecraftDirtPainter(),
      minecraftGrass: const _MinecraftGrassPainter(),
    );
  }

  @override
  BackgroundTextures copyWith({
    CustomPainter? dotPattern,
    CustomPainter? gridPattern,
    CustomPainter? minecraftDirt,
    CustomPainter? minecraftGrass,
  }) {
    return BackgroundTextures(
      dotPattern: dotPattern ?? this.dotPattern,
      gridPattern: gridPattern ?? this.gridPattern,
      minecraftDirt: minecraftDirt ?? this.minecraftDirt,
      minecraftGrass: minecraftGrass ?? this.minecraftGrass,
    );
  }

  @override
  BackgroundTextures lerp(BackgroundTextures? other, double t) {
    if (other == null) return this;
    // CustomPainter 为离散对象，不支持插值。
    return t < 0.5 ? this : other;
  }
}

/// 便捷扩展：从 [BuildContext] 获取 [BackgroundTextures]。
extension BackgroundTexturesX on BuildContext {
  /// 获取当前主题中注册的背景纹理。
  BackgroundTextures get backgroundTextures =>
      Theme.of(this).extension<BackgroundTextures>() ??
      BackgroundTextures.forFlavor(ThemeFlavor.standard, Brightness.light);
}

/// 网点图案绘制器。
class _DotPatternPainter extends CustomPainter {
  const _DotPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 24.0;
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    for (var y = 0.0; y < size.height; y += spacing) {
      for (var x = 0.0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 网格图案绘制器。
class _GridPatternPainter extends CustomPainter {
  const _GridPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 32.0;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Minecraft dirt 纹理绘制器（16x16 像素块重复）。
class _MinecraftDirtPainter extends CustomPainter {
  const _MinecraftDirtPainter();

  static const _base = Color(0xFF8B5A2B);
  static const _dark = Color(0xFF6B4220);
  static const _light = Color(0xFFA06B35);

  @override
  void paint(Canvas canvas, Size size) {
    const blockSize = 16.0;
    final random = _PseudoRandom(42);

    for (var y = 0.0; y < size.height; y += blockSize) {
      for (var x = 0.0; x < size.width; x += blockSize) {
        final value = random.nextDouble();
        final color = value < 0.33
            ? _dark
            : value < 0.66
                ? _base
                : _light;
        final paint = Paint()..color = color;
        canvas.drawRect(Rect.fromLTWH(x, y, blockSize, blockSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Minecraft grass 顶部纹理绘制器。
class _MinecraftGrassPainter extends CustomPainter {
  const _MinecraftGrassPainter();

  static const _dirt = Color(0xFF8B5A2B);
  static const _grass = Color(0xFF5D8C22);
  static const _grassDark = Color(0xFF4A701B);

  @override
  void paint(Canvas canvas, Size size) {
    const blockSize = 16.0;
    final random = _PseudoRandom(123);

    for (var y = 0.0; y < size.height; y += blockSize) {
      for (var x = 0.0; x < size.width; x += blockSize) {
        final isGrass = y < blockSize * 2;
        final value = random.nextDouble();
        Color color;
        if (isGrass) {
          color = value < 0.5 ? _grass : _grassDark;
        } else {
          color = value < 0.33
              ? _dirt
              : value < 0.66
                  ? const Color(0xFF6B4220)
                  : const Color(0xFFA06B35);
        }
        final paint = Paint()..color = color;
        canvas.drawRect(Rect.fromLTWH(x, y, blockSize, blockSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 确定性伪随机数生成器，保证图案在不同帧之间一致。
class _PseudoRandom {
  _PseudoRandom(this._seed);

  int _seed;

  double nextDouble() {
    _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
    return _seed / 0x7FFFFFFF;
  }
}
