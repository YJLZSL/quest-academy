import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quest_academy/data/db/connection.dart';

/// `quest_academy.db` 迁移逻辑测试：覆盖「复制旧库 / 不覆盖新库 / 无旧库」三路径。
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('quest_db_migration_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  File legacyFile() => File('${tempDir.path}/lingxi_academy.db');
  File newFile() => File('${tempDir.path}/quest_academy.db');

  test('新文件不存在且旧文件存在时，复制旧数据到新文件', () async {
    await legacyFile().writeAsBytes([1, 2, 3, 4]);

    final file = await getDatabaseFile(overrideDirectory: tempDir);

    expect(file.path, contains('quest_academy.db'));
    expect(file.existsSync(), isTrue);
    expect(await file.readAsBytes(), [1, 2, 3, 4]);
    // 旧文件保留（复制而非移动，便于回退）
    expect(legacyFile().existsSync(), isTrue);
  });

  test('新文件已存在时，不覆盖新文件内容', () async {
    await legacyFile().writeAsBytes([9, 9, 9]);
    await newFile().writeAsBytes([1, 1, 1]);

    final file = await getDatabaseFile(overrideDirectory: tempDir);

    expect(await file.readAsBytes(), [1, 1, 1]);
  });

  test('旧文件不存在时，直接返回新文件路径且不创建', () async {
    final file = await getDatabaseFile(overrideDirectory: tempDir);

    expect(file.path, contains('quest_academy.db'));
    expect(file.existsSync(), isFalse);
    expect(legacyFile().existsSync(), isFalse);
  });
}
