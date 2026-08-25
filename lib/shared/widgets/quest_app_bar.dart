import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest_academy/core/motion/animation_utils.dart';
import 'package:quest_academy/core/motion/spring_motion.dart';
import 'package:quest_academy/core/theme/background_textures.dart';
import 'package:quest_academy/core/theme/theme_flavor_provider.dart';

/// 问学 AppBar 组件
///
/// 基于 [AppBar]，默认居中标题，支持自定义 leading。
/// 支持滚动联动背景变化、leading/title/actions 交错入场。
///
/// 改动要点：
/// 1. standard：保持圆润居中标题与交错入场动画（原有行为）。
/// 2. minimal：标题强制左对齐，并禁用入场动画，契合低动效专注模式。
/// 3. minecraft：背景由 [BackgroundTextures.minecraftGrass]（顶部草地条）与
///    [BackgroundTextures.minecraftDirt]（下方 dirt）叠加组成；标题强制白色；
///    整体保持直角风格。
/// 4. 所有颜色/纹理均来自主题 Token，未硬编码。
class QuestAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  const QuestAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.scrolledUnderElevation = 0,
    this.bottom,
    this.scrollController,
    this.animateEntrance = true,
    this.backgroundGradient,
  });

  /// 标题
  final Widget title;

  /// 右侧操作区
  final List<Widget>? actions;

  /// 左侧前导部件
  final Widget? leading;

  /// 是否居中标题（standard 下生效，minimal 下强制左对齐）
  final bool centerTitle;

  /// 背景色
  final Color? backgroundColor;

  /// 前景色
  final Color? foregroundColor;

  /// 海拔
  final double elevation;

  /// 滚动时的海拔
  final double scrolledUnderElevation;

  /// 底部部件（如 TabBar）
  final PreferredSizeWidget? bottom;

  /// 滚动控制器（用于滚动联动效果）
  final ScrollController? scrollController;

  /// 是否启用 staggered 入场动画（minimal 下强制关闭）
  final bool animateEntrance;

  /// 背景渐变（设置后覆盖背景色，minecraft 下仍优先使用草地/dirt 纹理）
  final Gradient? backgroundGradient;

  @override
  ConsumerState<QuestAppBar> createState() => _QuestAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(
        bottom == null
            ? kToolbarHeight
            : kToolbarHeight + bottom!.preferredSize.height,
      );
}

