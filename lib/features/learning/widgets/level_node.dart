// ignore_for_file: lines_longer_than_80_lines

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/animation_utils.dart';
import '../../../core/motion/spring_motion.dart';
import '../../../core/theme/quest_colors.dart';
import '../../../core/theme/theme_flavor_provider.dart';
import '../../../data/models/course_content.dart';
import '../course_level_extensions.dart';

/// 关卡节点状态。
enum LevelNodeState {
  /// 锁定：尚未到达该级别。
  locked,

  /// 当前：正在进行该级别学习。
  current,

  /// 已完成：该级别课程全部完成。
  completed,
}

/// 学习路径上的单个关卡节点。
///
/// 展示 L0-L4 级别，根据状态显示不同视觉：
/// - [standard]： glossy 圆形渐变节点，当前节点带呼吸脉动。
/// - [minecraft]：像素方块节点，厚边框，当前节点上下浮动。
/// - [minimal]：扁平圆点，低对比度，无动画。
class LevelNode extends ConsumerStatefulWidget {
  const LevelNode({
    super.key,
    required this.level,
    this.state = LevelNodeState.locked,
    this.size = 56,
    this.onTap,
  });

  /// 课程级别。
  final CourseLevel level;

  /// 节点状态。
  final LevelNodeState state;

  /// 节点直径。
  final double size;

  /// 点击回调。
  final VoidCallback? onTap;

  @override
  ConsumerState<LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends ConsumerState<LevelNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.state == LevelNodeState.current &&
        !AnimationUtils.platformReduceMotion) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant LevelNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isCurrent = widget.state == LevelNodeState.current;
    final wasCurrent = oldWidget.state == LevelNodeState.current;
    if (isCurrent && !wasCurrent && !AnimationUtils.reduceMotionOf(context)) {
      _pulseController.repeat(reverse: true);
    } else if (!isCurrent && wasCurrent) {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flavor = ref.watch(themeFlavorProvider);
    final colors = context.questColors;
    final theme = Theme.of(context);
    final levelColor = widget.level.levelColor(colors);
    final reduceMotion = AnimationUtils.reduceMotionOf(context);

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        levelColor,
        levelColor.withValues(alpha: 0.75),
      ],
    );

    final icon = _levelIcon(widget.level);
    final isLocked = widget.state == LevelNodeState.locked;
    final isCompleted = widget.state == LevelNodeState.completed;
    final isCurrent = widget.state == LevelNodeState.current;

    Widget node;
    if (flavor == ThemeFlavor.minecraft) {
      node = _buildMinecraftNode(
        levelColor: levelColor,
        icon: icon,
        isLocked: isLocked,
        isCompleted: isCompleted,
        isCurrent: isCurrent,
      );
    } else if (flavor == ThemeFlavor.minimal) {
      node = _buildMinimalNode(
        levelColor: levelColor,
        icon: icon,
        isLocked: isLocked,
        isCompleted: isCompleted,
      );
    } else {
      node = _buildStandardNode(
        gradient: gradient,
        icon: icon,
        isLocked: isLocked,
        isCompleted: isCompleted,
        isCurrent: isCurrent,
      );
    }

    if (isCurrent && flavor != ThemeFlavor.minimal && !reduceMotion) {
      node = AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + 0.04 * math.sin(_pulseController.value * 2 * math.pi);
          return Transform.scale(scale: scale, child: child);
        },
        child: node,
      );
    }

    if (widget.onTap != null) {
      node = SpringMotion.scalePressFeedback(
        onTap: widget.onTap,
        pressedScale: flavor == ThemeFlavor.minecraft ? 0.88 : 0.92,
        child: node,
      );
    }

    return SizedBox(
      width: widget.size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: node),
          const SizedBox(height: 4),
          Text(
            _levelShortName(widget.level),
            style: theme.textTheme.labelSmall?.copyWith(
              color: isLocked
                  ? theme.colorScheme.outline
                  : theme.colorScheme.onSurface,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardNode({
    required Gradient gradient,
    required IconData icon,
    required bool isLocked,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    final colors = context.questColors;
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isLocked ? null : gradient,
        color: isLocked ? Colors.grey.withValues(alpha: 0.15) : null,
        border: isCurrent
            ? Border.all(color: colors.achievementGold, width: 3)
            : null,
        boxShadow: isLocked
            ? null
            : [
                BoxShadow(
                  color: (isCompleted ? colors.successGreen : colors.brandPrimary)
                      .withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      alignment: Alignment.center,
      child: isCompleted
          ? Icon(Icons.check_rounded, color: Colors.white, size: widget.size * 0.45)
          : Icon(
              icon,
              color: isLocked ? Colors.grey : Colors.white,
              size: widget.size * 0.4,
            ),
    );
  }

  Widget _buildMinimalNode({
    required Color levelColor,
    required IconData icon,
    required bool isLocked,
    required bool isCompleted,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: widget.size * 0.85,
      height: widget.size * 0.85,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLocked
            ? theme.colorScheme.surfaceContainerHighest
            : levelColor.withValues(alpha: 0.15),
        border: Border.all(
          color: isLocked ? theme.colorScheme.outline : levelColor,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: isCompleted
          ? Icon(Icons.check_rounded, color: levelColor, size: widget.size * 0.35)
          : Icon(
              icon,
              color: isLocked ? theme.colorScheme.outline : levelColor,
              size: widget.size * 0.3,
            ),
    );
  }

  Widget _buildMinecraftNode({
    required Color levelColor,
    required IconData icon,
    required bool isLocked,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    final colors = context.questColors;
    final theme = Theme.of(context);
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: isLocked ? colors.pixelDirt : levelColor,
        border: Border.all(
          color: isCurrent ? colors.achievementGold : colors.pixelWood,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: isCompleted
          ? Icon(Icons.check_rounded, color: Colors.white, size: widget.size * 0.45)
          : Icon(
              icon,
              color: isLocked ? theme.colorScheme.onSurfaceVariant : Colors.white,
              size: widget.size * 0.4,
            ),
    );
  }

  static IconData _levelIcon(CourseLevel level) => switch (level) {
        CourseLevel.l0 => Icons.child_care,
        CourseLevel.l1 => Icons.school,
        CourseLevel.l2 => Icons.auto_stories,
        CourseLevel.l3 => Icons.psychology,
        CourseLevel.l4 => Icons.emoji_events,
      };

  static String _levelShortName(CourseLevel level) => switch (level) {
        CourseLevel.l0 => 'L0',
        CourseLevel.l1 => 'L1',
        CourseLevel.l2 => 'L2',
        CourseLevel.l3 => 'L3',
        CourseLevel.l4 => 'L4',
      };
}
