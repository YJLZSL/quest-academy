import 'package:flutter/material.dart';

import '../../core/motion/animation_utils.dart';
import '../../core/motion/app_motion.dart';
import '../../core/motion/spring_motion.dart';
import '../../core/theme/quest_colors.dart';
import '../../core/theme/quest_spacing.dart';
import 'quest_button.dart';

/// 统一错误/失败状态组件。
///
/// 用于列表页加载失败、操作失败等场景，替代裸露的 `Text('加载失败：$e')`。
///
/// 规范：
/// - 图标与强调色取自 [QuestColors.misconceptionRed]，与「常见误解」语义一致；
/// - 提供 [onRetry] 时展示「重试」按钮，让用户可自助恢复；
/// - 支持 [onAction] 提供次级引导（例如「去配置 API」）；
/// - 入场使用与空状态一致的柔和过渡，reduceMotion 时直接显示。
class QuestErrorState extends StatelessWidget {
  const QuestErrorState({
    super.key,
    required this.message,
    this.title = '出了点问题',
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
    this.retryLabel = '重试',
    this.actionLabel,
    this.onAction,
  });

  /// 错误描述。
  final String message;

  /// 标题，默认「出了点问题」。
  final String title;

  /// 图标。
  final IconData icon;

  /// 重试回调；为 null 时不展示重试按钮。
  final VoidCallback? onRetry;

  /// 重试按钮文案。
  final String retryLabel;

  /// 次级操作文案（可选）。
  final String? actionLabel;

  /// 次级操作回调（可选）。
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.questSpacing;
    final colors = context.questColors;
    final reduceMotion = AnimationUtils.reduceMotionOf(context);

    final content = Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.misconceptionRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 34,
                color: colors.misconceptionRed,
              ),
            ),
            SizedBox(height: spacing.lg),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null || onAction != null) ...[
              SizedBox(height: spacing.xl),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  if (onRetry != null)
                    QuestButton(
                      label: Text(retryLabel),
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: onRetry,
                    ),
                  if (onAction != null && actionLabel != null)
                    QuestButton(
                      label: Text(actionLabel!),
                      variant: QuestButtonVariant.tonal,
                      onPressed: onAction,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (reduceMotion) return content;
    return SpringMotion.slideFadeTransition(
      direction: AxisDirection.up,
      distance: 16,
      duration: AppMotion.mediumOf(context),
      curve: AppMotion.standardCurveOf(context),
      child: content,
    );
  }
}
