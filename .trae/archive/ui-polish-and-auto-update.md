# UI 视觉深度优化 + 双端自动更新

> 计划基于 frontend-design 理念（独特、精致、有意图）深度优化视觉层次，并从零搭建 Android + Windows 双端自动更新机制，让用户无需反复删除安装。

---

## 一、当前状态分析

### 1.1 UI 设计现状（探索结论）

**设计体系成熟度：高**。已构建完整的 ThemeExtension 令牌系统（LingxiColors/LingxiGradients/LingxiElevations 三组 light/dark 双实例）、6 档 SpringMotion 弹簧动效（对齐 Material 3）、35 种 ShapeVariants 形状矩阵、矢量绘制的"小犀"吉祥物（6 情绪状态深度业务联动）。

**已识别的视觉不足**：
1. `_LevelSection._levelGradient` 中 L0-L4 级别颜色硬编码（`#4FC3F7`/`#66BB6A`/`#FFA726`/`#EF5350`），违反"禁止硬编码颜色"约定
2. `MascotWidget._MascotPainter` 内部 20+ 颜色常量为 static const，未通过 `context.lingxiColors` 获取，无法随主题切换
3. `kAppVersion` 在 `settings_page.dart` 与 `app_constants.dart` 重复定义
4. `kRepoUrl` 在 `settings_page.dart` 硬编码，未走常量层
5. MSIX 版本（0.3.0.0）与 pubspec 版本（0.4.0）不一致（CI 已通过 `--version` 覆盖，非阻塞）

### 1.2 更新机制现状

**完全没有更新机制**。设置页"关于"区只有静态版本号展示和 GitHub 仓库链接复制，无"检查更新"入口，无版本对比逻辑，无下载安装流程。Grep 全量扫描 `lib/` 确认零更新相关代码。

**可复用现有依赖**：`dio`（HTTP 下载）、`path_provider`（下载路径）、`path`（路径拼装）、`shared_preferences`（节流缓存）、`http_mock_adapter`（测试 mock）、`flutter_riverpod`（状态管理）、`flutter_markdown`（更新日志渲染）。

**发布产物**（来自 release.yml）：
- Android：3 个 split APK（arm64-v8a/armeabi-v7a/x86_64）+ 1 个 AAB
- Windows：1 个 ZIP（必产出）+ 1 个 MSIX（尽力产出，`continue-on-error`）
- GitHub Release：tag 名作为标题，`generate_release_notes: true` 自动生成 changelog
- API 端点：`GET https://api.github.com/repos/YJLZSL/polaris-learn/releases/latest`

---

## 二、用户决策（已确认）

| 决策点 | 选择 |
|--------|------|
| UI 审查深度 | **深度优化视觉** — 基于 frontend-design 理念精炼视觉层次、修复硬编码、打造独特更新体验 UI |
| 更新检查时机 | **启动自动 + 手动入口** — 启动时 24 小时节流自动检查，设置页也有手动入口 |
| Windows 更新方案 | **两者结合** — 提供"自动更新（ZIP 替换）"和"前往下载页"两个选项 |

---

## 三、实施方案

### 模块 A：UI 视觉深度优化

#### A1. 提取级别颜色到 LingxiColors（修复硬编码）

**文件**：`lib/core/theme/lingxi_colors.dart`

**改动**：在 `LingxiColors` 类中新增 5 个级别语义色字段（light/dark 双实例），用于学习路径的 L0-L4 级别标识：

```dart
// 新增字段
final Color level0Sky;    // L0 入门：天蓝  light #4FC3F7 / dark #4FC3F7
final Color level1Green;  // L1 基础：翠绿  light #66BB6A / dark #81C784
final Color level2Amber;  // L2 进阶：琥珀  light #FFA726 / dark #FFB74D
final Color level3Coral;  // L3 高级：珊瑚  light #EF5350 / dark #EF9A9A
final Color level4Violet; // L4 专家：紫罗兰 light #AB47BC / dark #CE93D8
```

