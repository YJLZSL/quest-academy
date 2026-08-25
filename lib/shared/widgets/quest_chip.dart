import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest_academy/core/motion/animation_utils.dart';
import 'package:quest_academy/core/theme/motion_tokens.dart';
import 'package:quest_academy/core/theme/shape_tokens.dart';
import 'package:quest_academy/core/theme/theme_flavor_provider.dart';

/// Chip 变体
enum QuestChipVariant {
  /// 过滤（可选中）
  filter,

  /// 信息（仅展示）
  info,

  /// 操作（可点击）
  action,
}

/// 问学 Chip 组件
///
/// 基于 Material [Chip] 系列封装，圆角统一使用 [ShapeTokens.chipRadius]。
/// 支持三种变体：
/// - [QuestChipVariant.filter]：可选中（[FilterChip]），选中态切换时带弹性缩放动画与轻触觉反馈
/// - [QuestChipVariant.info]：仅展示（[RawChip]），可选 [onTap] 让其变为可点击（类似 [ActionChip]）、[onDeleted] 显示删除按钮（删除时带收缩淡出动画）
/// - [QuestChipVariant.action]：可点击（[ActionChip]）
///
/// 改动要点：
/// 1. 圆角完全取自 [ShapeTokens.chipRadius]：standard 圆润、minimal 更扁平方正（radius=4）、minecraft 直角（radius=0）。
/// 2. 删除 / 选中动画时长由 [MotionTokens.pageEntranceDelay] 决定，minimal 下为 0 即无动画；同时尊重系统 reduceMotion。
/// 3. minecraft 变体增加像素风 2px 描边，强化方块感。
/// 4. minimal 下内边距更紧凑，信息密度更高。
///
/// 组件会自动跟随 [MediaQuery.disableAnimations]（即"减少动画"无障碍设置），
/// 当开启时跳过所有动画。
class QuestChip extends ConsumerStatefulWidget {
  const QuestChip({
    super.key,
    required this.label,
    this.avatar,
    this.variant = QuestChipVariant.info,
    this.selected = false,
    this.onSelected,
    this.onPressed,
    this.onDeleted,
    this.color,
    this.onTap,
  });

  /// 标签
  final Widget label;

  /// 头像（前缀图标等）
  final Widget? avatar;

  /// 变体
  final QuestChipVariant variant;

  /// 是否选中（仅 [QuestChipVariant.filter] 生效）
  final bool selected;

  /// 选中状态变化回调（仅 [QuestChipVariant.filter] 生效）
  final ValueChanged<bool>? onSelected;

  /// 点击回调（仅 [QuestChipVariant.action] 生效）
  final VoidCallback? onPressed;

  /// 删除回调（仅 [QuestChipVariant.info] 生效）。
  /// 触发时组件会先播放收缩淡出动画，动画结束后再调用该回调。
  final VoidCallback? onDeleted;

  /// 自定义 Chip 背景色；为 null 时使用主题默认颜色。
  final Color? color;

  /// 点击回调（仅 [QuestChipVariant.info] 生效）。
  /// 设置后信息 Chip 可点击，类似 [ActionChip] 行为，支持与 [onDeleted] 共存。
  final VoidCallback? onTap;

  @override
  ConsumerState<QuestChip> createState() => _QuestChipState();
}

