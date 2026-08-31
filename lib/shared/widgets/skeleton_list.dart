import 'package:flutter/material.dart';

import '../../core/motion/animation_utils.dart';
import '../../core/theme/quest_spacing.dart';
import '../../core/theme/shape_tokens.dart';
import 'shimmer_loading.dart';

/// 骨架屏样式。
enum SkeletonStyle {
  /// 列表项（头像 + 两行文字条），适用于对话/笔记/对话列表。
  listItem,

  /// 矩形卡片，适用于课程卡片、成就卡片、统计区块。
  card,
}

/// 统一列表骨架屏。
///
/// 用途：替代列表页加载时的裸 [CircularProgressIndicator]，让用户提前感知
/// 内容结构与大致数量，减少加载等待感。
///
/// 规范：
/// - 条目数默认 5，可通过 [itemCount] 调整；
/// - 尊重系统「减少动效」偏好：开启时关闭流光动画，仅保留静态占位；
/// - 间距统一取 [QuestSpacing]，与其他页面节奏一致。
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.style = SkeletonStyle.listItem,
    this.cardHeight = 140,
    this.padding,
    this.spacing,
  });

  /// 骨架条目数量。
  final int itemCount;

  /// 骨架样式。
  final SkeletonStyle style;

  /// 卡片样式的高度（[SkeletonStyle.card] 时生效）。
  final double cardHeight;

  /// 整体内边距。
  final EdgeInsetsGeometry? padding;

  /// 条目之间的间距；未指定时取 [QuestSpacing.md]（12）。
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final spacingValue = context.questSpacing;
    final enabled = !AnimationUtils.reduceMotionOf(context);
    final gap = spacing ?? spacingValue.md;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? EdgeInsets.all(spacingValue.lg),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: gap),
      itemBuilder: (context, index) {
        switch (style) {
          case SkeletonStyle.listItem:
            return ShimmerListItem(enabled: enabled);
          case SkeletonStyle.card:
            return ShimmerCard(
              height: cardHeight,
              enabled: enabled,
            );
        }
      },
    );
  }
}

/// 页面级骨架屏：标题条 + 若干内容区块。
///
/// 适用于设置/统计等信息分组型页面加载态。
class SkeletonPage extends StatelessWidget {
  const SkeletonPage({
    super.key,
    this.blockCount = 3,
    this.blockHeight = 110,
    this.showTitle = true,
    this.padding,
  });

  /// 内容区块数量。
  final int blockCount;

  /// 单个区块高度。
  final double blockHeight;

  /// 是否显示顶部标题条。
  final bool showTitle;

  /// 整体内边距。
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final spacing = context.questSpacing;
    final theme = Theme.of(context);
    final enabled = !AnimationUtils.reduceMotionOf(context);

    return SingleChildScrollView(
      padding: padding ?? EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTitle) ...[
            ShimmerLoading(
              enabled: enabled,
              child: Container(
                width: 180,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(context.shapeTokens.chipRadius),
                ),
              ),
            ),
            SizedBox(height: spacing.lg),
          ],
          for (var i = 0; i < blockCount; i++) ...[
            ShimmerCard(
              height: blockHeight,
              enabled: enabled,
            ),
            if (i < blockCount - 1) SizedBox(height: spacing.lg),
          ],
          // 避免骨架屏高度不足时视觉突兀。
          SizedBox(
            height: theme.textTheme.bodySmall?.fontSize ?? 12,
          ),
        ],
      ),
    );
  }
}
