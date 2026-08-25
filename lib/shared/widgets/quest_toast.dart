import 'package:flutter/material.dart';
import 'package:quest_academy/core/theme/quest_colors.dart';
import 'package:quest_academy/core/theme/motion_tokens.dart';
import 'package:quest_academy/core/theme/shape_tokens.dart';

/// Toast 变体类型。
enum QuestToastVariant {
  /// 成功提示（绿色图标）
  success,

  /// 错误提示（红色图标）
  error,

  /// 警告提示（琥珀色图标）
  warning,

  /// 信息提示（青色图标）
  info,
}

/// 问学统一 Toast/SnackBar 工具。
///
/// 主题适配说明：
/// - 背景色取自 [QuestColors] 语义色（successGreen / misconceptionRed / streakFire / infoTeal）；
/// - 文字/图标色通过背景亮度自动计算对比度，避免在任意种子色下可读性劣化；
/// - 圆角取自 [ShapeTokens.chipRadius]；
/// - Minimal 风味下隐藏图标，呈现更扁平、低干扰的提示条。
///
/// 提供一致的样式和动画效果，支持成功/错误/警告/信息四种变体。
/// 通过静态方法 [QuestToast.show] 便捷调用。
class QuestToast {
  QuestToast._();

  /// 显示 Toast 消息。
  ///
  /// 使用 ScaffoldMessenger 展示 SnackBar，自动适配主题颜色。
  static void show(
    BuildContext context, {
    required String message,
    QuestToastVariant variant = QuestToastVariant.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final colors = context.questColors;
    final shapeTokens = context.shapeTokens;
    final motionTokens = context.motionTokens;
    final (icon, bgColor, fgColor) = _getVariantStyle(
      variant,
      colors,
      motionTokens,
    );

    // Minimal 风味关闭图标，使提示条更扁平、更克制。
    final isMinimal =
        motionTokens.pageEntranceDelay == Duration.zero && !motionTokens.enableParticles;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (icon != null && !isMinimal) ...[
                Icon(icon, color: fgColor, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: fgColor),
                ),
              ),
            ],
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(shapeTokens.chipRadius),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: duration,
          action: action,
        ),
      );
  }

  /// 便捷方法：显示成功 Toast。
  static void success(BuildContext context, String message) {
    show(context, message: message, variant: QuestToastVariant.success);
  }

  /// 便捷方法：显示错误 Toast。
  static void error(BuildContext context, String message) {
    show(context, message: message, variant: QuestToastVariant.error);
  }

  /// 便捷方法：显示警告 Toast。
  static void warning(BuildContext context, String message) {
    show(context, message: message, variant: QuestToastVariant.warning);
  }

  /// 便捷方法：显示信息 Toast。
  static void info(BuildContext context, String message) {
    show(context, message: message, variant: QuestToastVariant.info);
  }

  static (IconData?, Color, Color) _getVariantStyle(
    QuestToastVariant variant,
    QuestColors colors,
    MotionTokens motionTokens,
  ) {
    // 语义背景色：直接消费 QuestColors，不再借用 colorScheme 的容器色。
    final bgColor = switch (variant) {
      QuestToastVariant.success => colors.successGreen,
      QuestToastVariant.error => colors.misconceptionRed,
      QuestToastVariant.warning => colors.streakFire,
      QuestToastVariant.info => colors.infoTeal,
    };

    // 根据背景亮度自动选择黑/白前景，保证 WCAG 对比度可读性。
    final fgColor = _contrastForeground(bgColor);

    // Minimal 风味返回 null 图标，由调用方决定是否渲染。
    if (motionTokens.pageEntranceDelay == Duration.zero &&
        !motionTokens.enableParticles) {
      return (null, bgColor, fgColor);
    }

    final icon = switch (variant) {
      QuestToastVariant.success => Icons.check_circle_rounded,
      QuestToastVariant.error => Icons.error_rounded,
      QuestToastVariant.warning => Icons.warning_rounded,
      QuestToastVariant.info => Icons.info_rounded,
    };

    return (icon, bgColor, fgColor);
  }

  /// 根据背景亮度计算高对比度前景色（黑/白）。
  ///
  /// 使用 [Color.computeLuminance] 判断背景属于亮/暗，从而自动满足对比度需求。
  static Color _contrastForeground(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
