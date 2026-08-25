import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest_academy/core/motion/animation_utils.dart';
import 'package:quest_academy/core/motion/spring_motion.dart';
import 'package:quest_academy/core/theme/quest_elevations.dart';
import 'package:quest_academy/core/theme/motion_tokens.dart';
import 'package:quest_academy/core/theme/shape_tokens.dart';
import 'package:quest_academy/core/theme/theme_flavor_provider.dart';

/// 按钮变体
enum QuestButtonVariant {
  /// 填充按钮（主要操作）
  filled,

  /// Tonal 填充按钮（次要操作）
  tonal,

  /// 凸起按钮
  elevated,

  /// 描边按钮
  outlined,

  /// 文本按钮
  text,
}

/// 按钮尺寸
enum QuestButtonSize {
  /// 小
  small,

  /// 中
  medium,

  /// 大
  large,
}

/// 问学按钮组件
///
/// 升级要点（ThemeFlavor Token 体系）：
/// - 圆角统一取自 [ShapeTokens.buttonRadius]；minecraft 风味下该值为 0，
///   因此按钮自动呈现直角像素块外观。
/// - 按压缩放统一读取 [MotionTokens.buttonPressedScale]；minimal 风味下
///   该值为 1.0，自动禁用按压缩放反馈。
/// - 阴影/边框全部取自 [QuestElevations]；minecraft 风味下使用
///   [QuestElevations.pixelBorder] 模拟像素厚边阴影，标准/极简风味下
///   保持 subtle/elevated 语义阴影切换。
class QuestButton extends ConsumerStatefulWidget {
  const QuestButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = QuestButtonVariant.filled,
    this.size = QuestButtonSize.medium,
    this.isLoading = false,
    this.pulse = false,
    this.enableHaptic = true,
  });

  /// 按钮文字
  final Widget label;

  /// 可选前缀图标
  final Widget? icon;

  /// 点击回调，为 null 时按钮处于禁用态
  final VoidCallback? onPressed;

  /// 按钮变体
  final QuestButtonVariant variant;

  /// 按钮尺寸
  final QuestButtonSize size;

  /// 是否显示 loading 指示器
  final bool isLoading;

  /// CTA 呼吸脉动效果
  final bool pulse;

  /// 是否启用触觉反馈
  final bool enableHaptic;

  @override
  ConsumerState<QuestButton> createState() => _QuestButtonState();
}

class _QuestButtonState extends ConsumerState<QuestButton> {
  bool _pressed = false;
  late final WidgetStatesController _statesController;

  @override
  void initState() {
    super.initState();
    _statesController = WidgetStatesController()
      ..addListener(_onStatesChanged);
  }

  @override
  void dispose() {
    _statesController.removeListener(_onStatesChanged);
    _statesController.dispose();
    super.dispose();
  }

  void _onStatesChanged() {
    final pressed = _statesController.value.contains(WidgetState.pressed);
    if (pressed != _pressed && mounted) {
      setState(() => _pressed = pressed);
    }
  }

