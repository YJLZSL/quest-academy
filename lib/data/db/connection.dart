import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

/// 获取应用数据库文件位置，并执行一次旧版数据库迁移。
///
/// 在各平台的应用文档目录下创建 `quest_academy.db`。
///
/// v0.6.0 起应用改名为「问学 Quest Academy」后，数据库文件名由
/// `lingxi_academy.db` 改为 `quest_academy.db`。首次启动时若检测到
/// 新文件不存在而旧文件存在，会将旧文件**复制**到新文件名（复制而非移动，
/// 保留回退机会）。Android 端因包名变更（applicationId 变化）按包隔离，
/// 旧文件不可见，自动跳过迁移。
Future<File> getDatabaseFile({Directory? overrideDirectory}) async {
  final dbFolder = overrideDirectory ?? await getApplicationDocumentsDirectory();
  final newFile = File(p.join(dbFolder.path, 'quest_academy.db'));

  // 一次性迁移：新文件不存在且旧文件存在时复制旧数据。
  final legacyFile = File(p.join(dbFolder.path, 'lingxi_academy.db'));
  if (!await newFile.exists() && await legacyFile.exists()) {
    try {
      await legacyFile.copy(newFile.path);
    } catch (_) {
      // 复制失败不阻断启动（数据库会重新创建空库）。
    }
  }
  return newFile;
}

/// 创建一个懒加载的跨端数据库连接。
///
/// 实际数据库在第一次被访问时才会打开，避免阻塞应用启动。
LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dbFile = await getDatabaseFile();

    // Android 旧版本（< 7.0）需要显式加载 sqlite3 共享库。
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    return NativeDatabase.createInBackground(
      dbFile,
      logStatements: false, // 生产环境关闭 SQL 日志
    );
  });
}
