import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_academy/core/providers/app_providers.dart';
import 'package:quest_academy/features/guide/guide_content.dart';
import 'package:quest_academy/features/guide/guide_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 构造带 mock SharedPreferences 的 ProviderContainer。
  Future<ProviderContainer> createContainer(
    Map<String, Object> initialValues,
  ) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('GuideController 初始状态', () {
    test('无持久化数据时为未完成', () async {
      final container = await createContainer(<String, Object>{});
      final state = container.read(guideControllerProvider);

      expect(state.completed, isFalse);
      expect(state.version, 0);
      expect(state.hasUpdate, isFalse);
    });

    test('已持久化完成状态与当前版本时恢复为已完成且无更新', () async {
      final container = await createContainer(<String, Object>{
        'guide_completed': true,
        'guide_version': kGuideVersion,
      });
      final state = container.read(guideControllerProvider);

      expect(state.completed, isTrue);
      expect(state.version, kGuideVersion);
      expect(state.hasUpdate, isFalse);
    });

    test('已完成但版本落后时 hasUpdate 为 true', () async {
      final container = await createContainer(<String, Object>{
        'guide_completed': true,
        'guide_version': kGuideVersion - 1,
      });
      final state = container.read(guideControllerProvider);

      expect(state.completed, isTrue);
      expect(state.hasUpdate, isTrue);
    });
  });

  group('GuideController 状态变更', () {
    test('complete 写入完成状态与当前内容版本', () async {
      final container = await createContainer(<String, Object>{});
      // 使用 container 内注入的那份 SharedPreferences，避免与 setMockInitialValues
      // 产生的另一个实例不一致。
      final prefs = container.read(sharedPreferencesProvider);

      await container.read(guideControllerProvider.notifier).complete();
      final state = container.read(guideControllerProvider);

      expect(state.completed, isTrue);
      expect(state.version, kGuideVersion);
      expect(state.hasUpdate, isFalse);
      // 确认真正落盘，而非仅内存状态。
      expect(prefs.getBool('guide_completed'), isTrue);
      expect(prefs.getInt('guide_version'), kGuideVersion);
    });

    test('markIncomplete 重置完成状态但保留版本记录', () async {
      final container = await createContainer(<String, Object>{
        'guide_completed': true,
        'guide_version': kGuideVersion,
      });

      await container.read(guideControllerProvider.notifier).markIncomplete();
      final state = container.read(guideControllerProvider);

      expect(state.completed, isFalse);
      // 版本记录保留，便于「重新查看」后再次完成时写入同版本。
      expect(state.version, kGuideVersion);
    });

    test('重新查看后可再次完成', () async {
      final container = await createContainer(<String, Object>{});
      final controller = container.read(guideControllerProvider.notifier);

      await controller.complete();
      expect(container.read(guideControllerProvider).completed, isTrue);

      await controller.markIncomplete();
      expect(container.read(guideControllerProvider).completed, isFalse);

      await controller.complete();
      expect(container.read(guideControllerProvider).completed, isTrue);
    });
  });

  group('GuideStep 内容', () {
    test('步骤数量与 id 唯一', () {
      expect(kGuideSteps, isNotEmpty);
      final ids = kGuideSteps.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('每步都有标题、摘要与要点', () {
      for (final step in kGuideSteps) {
        expect(step.title, isNotEmpty);
        expect(step.summary, isNotEmpty);
        expect(step.bullets, isNotEmpty);
      }
    });

    test('含跳转操作的步骤必须同时提供路由', () {
      for (final step in kGuideSteps) {
        if (step.actionLabel != null) {
          expect(step.actionRoute, isNotNull, reason: step.id);
        }
      }
    });
  });
}
