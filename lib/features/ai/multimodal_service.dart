import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// 多模态输入服务。
///
/// 封装图片选择、拍照、文件选择与编码为 Base64 Data URL 的能力，
/// 供对话页调用以构造带图片的 [ChatMessage]。
class MultimodalService {
  /// 创建服务实例。
  MultimodalService({
    ImagePicker? imagePicker,
    FilePicker? filePicker,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _filePicker = filePicker ?? FilePicker.platform;

  final ImagePicker _imagePicker;
  final FilePicker _filePicker;

  /// 从相机拍照并返回 Base64 Data URL。
  Future<String?> takePhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return _fileToBase64DataUrl(File(picked.path));
  }

  /// 从相册选择图片并返回 Base64 Data URL。
  Future<String?> pickImageFromGallery() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return _fileToBase64DataUrl(File(picked.path));
  }

  /// 选择文件（文档/图片）并返回内容。
  ///
  /// 若文件是图片，则返回 Base64 Data URL；
  /// 若文件是文本/PDF/Markdown 等可读文档，则返回文本内容；
  /// 其他类型返回 null。
  Future<String?> pickDocument() async {
    final result = await _filePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'txt', 'md', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes;
    final filePath = file.path;

    if (bytes == null && filePath == null) return null;

    final ext = path.extension(file.name).toLowerCase();
    final isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);

    if (isImage) {
      if (bytes != null) {
        return _bytesToBase64DataUrl(bytes, file.name);
      }
      return _fileToBase64DataUrl(File(filePath!));
    }

    // 文本类文档直接读取文本。
    if (ext == '.txt' || ext == '.md') {
      if (bytes != null) {
        return utf8.decode(bytes, allowMalformed: true);
      }
      return File(filePath!).readAsString();
    }

    // PDF 暂不解析内容，返回提示文本。
    if (ext == '.pdf') {
      return '[PDF 文档：${file.name}，已作为附件上传]';
    }

    return null;
  }

  /// 读取本地文件并编码为 Base64 Data URL。
  Future<String> _fileToBase64DataUrl(File file) async {
    final bytes = await file.readAsBytes();
    return _bytesToBase64DataUrl(bytes, file.path);
  }

  /// 将字节数组编码为 Base64 Data URL。
  String _bytesToBase64DataUrl(List<int> bytes, String fileName) {
    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
    final base64 = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64';
  }

  /// 将图片 Data URL 写入临时目录并返回本地文件路径。
  ///
  /// 用于 TTS 等需要先持久化图片的场景（当前未使用，保留扩展）。
  Future<File?> writeDataUrlToTemp(String dataUrl, {String? name}) async {
    final parsed = _parseBase64DataUrl(dataUrl);
    if (parsed == null) return null;
    final tempDir = await getTemporaryDirectory();
    final fileName = name ?? 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(base64Decode(parsed.base64Data));
    return file;
  }

  ({String mimeType, String base64Data})? _parseBase64DataUrl(String dataUrl) {
    final match = RegExp(r'^data:([^;]+);base64,(.+)$').firstMatch(dataUrl);
    if (match == null) return null;
    return (
      mimeType: match.group(1)!,
      base64Data: match.group(2)!,
    );
  }
}
