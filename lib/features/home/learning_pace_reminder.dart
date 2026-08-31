import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest_academy/core/theme/quest_colors.dart';
import 'package:quest_academy/core/theme/shape_variants.dart';
import 'package:quest_academy/features/progress/streak_service.dart';
import 'package:quest_academy/shared/widgets/quest_card.dart';

/// 节奏提醒的语义强调色。
///
/// 使用语义枚举而非硬编码色值，实际颜色在 build 时从 [QuestColors] 解析，
/// 保证浅色/深色主题下均有足够对比度。
enum _PaceAccent { info, fire, success, gold, brand }

/// 学习节奏提醒 Widget。
///
/// 基于 Streak 数据，在首页展示个性化鼓励语或适度休息建议。
/// - Streak >= 7 天：持续学习鼓励 + 适度休息提醒
/// - Streak 3-6 天：保持势头鼓励
/// - Streak 1-2 天：刚开始学习的鼓励
/// - Streak 0：温和邀请回归
class LearningPaceReminder extends ConsumerWidget {
  const LearningPaceReminder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final questColors = context.questColors;

    return FutureBuilder<_PaceInfo>(
      future: _getPaceInfo(ref),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final info = snapshot.data!;
        final accentColor = _resolveAccent(questColors, info.accent);

        return QuestCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: ShapeVariants.roundedMedium.borderRadius,
                ),
                child: Icon(
                  info.icon,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_PaceInfo> _getPaceInfo(WidgetRef ref) async {
    try {
      final streakService = ref.read(streakServiceProvider);
      final streak = await streakService.getStreak();
      final days = streak.currentStreak;
      return _buildPaceInfo(days);
    } catch (_) {
      return _buildPaceInfo(0);
    }
  }

  _PaceInfo _buildPaceInfo(int streakDays) {
    if (streakDays >= 14) {
      return const _PaceInfo(
        icon: Icons.self_improvement_rounded,
        accent: _PaceAccent.info,
        title: '学习达人！记得适当休息',
        subtitle: '持续学习很棒，但大脑也需要休息来巩固记忆哦',
      );
    }
    if (streakDays >= 7) {
      return const _PaceInfo(
        icon: Icons.local_fire_department_rounded,
        accent: _PaceAccent.fire,
        title: '一周连续学习！势不可挡',
        subtitle: '坚持7天以上，你已经养成了良好的学习习惯',
      );
    }
    if (streakDays >= 3) {
      return const _PaceInfo(
        icon: Icons.trending_up_rounded,
        accent: _PaceAccent.success,
        title: '保持这个节奏！',
        subtitle: '再坚持几天就能养成稳定的学习习惯',
      );
    }
    if (streakDays >= 1) {
      return const _PaceInfo(
        icon: Icons.wb_sunny_rounded,
        accent: _PaceAccent.gold,
        title: '今天也在学习，很棒！',
        subtitle: '每天一小步，坚持就会看到进步',
      );
    }
    return const _PaceInfo(
      icon: Icons.waving_hand_rounded,
      accent: _PaceAccent.brand,
      title: '好久不见，欢迎回来！',
      subtitle: '从上次学的地方继续，重新开始永远不晚',
    );
  }

  /// 将语义强调色解析为当前主题下的实际颜色。
  Color _resolveAccent(QuestColors colors, _PaceAccent accent) {
    return switch (accent) {
      _PaceAccent.info => colors.infoTeal,
      _PaceAccent.fire => colors.streakFire,
      _PaceAccent.success => colors.successGreen,
      _PaceAccent.gold => colors.achievementGold,
      _PaceAccent.brand => colors.brandPrimary,
    };
  }
}

/// 节奏提醒信息。
class _PaceInfo {
  const _PaceInfo({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;

  /// 语义强调色（实际颜色由主题解析）。
  final _PaceAccent accent;

  final String title;
  final String subtitle;
}
