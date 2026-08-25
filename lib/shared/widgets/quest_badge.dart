import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/animation_utils.dart';
import '../../core/motion/spring_motion.dart';
import '../../core/theme/quest_colors.dart';
import '../../core/theme/shape_tokens.dart';
import '../../core/theme/theme_flavor_provider.dart';

/// 徽章形状
enum QuestBadgeShape {
  /// 圆形
  circle,

  /// 圆角矩形
  rounded,

  /// 八角形（切角矩形）
  octagon,
}

/// 灵犀学院成就徽章组件
///
/// 升级要点（ThemeFlavor Token 体系）：
/// - 圆角/形状统一取自 [ShapeTokens.avatarRadius]（圆角矩形形态）或
///   使用对应语义形状（圆形、八角形），禁止硬编码半径。
/// - 已解锁 / 新解锁的入场、呼吸、光环动画均通过
///   [AnimationUtils.reduceMotionOf] / [MediaQuery.disableAnimations] 判断，
///   在减少动画模式下降级为静态终态。
/// - 未解锁进度弧颜色统一使用 [QuestColors.achievementGold]，
///   不再依赖任何硬编码金色值。
class QuestBadge extends ConsumerStatefulWidget {
  const QuestBadge({
    super.key,
    required this.icon,
    required this.label,
    this.unlocked = false,
    this.shape = QuestBadgeShape.circle,
    this.size = 64,
    this.newlyUnlocked = false,
    this.progress,
    this.onTap,
  });

  /// 徽章图标（解锁时展示）
  final Widget icon;

  /// 徽章下方文字
  final Widget label;

  /// 是否已解锁
  final bool unlocked;

  /// 徽章形状
  final QuestBadgeShape shape;

  /// 徽章尺寸（直径 / 边长）
  final double size;

  /// 是否为新解锁徽章。
  ///
  /// 为 true 时播放弹性入场动画（scale 0→1.2→1.0，800ms，[Curves.easeOutBack]）
  /// 并在徽章背后显示金色 SparkleRing 光环扩散。
  final bool newlyUnlocked;

  /// 解锁进度（0.0~1.0），仅对未解锁徽章生效。
  ///
  /// - 为 null 或 0.0 时不显示进度弧；
  /// - 为 1.0 时弧完整形成一个整圆；
  /// - 值变化时以弹簧动画平滑过渡。
  final double? progress;

  /// 点击回调；为 null 时不响应点击（不显示水波纹）。
  final VoidCallback? onTap;

  @override
  ConsumerState<QuestBadge> createState() => _QuestBadgeState();
}

