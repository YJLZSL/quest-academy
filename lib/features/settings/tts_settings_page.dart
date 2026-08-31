import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/motion/spring_motion.dart';
import '../../core/providers/app_providers.dart';
import '../../features/ai/ai_providers.dart';
import '../../features/ai/tts_service.dart';
import '../../shared/widgets/quest_app_bar.dart';

/// TTS 设置页。
///
/// 提供语速调节、音色选择、试听功能。语音能力依赖系统 TTS 引擎，
/// 不同平台可用音色不同。
class TtsSettingsPage extends ConsumerStatefulWidget {
  /// 创建 TTS 设置页。
  const TtsSettingsPage({super.key});

  @override
  ConsumerState<TtsSettingsPage> createState() => _TtsSettingsPageState();
}

class _TtsSettingsPageState extends ConsumerState<TtsSettingsPage> {
  bool _initialized = false;
  double _rate = 0.5;
  String? _voice;
  List<Map<String, String>> _voices = [];
  bool _playing = false;
  SharedPreferences? _prefs;

  TtsService get _tts => ref.read(ttsServiceProvider);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final tts = _tts;
    _prefs = ref.read(sharedPreferencesProvider);
    // 等待 TTS 初始化完成（若尚未完成）。
    for (var i = 0; i < 10 && !tts.initialized; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;
    final savedRate = _prefs?.getDouble('tts_speech_rate');
    final savedVoice = _prefs?.getString('tts_voice');
    if (savedRate != null) {
      await tts.setSpeechRate(savedRate);
    }
    if (savedVoice != null && savedVoice.isNotEmpty) {
      await tts.setVoice(savedVoice);
    }
    if (!mounted) return;
    setState(() {
      _initialized = tts.initialized;
      _rate = tts.speechRate;
      _voice = tts.currentVoice;
      _voices = tts.voices;
      _playing = tts.status == TtsStatus.playing;
    });
  }

  Future<void> _setRate(double value) async {
    final tts = _tts;
    await tts.setSpeechRate(value);
    setState(() => _rate = value);
    await _prefs?.setDouble('tts_speech_rate', value);
  }

  Future<void> _setVoice(String? value) async {
    if (value == null || value.isEmpty) return;
    final tts = _tts;
    await tts.setVoice(value);
    setState(() => _voice = value);
    await _prefs?.setString('tts_voice', value);
  }

  Future<void> _playSample() async {
    final tts = _tts;
    setState(() => _playing = true);
    await tts.speak('你好，我是问学的 AI 学习助手。我可以朗读知识点、解析题目。');
    await Future<void>.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _playing = false);
  }

  Future<void> _stop() async {
    await _tts.stop();
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zhVoices = _voices.where((v) {
      final locale = v['locale']?.toLowerCase() ?? '';
      return locale.startsWith('zh') || locale.startsWith('cn');
    }).toList();
    final displayVoices = zhVoices.isNotEmpty ? zhVoices : _voices;

    return Scaffold(
      appBar: const QuestAppBar(title: Text('语音设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_initialized)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 16),
                    Text('正在初始化语音引擎…', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            '语速',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '拖动滑块调整朗读语速',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.speed, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _rate,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: _rate.toStringAsFixed(1),
                  onChanged: _initialized ? _setRate : null,
                ),
              ),
              Text('${_rate.toStringAsFixed(1)}x'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '音色',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            displayVoices.isEmpty
                ? '当前系统没有可用音色，将使用默认引擎。'
                : '选择朗读音色',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (displayVoices.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final voice in displayVoices)
                  ChoiceChip(
                    label: Text(voice['name'] ?? '未知'),
                    selected: _voice == voice['name'],
                    onSelected: _initialized
                        ? (_) => _setVoice(voice['name'])
                        : null,
                  ),
              ],
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _initialized ? (_playing ? _stop : _playSample) : null,
            icon: AnimatedSwitcher(
              duration: SpringMotion.fastDuration,
              child: _playing
                  ? const Icon(Icons.stop, key: ValueKey('stop'))
                  : const Icon(Icons.volume_up, key: ValueKey('play')),
            ),
            label: Text(_playing ? '停止试听' : '试听语音'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '说明',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '朗读功能使用系统自带的文本转语音引擎（TTS），不消耗 AI 额度。'
                    'Android 与 Windows 均支持语速调节；音色列表取决于系统已安装的语音包。',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
