import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest_academy/core/motion/animation_utils.dart';
import 'package:quest_academy/core/motion/app_motion.dart';
import 'package:quest_academy/core/motion/spring_motion.dart';
import 'package:quest_academy/core/theme/motion_tokens.dart';
import 'package:quest_academy/core/theme/quest_colors.dart';
import 'package:quest_academy/core/theme/quest_spacing.dart';
import 'package:quest_academy/core/theme/shape_tokens.dart';
import 'package:quest_academy/shared/utils/responsive.dart';
import 'package:quest_academy/shared/widgets/quest_app_bar.dart';
import 'package:quest_academy/shared/widgets/quest_button.dart';

import 'guide_content.dart';
import 'guide_controller.dart';

/// 应用内「新手教程」页（设置 → 新手教程）。
///
/// 交互设计：
/// - **分步引导**：5 步 PageView，顶部有步骤指示器（进度条 + 圆点 + 文字），
///   底部有「上一步 / 下一步」，最后一步为「完成」；
/// - **可跳过**：任意步骤均可点击右上角「跳过」，直接标记完成并退出；
/// - **可重新查看**：完成后再次进入显示完成态，提供「重新查看」从头开始；
/// - **完成状态持久化**：由 [GuideController] 写入 SharedPreferences，
///   并记录内容版本，教程更新后可提示「有更新」。
///
/// 动效：步骤切换 250ms（与全局一致），内容交错入场，reduceMotion 时降级。
class GuidePage extends ConsumerStatefulWidget {
  const GuidePage({super.key});

  @override
  ConsumerState<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends ConsumerState<GuidePage> {
  late final PageController _pageController;
  int _current = 0;

  /// 本地完成标记：用于在本页内展示完成态（不依赖刷新 Provider）。
  bool _justFinished = false;

  bool get _isLast => _current == kGuideSteps.length - 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= kGuideSteps.length) return;
    _pageController.animateToPage(
      index,
      duration: SpringMotion.gentleDuration,
      curve: SpringMotion.defaultCurve,
    );
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _goTo(_current + 1);
    }
  }

  /// 完成教程：记录完成状态后展示完成态（不自动退出，便于用户回看）。
  Future<void> _finish() async {
    AnimationUtils.hapticLight();
    await ref.read(guideControllerProvider.notifier).complete();
    if (!mounted) return;
    setState(() => _justFinished = true);
  }

  /// 跳过：与完成等效，但立即返回上一页。
  Future<void> _skip() async {
    await ref.read(guideControllerProvider.notifier).complete();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  /// 重新查看：重置完成状态并回到第 1 步。
  Future<void> _restart() async {
    await ref.read(guideControllerProvider.notifier).markIncomplete();
    if (!mounted) return;
    setState(() {
      _justFinished = false;
      _current = 0;
    });
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AnimationUtils.reduceMotionOf(context);
    final motion = context.motionTokens;
    final steps = kGuideSteps;

    return Scaffold(
      appBar: QuestAppBar(
        title: const Text('新手教程'),
        actions: [
          if (!_justFinished)
            TextButton(
              onPressed: _skip,
              child: const Text('跳过'),
            ),
        ],
      ),
      body: SafeArea(
        child: _justFinished
            ? _FinishedView(onRestart: _restart)
            : Column(
                children: [
                  _StepIndicator(
                    current: _current,
                    total: steps.length,
                    reduceMotion: reduceMotion,
                    duration: AppMotion.resolve(
                      context,
                      AppMotion.mediumOf(context),
                    ),
                    curve: motion.curveStandard,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _current = i),
                      itemCount: steps.length,
                      itemBuilder: (context, index) {
                        return _GuideStepView(
                          key: ValueKey('guide_step_$index'),
                          step: steps[index],
                          isDesktop: Responsive.isDesktop(context),
                          isActive: index == _current,
                          reduceMotion: reduceMotion,
                        );
                      },
                    ),
                  ),
                  _buildBottomBar(context),
                ],
              ),
      ),
    );
  }

  /// 底部导航：上一步 / 圆点 / 下一步(完成)。
  Widget _buildBottomBar(BuildContext context) {
    final steps = kGuideSteps;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_current > 0)
            QuestButton(
              label: const Text('上一步'),
              icon: const Icon(Icons.arrow_back),
              variant: QuestButtonVariant.text,
              onPressed: () => _goTo(_current - 1),
            )
          else
            const SizedBox(width: 120),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(steps.length, (i) {
              final isActive = i == _current;
              return GestureDetector(
                onTap: () => _goTo(i),
                child: AnimatedContainer(
                  duration: AppMotion.resolve(
                    context,
                    AppMotion.shortOf(context),
                  ),
                  curve: context.motionTokens.curveStandard,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          QuestButton(
            label: Text(_isLast ? '完成' : '下一步'),
            icon: Icon(
              _isLast ? Icons.check_rounded : Icons.arrow_forward,
            ),
            onPressed: _next,
          ),
        ],
      ),
    );
  }
}

