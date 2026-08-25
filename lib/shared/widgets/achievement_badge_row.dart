// ignore_for_file: lines_longer_than_80_lines

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/animation_utils.dart';
import '../../core/motion/spring_motion.dart';
import '../../core/theme/quest_colors.dart';
import '../../core/theme/quest_gradients.dart';
import '../../core/theme/theme_flavor_provider.dart';

/// 成就徽章数据项。
class AchievementBadgeItem {
  const AchievementBadgeItem({
    required this.icon,
    required this.title,
    this.unlocked = true,
    this.progress = 1.0,
  });

  /// 徽章图标（通常为 emoji）。
  final String icon;

  /// 徽章标题。
  final String title;

  /// 是否已解锁。
  final bool unlocked;

  /// 解锁进度（0.0 - 1.0），未解锁时用于底部小进度条。
  final double progress;
}

/// 横向滚动的成就徽章行。
///
/// 展示最近解锁 / 即将解锁的成就徽章，每个徽章包含图标、标题、锁定遮罩。
/// - [standard]：圆形金渐变徽章、圆角、解锁动画。
/// - [minecraft]：方形金渐变徽章、厚边框、像素风格。
/// - [minimal]：扁平、低饱和、无动画。
class AchievementBadgeRow extends ConsumerWidget {
  const AchievementBadgeRow({
    super.key,
    required this.items,
    this.onTap,
    this.height = 116,
    this.itemWidth = 80,
  });

  /// 徽章数据列表。
  final List<AchievementBadgeItem> items;

  /// 整行点击回调（通常为跳转成就页）。
  final VoidCallback? onTap;

  /// 行高度。
  final double height;

  /// 单个徽章宽度。
  final double itemWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavor = ref.watch(themeFlavorProvider);
    final reduceMotion = AnimationUtils.reduceMotionOf(context);

    return SizedBox(
      height: height,
      child: SpringMotion.scalePressFeedback(
        onTap: onTap,
        pressedScale: 0.98,
        enableHaptic: false,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return _BadgeItem(
              item: item,
              width: itemWidth,
              flavor: flavor,
              reduceMotion: reduceMotion,
              index: index,
            );
          },
        ),
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.item,
    required this.width,
    required this.flavor,
    required this.reduceMotion,
    required this.index,
  });

  final AchievementBadgeItem item;
  final double width;
  final ThemeFlavor flavor;
  final bool reduceMotion;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.questColors;
    final gradients = context.questGradients;
    final isMinecraft = flavor == ThemeFlavor.minecraft;
    final isMinimal = flavor == ThemeFlavor.minimal;

    final shape = isMinecraft
        ? BoxShape.rectangle
        : BoxShape.circle;
    final borderRadius = isMinecraft ? BorderRadius.zero : null;

    final backgroundGradient = item.unlocked
        ? gradients.achievementGold
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surfaceContainerHighest,
              theme.colorScheme.surfaceContainerLow,
            ],
          );

    Widget badge = Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: shape,
              borderRadius: borderRadius,
              gradient: backgroundGradient,
              border: isMinecraft
                  ? Border.all(color: colors.pixelWood, width: 3)
                  : (isMinimal
                      ? Border.all(color: theme.colorScheme.outline)
                      : null),
              boxShadow: isMinimal || item.unlocked == false
                  ? null
                  : [
                      BoxShadow(
                        color: colors.achievementGold.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: Text(
              item.icon,
              style: TextStyle(
                fontSize: isMinecraft ? 22 : 26,
                color: item.unlocked
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: item.unlocked
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: isMinecraft ? 11 : 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (!item.unlocked) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: 48,
              height: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: item.progress,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.achievementGold),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    // 锁定遮罩
    if (!item.unlocked) {
      badge = Stack(
        alignment: Alignment.center,
        children: [
          badge,
          Positioned(
            top: 8,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: shape,
                borderRadius: borderRadius,
                color: Colors.black.withValues(alpha: 0.35),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.lock_outline_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
            ),
          ),
        ],
      );
    }

    if (reduceMotion) {
      return SizedBox(width: width, child: badge);
    }

    return SpringMotion.springTransition(
      beginScale: 0.9,
      beginOffset: const Offset(0, 0.05),
      duration: Duration(milliseconds: 300 + index * 50),
      child: SizedBox(width: width, child: badge),
    );
  }
}