class _QuestBadgeState extends ConsumerState<QuestBadge>
    with TickerProviderStateMixin {
  // ── 入场动画（新解锁弹性弹跳） ──────────────────────────
  late final AnimationController _entranceController;
  late final Animation<double> _entranceScale;

  // ── 进度弧动画（弹簧驱动） ──────────────────────────────
  late final AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0.0;

  bool get _reduceMotion =>
      SchedulerBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;

  @override
  void initState() {
    super.initState();

    // 入场动画：scale 0 → 1.2 → 1.0，800ms
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entranceScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
    ]).animate(_entranceController);

    // 减少动画模式下直接置为终态，跳过入场动画。
    if (widget.newlyUnlocked && !_reduceMotion) {
      _entranceController.forward();
    } else {
      _entranceController.value = 1.0;
    }

    // 进度弧：初始值即当前进度，后续变化以弹簧驱动
    final initialProgress = AnimationUtils.clamp01(widget.progress ?? 0.0);
    _previousProgress = initialProgress;
    _progressController = AnimationController.unbounded(
      vsync: this,
    );
    _progressAnimation = AlwaysStoppedAnimation<double>(initialProgress);
  }

  @override
  void didUpdateWidget(covariant QuestBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 进度变化 → 弹簧动画
    final newProgress = AnimationUtils.clamp01(widget.progress ?? 0.0);
    if ((newProgress - _previousProgress).abs() > 1e-6) {
      _animateProgressTo(newProgress);
    }

    // newlyUnlocked 从 false 切到 true → 重新播放入场（仅在非减少动画模式下）
    if (!oldWidget.newlyUnlocked && widget.newlyUnlocked && !_reduceMotion) {
      _entranceController.forward(from: 0.0);
    }
  }

  void _animateProgressTo(double target) {
    _previousProgress = target;
    _progressAnimation = _progressController.drive(
      Tween<double>(begin: _progressAnimation.value, end: target),
    );
    _progressController.value = 0.0;
    final simulation = SpringSimulation(
      SpringMotion.gentleSpeed,
      0.0,
      1.0,
      0.0,
    );
    _progressController.animateWith(simulation);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  /// 根据形状返回对应的 [ShapeBorder]（用于 [Material.shape] 与
  /// [InkWell.customBorder]，保证水波纹贴合形状）。
  ///
  /// 圆角矩形形态使用 [ShapeTokens.avatarRadius]，确保与主题 Token 体系一致。
  ShapeBorder _shapeBorderFor(QuestBadgeShape shape) {
    switch (shape) {
      case QuestBadgeShape.circle:
        return const CircleBorder();
      case QuestBadgeShape.rounded:
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.shapeTokens.avatarRadius),
        );
      case QuestBadgeShape.octagon:
        return const _OctagonBorder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.questColors;
    final flavor = ref.watch(themeFlavorProvider);
    final accent = flavor == ThemeFlavor.minecraft
        ? colors.minecraftGrass
        : colors.achievementGold;
    final iconColor =
        widget.unlocked ? accent : theme.colorScheme.onSurfaceVariant;
    final bgColor = widget.unlocked
        ? accent.withValues(alpha: 0.16)
        : theme.colorScheme.surfaceContainerHigh;

    final labelStyle = (theme.textTheme.labelSmall ?? const TextStyle())
        .copyWith(
          color: widget.unlocked
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
        );

    final badgeSize = widget.size;
    // 光环 / 进度弧 预留的外圈边距
    const ringPadding = 8.0;
    final ringSize = badgeSize + ringPadding * 2;

    final showProgress = !widget.unlocked &&
        widget.progress != null &&
        widget.progress! > 0.0;

    // ── 徽章图标 / 锁 ─────────────────────────────────────
    final iconSize = widget.unlocked ? badgeSize * 0.5 : badgeSize * 0.4;
    final badgeContent = IconTheme(
      data: IconThemeData(color: iconColor, size: iconSize),
      child: widget.unlocked
          ? widget.icon
          : const Icon(Icons.lock_outline),
    );

    final shapeBorder = _shapeBorderFor(widget.shape);

    // ── 徽章主体 ──────────────────────────────────────────
    Widget badge = Material(
      color: bgColor,
      shape: shapeBorder,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        customBorder: shapeBorder,
        child: SizedBox(
          width: badgeSize,
          height: badgeSize,
          child: Center(child: badgeContent),
        ),
      ),
    );

    // ── 新解锁：弹性入场 + 光环扩散 ───────────────────────
    if (widget.newlyUnlocked && !_reduceMotion) {
      badge = AnimatedBuilder(
        animation: _entranceController,
        builder: (context, child) {
          return Transform.scale(
            scale: _entranceScale.value,
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            SpringMotion.sparkleRing(
              color: colors.achievementGold,
              size: ringSize,
            ),
            badge,
          ],
        ),
      );
    }

    // ── 已解锁（非新解锁）：金色呼吸光效 ─────────────────
    if (widget.unlocked && !widget.newlyUnlocked && !_reduceMotion) {
      badge = SpringMotion.pulseBreathing(
        minScale: 0.98,
        maxScale: 1.02,
        child: badge,
      );
    }

    // ── 未解锁进度弧 ─────────────────────────────────────
    if (showProgress) {
      badge = AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: Size(ringSize, ringSize),
            painter: _ProgressArcPainter(
              progress: _progressAnimation.value,
              color: colors.achievementGold,
              strokeWidth: 4.0,
            ),
            child: child,
          );
        },
        child: SizedBox(
          width: ringSize,
          height: ringSize,
          child: Center(child: badge),
        ),
      );
    }

    // ── 标签 + 整体布局 ──────────────────────────────────
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(height: 8),
        DefaultTextStyle(
          style: labelStyle,
          textAlign: TextAlign.center,
          child: widget.label,
        ),
      ],
    );
  }
}

/// 八角形边框（切角矩形）。
class _OctagonBorder extends ShapeBorder {
  const _OctagonBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final cut = rect.shortestSide * 0.15;
    return Path()
      ..moveTo(rect.left + cut, rect.top)
      ..lineTo(rect.right - cut, rect.top)
      ..lineTo(rect.right, rect.top + cut)
      ..lineTo(rect.right, rect.bottom - cut)
      ..lineTo(rect.right - cut, rect.bottom)
      ..lineTo(rect.left + cut, rect.bottom)
      ..lineTo(rect.left, rect.bottom - cut)
      ..lineTo(rect.left, rect.top + cut)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => const _OctagonBorder();
}

/// 未解锁进度弧绘制器。
///
/// 颜色由外部注入，确保使用 [QuestColors.achievementGold] 而非硬编码值。
class _ProgressArcPainter extends CustomPainter {
  _ProgressArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
