// ignore_for_file: lines_longer_than_80_lines

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest_academy/core/motion/animation_utils.dart';
import 'package:quest_academy/core/motion/spring_motion.dart';
import 'package:quest_academy/core/router/route_names.dart';
import 'package:quest_academy/core/theme/quest_colors.dart';
import 'package:quest_academy/core/theme/quest_gradients.dart';
import 'package:quest_academy/core/theme/shape_variants.dart';
import 'package:quest_academy/data/models/course_content.dart';
import 'package:quest_academy/data/providers/course_providers.dart';
import 'package:quest_academy/data/providers/db_providers.dart';
import 'package:quest_academy/data/repositories/progress_repository.dart';
import 'package:quest_academy/features/learning/course_level_extensions.dart';
import 'package:quest_academy/features/progress/achievement_service.dart';
import 'package:quest_academy/features/progress/celebration_service.dart';
import 'package:quest_academy/features/progress/streak_service.dart';
import 'package:quest_academy/shared/widgets/achievement_badge_row.dart';
import 'package:quest_academy/shared/widgets/animated_progress_bar.dart';
import 'package:quest_academy/shared/widgets/quest_app_bar.dart';
import 'package:quest_academy/shared/widgets/quest_button.dart';
import 'package:quest_academy/shared/widgets/quest_card.dart';
import 'package:quest_academy/shared/widgets/quest_error_state.dart';
import 'package:quest_academy/shared/widgets/quest_toast.dart';
import 'package:quest_academy/shared/widgets/skeleton_list.dart';
import 'package:quest_academy/shared/widgets/streak_flame_badge.dart';
import 'package:quest_academy/shared/widgets/xp_progress_ring.dart';
/// 首页：展示欢迎信息、连续学习天数、继续学习入口与快捷操作。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _streakDays = 0;
  final ScrollController _scrollController = ScrollController();

  /// 交错入场的起始延迟与步进
  static const Duration _staggerBaseDelay = Duration(milliseconds: 100);
  static const Duration _staggerStep = Duration(milliseconds: 40);
  static const Duration _staggerDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    // 延迟一帧后执行，确保 ref 可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordStudyActivity();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 记录今日学习活动，更新 streak 与成就。
  Future<void> _recordStudyActivity() async {
    try {
      final streakService = ref.read(streakServiceProvider);
      final streak = await streakService.recordStudyActivity();

      if (!mounted) return;
      setState(() => _streakDays = streak.currentStreak);

      // streak >= 3 时触发星光庆祝
      if (streak.currentStreak >= 3) {
        final size = MediaQuery.sizeOf(context);
        CelebrationService.instance.celebrate(
          CelebrationEvent(
            origin: Offset(size.width / 2, size.height * 0.35),
            type: CelebrationType.sparkles,
            particleCount: 24,
          ),
        );
      }

      // 检查 streak 相关成就
      await ref
          .read(achievementServiceProvider)
          .checkStreakAchievements(streak.currentStreak);
    } on Object {
      // DB 操作失败时静默处理，不影响首页展示
      if (mounted) {
        QuestToast.error(context, '学习记录同步失败，请稍后重试');
      }
    }
  }

  /// 计算指定索引项的交错延迟
  Duration _entranceDelayFor(int index) {
    return _staggerBaseDelay + _staggerStep * index;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradients = context.questGradients;
    final reduceMotion = AnimationUtils.reduceMotionOf(context);
    final isStreakActive = _streakDays > 0;

    return Scaffold(
      appBar: QuestAppBar(
        title: const Text('首页'),
        scrollController: _scrollController,
        actions: [
          StreakFlameBadge(
            days: _streakDays,
            isActive: isStreakActive,
            onTap: () => context.go(RouteNames.statisticsPath),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Hero 问候区（渐变背景）──
                _buildHeroSection(
                  colorScheme: colorScheme,
                  gradients: gradients,
                  reduceMotion: reduceMotion,
                ),

                const SizedBox(height: 24),

                // ── 2. 继续学习 CTA ──
                _buildContinueLearning(
                  theme: theme,
                  colorScheme: colorScheme,
                  reduceMotion: reduceMotion,
                ),

                const SizedBox(height: 28),

                // ── 3. 课程进度卡片 ──
                _SectionTitle(
                  title: '学习进度',
                  subtitle: '继续你的 AI 学习之旅',
                  entranceDelay: _entranceDelayFor(2),
                ),
                const SizedBox(height: 12),
                _buildCourseProgressCards(
                  theme: theme,
                  colorScheme: colorScheme,
                  startIndex: 3,
                ),

                const SizedBox(height: 20),

                // ── 4. 最近成就 ──
                _buildRecentAchievements(
                  entranceDelay: _entranceDelayFor(5),
                ),

                const SizedBox(height: 28),

                // ── 5. 快捷操作网格 ──
                _SectionTitle(
                  title: '快捷入口',
                  subtitle: '一键直达常用功能',
                  entranceDelay: _entranceDelayFor(6),
                ),
                const SizedBox(height: 12),
                _buildQuickActions(
                  theme: theme,
                  colorScheme: colorScheme,
                  startIndex: 7,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero 问候区 ──────────────────────────────────────────

  /// 桌面端断点：≥1024px 视为桌面布局（与全局 Responsive.isDesktop 一致）
  static const double _desktopBreakpoint = 1024;

  Widget _buildHeroSection({
    required ColorScheme colorScheme,
    required QuestGradients gradients,
    required bool reduceMotion,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= _desktopBreakpoint;

    // 副标题：今日日期（如 "7月20日 周日"）
    final now = DateTime.now();
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateStr = '${now.month}月${now.day}日 ${weekdays[now.weekday - 1]}';

    // 文字区域
    final textContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          '欢迎来到问学',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            height: 1.2,
          ),
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          dateStr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          '开启你的 AI 学习之旅',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
        ),
      ],
    );

    // 游戏化反馈区：XP 环 + 火焰徽章
    final gamificationRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _xpSummaryRing(),
        const SizedBox(width: 16),
        StreakFlameBadge(
          days: _streakDays,
          isActive: _streakDays > 0,
          onTap: () => context.go(RouteNames.statisticsPath),
        ),
      ],
    );

    final content = isDesktop
        ? Row(
            children: [
              Expanded(child: textContent),
              gamificationRow,
            ],
          )
        : Column(
            children: [
              textContent,
              const SizedBox(height: 20),
              gamificationRow,
            ],
          );

    return _StaggeredEntrance(
      delay: _entranceDelayFor(0),
      duration: _staggerDuration,
      reduceMotion: reduceMotion,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradients.primarySurface,
          borderRadius: ShapeVariants.roundedExtraLarge.borderRadius,
        ),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: content,
      ),
    );
  }

  /// 从学习进度计算 XP 并渲染 [XpProgressRing]。
  Widget _xpSummaryRing() {
    final progressRepo = ref.watch(progressRepositoryProvider);
    return FutureBuilder<int>(
      future: _computeTotalXp(progressRepo),
      builder: (context, snapshot) {
        final totalXp = snapshot.data ?? 0;
        const xpPerLevel = 100;
        final level = totalXp ~/ xpPerLevel;
        final currentXp = totalXp % xpPerLevel;
        return XpProgressRing(
          currentXp: currentXp,
          xpToNextLevel: xpPerLevel,
          level: level,
          size: 96,
          onTap: () => context.go(RouteNames.statisticsPath),
        );
      },
    );
  }

  /// 每个已完成知识点计 10 XP。
  Future<int> _computeTotalXp(ProgressRepository repo) async {
    final progressList = await repo.getAllProgress();
    final completed =
        progressList.where((p) => p.status == 'completed').length;
    return completed * 10;
  }

  /// 构建最近成就徽章行：展示最近解锁的 5 枚成就，不足时补位即将解锁的成就。
  Widget _buildRecentAchievements({required Duration entranceDelay}) {
    final achievementService = ref.watch(achievementServiceProvider);
    return FutureBuilder<List<AchievementWithProgress>>(
      future: achievementService.getAll(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const [];
        final unlocked = all.where((a) => a.unlocked).toList();
        final upcoming = all.where((a) => !a.unlocked).toList();
        // 优先展示最近解锁，再补位进度最高的未解锁成就。
        final display = [
          ...unlocked.take(5),
          ...upcoming.take(5 - unlocked.length.clamp(0, 5)),
        ];

        final items = [
          for (final a in display)
            AchievementBadgeItem(
              icon: a.achievement.icon,
              title: a.achievement.name,
              unlocked: a.unlocked,
              progress: a.progress,
            ),
        ];

        return _StaggeredEntrance(
          delay: entranceDelay,
          duration: _staggerDuration,
          reduceMotion: AnimationUtils.reduceMotionOf(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '最近成就',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(RouteNames.achievementsPath),
                    child: const Text('查看全部'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (items.isEmpty)
                Text(
                  '暂无成就，开始学习即可解锁',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                )
              else
                AchievementBadgeRow(
                  items: items,
                  onTap: () => context.go(RouteNames.achievementsPath),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── 继续学习 CTA ────────────────────────────────────────

  Widget _buildContinueLearning({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool reduceMotion,
  }) {
    return _StaggeredEntrance(
      delay: _entranceDelayFor(1),
      duration: _staggerDuration,
      reduceMotion: reduceMotion,
      child: QuestCard(
        variant: QuestCardVariant.primary,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: ShapeVariants.roundedMedium.borderRadius,
              ),
              child: Icon(
                Icons.play_circle_filled_rounded,
                size: 30,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '继续学习',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '从上次中断的地方继续',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            QuestButton(
              label: const Text('开始'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              variant: QuestButtonVariant.filled,
              size: QuestButtonSize.medium,
              pulse: !reduceMotion,
              onPressed: () {
                AnimationUtils.hapticMedium();
                context.go(RouteNames.learningPath);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── 课程进度卡片 ────────────────────────────────────────

  /// 为不同级别的课程生成图标
  static const _levelIcons = <CourseLevel, IconData>{
    CourseLevel.l0: Icons.code_rounded,
    CourseLevel.l1: Icons.auto_awesome_rounded,
    CourseLevel.l2: Icons.rocket_launch_rounded,
    CourseLevel.l3: Icons.psychology_rounded,
    CourseLevel.l4: Icons.architecture_rounded,
  };

  Widget _buildCourseProgressCards({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required int startIndex,
  }) {
    final coursesAsync = ref.watch(allCoursesProvider);

    return coursesAsync.when(
      data: (courses) {
        if (courses.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '暂无课程，请稍后再来',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < courses.length; i++)
              _CourseProgressCard(
                course: courses[i],
                index: startIndex + i,
                entranceDelay: _entranceDelayFor(startIndex + i),
                isLast: i == courses.length - 1,
              ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SkeletonList(
          style: SkeletonStyle.card,
          itemCount: 2,
          cardHeight: 88,
          padding: EdgeInsets.zero,
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: QuestErrorState(
          title: '课程加载失败',
          message: '暂时无法读取课程内容，可稍后重试。',
          onRetry: () => ref.invalidate(allCoursesProvider),
        ),
      ),
    );
  }

  // ── 快捷操作网格 ────────────────────────────────────────

  Widget _buildQuickActions({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required int startIndex,
  }) {
    final actions = _getQuickActions();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        // 48x48 图标容器 + 间距 + 文字 + 卡片 padding，需要更高格子
        childAspectRatio: 0.82,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) {
        final action = actions[i];
        final item = QuestCard(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          onTap: () {
            AnimationUtils.hapticLight();
            action.onTap(context);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 圆角方形图标容器：48x48 + BorderRadius.circular(12) + 语义色背景
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: action.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  action.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );

        // 卡片自身已有 hover/press 效果；外包交错入场动画
        return _StaggeredEntrance(
          delay: _entranceDelayFor(startIndex + i),
          duration: _staggerDuration,
          reduceMotion: AnimationUtils.reduceMotionOf(context),
          beginOffset: const Offset(0, 0.08),
          child: item,
        );
      },
    );
  }

  // ── 演示数据（已移除 _getDemoCourses，改用真实数据）────────────

  List<_QuickAction> _getQuickActions() {
    final questColors = context.questColors;
    return [
      _QuickAction(
        label: 'AI 对话',
        icon: Icons.chat_bubble_outline_rounded,
        // 苏格拉底引导蓝
        color: questColors.socraticBlue,
        onTap: (ctx) => ctx.go(RouteNames.chatListPath),
      ),
      _QuickAction(
        label: '我的笔记',
        icon: Icons.edit_note_rounded,
        // 品牌辅色 - 温暖橙
        color: questColors.brandSecondary,
        onTap: (ctx) => ctx.go(RouteNames.notesPath),
      ),
      _QuickAction(
        label: '成就',
        icon: Icons.emoji_events_outlined,
        // 成就金
        color: questColors.achievementGold,
        onTap: (ctx) => ctx.go(RouteNames.achievementsPath),
      ),
      _QuickAction(
        label: '统计',
        icon: Icons.bar_chart_rounded,
        // 品牌主色 - 星空紫
        color: questColors.brandPrimary,
        onTap: (ctx) => ctx.go(RouteNames.statisticsPath),
      ),
    ];
  }
}

// ── 课程进度卡片组件（从真实数据渲染）────────────────────

/// 单个课程进度卡片，从 [ProgressRepository] 实时查询完成率。
class _CourseProgressCard extends ConsumerWidget {
  const _CourseProgressCard({
    required this.course,
    required this.index,
    required this.entranceDelay,
    required this.isLast,
  });

  final Course course;
  final int index;
  final Duration entranceDelay;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progressRepo = ref.watch(progressRepositoryProvider);

    // 级别渐变：以 [CourseLevel.levelColor] 语义色为主色，配以 70% 透明度
    // 形成同色系渐变，避免硬编码十六进制色值。
    final levelColor = course.level.levelColor(context.questColors);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [levelColor, levelColor.withValues(alpha: 0.7)],
    );
    final icon =
        _HomePageState._levelIcons[course.level] ?? Icons.code_rounded;

    // 计算总知识点数用于统计
    final totalKnowledgePoints = course.modules.fold<int>(
      0,
      (sum, m) => sum + m.lessons.fold<int>(
        0,
        (s, l) => s + l.knowledgePoints.length,
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: FutureBuilder<double>(
        future: progressRepo.getCompletionRate(course.id),
        builder: (context, snapshot) {
          final progress = snapshot.data ?? 0.0;
          final levelLabel = _levelDisplayName(course.level);
          final subtitle = progress > 0
              ? '$levelLabel · 已完成 ${(progress * 100).round()}%'
              : '$levelLabel · $totalKnowledgePoints 个知识点';

          return QuestCard(
            animateEntrance: true,
            entranceDelay: entranceDelay,
            onTap: () {
              AnimationUtils.hapticLight();
              context.go(RouteNames.learningPath);
            },
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius:
                            ShapeVariants.roundedMedium.borderRadius,
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedProgressBar(
                  progress: progress,
                  height: 6,
                  borderRadius: 3,
                  gradient: gradient,
                  enablePulse: progress > 0 && progress < 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _levelDisplayName(CourseLevel level) {
    switch (level) {
      case CourseLevel.l0:
        return 'L0 入门';
      case CourseLevel.l1:
        return 'L1 进阶';
      case CourseLevel.l2:
        return 'L2 应用';
      case CourseLevel.l3:
        return 'L3 实践';
      case CourseLevel.l4:
        return 'L4 高阶';
    }
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final void Function(BuildContext) onTap;
}

// ── 交错入场组件 ────────────────────────────────────────

/// 简化版交错入场组件：淡入 + 上移 + 轻微缩放。
///
/// 当 [reduceMotion] 为 true 时直接返回 child。
class _StaggeredEntrance extends StatefulWidget {
  const _StaggeredEntrance({
    required this.child,
    required this.delay,
    required this.duration,
    required this.reduceMotion,
    this.beginOffset = const Offset(0, 0.06),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final bool reduceMotion;
  final Offset beginOffset;

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.reduceMotion) {
      _visible = true;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) {
      return widget.child;
    }
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: widget.duration,
      curve: SpringMotion.entranceCurve,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : widget.beginOffset,
        duration: widget.duration,
        curve: SpringMotion.entranceCurve,
        child: AnimatedScale(
          scale: _visible ? 1.0 : 0.96,
          duration: widget.duration,
          curve: SpringMotion.entranceCurve,
          child: widget.child,
        ),
      ),
    );
  }
}

// ── 段落标题组件 ──────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.entranceDelay,
  });

  final String title;
  final String subtitle;
  final Duration entranceDelay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reduceMotion = AnimationUtils.reduceMotionOf(context);

    return _StaggeredEntrance(
      delay: entranceDelay,
      duration: const Duration(milliseconds: 500),
      reduceMotion: reduceMotion,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
  }
}