  void _handlePressed() {
    if (widget.isLoading) return;
    if (widget.enableHaptic) {
      AnimationUtils.hapticLight();
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AnimationUtils.reduceMotionOf(context);
    final shapeTokens = context.shapeTokens;
    final motionTokens = context.motionTokens;
    final flavor = ref.watch(themeFlavorProvider);
    final disabled = widget.onPressed == null || widget.isLoading;
    final scale = _pressed && !disabled ? motionTokens.buttonPressedScale : 1.0;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(shapeTokens.buttonRadius),
    );

    final (vertical, horizontal, fontSize, iconSize) = switch (widget.size) {
      QuestButtonSize.small => (6.0, 12.0, null, 16.0),
      QuestButtonSize.medium => (12.0, 20.0, null, 18.0),
      QuestButtonSize.large => (16.0, 28.0, 16.0, 20.0),
    };

    final padding = EdgeInsets.symmetric(
      vertical: vertical,
      horizontal: horizontal,
    );
    final textStyle = fontSize == null ? null : TextStyle(fontSize: fontSize);

    // 构建按钮内容
    Widget buttonContent;
    if (widget.isLoading) {
      final spinnerSize = switch (widget.size) {
        QuestButtonSize.small => 14.0,
        QuestButtonSize.medium => 18.0,
        QuestButtonSize.large => 20.0,
      };
      buttonContent = SizedBox(
        width: spinnerSize,
        height: spinnerSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          strokeAlign: BorderSide.strokeAlignInside,
          color: _spinnerColorFor(context),
        ),
      );
    } else if (widget.icon != null) {
      buttonContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(
            data: IconThemeData(size: iconSize),
            child: widget.icon!,
          ),
          const SizedBox(width: 8),
          widget.label,
        ],
      );
    } else {
      buttonContent = widget.label;
    }

    final buttonStyle = ButtonStyle(
      shape: WidgetStatePropertyAll(shape),
      padding: WidgetStatePropertyAll(padding),
      textStyle: WidgetStatePropertyAll(textStyle),
    );

    // 构建按钮
    Widget button = switch (widget.variant) {
      QuestButtonVariant.filled => FilledButton(
          onPressed: disabled ? null : _handlePressed,
          statesController: _statesController,
          style: buttonStyle,
          child: buttonContent,
        ),
      QuestButtonVariant.tonal => FilledButton.tonal(
          onPressed: disabled ? null : _handlePressed,
          statesController: _statesController,
          style: buttonStyle,
          child: buttonContent,
        ),
      QuestButtonVariant.elevated => ElevatedButton(
          onPressed: disabled ? null : _handlePressed,
          statesController: _statesController,
          style: buttonStyle,
          child: buttonContent,
        ),
      QuestButtonVariant.outlined => OutlinedButton(
          onPressed: disabled ? null : _handlePressed,
          statesController: _statesController,
          style: buttonStyle,
          child: buttonContent,
        ),
      QuestButtonVariant.text => TextButton(
          onPressed: disabled ? null : _handlePressed,
          statesController: _statesController,
          style: buttonStyle,
          child: buttonContent,
        ),
    };

    // 按压阴影抬升（subtle → elevated）+ 弹性缩放。
    // minecraft 风味下使用 pixelBorder 模拟像素厚边阴影；minimal 风味下
    // buttonPressedScale == 1.0，自动跳过视觉缩放反馈。
    if (!reduceMotion) {
      final elevations = context.questElevations;
      final shadows = flavor == ThemeFlavor.minecraft
          ? elevations.pixelBorder
          : _pressed && !disabled
              ? elevations.elevated
              : elevations.subtle;
      button = AnimatedContainer(
        duration: SpringMotion.fastDuration,
        curve: SpringMotion.fastCurve,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(shapeTokens.buttonRadius),
          boxShadow: shadows,
        ),
        child: AnimatedScale(
          scale: scale,
          duration: SpringMotion.fastDuration,
          curve: SpringMotion.fastCurve,
          child: button,
        ),
      );
    }

    // CTA 呼吸脉动：在 minimal 等低动效风味下禁用。
    if (widget.pulse &&
        !widget.isLoading &&
        !disabled &&
        !reduceMotion &&
        motionTokens.buttonPressedScale != 1.0) {
      button = SpringMotion.pulseBreathing(
        minScale: 0.98,
        maxScale: 1.02,
        child: button,
      );
    }

    return button;
  }

  Color? _spinnerColorFor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (widget.variant) {
      QuestButtonVariant.filled => colorScheme.onPrimary,
      QuestButtonVariant.tonal => colorScheme.onSecondaryContainer,
      QuestButtonVariant.elevated => colorScheme.onPrimary,
      QuestButtonVariant.outlined => colorScheme.primary,
      QuestButtonVariant.text => colorScheme.primary,
    };
  }
}