同步更新 `lerp` 与 `copyWith`。light/dark 值参考现有 `_levelGradient` 硬编码值，dark 实例适当提亮以满足 WCAG AA。

**文件**：`lib/features/learning/learning_path_page.dart`

**改动**：`_LevelSection._levelGradient` 从硬编码 `Color(0xFF...)` 改为读取 `context.lingxiColors.level0Sky` 等。移除文件内的级别色 Map。

#### A2. MascotWidget 关键色接入 ThemeExtension

**文件**：`lib/features/mascot/mascot_widget.dart`

**改动**：`_MascotPainter` 当前所有颜色为 static const，无法随主题切换。由于 CustomPainter 无 BuildContext，采用**通过构造函数注入主题色**的方案：

- `_MascotPainter` 新增 `required Color bodyTop, required Color bodyBottom, required Color bodyOuter` 等参数（仅对主题敏感的关键色，约 5-6 个）
- `MascotWidget.build` 中从 `context.lingxiColors` 读取 `mascotPrimary`/`mascotSecondary` 等，传入 `_MascotPainter`
- 保留 `static const` 的非主题色（如 `_capColor` 黑色、`_scleraColor` 白色，这些不随主题变化）
- `_MascotPainter` 的 `shouldRepaint` 增加颜色比较

**注意**：吉祥物身体径向渐变当前是 `#7C4DFF → #B39DDB → #5E35B1`，其中 `#7C4DFF` 已对应 `LingxiColors.mascotPrimary`。将 `_bodyTop`/`_bodyBottom`/`_bodyOuter` 改为从 ThemeExtension 获取，dark 模式下自动切换到 `#9D7CFF` 等校准值。

#### A3. 统一 kAppVersion 与 kRepoUrl 常量

**文件**：`lib/core/constants/app_constants.dart`

**改动**：新增仓库相关常量（供更新功能复用）：
```dart
const String kRepoOwner = 'YJLZSL';
const String kRepoName = 'polaris-learn';
const String kRepoUrl = 'https://github.com/YJLZSL/polaris-learn';
const String kGitHubApiBase = 'https://api.github.com';
const int kUpdateCheckIntervalHours = 24;
```

**文件**：`lib/features/settings/settings_page.dart`

**改动**：
- 删除第 21 行 `const kAppVersion = '0.4.0';` 和第 24 行 `const kRepoUrl = ...`
- 改为 `import '../../core/constants/app_constants.dart';` 并使用 `kAppVersion`、`kRepoUrl`

---

### 模块 B：自动更新功能（核心）

#### B1. 新增依赖

**文件**：`pubspec.yaml`

**改动**：在 dependencies 中添加：
```yaml
package_info_plus: ^8.0.0   # 运行时读取版本号（替代硬编码 kAppVersion）
open_filex: ^3.5.0          # Android 触发系统 APK 安装器
archive: ^3.6.1             # Windows ZIP 解压
```

同步更新 `AGENTS.md` 的依赖版本表。

#### B2. UpdateState 状态定义

**新文件**：`lib/features/update/update_state.dart`

```dart
enum UpdateStatus {
  idle,           // 初始/无操作
  checking,       // 正在检查 GitHub Release
  upToDate,       // 已是最新
  available,      // 发现新版本，等待用户决策
  downloading,    // 下载中
  downloaded,     // 下载完成，等待安装（Android）/等待应用退出重启（Windows）
  installing,     // 安装中（Windows ZIP 替换）
  error,          // 出错
  skipped,        // 用户跳过此版本
}

@immutable
class UpdateState {
  final UpdateStatus status;
  final ReleaseInfo? releaseInfo;     // 新版本元数据
  final double downloadProgress;      // 0.0-1.0
  final String? errorMessage;
  final String? skippedVersion;       // 用户跳过的版本号
  // ... copyWith / props
}

@immutable
class ReleaseInfo {
  final String version;         // 如 "0.4.0"（已去 v 前缀）
  final String tagName;         // 如 "v0.4.0"
  final String name;            // Release 标题
  final String body;            // Release notes (Markdown)
  final String? androidApkUrl;  // 匹配设备 ABI 的 APK 下载 URL
  final String? windowsZipUrl;  // Windows ZIP 下载 URL
  final int? apkSize;           // APK 文件大小（字节）
  final int? zipSize;           // ZIP 文件大小（字节）
  final DateTime publishedAt;
}
```

