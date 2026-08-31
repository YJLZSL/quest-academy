import 'package:flutter/material.dart';

import '../theme/motion_tokens.dart';
import '../theme/quest_spacing.dart';
import '../theme/shape_tokens.dart';
import 'animation_utils.dart';
import 'spring_motion.dart';

/// 全局统一动效入口。
///
/// 目标：让页面切换、弹窗、侧边栏、列表展开收起、按钮与卡片交互共享同一套
/// **时长与缓动曲线**，整体节奏一致且不拖沓（单次动效 200–300ms）。
///
/// 时长与曲线统一来源于主题令牌 [MotionTokens]：
/// - 短 200ms：按压反馈、悬停/聚焦态、箭头旋转等小元素
/// - 中 250ms：展开收起、卡片/列表项入场、弹窗与底部面板
/// - 长 300ms：页面切换、侧边栏、大位移
///
/// 所有组件均自动尊重系统「减少动效」偏好：开启时降级为即时切换或静态态。
class AppMotion {
  const AppMotion._();

  /// 短时长（200ms）。
  static Duration shortOf(BuildContext context) =>
      context.motionTokens.durationShort;

  /// 中等时长（250ms）。
  static Duration mediumOf(BuildContext context) =>
      context.motionTokens.durationMedium;

  /// 长时长（300ms）。
  static Duration longOf(BuildContext context) =>
      context.motionTokens.durationLong;

  /// 标准减速曲线。
  static Curve standardCurveOf(BuildContext context) =>
      context.motionTokens.curveStandard;

  /// 强调减速曲线（大位移）。
  static Curve emphasizedCurveOf(BuildContext context) =>
      context.motionTokens.curveEmphasized;

  /// 离场曲线。
  static Curve exitCurveOf(BuildContext context) =>
      context.motionTokens.curveExit;

  /// 解析时长：reduceMotion 时返回 [Duration.zero]。
  static Duration resolve(BuildContext context, Duration normal) {
    return AnimationUtils.reduceMotionOf(context) ? Duration.zero : normal;
  }

  /// 列表交错入场间隔（reduceMotion 时为 0）。
  static Duration staggerDelayOf(BuildContext context, int index) {
    if (AnimationUtils.reduceMotionOf(context)) return Duration.zero;
    return context.motionTokens.listStaggerDelay * index;
  }
}

/// 可折叠区块：标题行 + 展开内容。
///
/// 统一动效规范：
/// - 高度变化：[MotionTokens.durationMedium]（250ms）+ 标准减速曲线
/// - 箭头旋转：[MotionTokens.durationShort]（200ms），展开时旋转 180°
/// - 点击时提供轻微触觉反馈
/// - reduceMotion 时高度与旋转均为即时切换
///
/// 与 [ExpansionTile] 的差异：本组件使用主题令牌驱动时长/曲线，
/// 且标题与内容间距遵循 [QuestSpacing]，保证与全局节奏一致。
class AppExpandable extends StatefulWidget {
  const AppExpandable({
    super.key,
    required this.title,
    required this.children,
    this.leading,
    this.subtitle,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  /// 标题。
  final Widget title;

  /// 可选副标题。
  final Widget? subtitle;

  /// 可选前置图标。
  final Widget? leading;

  /// 展开后的子内容。
  final List<Widget> children;

  /// 初始是否展开。
  final bool initiallyExpanded;

  /// 展开状态变化回调。
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<AppExpandable> createState() => _AppExpandableState();
}

class _AppExpandableState extends State<AppExpandable>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _arrowController;
  late final Animation<double> _arrowTurns;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _arrowController = AnimationController(
      vsync: this,
      duration: SpringMotion.fastDuration,
      value: _expanded ? 1.0 : 0.0,
    );
    _arrowTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _arrowController,
        curve: SpringMotion.defaultCurve,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant AppExpandable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _setExpanded(widget.initiallyExpanded);
    }
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  void _setExpanded(bool value) {
    if (_expanded == value) return;
    setState(() => _expanded = value);
    if (value) {
      _arrowController.forward();
    } else {
      _arrowController.reverse();
    }
    widget.onExpansionChanged?.call(value);
  }

