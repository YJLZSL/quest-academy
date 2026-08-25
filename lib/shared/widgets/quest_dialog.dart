import 'package:flutter/material.dart';
import 'package:quest_academy/core/motion/spring_motion.dart';
import 'package:quest_academy/core/theme/quest_colors.dart';
import 'package:quest_academy/core/theme/quest_elevations.dart';
import 'package:quest_academy/core/theme/motion_tokens.dart';
import 'package:quest_academy/core/theme/shape_tokens.dart';

/// 问学统一对话框组件。
///
/// 主题适配说明（v0.x 主题 Token 化改造）：
/// - 圆角完全取自 [ShapeTokens.dialogRadius]；
/// - Minecraft 风味下强制直角，并改用 [QuestElevations.pixelBorder] 厚边阴影；
/// - Minimal 风味下通过 [MotionTokens.pageEntranceDelay] 判断是否关闭缩放入场；
/// - 颜色、阴影均走语义 Token，组件内不再硬编码任何视觉常量。
///
/// 提供一致的圆角、标题、内容和操作按钮布局。
/// 支持自定义图标和确认/取消回调。
class QuestDialog extends StatelessWidget {
  const QuestDialog({
    super.key,
    required this.title,
    this.content,
    this.contentWidget,
    this.icon,
    this.iconColor,
    this.confirmLabel = '确认',
    this.cancelLabel = '取消',
    this.onConfirm,
    this.onCancel,
    this.showCancel = true,
    this.isDestructive = false,
  });

  /// 对话框标题。
  final String title;

  /// 文本内容（与 [contentWidget] 二选一）。
  final String? content;

  /// 自定义内容 Widget（与 [content] 二选一）。
  final Widget? contentWidget;

  /// 标题图标。
  final IconData? icon;

  /// 图标颜色。
  final Color? iconColor;

  /// 确认按钮文字。
  final String confirmLabel;

  /// 取消按钮文字。
  final String cancelLabel;

  /// 确认回调。
  final VoidCallback? onConfirm;

  /// 取消回调。
  final VoidCallback? onCancel;

  /// 是否显示取消按钮。
  final bool showCancel;

  /// 是否为破坏性操作（确认按钮变红）。
  final bool isDestructive;

  /// 便捷的弹出方法。
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? content,
    Widget? contentWidget,
    IconData? icon,
    Color? iconColor,
    String confirmLabel = '确认',
    String cancelLabel = '取消',
    bool showCancel = true,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => QuestDialog(
        title: title,
        content: content,
        contentWidget: contentWidget,
        icon: icon,
        iconColor: iconColor,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        showCancel: showCancel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = context.questColors;
    final shapeTokens = context.shapeTokens;
    final motionTokens = context.motionTokens;
    final elevations = context.questElevations;

    // 通过 ShapeTokens / MotionTokens 推断当前风味，避免引入额外 Provider。
    // Minecraft：按钮半径为 0 是其独有特征；Minimal：页面入场延迟为 0 且关闭粒子。
    final isMinecraft = shapeTokens.buttonRadius == 0;
    final isMinimal =
        motionTokens.pageEntranceDelay == Duration.zero && !motionTokens.enableParticles;
    final borderRadius = isMinecraft
        ? BorderRadius.zero
        : BorderRadius.circular(shapeTokens.dialogRadius);

    return SpringMotion.springTransition(
      // Minimal 风味关闭缩放入场，仅保留淡入，营造更克制的视觉节奏。
      beginScale: isMinimal ? 1.0 : 0.9,
      beginOffset: const Offset(0, 0.02),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: borderRadius,
            boxShadow: isMinecraft
                ? elevations.pixelBorder
                : elevations.highlighted,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 32,
                      color: iconColor ?? colors.brandPrimary,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (contentWidget != null || content != null) ...[
                    const SizedBox(height: 16),
                    contentWidget ??
                        Text(
                          content!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showCancel)
                        TextButton(
                          onPressed: onCancel ??
                              () => Navigator.of(context).pop(false),
                          child: Text(cancelLabel),
                        ),
                      if (showCancel) const SizedBox(width: 8),
                      FilledButton(
                        onPressed: onConfirm ??
                            () => Navigator.of(context).pop(true),
                        style: isDestructive
                            ? FilledButton.styleFrom(
                                backgroundColor: colors.misconceptionRed,
                                foregroundColor: colorScheme.onError,
                              )
                            : null,
                        child: Text(confirmLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
