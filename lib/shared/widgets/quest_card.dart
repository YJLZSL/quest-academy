import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest_academy/core/motion/animation_utils.dart';
import 'package:quest_academy/core/motion/spring_motion.dart';
import 'package:quest_academy/core/theme/quest_elevations.dart';
import 'package:quest_academy/core/theme/motion_tokens.dart';
import 'package:quest_academy/core/theme/shape_tokens.dart';
import 'package:quest_academy/core/theme/theme_flavor_provider.dart';

/// 卡片变体
enum QuestCardVariant {
  /// 默认卡片（surfaceContainerLow 背景）
  defaultColor,

  /// 主色卡片（primaryContainer 背景）
  primary,

  /// 次要卡片（surfaceContainerHighest 背景）
  secondary,

  /// 毛玻璃卡片
  glass,
}

/// 灵犀学院卡片组件
///
/// 升级要点（ThemeFlavor Token 体系）：
/// - 圆角统一取自 [ShapeTokens.cardRadius]，禁止硬编码。
/// - hover / press 缩放统一读取 [MotionTokens.cardHoverScale]；
///   minimal 风味下 [cardHoverScale] 为 1.0，自动禁用 hover 与 press 缩放反馈。
/// - 阴影全部取自 [QuestElevations] 的语义档位；minimal 风味通过
///   [QuestElevations.fromSeed] 已将阴影透明度降至 30%，更淡更克制。
/// - minecraft 风味下使用 [QuestElevations.pixelBorder] 模拟像素厚边，
///   并配合直角外观（BorderRadius.zero）。
class QuestCard extends ConsumerStatefulWidget {
  const QuestCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.margin,
    this.variant = QuestCardVariant.defaultColor,
    this.animateEntrance = false,
    this.entranceDelay = Duration.zero,
    this.backgroundGradient,
    this.borderColor,
    this.elevation = 1,
  });

  /// 子内容
  final Widget child;

  /// 点击回调，为 null 时不可点击
  final VoidCallback? onTap;

  /// 内边距，默认 16
  final EdgeInsetsGeometry? padding;

  /// 自定义背景色
  final Color? color;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  /// 卡片变体
  final QuestCardVariant variant;

  /// 是否启用入场动画（淡入 + 上移 + 缩放）
  final bool animateEntrance;

  /// 入场动画延迟（用于 staggered 效果）
  final Duration entranceDelay;

  /// 背景渐变（设置后覆盖 color/variant 的背景色）
  final Gradient? backgroundGradient;

  /// 边框颜色
  final Color? borderColor;

  /// 卡片阴影档位
  ///
  /// 映射到 [QuestElevations] 的 3 档语义阴影：
  /// - 0 → [QuestElevations.subtle]：平铺卡片
  /// - 1 → [QuestElevations.elevated]：悬浮卡片（默认）
  /// - 2 → [QuestElevations.highlighted]：强调卡片/对话框
  ///
  /// 可交互卡片在 hover 时会自动升级到 [QuestElevations.highlighted]，
  /// press 时降级到 [QuestElevations.subtle]，以提供视觉反馈。
  /// minimal 风味下整体阴影更淡；minecraft 风味下使用 [pixelBorder]。
  final int elevation;

  @override
  ConsumerState<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends ConsumerState<QuestCard> {
  bool _hovering = false;
  bool _pressed = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.animateEntrance && !AnimationUtils.platformReduceMotion) {
      if (widget.entranceDelay == Duration.zero) {
        _visible = true;
      } else {
        Future.delayed(widget.entranceDelay, () {
          if (mounted) setState(() => _visible = true);
        });
      }
    } else {
      _visible = true;
    }
  }

  Color _resolveColor(BuildContext context) {
    if (widget.color != null) return widget.color!;
    final colorScheme = Theme.of(context).colorScheme;
    return switch (widget.variant) {
      QuestCardVariant.defaultColor => colorScheme.surfaceContainerLow,
      QuestCardVariant.primary => colorScheme.primaryContainer,
      QuestCardVariant.secondary => colorScheme.surfaceContainerHighest,
      // 毛玻璃卡片使用主题 surface 色低透明，保持明暗主题自适配。
      QuestCardVariant.glass =>
          colorScheme.surface.withValues(alpha: 0.15),
    };
  }

  /// 解析当前应使用的阴影列表
  ///
  /// 基础阴影来自 [widget.elevation] 映射到 [QuestElevations] 的 3 档语义阴影
  /// （0→subtle, 1→elevated, 2→highlighted）。
  /// 当卡片可交互且未启用 reduceMotion 时：
  /// - hover 状态升级到 [QuestElevations.highlighted]
  /// - press 状态降级到 [QuestElevations.subtle]
  /// 以提供视觉反馈。
  ///
  /// [ThemeFlavor.minecraft] 下使用像素厚边 [QuestElevations.pixelBorder]
  /// 并配合直角外观。
  List<BoxShadow> _resolveShadows(
    BuildContext context,
    ThemeFlavor flavor,
    bool clickable,
    bool reduceMotion,
  ) {
    final elevations = context.questElevations;

    // Minecraft 彩蛋：使用体素风像素厚边阴影。
    if (flavor == ThemeFlavor.minecraft) {
      return elevations.pixelBorder;
    }

    // 基础阴影：根据 widget.elevation 选择档位；minimal 风味下已由
    // QuestElevations.fromSeed 降低透明度，因此这里无需额外判断。
    final List<BoxShadow> base = switch (widget.elevation) {
      0 => elevations.subtle,
      2 => elevations.highlighted,
      _ => elevations.elevated,
    };

    if (!clickable || reduceMotion) {
      return base;
    }

    // 交互态：hover → highlighted，press → subtle。
    if (_pressed) {
      return elevations.subtle;
    }
    if (_hovering) {
      return elevations.highlighted;
    }
    return base;
  }

  void _handleTap() {
    AnimationUtils.hapticLight();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AnimationUtils.reduceMotionOf(context);
    final shapeTokens = context.shapeTokens;
    final motionTokens = context.motionTokens;
    final flavor = ref.watch(themeFlavorProvider);
    final borderRadius = flavor == ThemeFlavor.minecraft
        ? BorderRadius.zero
        : BorderRadius.circular(shapeTokens.cardRadius);
    final cardColor = _resolveColor(context);
    final clickable = widget.onTap != null;

    // hover/press 缩放统一从 MotionTokens 读取；minimal 下 cardHoverScale == 1.0
    // 自动禁用缩放反馈，避免在专注模式下分散注意力。
    final cardHoverScale = motionTokens.cardHoverScale;
    final cardPressScale = 1.0 - (cardHoverScale - 1.0) * 0.5;
    double scale = 1.0;
    if (clickable && !reduceMotion && cardHoverScale != 1.0) {
      if (_pressed) {
        scale = cardPressScale;
      } else if (_hovering) {
        scale = cardHoverScale;
      }
    }

    // 解析当前阴影（基础档位 + 交互态切换）
    final shadows = _resolveShadows(context, flavor, clickable, reduceMotion);

    final content = Padding(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: widget.child,
    );

    // 构建核心卡片（Material + InkWell 水波纹）
    Widget card = _buildCardSurface(
      color: cardColor,
      borderRadius: borderRadius,
      clickable: clickable,
      content: content,
      shadows: shadows,
    );

    // 毛玻璃
    if (widget.variant == QuestCardVariant.glass) {
      card = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: card,
        ),
      );
    }

    // hover + press 动画（使用 Listener 避免与 InkWell 手势冲突）。
    // 仅在允许动效且风味提供非 1.0 的 hover 缩放时生效。
    if (clickable && !reduceMotion && cardHoverScale != 1.0) {
      card = MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() {
          _hovering = false;
          _pressed = false;
        }),
        cursor: SystemMouseCursors.click,
        child: Listener(
          onPointerDown: (_) => setState(() => _pressed = true),
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: scale,
            duration: SpringMotion.fastDuration,
            curve: SpringMotion.fastCurve,
            child: card,
          ),
        ),
      );
    }

    // 入场动画
    if (widget.animateEntrance && !reduceMotion) {
      card = AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: SpringMotion.gentleDuration,
        curve: SpringMotion.entranceCurve,
        child: AnimatedSlide(
          offset: _visible ? Offset.zero : const Offset(0, 0.05),
          duration: SpringMotion.gentleDuration,
          curve: SpringMotion.entranceCurve,
          child: AnimatedScale(
            scale: _visible ? 1.0 : 0.95,
            duration: SpringMotion.gentleDuration,
            curve: SpringMotion.entranceCurve,
            child: card,
          ),
        ),
      );
    }

    if (widget.margin != null) {
      card = Padding(padding: widget.margin!, child: card);
    }

    return card;
  }

  Widget _buildCardSurface({
    required Color color,
    required BorderRadius borderRadius,
    required bool clickable,
    required Widget content,
    required List<BoxShadow> shadows,
  }) {
    final hasBorder = widget.borderColor != null;
    final hasGradient = widget.backgroundGradient != null;

    return Material(
      color: hasGradient ? Colors.transparent : color,
      borderRadius: borderRadius,
      child: Ink(
        decoration: BoxDecoration(
          gradient: widget.backgroundGradient,
          borderRadius: borderRadius,
          border: hasBorder ? Border.all(color: widget.borderColor!) : null,
          boxShadow: shadows,
        ),
        child: clickable
            ? InkWell(
                onTap: _handleTap,
                borderRadius: borderRadius,
                child: content,
              )
            : content,
      ),
    );
  }
}
