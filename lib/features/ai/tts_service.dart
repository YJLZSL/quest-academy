import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS 播放状态。
enum TtsStatus { idle, playing, paused, stopped, error }

/// TTS 服务封装。
///
/// 基于 `flutter_tts` 提供跨平台（Android / Windows）文本转语音能力：
/// - 播放、暂停、停止
/// - 语速调节
/// - 可用音色列表与切换
/// - 状态监听
class TtsService {
  /// 创建服务并初始化引擎。
  TtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    _init();
  }

  final FlutterTts _tts;

  final _statusController = StreamController<TtsStatus>.broadcast();

  /// TTS 状态流。
  Stream<TtsStatus> get statusStream => _statusController.stream;

  TtsStatus _status = TtsStatus.idle;

  /// 当前 TTS 状态。
  TtsStatus get status => _status;

  double _speechRate = 0.5;

  /// 当前语速（0.0 ~ 1.0）。
  double get speechRate => _speechRate;

  String? _currentVoice;

  /// 当前选中的音色标识。
  String? get currentVoice => _currentVoice;

  List<Map<String, String>> _voices = [];

  /// 可用音色列表。
  List<Map<String, String>> get voices => List.unmodifiable(_voices);

  bool _initialized = false;

  /// 是否已初始化完成。
  bool get initialized => _initialized;

  Future<void> _init() async {
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() => _setStatus(TtsStatus.playing));
      _tts.setCompletionHandler(() => _setStatus(TtsStatus.idle));
      _tts.setCancelHandler(() => _setStatus(TtsStatus.stopped));
      _tts.setPauseHandler(() => _setStatus(TtsStatus.paused));
      _tts.setContinueHandler(() => _setStatus(TtsStatus.playing));
      _tts.setErrorHandler((msg) {
        debugPrint('TTS error: $msg');
        _setStatus(TtsStatus.error);
      });

      await _loadVoices();
      _initialized = true;
    } on Object catch (e) {
      debugPrint('TTS init failed: $e');
      _initialized = false;
    }
  }

  Future<void> _loadVoices() async {
    try {
      final dynamic voices = await _tts.getVoices;
      if (voices is List) {
        _voices = voices
            .whereType<Map<dynamic, dynamic>>()
            .map((v) {
              final name = v['name']?.toString() ?? '';
              final locale = v['locale']?.toString() ?? '';
              if (name.isEmpty) return null;
              return <String, String>{
                'name': name,
                'locale': locale,
              };
            })
            .whereType<Map<String, String>>()
            .toList();
      }
    } on Object catch (e) {
      debugPrint('TTS load voices failed: $e');
      _voices = [];
    }
  }

  void _setStatus(TtsStatus value) {
    _status = value;
    if (!_statusController.isClosed) {
      _statusController.add(value);
    }
  }

  /// 播放指定文本。
  ///
  /// 若当前正在播放，会先停止当前播放再开始新文本。
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    if (_status == TtsStatus.playing) {
      await stop();
    }
    await _tts.speak(text.trim());
  }

  /// 停止播放。
  Future<void> stop() async {
    await _tts.stop();
    _setStatus(TtsStatus.stopped);
  }

  /// 暂停播放（平台支持时）。
  Future<void> pause() async {
    await _tts.pause();
    _setStatus(TtsStatus.paused);
  }

  /// 设置语速（0.0 ~ 1.0）。
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _tts.setSpeechRate(_speechRate);
  }

  /// 设置音色。
  ///
  /// [voiceName] 来自 [voices] 中的 `name` 字段。
  Future<void> setVoice(String voiceName) async {
    if (voiceName.isEmpty) return;
    _currentVoice = voiceName;
    try {
      await _tts.setVoice(<String, String>{'name': voiceName});
    } on Object catch (e) {
      debugPrint('TTS setVoice failed: $e');
    }
  }

  /// 释放资源。
  Future<void> dispose() async {
    await _tts.stop();
    await _statusController.close();
  }
}
