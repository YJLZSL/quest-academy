import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest_academy/features/ai/ai_providers.dart';
import 'package:quest_academy/shared/widgets/quest_toast.dart';

/// 多模态输入工具栏。
///
/// 提供拍照、相册、文件、语音输入入口，适配桌面与移动端宽度。
/// 内部封装图片/文件选择，将结果通过回调交给父组件。
class MultimodalInputToolbar extends ConsumerStatefulWidget {
  /// 创建工具栏。
  const MultimodalInputToolbar({
    super.key,
    required this.onImageSelected,
    required this.onDocumentText,
    required this.onVoiceText,
    this.enabled = true,
  });

  /// 图片已选择回调，参数为 Base64 Data URL 列表。
  final ValueChanged<List<String>> onImageSelected;

  /// 文档已选择并解析回调，参数为文档文本或描述。
  final ValueChanged<String> onDocumentText;

  /// 语音输入识别完成回调，参数为识别文本。
  final ValueChanged<String> onVoiceText;

  /// 是否可用。
  final bool enabled;

  @override
  ConsumerState<MultimodalInputToolbar> createState() =>
      _MultimodalInputToolbarState();
}

class _MultimodalInputToolbarState
    extends ConsumerState<MultimodalInputToolbar> {
  bool _busy = false;

  Future<void> _pickImage() async => _run(() async {
        final service = ref.read(multimodalServiceProvider);
        final url = await service.pickImageFromGallery();
        if (url != null && mounted) {
          widget.onImageSelected([url]);
        }
      });

  Future<void> _takePhoto() async => _run(() async {
        final service = ref.read(multimodalServiceProvider);
        final url = await service.takePhoto();
        if (url != null && mounted) {
          widget.onImageSelected([url]);
        }
      });

  Future<void> _pickDocument() async => _run(() async {
        final service = ref.read(multimodalServiceProvider);
        final text = await service.pickDocument();
        if (text != null && text.isNotEmpty && mounted) {
          widget.onDocumentText(text);
        }
      });

  Future<void> _voiceInput() async => _run(() async {
        // 语音输入当前通过系统输入法语音键盘实现；
        // 在 Android 上调用会触发键盘语音模式（若输入法支持）。
        // 更完整的 ASR 可在后续接入 OpenAI Whisper API。
        if (mounted) {
          widget.onVoiceText('');
          QuestToast.info(context, '请使用键盘语音输入（长按空格或麦克风图标）');
        }
      });

  Future<void> _run(Future<void> Function() action) async {
    if (!widget.enabled || _busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (e) {
      if (mounted) {
        QuestToast.error(context, '操作失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Platform.isAndroid || Platform.isIOS;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _ToolbarButton(
            icon: Icons.camera_alt_outlined,
            label: isMobile ? '拍照' : '拍照/截图',
            onPressed: widget.enabled && !_busy ? _takePhoto : null,
          ),
          _ToolbarButton(
            icon: Icons.image_outlined,
            label: '图片',
            onPressed: widget.enabled && !_busy ? _pickImage : null,
          ),
          _ToolbarButton(
            icon: Icons.description_outlined,
            label: '文件',
            onPressed: widget.enabled && !_busy ? _pickDocument : null,
          ),
          _ToolbarButton(
            icon: _busy ? Icons.mic_none : Icons.mic,
            label: '语音',
            onPressed: widget.enabled && !_busy ? _voiceInput : null,
            color: _busy ? theme.colorScheme.outline : theme.colorScheme.primary,
          ),
          if (_busy)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurfaceVariant;

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: effectiveColor),
      label: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: effectiveColor),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
