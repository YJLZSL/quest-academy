import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/storage_providers.dart';
import 'ai_provider.dart';
import 'ai_provider_registry.dart';
import 'multimodal_service.dart';
import 'prompt_manager.dart';
import 'tts_service.dart';

/// [AiProviderRegistry] 提供者。
///
/// 单例依赖 [providerConfigRepositoryProvider]，应用生命周期内复用同一实例。
/// UI 与业务层通过该 registry 获取/切换 AI Provider。
final aiProviderRegistryProvider = Provider<AiProviderRegistry>((ref) {
  return AiProviderRegistry(
    ref.watch(providerConfigRepositoryProvider),
  );
});

/// 当前 AI Provider 提供者。
///
/// `FutureProvider` 自动处理异步加载：当用户配置变化后可通过 `invalidate`
/// 触发重新读取。返回 null 表示当前无可用 Provider（用户尚未配置任何服务商）。
final currentAiProviderProvider = FutureProvider<AiProvider?>((ref) async {
  final registry = ref.watch(aiProviderRegistryProvider);
  return registry.getProvider();
});

/// [PromptManager] 提供者。
///
/// 单例：首次被监听时创建 [PromptManager] 并预加载 assets 中的系统提示词。
/// UI 与业务层通过 `ref.watch(promptManagerProvider).whenData(...)` 取用，
/// 分级探索（简化/深入/图示）等辅助提示词可直接通过加载完成的实例生成。
final promptManagerProvider = FutureProvider<PromptManager>((ref) async {
  final manager = PromptManager();
  await manager.loadPrompts();
  return manager;
});

/// [TtsService] 提供者。
///
/// 单例：应用生命周期内复用同一 TTS 引擎。
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});

/// [MultimodalService] 提供者。
///
/// 单例：应用生命周期内复用同一图片/文件选择服务。
final multimodalServiceProvider = Provider<MultimodalService>((ref) {
  return MultimodalService();
});