#### B3. UpdateService 核心服务

**新文件**：`lib/features/update/update_service.dart`

**职责**：纯逻辑层，无 Riverpod 依赖，可独立测试。

**方法**：
- `Future<ReleaseInfo?> fetchLatestRelease()` — 调用 GitHub API `GET /repos/YJLZSL/polaris-learn/releases/latest`，解析 JSON 为 `ReleaseInfo`。根据 `Platform.isAndroid`/`Platform.isWindows` 和设备 ABI 匹配正确的产物 URL。
- `Future<String> downloadFile(String url, String savePath, void Function(double) onProgress)` — 用 dio 的 `download()` 方法下载，回调进度。
- `Future<bool> installAndroidApk(String apkPath)` — 用 `open_filex` 触发系统安装器。
- `Future<void> installWindowsZip(String zipPath, String installDir)` — 用 `archive` 解压 ZIP，生成 `updater.bat` 批处理脚本，启动脚本后退出应用。
- `Future<String> getCurrentVersion()` — 用 `package_info_plus` 读取 `version`（如 "0.4.0"）。
- `int compareVersions(String v1, String v2)` — Semver 比较，返回 -1/0/1。

**GitHub API 调用细节**：
- URL：`https://api.github.com/repos/YJLZSL/polaris-learn/releases/latest`
- 请求头：`Accept: application/vnd.github+json`
- 解析 `tag_name`（去 `v` 前缀）、`name`、`body`、`published_at`、`assets[]`
- Android ABI 匹配：`Platform.androidArchitecture` → `arm64-v8a`(主流) / `armeabi-v7a` / `x86_64`，匹配 `assets[].name` 中的 ABI 字段
- Windows：匹配 `assets[].name` 包含 `windows-x64.zip`

**Windows ZIP 替换式更新批处理脚本**（`updater.bat`）：
```bat
@echo off
:: 等待主进程退出
timeout /t 2 /nobreak >nul
:: 备份旧文件
xcopy /E /I /Y "%INSTALL_DIR%" "%INSTALL_DIR%\..\backup_temp"
:: 覆盖新文件
xcopy /E /I /Y "%EXTRACT_DIR%\*" "%INSTALL_DIR%\"
:: 重启应用
start "" "%INSTALL_DIR%\lingxi_academy.exe"
:: 删除临时文件
rd /S /Q "%EXTRACT_DIR%"
```

Dart 端通过 `Process.run('cmd', ['/c', 'start', '', 'updater.bat'])` 启动后，调用 `exit(0)` 退出。

#### B4. UpdatePreferencesRepository（节流 + 跳过版本）

**新文件**：`lib/data/repositories/update_preferences_repository.dart`

**风格**：参考 `ProviderConfigRepository`（SharedPreferences 后端，非 Drift）。

**方法**：
- `DateTime? getLastCheckTime()` — 读取 `last_update_check_time`（ISO8601）
- `Future<void> setLastCheckTime(DateTime time)`
- `String? getSkippedVersion()` — 读取 `skipped_version`
- `Future<void> setSkippedVersion(String? version)` — null 表示清除跳过

**不新建 Drift 表**，避免 schemaVersion 迁移负担。

#### B5. UpdateController（状态机编排）

**新文件**：`lib/features/update/update_controller.dart`

**风格**：`StateNotifier<UpdateState>`，参考 `ChatController` / `SocraticModeNotifier`。