class _QuestChipState extends ConsumerState<QuestChip>
    with TickerProviderStateMixin {
  /// 选中态切换时的弹性缩放动画
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  /// 删除时的收缩 + 淡出动画
  late AnimationController _dismissController;
  late Animation<double> _dismissScaleAnimation;
  late Animation<double> _dismissOpacityAnimation;

  /// 是否正在播放删除动画
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();

    final initialDuration = MotionTokens.standard.pageEntranceDelay;

    // 弹性缩放动画：0.95 -> 1.0，使用 easeOutBack 曲线自带过冲弹跳效果
    _bounceController = AnimationController(
      vsync: this,
      duration: initialDuration,
      value: 1.0, // 初始静止状态为 1.0
    );
    _bounceAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeOutBack,
      ),
    );

    // 删除动画：缩放 1.0 -> 0.0，不透明度 1.0 -> 0.0
    _dismissController = AnimationController(
      vsync: this,
      duration: initialDuration,
    );
    _dismissScaleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _dismissController,
        curve: Curves.easeIn,
      ),
    );
    _dismissOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _dismissController,
        curve: Curves.easeIn,
      ),
    );
    _dismissController.addStatusListener(_handleDismissStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 动画时长跟随当前主题风味的 motionTokens，minimal 下为 0 即即时切换。
    final duration = context.motionTokens.pageEntranceDelay;
    _bounceController.duration = duration;
    _dismissController.duration = duration;
  }

  @override
  void didUpdateWidget(covariant QuestChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 选中状态变化时触发弹性缩放动画
    if (widget.selected != oldWidget.selected) {
      _playBounceAnimation();
    }
  }

  @override
  void dispose() {
    _dismissController.removeStatusListener(_handleDismissStatus);
    _bounceController.dispose();
    _dismissController.dispose();
    super.dispose();
  }

  /// 播放选中态弹性动画
  void _playBounceAnimation() {
    if (AnimationUtils.reduceMotionOf(context)) {
      return;
    }
    // 轻触觉反馈
    AnimationUtils.hapticLight();
    // 重置到 0.0（对应 scale 0.95），再向前播放到 1.0（easeOutBack 产生过冲弹跳）
    _bounceController.value = 0.0;
    _bounceController.forward();
  }

  /// 处理删除按钮点击：先播放动画，结束后再回调
  void _handleDeleteTap() {
    if (widget.onDeleted == null) return;
    if (AnimationUtils.reduceMotionOf(context)) {
      widget.onDeleted!();
      return;
    }
    setState(() => _dismissing = true);
    _dismissController.forward();
  }

  /// 删除动画状态监听
  void _handleDismissStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onDeleted?.call();
    }
  }

  /// 根据主题风味返回 chip 内边距：minimal 更紧凑扁平，minecraft/standard 保持常规。
  EdgeInsetsGeometry _chipPadding(ThemeFlavor flavor) {
    return switch (flavor) {
      ThemeFlavor.minimal => const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 2,
        ),
      ThemeFlavor.minecraft => const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
      ThemeFlavor.standard => const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final flavor = ref.watch(themeFlavorProvider);
    final shapeTokens = context.shapeTokens;
    final colorScheme = Theme.of(context).colorScheme;
    final isMinecraft = flavor == ThemeFlavor.minecraft;

    // 圆角统一取自 shapeTokens，minecraft 下为 0 即直角。
    final chipShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(shapeTokens.chipRadius),
      side: isMinecraft
          ? BorderSide(color: colorScheme.outline, width: 2)
          : BorderSide.none,
    );

    final padding = _chipPadding(flavor);

    // 构建对应变体的 Chip
    Widget chip;
    switch (widget.variant) {
      case QuestChipVariant.filter:
        chip = FilterChip(
          label: widget.label,
          avatar: widget.avatar,
          selected: widget.selected,
          onSelected: widget.onSelected != null
              ? (value) {
                  _playBounceAnimation();
                  widget.onSelected!(value);
                }
              : null,
          selectedColor: widget.color ?? colorScheme.primaryContainer,
          backgroundColor: widget.color,
          checkmarkColor: colorScheme.onPrimaryContainer,
          shape: chipShape,
          padding: padding,
          showCheckmark: true,
        );
      case QuestChipVariant.action:
        chip = ActionChip(
          label: widget.label,
          avatar: widget.avatar,
          onPressed: () {
            _playBounceAnimation();
            widget.onPressed?.call();
          },
          backgroundColor: widget.color,
          shape: chipShape,
          padding: padding,
        );
      case QuestChipVariant.info:
        chip = RawChip(
          label: widget.label,
          avatar: widget.avatar,
          onPressed: widget.onTap,
          onDeleted: widget.onDeleted != null ? _handleDeleteTap : null,
          deleteIcon: widget.onDeleted != null
              ? const Icon(Icons.close, size: 18)
              : null,
          backgroundColor: widget.color,
          shape: chipShape,
          padding: padding,
        );
    }

    // 删除 / 选中动画包裹：minimal 与 reduceMotion 下即时切换。
    if (AnimationUtils.reduceMotionOf(context)) {
      return chip;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_bounceController, _dismissController]),
      builder: (context, child) {
        final scale = _dismissing
            ? _dismissScaleAnimation.value
            : _bounceAnimation.value;
        final opacity = _dismissing
            ? _dismissOpacityAnimation.value
            : 1.0;
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: chip,
    );
  }
}
