import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/animation_utils.dart';
import '../../core/motion/spring_motion.dart';
import '../../core/theme/quest_gradients.dart';
import '../../core/theme/theme_flavor_provider.dart';
import 'animated_count_text.dart';

/// 连续学习火焰徽章。
///
/// 紧凑的火焰图标 + 天数数字组合，用于 AppBar 与首页 Hero 区。
/// - 活跃连续（days > 0）：streakFire 渐变 + 流光 shimmer。
/// - 未活跃（days == 0）：outline 色描边样式。
/// - 点击触发 [onTap]，并带有弹簧按压缩放反馈。
class StreakFlameBadge extends ConsumerWidget {
  const StreakFlameBadge({
    super.key,
    required this.days,
    required this.isActive,
    this.onTap,
  });

  /// 连续学习天数。
  final int days;

  /// 当前是否处于活跃连续状态。
  final bool isActive;

  /// 点击回调。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final gradients = context.questGradients;
    final colors = context.questColors;
    final flavor = ref.watch(themeFlavorProvider);
    final reduceMotion = AnimationUtils.reduceMotionOf(context);
    final fireColor = isActive ? colors.streakFire : theme.colorScheme.outline;

    Widget icon = Icon(
      Icons.local_fire_department_rounded,
      color: fireColor,
      size: flavor == ThemeFlavor.minecraft ? 20 : 22,
    );

    // 活跃状态下给火焰图标添加流光效果（minimal 除外）。
    if (isActive && flavor != ThemeFlavor.minimal && !reduceMotion) {
      icon = SpringMotion.shimmerGlow(
        glowColor: fireColor,
        period: const Duration(seconds: 2),
        child: icon,
      );
    }

    final countText = isActive
        ? ShaderMask(
            shaderCallback: (bounds) => gradients.streakFire.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            blendMode: BlendMode.srcIn,
            child: AnimatedCountText(
              value: days,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
              duration: const Duration(milliseconds: 800),
              curve: SpringMotion.entranceCurve,
            ),
          )
        : AnimatedCountText(
            value: days,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.colorScheme.outline,
            ),
            duration: const Duration(milliseconds: 800),
            curve: SpringMotion.entranceCurve,
          );

    return SpringMotion.scalePressFeedback(
      onTap: onTap,
      pressedScale: flavor == ThemeFlavor.minecraft ? 0.9 : 0.92,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(
            flavor == ThemeFlavor.minecraft ? 0 : 20,
          ),
          border: flavor == ThemeFlavor.minecraft
              ? Border.all(color: theme.colorScheme.outline, width: 2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            countText,
          ],
        ),
      ),
    );
  }
}