**方法**：
- `Future<void> checkForUpdate({bool force = false})` — 主入口。`force=true` 跳过节流（手动检查时）。流程：
  1. 设 `status = checking`
  2. 读 `package_info_plus` 获取当前版本
  3. 读 `UpdatePreferencesRepository.lastCheckTime`，若非 force 且未过 24 小时节流，直接返回
  4. 调 `UpdateService.fetchLatestRelease()`
  5. 比较版本：若 `<=` 当前版本，设 `status = upToDate`；若 `>` 且等于 `skippedVersion`，设 `status = skipped`；否则设 `status = available`
  6. 更新 `lastCheckTime`
  7. 出错设 `status = error`
- `Future<void> downloadUpdate()` — 设 `status = downloading`，调 `UpdateService.downloadFile()`，回调更新 `downloadProgress`。完成设 `status = downloaded`。
- `Future<void> installUpdate()` — Android 调 `installAndroidApk()`；Windows 调 `installWindowsZip()` 后 `exit(0)`。
- `void skipVersion()` — 设 `status = skipped`，写 `UpdatePreferencesRepository.skippedVersion`。
- `void reset()` — 重置为 `idle`。

**Provider 注册**：

**新文件**：`lib/features/update/update_providers.dart`

```dart
final updatePreferencesRepositoryProvider = Provider<UpdatePreferencesRepository>((ref) {
  return UpdatePreferencesRepository(ref.watch(sharedPreferencesProvider));
});

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

final updateControllerProvider = StateNotifierProvider<UpdateController, UpdateState>((ref) {
  return UpdateController(
    ref.watch(updateServiceProvider),
    ref.watch(updatePreferencesRepositoryProvider),
  );
});
```

#### B6. 更新提示弹窗 UI（frontend-design 重点）

**新文件**：`lib/features/update/update_dialog.dart`

**设计理念**：不是普通 AlertDialog，而是有吉祥物参与的**庆祝感更新体验**。采用 frontend-design 的"独特、精致、有意图"原则：

**视觉结构**：
- 使用 `LingxiDialog` 基础容器（roundedExtraLarge 28px 圆角）
- 顶部：吉祥物 `celebrate` 状态（160px）+ `LingxiGradients.celebration` 渐变背景光晕
- 标题："发现新版本 v{version}"，Quicksand 字体，headlineMedium
- 更新日志：`flutter_markdown` 渲染 `ReleaseInfo.body`，最大高度 240px 可滚动，surfaceContainerLow 背景
- 文件大小信息：小字显示"下载大小：约 {size} MB"
- 按钮区（Row）：
  - 左：`LingxiButton.text("稍后")` — 关闭弹窗
  - 中：`LingxiButton.outlined("跳过此版本")` — 调 `skipVersion()`
  - 右：`LingxiButton.filled("立即更新", pulse: true)` — 触发下载安装流程
- 入场动画：`SpringMotion.springTransition`（scale 0.9 + 淡入），吉祥物先于内容出现（staggered）

**Windows 额外选项**：当 `Platform.isWindows` 时，按钮区增加"前往下载页"选项（`LingxiButton.tonal`），用 `url_launcher`（或 dio 无法打开浏览器时用 `Process.run`）打开 GitHub Release 页面。

**下载进度态**：点击"立即更新"后，弹窗内容切换为下载进度视图：
- `AnimatedProgressBar`（线性，渐变填充，enablePulse）显示 `downloadProgress`
- 文字："正在下载... {percent}%"
- 取消按钮：`LingxiButton.text("取消")` — 中断下载，回到 `available` 状态

**下载完成态**（Android）：显示"下载完成，点击安装"，按钮变为"安装"，点击触发 `installUpdate()`。

**下载完成态**（Windows）：显示"下载完成，点击立即应用更新（应用将重启）"，按钮变为"应用并重启"，点击触发 `installUpdate()` → `exit(0)`。

