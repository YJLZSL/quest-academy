import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest_academy/core/theme/shape_tokens.dart';
import 'package:quest_academy/core/theme/theme_flavor_provider.dart';

/// 灵犀学院统一输入框组件。
///
/// 提供一致的圆角、内边距和聚焦动画效果。
/// 支持前缀图标、后缀组件、多行文本和密码模式。
///
/// 改动要点：
/// 1. 圆角统一取自 [ShapeTokens.inputRadius]：standard 圆润（radius=16）、minimal 更方正（radius=4）、minecraft 直角（radius=0）。
/// 2. minimal 模式下边框更细（1px）、饱和度和对比度降低，契合低信息装饰风格。
/// 3. minecraft 模式下使用直角 + 像素风厚描边（3px），关闭填充色，呈现方块面板感。
/// 4. 所有颜色/半径均来自主题 Token，未硬编码。
class QuestTextField extends ConsumerWidget {
  const QuestTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.enabled = true,
    this.autofocus = false,
    this.errorText,
    this.helperText,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool autofocus;
  final String? errorText;
  final String? helperText;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavor = ref.watch(themeFlavorProvider);
    final shapeTokens = context.shapeTokens;
    final colorScheme = Theme.of(context).colorScheme;
    final isMinimal = flavor == ThemeFlavor.minimal;
    final isMinecraft = flavor == ThemeFlavor.minecraft;

    final radius = shapeTokens.inputRadius;
    final borderRadius = BorderRadius.circular(radius);

    // minimal：更细、更淡的边框；minecraft：像素风厚描边。
    final enabledBorderSide = isMinecraft
        ? BorderSide(color: colorScheme.outline, width: 3)
        : BorderSide(
            color: colorScheme.outlineVariant
                .withValues(alpha: isMinimal ? 0.5 : 0.7),
            width: isMinimal ? 1.0 : 1.5,
          );

    final focusedBorderSide = isMinecraft
        ? BorderSide(color: colorScheme.primary, width: 3)
        : BorderSide(
            color: colorScheme.primary,
            width: isMinimal ? 1.5 : 2.0,
          );

    final errorBorderSide = BorderSide(
      color: colorScheme.error,
      width: isMinecraft ? 3.0 : (isMinimal ? 1.5 : 1.0),
    );

    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      enabled: enabled,
      autofocus: autofocus,
      focusNode: focusNode,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        helperText: helperText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: colorScheme.onSurfaceVariant)
            : null,
        suffixIcon: suffixIcon,
        // minecraft 关闭填充，突出像素描边；其余风格保持柔和填充。
        filled: !isMinecraft,
        fillColor: isMinecraft ? null : colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: isMinecraft ? BorderSide.none : enabledBorderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: enabledBorderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: focusedBorderSide,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: errorBorderSide,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: errorBorderSide.copyWith(
            width: isMinecraft ? 3.0 : (isMinimal ? 1.5 : 2.0),
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMinecraft ? 12 : 16,
          vertical: isMinecraft ? 12 : 14,
        ),
      ),
    );
  }
}