class _QuestAppBarState extends ConsumerState<QuestAppBar> {
  bool _scrolled = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
    // minimal 模式下禁用入场动画；同时尊重平台级 reduceMotion。
    final isMinimal = ref.read(themeFlavorProvider) == ThemeFlavor.minimal;
    final shouldAnimate = widget.animateEntrance &&
        !isMinimal &&
        !AnimationUtils.platformReduceMotion;
    if (shouldAnimate) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) setState(() => _visible = true);
      });
    } else {
      _visible = true;
    }
  }

  @override
  void didUpdateWidget(covariant QuestAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) return;
    final offset = controller.offset;
    final isScrolled = offset > 4;
    if (isScrolled != _scrolled && mounted) {
      setState(() => _scrolled = isScrolled);
    }
  }

  /// 构建 minecraft 风格背景：顶部草地条 + 下方 dirt。
  Widget _buildMinecraftBackground() {
    const grassHeight = 32.0; // 2 个 16x16 像素块高度
    return Stack(
      fit: StackFit.expand,
      children: [
        // 下方 dirt 铺满整个 AppBar
        CustomPaint(painter: context.backgroundTextures.minecraftDirt),
        // 顶部草地条
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: grassHeight,
          child: CustomPaint(painter: context.backgroundTextures.minecraftGrass),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final flavor = ref.watch(themeFlavorProvider);
    final isMinimal = flavor == ThemeFlavor.minimal;
    final isMinecraft = flavor == ThemeFlavor.minecraft;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // minimal 强制无动画；同时尊重系统 reduceMotion。
    final reduceMotion = AnimationUtils.reduceMotionOf(context) || isMinimal;

    // minimal 下标题强制左对齐；其余风味尊重 widget.centerTitle。
    final effectiveCenterTitle = isMinimal ? false : widget.centerTitle;

    Widget title = widget.title;
    Widget? leading = widget.leading;
    List<Widget>? actions = widget.actions;

    // minecraft 下标题强制白色，确保在草地背景上可读。
    if (isMinecraft) {
      final titleStyle = theme.appBarTheme.titleTextStyle ??
          theme.textTheme.titleLarge ??
          const TextStyle();
      title = DefaultTextStyle(
        style: titleStyle.copyWith(color: Colors.white),
        child: title,
      );
    }

    // staggered 入场动画（standard 启用，minimal 禁用）。
    if (widget.animateEntrance && !reduceMotion) {
      const duration = SpringMotion.fastDuration;
      const curve = SpringMotion.entranceCurve;

      if (leading != null) {
        leading = AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
          duration: duration,
          curve: curve,
          child: AnimatedSlide(
            offset: _visible ? Offset.zero : const Offset(-0.2, 0),
            duration: duration,
            curve: curve,
            child: leading,
          ),
        );
      }

      title = AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: duration,
        curve: curve,
        child: AnimatedSlide(
          offset: _visible ? Offset.zero : const Offset(0, 0.3),
          duration: duration,
          curve: curve,
          child: title,
        ),
      );

      if (actions != null) {
        actions = [
          for (var i = 0; i < actions.length; i++)
            AnimatedOpacity(
              opacity: _visible ? 1.0 : 0.0,
              duration: duration,
              curve: curve,
              child: AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(0.2, 0),
                duration: duration,
                curve: curve,
                child: actions[i],
              ),
            ),
        ];
      }
    }

    // 构建 AppBar
    PreferredSizeWidget appBar;
    if (isMinecraft) {
      // minecraft 使用草地 + dirt 纹理背景，直角风格，标题白色。
      appBar = AppBar(
        title: title,
        centerTitle: effectiveCenterTitle,
        actions: actions,
        leading: leading,
        backgroundColor: Colors.transparent,
        foregroundColor: widget.foregroundColor ?? Colors.white,
        elevation: widget.elevation,
        scrolledUnderElevation: widget.scrolledUnderElevation,
        bottom: widget.bottom,
        flexibleSpace: _buildMinecraftBackground(),
        shape: null,
      );
    } else if (widget.backgroundGradient != null) {
      appBar = AppBar(
        title: title,
        centerTitle: effectiveCenterTitle,
        actions: actions,
        leading: leading,
        backgroundColor: Colors.transparent,
        foregroundColor:
            widget.foregroundColor ?? theme.appBarTheme.foregroundColor,
        elevation: widget.elevation,
        scrolledUnderElevation: widget.scrolledUnderElevation,
        bottom: widget.bottom,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: widget.backgroundGradient),
        ),
        shape: _scrolled
            ? Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              )
            : null,
      );
    } else {
      final effectiveBg = _scrolled
          ? (widget.backgroundColor ?? colorScheme.surfaceContainerLow)
          : (widget.backgroundColor ??
              theme.appBarTheme.backgroundColor ??
              colorScheme.surface);

      // 滚动联动底部边框：通过 AppBar.shape 参数实现，避免用 AnimatedContainer
      // 包装 AppBar 导致类型不匹配 PreferredSizeWidget。
      // 注：AppBar 自身的 scrolledUnderElevation 已处理滚动抬升，此处仅补充视觉分隔线。
      final bottomBorder = _scrolled
          ? Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 0.5,
              ),
            )
          : null;
      appBar = AppBar(
        title: title,
        centerTitle: effectiveCenterTitle,
        actions: actions,
        leading: leading,
        backgroundColor: effectiveBg,
        foregroundColor:
            widget.foregroundColor ?? theme.appBarTheme.foregroundColor,
        elevation: widget.elevation,
        scrolledUnderElevation: widget.scrolledUnderElevation,
        bottom: widget.bottom,
        shape: bottomBorder,
      );
    }

    return appBar;
  }
}