  void _toggle() {
    AnimationUtils.hapticLight();
    _setExpanded(!_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.questSpacing;
    final duration = AppMotion.resolve(
      context,
      AppMotion.mediumOf(context),
    );
    final curve = AppMotion.standardCurveOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          child: InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(context.shapeTokens.chipRadius),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.md,
                vertical: spacing.md,
              ),
              child: Row(
                children: [
                  if (widget.leading != null) ...[
                    widget.leading!,
                    SizedBox(width: spacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DefaultTextStyle(
                          style: theme.textTheme.titleSmall ??
                              const TextStyle(),
                          child: widget.title,
                        ),
                        if (widget.subtitle != null) ...[
                          SizedBox(height: spacing.xs),
                          DefaultTextStyle(
                            style: (theme.textTheme.bodySmall ??
                                    const TextStyle())
                                .copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            child: widget.subtitle!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _arrowTurns,
                    child: const Icon(Icons.expand_more, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: duration,
            curve: curve,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: EdgeInsets.fromLTRB(
                      spacing.md,
                      0,
                      spacing.md,
                      spacing.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: widget.children,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }
}

/// 交错入场包装：按 [index] 延迟播放淡入 + 上移动画。
///
/// 用于列表/卡片组，使多个元素依次入场而非同时出现，节奏由
/// [MotionTokens.listStaggerDelay] 控制。reduceMotion 时直接显示内容。
class AppStaggeredItem extends StatefulWidget {
  const AppStaggeredItem({
    super.key,
    required this.index,
    required this.child,
    this.distance = 16,
  });

  /// 元素在列表中的序号（决定延迟）。
  final int index;

  /// 子元素。
  final Widget child;

  /// 入场位移距离。
  final double distance;

  @override
  State<AppStaggeredItem> createState() => _AppStaggeredItemState();
}

class _AppStaggeredItemState extends State<AppStaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    final reduceMotion = AnimationUtils.platformReduceMotion;
    _controller = AnimationController(
      vsync: this,
      duration: SpringMotion.gentleDuration,
      value: reduceMotion ? 1.0 : 0.0,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: SpringMotion.entranceCurve,
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _offset = Tween<Offset>(
      begin: Offset(0, widget.distance),
      end: Offset.zero,
    ).animate(curved);

    if (!reduceMotion) {
      final delay = widget.index * 60;
      Future<void>.delayed(Duration(milliseconds: delay), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AnimationUtils.reduceMotionOf(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _offset.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// 通用交互容器：按压缩放 + 桌面端悬停高亮 + 键盘聚焦描边。
///
/// 统一消费 [MotionTokens]：
/// - 按压缩放比例取 [MotionTokens.buttonPressedScale]
/// - 过渡时长取 [MotionTokens.durationShort]（200ms）
/// - 悬停态底色取 `colorScheme.primary` 的 8% 透明度
/// - 聚焦态显示 2px 主色描边，保证键盘可达性
///
/// reduceMotion 时跳过缩放，仅保留颜色态变化。
class AppInteractive extends StatefulWidget {
  const AppInteractive({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.padding,
    this.selected = false,
    this.enableHaptic = true,
    this.semanticLabel,
  });

  /// 子组件。
  final Widget child;

  /// 点击回调。
  final VoidCallback? onTap;

  /// 圆角（默认取 ShapeTokens.cardRadius）。
  final BorderRadius? borderRadius;

  /// 内边距。
  final EdgeInsets? padding;

  /// 是否为选中态（显示主色浅底 + 主色描边）。
  final bool selected;

  /// 是否启用触觉反馈。
  final bool enableHaptic;

  /// 无障碍语义标签。
  final String? semanticLabel;

  @override
  State<AppInteractive> createState() => _AppInteractiveState();
}

class _AppInteractiveState extends State<AppInteractive> {
  bool _hovering = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _interactive => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shapeTokens = context.shapeTokens;
    final motionTokens = context.motionTokens;
    final reduceMotion = AnimationUtils.reduceMotionOf(context);

    final radius = widget.borderRadius ??
        BorderRadius.circular(shapeTokens.cardRadius);

    Color? background;
    BorderSide? border;

    if (widget.selected) {
      background = colorScheme.primary.withValues(alpha: 0.12);
      border = BorderSide(color: colorScheme.primary, width: 1.5);
    } else if (_hovering && _interactive) {
      background = colorScheme.primary.withValues(alpha: 0.08);
    }

    if (_focused && _interactive) {
      border = BorderSide(color: colorScheme.primary, width: 2);
    }

    final scale = _pressed && _interactive && !reduceMotion
        ? motionTokens.buttonPressedScale
        : 1.0;

    return Semantics(
      button: _interactive,
      label: widget.semanticLabel,
      child: Focus(
        onFocusChange: (value) => setState(() => _focused = value),
        child: GestureDetector(
          onTapDown: _interactive
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: _interactive ? (_) => setState(() => _pressed = false) : null,
          onTapCancel:
              _interactive ? () => setState(() => _pressed = false) : null,
          onTap: _interactive
              ? () {
                  if (widget.enableHaptic) AnimationUtils.hapticLight();
                  widget.onTap?.call();
                }
              : null,
          behavior: HitTestBehavior.opaque,
          child: MouseRegion(
            onEnter: _interactive ? (_) => setState(() => _hovering = true) : null,
            onExit: _interactive ? (_) => setState(() => _hovering = false) : null,
            cursor: _interactive
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: AnimatedScale(
              scale: scale,
              duration: AppMotion.resolve(
                context,
                motionTokens.durationShort,
              ),
              curve: motionTokens.curveStandard,
              child: AnimatedContainer(
                duration: AppMotion.resolve(
                  context,
                  motionTokens.durationShort,
                ),
                curve: motionTokens.curveStandard,
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: radius,
                  border: border == null ? null : Border.fromBorderSide(border),
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