/// 顶部步骤指示器：进度条 + 圆点 + 「第 X 步 / 共 N 步」文字。
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.current,
    required this.total,
    required this.reduceMotion,
    required this.duration,
    required this.curve,
  });

  final int current;
  final int total;
  final bool reduceMotion;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.questSpacing;
    final progress = total == 0 ? 0.0 : (current + 1) / total;

    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.xl, spacing.md, spacing.xl, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '第 ${current + 1} 步 / 共 $total 步',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.16),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单个教程步骤视图。
///
/// 桌面端两列（左侧图标插画，右侧文字），移动端单列垂直排列。
/// 要点列表采用交错入场，避免整块文字同时出现带来的压迫感。
class _GuideStepView extends StatelessWidget {
  const _GuideStepView({
    super.key,
    required this.step,
    required this.isDesktop,
    required this.isActive,
    required this.reduceMotion,
  });

  final GuideStep step;
  final bool isDesktop;
  final bool isActive;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.questSpacing;

    final illustration = _StepIllustration(
      icon: step.icon,
      size: isDesktop ? 200 : 140,
      color: context.questColors.brandPrimary,
    );

    final content = SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 8 : spacing.xl,
        vertical: spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            step.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: spacing.md),
          Text(
            step.summary,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
          SizedBox(height: spacing.lg),
          for (var i = 0; i < step.bullets.length; i++) ...[
            AppStaggeredItem(
              index: isActive ? i : 0,
              distance: 12,
              child: _BulletRow(text: step.bullets[i]),
            ),
            if (i < step.bullets.length - 1) SizedBox(height: spacing.sm),
          ],
          if (step.tips != null) ...[
            SizedBox(height: spacing.lg),
            _TipsCard(text: step.tips!),
          ],
          if (step.actionLabel != null && step.actionRoute != null) ...[
            SizedBox(height: spacing.xl),
            QuestButton(
              label: Text(step.actionLabel!),
              icon: const Icon(Icons.arrow_outward),
              variant: QuestButtonVariant.tonal,
              onPressed: () => context.go(step.actionRoute!),
            ),
          ],
        ],
      ),
    );

    if (isDesktop) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.x2l,
          vertical: spacing.lg,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 240,
              child: Center(child: illustration),
            ),
            SizedBox(width: spacing.x2l),
            Expanded(child: content),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: spacing.lg),
          illustration,
          content,
        ],
      ),
    );
  }
}

/// 要点行：圆点 + 文本。
class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// 小贴士卡片。
class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.questSpacing;
    final colors = context.questColors;

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: colors.infoTeal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.shapeTokens.chipRadius),
        border: Border.all(
          color: colors.infoTeal.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 18,
            color: colors.infoTeal,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 步骤图标插画。
class _StepIllustration extends StatelessWidget {
  const _StepIllustration({
    required this.icon,
    required this.size,
    this.color,
  });

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.primary;
    final containerSize = size * 0.9;
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            iconColor.withValues(alpha: 0.20),
            iconColor.withValues(alpha: 0.06),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size * 0.42,
        color: iconColor,
      ),
    );
  }
}

/// 完成态视图：展示已完成，并提供「重新查看」入口。
class _FinishedView extends StatelessWidget {
  const _FinishedView({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.questSpacing;
    final colors = context.questColors;
    final reduceMotion = AnimationUtils.reduceMotionOf(context);

    Widget badge = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: colors.successGreen.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_rounded,
        size: 48,
        color: colors.successGreen,
      ),
    );
    if (!reduceMotion) {
      badge = SpringMotion.springTransition(
        beginScale: 0.8,
        duration: AppMotion.mediumOf(context),
        child: badge,
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            badge,
            SizedBox(height: spacing.xl),
            Text(
              '教程已完成',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.sm),
            Text(
              '随时可以在「设置 → 新手教程」重新查看。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.x2l),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                QuestButton(
                  label: const Text('重新查看'),
                  icon: const Icon(Icons.replay_rounded),
                  variant: QuestButtonVariant.tonal,
                  onPressed: onRestart,
                ),
                QuestButton(
                  label: const Text('返回设置'),
                  icon: const Icon(Icons.arrow_back),
                  variant: QuestButtonVariant.text,
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/settings');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
