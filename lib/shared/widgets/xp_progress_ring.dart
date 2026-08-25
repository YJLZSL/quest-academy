// ignore_for_file: lines_longer_than_80_lines

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/animation_utils.dart';
import '../../core/motion/spring_motion.dart';
import '../../core/theme/quest_colors.dart';
import '../../core/theme/quest_gradients.dart';
import '../../core/theme/theme_flavor_provider.dart';

/// XP 进度环：展示当前等级与距离下一等级的 XP 进度。
///
/// - [standard]：平滑圆环 + 渐变描边（xpBlue → brandPrimary），带入场动画。
/// - [minecraft]：像素化方块分段环，已完成段使用 pixelGrass，轨道使用 pixelDirt。
/// - [minimal]：细描边、低动效、无脉冲。
class XpProgressRing extends ConsumerStatefulWidget {
  const XpProgressRing({
    super.key,
    required this.currentXp,
    required this.xpToNextLevel,
    required this.level,
    this.size = 96,
    this.strokeWidth,
    this.onTap,
  });

  /// 当前已积累的 XP。
  final int currentXp;

  /// 升到下一级所需的 XP。
  final int xpToNextLevel;

  /// 当前等级。
  final int level;

  /// 环的整体尺寸（宽高）。
  final double size;

  /// 描边宽度；null 时按主题风味自动选择。
  final double? strokeWidth;

  /// 点击回调（通常为跳转到统计页）。
  final VoidCallback? onTap;

  @override
  ConsumerState<XpProgressRing> createState() => _XpProgressRingState();
}

class _XpProgressRingState extends ConsumerState<XpProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _targetProgress = 0.0;

  double get _progress => widget.xpToNextLevel > 0
      ? (widget.currentXp / widget.xpToNextLevel).clamp(0.0, 1.0)
      : 0.0;

  @override
  void initState() {
    super.initState();
    final initial = _progress;
    _targetProgress = initial;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0.0, end: initial).animate(
      CurvedAnimation(parent: _controller, curve: SpringMotion.entranceCurve),
    );
    if (AnimationUtils.platformReduceMotion) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant XpProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newProgress = _progress;
    if (newProgress != _targetProgress) {
      _targetProgress = newProgress;
      final currentDisplay = _animation.value;
      _animation = Tween<double>(begin: currentDisplay, end: newProgress).animate(
        CurvedAnimation(parent: _controller, curve: SpringMotion.entranceCurve),
      );
      if (AnimationUtils.reduceMotionOf(context)) {
        _controller.value = 1.0;
      } else {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flavor = ref.watch(themeFlavorProvider);
    final colors = context.questColors;
    final gradients = context.questGradients;
    final reduceMotion = AnimationUtils.reduceMotionOf(context);
    final effectiveStrokeWidth = widget.strokeWidth ??
        (flavor == ThemeFlavor.minimal ? 4.0 : 8.0);
    final trackColor = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withValues(alpha: 0.5);

    Widget ring = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _XpRingPainter(
            progress: _animation.value,
            flavor: flavor,
            colors: colors,
            gradients: gradients,
            trackColor: trackColor,
            strokeWidth: effectiveStrokeWidth,
            reduceMotion: reduceMotion,
          ),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: child,
          ),
        );
      },
      child: _buildCenter(context, flavor),
    );

    if (widget.onTap != null) {
      ring = SpringMotion.scalePressFeedback(
        onTap: widget.onTap,
        pressedScale: flavor == ThemeFlavor.minecraft ? 0.9 : 0.92,
        child: ring,
      );
    }

    return ring;
  }

  Widget _buildCenter(BuildContext context, ThemeFlavor flavor) {
    final theme = Theme.of(context);
    final colors = context.questColors;
    final isMinecraft = flavor == ThemeFlavor.minecraft;
    final isMinimal = flavor == ThemeFlavor.minimal;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Lv.${widget.level}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isMinecraft ? colors.pixelGrass : colors.brandPrimary,
            fontSize: isMinecraft ? 14 : (isMinimal ? 16 : 18),
          ),
        ),
        Text(
          '${widget.currentXp}/${widget.xpToNextLevel}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: isMinecraft ? 10 : 12,
          ),
        ),
        Text(
          'XP',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
            fontSize: isMinecraft ? 8 : 10,
          ),
        ),
      ],
    );
  }
}

class _XpRingPainter extends CustomPainter {
  const _XpRingPainter({
    required this.progress,
    required this.flavor,
    required this.colors,
    required this.gradients,
    required this.trackColor,
    required this.strokeWidth,
    required this.reduceMotion,
  });

  final double progress;
  final ThemeFlavor flavor;
  final QuestColors colors;
  final QuestGradients gradients;
  final Color trackColor;
  final double strokeWidth;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    if (flavor == ThemeFlavor.minecraft) {
      _paintMinecraft(canvas, size);
    } else {
      _paintSmooth(canvas, size);
    }
  }

  void _paintSmooth(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final isMinimal = flavor == ThemeFlavor.minimal;

    // 轨道
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = isMinimal ? StrokeCap.butt : StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // 进度弧
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = isMinimal ? StrokeCap.butt : StrokeCap.round;

    if (isMinimal) {
      arcPaint.color = colors.xpBlue;
    } else {
      arcPaint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colors.xpBlue, colors.brandPrimary],
      ).createShader(rect);
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 2);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawArc(rect, 0, 2 * math.pi * progress, false, arcPaint);
    canvas.restore();

    // 脉冲光点（仅 standard）
    if (!isMinimal && !reduceMotion && progress > 0) {
      _drawPulseDot(canvas, center, radius, colors.brandPrimary);
    }
  }

  void _paintMinecraft(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    const segmentCount = 24;
    final segmentAngle = 2 * math.pi / segmentCount;
    final segmentLength = radius * segmentAngle * 0.7;
    final segmentWidth = segmentLength.clamp(4.0, strokeWidth);
    final filledSegments = (segmentCount * progress).round();

    for (var i = 0; i < segmentCount; i++) {
      final angle = -math.pi / 2 + i * segmentAngle;
      final isFilled = i < filledSegments;
      final cx = center.dx + radius * math.cos(angle);
      final cy = center.dy + radius * math.sin(angle);

      final paint = Paint()
        ..color = isFilled ? colors.pixelGrass : colors.pixelDirt
        ..style = PaintingStyle.fill;

      // 像素方块：无抗锯齿，直角
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: segmentWidth, height: segmentWidth),
        Radius.zero,
      );
      canvas.drawRRect(rect, paint);

      // 方块内高光像素点
      if (isFilled) {
        final highlightPaint = Paint()
          ..color = colors.pixelGrass.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;
        final highlightRect = Rect.fromCenter(
          center: Offset(cx - segmentWidth * 0.2, cy - segmentWidth * 0.2),
          width: segmentWidth * 0.3,
          height: segmentWidth * 0.3,
        );
        canvas.drawRect(highlightRect, highlightPaint);
      }
    }
  }

  void _drawPulseDot(Canvas canvas, Offset center, double radius, Color color) {
    final endAngle = -math.pi / 2 + 2 * math.pi * progress;
    final dotCenter = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth);
    canvas.drawCircle(dotCenter, strokeWidth * 1.2, glowPaint);
    canvas.drawCircle(dotCenter, strokeWidth * 0.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _XpRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.flavor != flavor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.reduceMotion != reduceMotion ||
        oldDelegate.trackColor != trackColor;
  }
}
