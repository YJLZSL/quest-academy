import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/motion_tokens.dart';
import 'spring_motion.dart';

/// 问学统一页面转场动画
///
/// 为 GoRouter 提供三种转场：
/// - [buildPage]：主转场（淡入 + 上移，基于 [slideFadeTransitionBuilder]）
/// - [buildSlidePage]：右滑入（对话子页面等）
/// - [buildModalPage]：底部滑入（编辑器等全屏模态）
///
/// 时长统一取自主题令牌 [MotionTokens]，保证与全局动效节奏一致：
/// - 主转场：入 300ms / 出 200ms
/// - 滑动与模态：入 250ms / 出 200ms
///
/// 自动检测 reduceMotion 无障碍设置并降级为即时切换（直接返回 child）。
class QuestPageTransitions {
  const QuestPageTransitions._();

  /// 统一的 slide + fade 过渡构建器。
  ///
  /// 作为 [CustomTransitionPage.transitionsBuilder] 使用，双端（Android /
  /// Windows）共享同一曲线与时长，确保视觉一致。
  ///
  /// - 入场曲线：[SpringMotion.entranceCurve]（easeOutCubic）
  /// - 位移：从下方 5% 滑入（[Offset] `(0.0, 0.05)` → `Offset.zero`）
  /// - 透明度：跟随 [animation] 完整淡入
  ///
  /// 当 `MediaQuery.disableAnimationsOf(context)` 为 true（reduceMotion）
  /// 时直接返回 [child]，降级为即时切换，无任何动画。
  static Widget slideFadeTransitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      return child;
    }
    final curved = CurvedAnimation(
      parent: animation,
      curve: SpringMotion.entranceCurve,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.05),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  /// 主转场：淡入 + 上移，基于 [slideFadeTransitionBuilder]。
  ///
  /// 适用于大多数页面切换。三端共享同一过渡曲线，reduceMotion 时即时切换。
  static CustomTransitionPage<T> buildPage<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    final motion = context.motionTokens;
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: slideFadeTransitionBuilder,
      transitionDuration: motion.durationLong,
      reverseTransitionDuration: motion.durationShort,
    );
  }

  /// 滑动转场：从右侧滑入（类似 iOS 页面推进）
  ///
  /// 适用于对话详情、笔记编辑器等子页面。
  static CustomTransitionPage<T> buildSlidePage<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    final motion = context.motionTokens;
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: _buildSlideTransition,
      transitionDuration: motion.durationMedium,
      reverseTransitionDuration: motion.durationShort,
    );
  }

  /// 模态转场：从底部滑入
  ///
  /// 适用于全屏模态页面。
  static CustomTransitionPage<T> buildModalPage<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    bool fullscreenDialog = true,
  }) {
    final motion = context.motionTokens;
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      fullscreenDialog: fullscreenDialog,
      transitionsBuilder: _buildModalTransition,
      transitionDuration: motion.durationMedium,
      reverseTransitionDuration: motion.durationShort,
    );
  }

  // ── 私有转场构建器 ──────────────────────────────────────

  static Widget _buildSlideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (SpringMotion.reduceMotionOf(context)) {
      return child;
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: SpringMotion.entranceCurve,
      reverseCurve: SpringMotion.exitCurve,
    );

    // 新页面从右滑入，旧页面向左微移（视差效果）
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.08, 0),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(
        opacity: curved,
        child: child,
      ),
    );
  }

  static Widget _buildModalTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (SpringMotion.reduceMotionOf(context)) {
      return child;
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: SpringMotion.entranceCurve,
      reverseCurve: SpringMotion.exitCurve,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(
        opacity: curved,
        child: child,
      ),
    );
  }

}