#### B7. 设置页"检查更新"入口

**文件**：`lib/features/settings/settings_page.dart`

**改动**：在"关于"分区的"版本"项下方新增"检查更新"项：
```dart
SpringMotion.scalePressFeedback(
  onTap: () => _checkForUpdate(context, ref),
  child: const ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(Icons.system_update_outlined),
    title: Text('检查更新'),
    trailing: Icon(Icons.chevron_right, size: 18),
  ),
),
```

`_checkForUpdate` 方法：调 `ref.read(updateControllerProvider.notifier).checkForUpdate(force: true)`，监听状态变化，若 `available` 则显示 `UpdateDialog`，否则用 SnackBar 提示"已是最新版本"或"检查失败"。

#### B8. 应用启动自动检查

**文件**：`lib/app.dart` 或 `lib/features/home/home_page.dart`

**改动**：在 `HomePage` 的 `initState` 中（应用启动后首个用户可见页面），延迟 3 秒后触发静默检查：
```dart
@override
void initState() {
  super.initState();
  // 延迟 3 秒，避免与首屏渲染争抢资源
  Future.delayed(const Duration(seconds: 3), () {
    if (mounted) {
      ref.read(updateControllerProvider.notifier).checkForUpdate(force: false);
    }
  });
}
```

在 `HomePage.build` 中监听 `updateControllerProvider`，当 `status == available` 且非用户主动触发时，自动弹出 `UpdateDialog`（带节流：每次启动最多弹一次）。

#### B9. Android 平台配置

**文件**：`android/app/src/main/AndroidManifest.xml`

**改动**：在 `<manifest>` 标签内添加权限：
```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
```

**新文件**：`android/app/src/main/res/xml/file_paths.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-cache-path name="apk" path="." />
    <cache-path name="cache" path="." />
</paths>
```

**文件**：`android/app/src/main/AndroidManifest.xml`

**改动**：在 `<application>` 标签内添加 FileProvider：
```xml
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
```

#### B10. 测试

**新文件**：`test/features/update/update_service_test.dart`

**内容**：用 `http_mock_adapter` mock GitHub API 响应，测试：
- `fetchLatestRelease()` 解析正确
- `compareVersions()` semver 比较逻辑
- ABI 匹配逻辑（mock `Platform.androidArchitecture`）
- 下载进度回调

**新文件**：`test/features/update/update_controller_test.dart`

**内容**：mock `UpdateService` 和 `UpdatePreferencesRepository`，测试状态机流转：
- `checkForUpdate()` 节流逻辑
- `checkForUpdate(force: true)` 跳过节流
- 发现新版本 → `status = available`
- 跳过版本 → `status = skipped`
- 下载流程 → `downloading` → `downloaded`

---

## 四、文件变更清单

### 新增文件（9 个）
| 文件 | 用途 |
|------|------|
| `lib/features/update/update_state.dart` | 状态与数据模型 |
| `lib/features/update/update_service.dart` | GitHub API + 下载安装核心逻辑 |
| `lib/features/update/update_controller.dart` | StateNotifier 状态机 |
| `lib/features/update/update_providers.dart` | Provider 注册 |
| `lib/features/update/update_dialog.dart` | 更新提示弹窗 UI |
| `lib/data/repositories/update_preferences_repository.dart` | SharedPreferences 节流/跳过 |
| `android/app/src/main/res/xml/file_paths.xml` | FileProvider 路径 |
| `test/features/update/update_service_test.dart` | 服务测试 |
| `test/features/update/update_controller_test.dart` | 控制器测试 |

