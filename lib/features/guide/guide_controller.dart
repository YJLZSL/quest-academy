import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/app_providers.dart';
import 'guide_content.dart';

/// 教程完成状态。
///
/// 使用 SharedPreferences 持久化（键 `guide_completed` / `guide_version`），
/// **不新增数据库表**，因此不会影响既有数据结构与迁移路径。
class GuideState {
  const GuideState({
    required this.completed,
    required this.version,
  });

  /// 初始状态（未完成）。
  const GuideState.initial()
      : completed = false,
        version = 0;

  /// 用户是否已看过并完成教程。
  final bool completed;

  /// 用户完成时的教程内容版本。
  final int version;

  /// 教程内容是否有更新（已完成但版本落后于 [kGuideVersion]）。
  bool get hasUpdate => completed && version < kGuideVersion;

  GuideState copyWith({
    bool? completed,
    int? version,
  }) {
    return GuideState(
      completed: completed ?? this.completed,
      version: version ?? this.version,
    );
  }
}

/// 教程控制器：管理完成状态与内容版本的持久化。
///
/// 设计要点：
/// - 完成状态与「内容版本」一同记录，教程文案更新后可为老用户提示更新，
///   而不强行重置其完成状态；
/// - 所有写操作同步更新内存状态，UI 立即响应（无需等待异步完成）。
class GuideController extends StateNotifier<GuideState> {
  GuideController(this._prefs) : super(const GuideState.initial()) {
    _load();
  }

  final SharedPreferences _prefs;

  /// 完成状态持久化键。
  static const String _completedKey = 'guide_completed';

  /// 内容版本持久化键。
  static const String _versionKey = 'guide_version';

  void _load() {
    final completed = _prefs.getBool(_completedKey) ?? false;
    final version = _prefs.getInt(_versionKey) ?? 0;
    state = GuideState(completed: completed, version: version);
  }

  /// 标记教程已完成（记录当前内容版本）。
  Future<void> complete() async {
    state = state.copyWith(completed: true, version: kGuideVersion);
    await _prefs.setBool(_completedKey, true);
    await _prefs.setInt(_versionKey, kGuideVersion);
  }

  /// 标记为未完成——用于「重新查看」场景：
  /// 重置后设置页入口回到未完成态，用户再次走完即重新记录完成。
  Future<void> markIncomplete() async {
    state = state.copyWith(completed: false);
    await _prefs.setBool(_completedKey, false);
  }
}

/// 教程状态 Provider。
///
/// 依赖已初始化的 [sharedPreferencesProvider]，单例共享。
final guideControllerProvider =
    StateNotifierProvider<GuideController, GuideState>((ref) {
  return GuideController(ref.watch(sharedPreferencesProvider));
});