### 修改文件（8 个）
| 文件 | 改动 |
|------|------|
| `pubspec.yaml` | +3 依赖（package_info_plus, open_filex, archive） |
| `lib/core/constants/app_constants.dart` | +6 更新常量（kRepoOwner/kRepoName/kRepoUrl/kGitHubApiBase/kUpdateCheckIntervalHours） |
| `lib/core/theme/lingxi_colors.dart` | +5 级别色字段（level0Sky~level4Violet）+ lerp/copyWith |
| `lib/features/learning/learning_path_page.dart` | _levelGradient 改用 context.lingxiColors |
| `lib/features/mascot/mascot_widget.dart` | _MascotPainter 关键色改构造注入 |
| `lib/features/settings/settings_page.dart` | 移除重复 kAppVersion/kRepoUrl + 新增检查更新入口 |
| `lib/features/home/home_page.dart` | initState 启动自动检查 + 监听弹窗 |
| `android/app/src/main/AndroidManifest.xml` | +REQUEST_INSTALL_PACKAGES 权限 + FileProvider |
| `AGENTS.md` | 同步依赖版本表 |

---

## 五、假设与决策

1. **仓库地址确认**：`kRepoUrl = 'https://github.com/YJLZSL/polaris-learn'`，GitHub API 调用 `YJLZSL/polaris-learn`。此地址来自 `settings_page.dart` 现有定义，假设正确。
2. **不新建 Drift 表**：更新状态是临时的，用 SharedPreferences 足够，避免 schemaVersion 迁移。
3. **不硬编码 GitHub token**：未认证 API 限速 60 次/小时/IP，配合 24 小时节流足够。token 暴露客户端有安全风险。
4. **Windows 替换式更新无回滚**：第一版不做回滚保护（备份目录会创建但无自动回滚逻辑），后期可补充。
5. **Android ABI 优先级**：arm64-v8a（64位 ARM，主流）> armeabi-v7a（32位 ARM）> x86_64（模拟器）。
6. **版本比较用 Semver**：`0.4.0` vs `0.4.1`，比较 major.minor.patch 三段。预发布标签（如 `-beta`）暂不支持。
7. **更新弹窗不阻塞引导流程**：若 onboarding 未完成，不触发更新检查。
8. **dio 请求经过 SecureLogInterceptor**：保持一致性，虽然更新请求无敏感信息。

---

## 六、验证步骤

1. **静态分析**：`flutter analyze` 零 error（warnings 在 PR 中说明）
2. **单元测试**：`flutter test test/features/update/` 全部通过
3. **Android 手动验证**：
   - 构造一个"假新版本"（mock GitHub API 返回更高版本号），验证弹窗弹出
   - 验证 APK 下载到临时目录
   - 验证点击"安装"后系统安装器弹出
4. **Windows 手动验证**：
   - 同上 mock 验证弹窗
   - 验证 ZIP 下载与解压
   - 验证 `updater.bat` 生成正确
   - 验证应用退出后文件被替换并重启
5. **节流验证**：启动后 3 秒触发检查，24 小时内第二次启动不重复检查
6. **跳过版本验证**：点击"跳过此版本"后，下次启动不弹窗（除非有更新的版本）
7. **视觉验证**：
   - 更新弹窗在 light/dark 双主题下均美观
   - 吉祥物 celebrate 状态在新弹窗中正确显示
   - 下载进度条动画流畅（60fps）
   - `_LevelSection` 级别颜色在主题切换时正确变化
   - `MascotWidget` 身体颜色在 dark 模式下自动切换

---

## 七、实施顺序

1. **A3 统一常量**（前置清理，最小改动）
2. **A1 级别颜色提取**（修复硬编码）
3. **A2 MascotWidget 主题接入**（修复硬编码）
4. **B1 新增依赖** + **B9 Android 平台配置**（基础设施）
5. **B2 UpdateState** + **B4 UpdatePreferencesRepository**（数据层）
6. **B3 UpdateService**（核心逻辑）
7. **B5 UpdateController** + Provider 注册（状态层）
8. **B6 更新弹窗 UI**（frontend-design 重点）
9. **B7 设置页入口** + **B8 启动自动检查**（集成层）
10. **B10 测试**（质量保障）
11. 全量 `flutter analyze` + `flutter test` 验证
