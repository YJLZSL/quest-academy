# 前端 UI 检查修复 + 双端自动更新 执行计划

> 基于 trae-remote-official:frontend-design 理念审查前端 UI，修复已识别的视觉硬编码问题，并从零搭建 Android + Windows 双端自动更新机制，让用户无需反复删除安装。

---

## 一、当前状态分析（基于 Phase 1 探索）

### 1.1 UI 设计现状

**设计体系成熟度：高**。已构建完整的 ThemeExtension 令牌系统（LingxiColors/LingxiGradients/LingxiElevations 三组 light/dark 双实例）、6 档 SpringMotion 弹簧动效、35 种 ShapeVariants、矢量绘制的"小犀"吉祥物（6 情绪状态）。

**已识别的 3 处视觉不足（经实际代码验证）**：

| 问题 | 位置 | 现状 | 影响 |
|------|------|------|------|
| 1. 级别渐变硬编码 | [learning_path_page.dart](file:///d:/AIKFCC/AI%20%20Classroom/lib/features/learning/learning_path_page.dart) `_LevelSection._levelGradient`（L393-415） | 硬编码 `#4FC3F7`/`#66BB6A`/`#FFA726`/`#EF5350` | 主题切换时级别色不变；与同文件 L745 的 `levelColor()` 调用风格不一致 |
| 2. 吉祥物身体色未接入主题 | [mascot_widget.dart](file:///d:/AIKFCC/AI%20%20Classroom/lib/features/mascot/mascot_widget.dart) `_MascotPainter._bodyTop/_bodyBottom/_bodyOuter`（L401-403） | static const `#7C4DFF`/`#B39DDB`/`#5E35B1` | dark 模式下吉祥物身体不变色（LingxiColors.dark.mascotPrimary=`#9D7CFF` 未生效） |
| 3. 常量重复定义 | [settings_page.dart](file:///d:/AIKFCC/AI%20%20Classroom/lib/features/settings/settings_page.dart) L20-24 | 重复定义 `kAppVersion`、`kRepoUrl` | 与 [app_constants.dart](file:///d:/AIKFCC/AI%20%20Classroom/lib/core/constants/app_constants.dart) 冲突；自动更新功能需复用仓库常量 |

**关键修正（与原方案文档的差异）**：
- 原方案 A1 提议在 `LingxiColors` 新增 `level0Sky`~`level4Violet` 5 个字段。**经探索发现** [course_level_extensions.dart](file:///d:/AIKFCC/AI%20%20Classroom/lib/features/learning/course_level_extensions.dart) 已将 L0-L4 映射到现有语义色（mascotSecondary/socraticBlue/mascotPrimary/achievementGold/streakFire），且 `home_page.dart` 的 `_CourseProgressCard` 已正确使用 `course.level.levelColor(context.lingxiColors)`。
- **修正方案**：不新增 LingxiColors 字段（避免语义重复），改为让 `_levelGradient` 复用 `levelColor()` 派生同色系渐变，与 `home_page.dart` 风格统一。

### 1.2 更新机制现状

**完全没有更新机制**。Grep 全量扫描 `lib/` 确认零自动更新代码。设置页"关于"区只有静态版本号展示和 GitHub 仓库链接复制。

**可复用现有依赖**：`dio`、`path_provider`、`path`、`shared_preferences`、`http_mock_adapter`、`flutter_riverpod`、`flutter_markdown`。

**发布产物**（来自 [release.yml](file:///d:/AIKFCC/AI%20%20Classroom/.github/workflows/release.yml)）：
- Android：3 个 split APK（arm64-v8a/armeabi-v7a/x86_64）+ 1 个 AAB
- Windows：1 个 ZIP（必产出）+ 1 个 MSIX（尽力产出）
- GitHub Release：tag 名作为标题，`generate_release_notes: true`
- API 端点：`GET https://api.github.com/repos/YJLZSL/polaris-learn/releases/latest`

---

## 二、实施方案

### 模块 A：UI 视觉修复（3 项）

#### A1. 统一 learning_path_page 级别渐变（修复硬编码）

**文件**：`lib/features/learning/learning_path_page.dart`

**改动**：将 `_LevelSection._levelGradient(ThemeData theme)`（L393-415）改为接收 `LingxiColors`，使用 `widget.level.levelColor(colors)` 派生同色系渐变（主色 + 70% alpha），与 `home_page.dart` 的 `_CourseProgressCard`（L555-559）风格完全一致。

```dart
// 修改前：硬编码 5 组 hex
List<Color> _levelGradient(ThemeData theme) {
  return switch (level) {
    CourseLevel.l0 => [const Color(0xFF4FC3F7), const Color(0xFF29B6F6)],
    // ...
  };
}

// 修改后：复用 levelColor 派生
List<Color> _levelGradient(LingxiColors colors) {
  final base = level.levelColor(colors);
  return [base, base.withValues(alpha: 0.7)];
}
```

调用处（L430）同步改为 `_levelGradient(context.lingxiColors)`。删除未使用的 `theme` 参数传递。

#### A2. MascotWidget 身体色接入 ThemeExtension

**文件**：`lib/features/mascot/mascot_widget.dart`

**改动**：`_MascotPainter` 的 3 个主题敏感色（`_bodyTop`/`_bodyBottom`/`_bodyOuter`）改为构造函数注入，其余非主题色（黑色帽、白色巩膜等）保持 static const。

- `_MascotPainter` 新增 `required Color bodyTop, required Color bodyBottom, required Color bodyOuter` 参数
- `_bodyGradient` 从 static const 改为实例字段，在构造时根据传入色构建
- `MascotWidget.build` 中从 `context.lingxiColors` 读取：
  - light: `mascotPrimary(#7C4DFF)` / `mascotPrimary.withValues(alpha:0.8)` / `#5E35B1`（深紫，可硬编码为深色衍生）
  - dark: `mascotPrimary(#9D7CFF)` / `#B39DDB`（提亮）/ `#5E35B1`
  - 为简化，`bodyTop` 直接用 `lingxiColors.mascotPrimary`，`bodyBottom`/`bodyOuter` 用 `mascotPrimary` 的衍生色（`withValues(alpha:)` 或固定深色）
- `shouldRepaint` 增加颜色比较

**简化决策**：只注入 `bodyTop`（主色），`bodyBottom` 和 `bodyOuter` 在 painter 内部用 `bodyTop.withValues(alpha: 0.8)` 和固定深紫派生，避免传过多参数。这样 light/dark 切换时只需一个颜色参数变化。

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
- 删除 L20-24 的 `const kAppVersion = '0.4.0';` 和 `const kRepoUrl = ...`
- 添加 `import '../../core/constants/app_constants.dart';`
- 文件内引用改为 `kAppVersion`、`kRepoUrl`（已存在引用无需改名）

---

### 模块 B：自动更新功能（核心）

#### B1. 新增依赖

**文件**：`pubspec.yaml`

**改动**：在 dependencies 中添加：
```yaml
package_info_plus: ^8.0.0   # 运行时读取版本号
open_filex: ^3.5.0          # Android 触发系统 APK 安装器
archive: ^3.6.1             # Windows ZIP 解压
```

运行 `flutter pub get` 后同步更新 `AGENTS.md` 依赖版本表。

#### B2. UpdateState 状态定义

**新文件**：`lib/features/update/update_state.dart`

```dart
enum UpdateStatus {
  idle, checking, upToDate, available,
  downloading, downloaded, installing, error, skipped,
}

@immutable
class UpdateState {
  final UpdateStatus status;
  final ReleaseInfo? releaseInfo;
  final double downloadProgress;
  final String? errorMessage;
  final String? skippedVersion;
  // copyWith + props
}

@immutable
class ReleaseInfo {
  final String version;       // "0.4.0"（去 v 前缀）
  final String tagName;       // "v0.4.0"
  final String name;
  final String body;          // Markdown 更新日志
  final String? androidApkUrl;
  final String? windowsZipUrl;
  final int? apkSize;
  final int? zipSize;
  final DateTime publishedAt;
}
```

#### B3. UpdateService 核心服务

**新文件**：`lib/features/update/update_service.dart`

纯逻辑层，无 Riverpod 依赖，可独立测试。

**方法**：
- `Future<ReleaseInfo?> fetchLatestRelease()` — 调 `GET /repos/YJLZSL/polaris-learn/releases/latest`，解析 JSON。根据 `Platform.isAndroid`/`Platform.isWindows` 和设备 ABI 匹配产物 URL。
- `Future<String> downloadFile(String url, String savePath, void Function(double) onProgress)` — 用 dio.download()，回调进度。
- `Future<bool> installAndroidApk(String apkPath)` — 用 open_filex 触发系统安装器。
- `Future<void> installWindowsZip(String zipPath, String installDir)` — 用 archive 解压，生成 `updater.bat`，启动后 exit(0)。
- `Future<String> getCurrentVersion()` — 用 package_info_plus 读取 version。
- `int compareVersions(String v1, String v2)` — Semver 比较 -1/0/1。

**GitHub API 细节**：
- URL：`https://api.github.com/repos/YJLZSL/polaris-learn/releases/latest`
- 头：`Accept: application/vnd.github+json`
- 解析 `tag_name`（去 v）、`name`、`body`、`published_at`、`assets[]`
- Android ABI：`Platform.androidArchitecture` → arm64-v8a(主流)/armeabi-v7a/x86_64，匹配 `assets[].name`
- Windows：匹配 `assets[].name` 含 `windows-x64.zip`

**Windows updater.bat**：等待 2s → xcopy 覆盖 → 重启 exe → 清理临时目录。Dart 端 `Process.run('cmd', ['/c','start','','updater.bat'])` 后 `exit(0)`。

#### B4. UpdatePreferencesRepository（节流 + 跳过版本）

**新文件**：`lib/data/repositories/update_preferences_repository.dart`

风格参考 `ProviderConfigRepository`（SharedPreferences 后端，非 Drift）。**不新建 Drift 表**，避免 schemaVersion 迁移。

**方法**：
- `DateTime? getLastCheckTime()` / `setLastCheckTime(DateTime)`
- `String? getSkippedVersion()` / `setSkippedVersion(String?)`

#### B5. UpdateController + Provider 注册

**新文件**：`lib/features/update/update_controller.dart`

`StateNotifier<UpdateState>`，参考 `ChatController`。

**方法**：
- `checkForUpdate({bool force = false})` — 主入口。force 跳过节流。流程：设 checking → 读当前版本 → 读 lastCheckTime（非 force 且未过 24h 则返回）→ fetchLatestRelease → 比较版本 → 设 upToDate/available/skipped → 更新 lastCheckTime → 出错设 error
- `downloadUpdate()` — downloading → downloadFile(进度回调) → downloaded
- `installUpdate()` — Android: installAndroidApk; Windows: installWindowsZip + exit(0)
- `skipVersion()` — skipped + 写 skippedVersion
- `reset()` — idle

**新文件**：`lib/features/update/update_providers.dart`

```dart
final updatePreferencesRepositoryProvider = Provider<UpdatePreferencesRepository>((ref) {
  return UpdatePreferencesRepository(ref.watch(sharedPreferencesProvider));
});

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

final updateControllerProvider = StateNotifierProvider<UpdateController, UpdateState>((ref) {
  return UpdateController(
    ref.watch(updateServiceProvider),
    ref.watch(updatePreferencesRepositoryProvider),
  );
});
```

#### B6. 更新提示弹窗 UI（frontend-design 重点）

**新文件**：`lib/features/update/update_dialog.dart`

**设计理念**（遵循 frontend-design "独特、精致、有意图"原则）：不是普通 AlertDialog，而是有吉祥物参与的庆祝感更新体验。

**视觉结构**：
- 容器：`LingxiCard` 或 `Dialog`，roundedExtraLarge 28px 圆角
- 顶部：吉祥物 `MascotWidget(mood: MascotMood.celebrate, size: 120)` + `LingxiGradients.celebration` 渐变光晕背景
- 标题："发现新版本 v{version}"，headlineMedium，Quicksand 字体
- 更新日志：`flutter_markdown` 渲染 `ReleaseInfo.body`，最大高度 240px 可滚动，surfaceContainerLow 背景
- 文件大小：小字"下载大小：约 {size} MB"
- 按钮区（Row）：
  - `LingxiButton.text("稍后")` — 关闭
  - `LingxiButton.outlined("跳过此版本")` — skipVersion()
  - `LingxiButton.filled("立即更新", pulse: true)` — 触发下载安装
- 入场动画：`SpringMotion.springTransition`（scale 0.9 + 淡入），吉祥物先于内容 staggered 出现
- Windows 额外：`LingxiButton.tonal("前往下载页")` 打开 GitHub Release 页（用 `url_launcher` 或 Process.run）

**状态切换**：
- available 态：上述布局
- downloading 态：内容切换为 `AnimatedProgressBar`（渐变填充 + pulse）+ "正在下载... {percent}%" + 取消按钮
- downloaded 态（Android）：按钮变"安装"，点击 installUpdate()
- downloaded 态（Windows）：按钮变"应用并重启"，点击 installUpdate() → exit(0)

#### B7. 设置页"检查更新"入口

**文件**：`lib/features/settings/settings_page.dart`

**改动**：在"关于"分区"版本"项下方新增"检查更新"项：
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

`_checkForUpdate`：调 `ref.read(updateControllerProvider.notifier).checkForUpdate(force: true)`，监听状态，available 则显示 `UpdateDialog`，否则 SnackBar 提示"已是最新版本"/"检查失败"。

#### B8. 应用启动自动检查

**文件**：`lib/features/home/home_page.dart`

**改动**：在 `_HomePageState.initState` 中（已有 `WidgetsBinding.instance.addPostFrameCallback`），延迟 3 秒后触发静默检查：
```dart
Future.delayed(const Duration(seconds: 3), () {
  if (mounted) {
    ref.read(updateControllerProvider.notifier).checkForUpdate(force: false);
  }
});
```

在 `build` 中监听 `updateControllerProvider`，当 `status == available` 且本次启动未弹过时，自动弹出 `UpdateDialog`（用 `_UpdateShown` flag 防止重复）。

#### B9. Android 平台配置

**文件**：`android/app/src/main/AndroidManifest.xml`

**改动 1**：`<manifest>` 标签内添加权限：
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

**改动 2**：`<application>` 标签内添加 FileProvider：
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

用 `http_mock_adapter` mock GitHub API，测试：
- `fetchLatestRelease()` 解析正确
- `compareVersions()` semver 比较
- ABI 匹配逻辑
- 下载进度回调

**新文件**：`test/features/update/update_controller_test.dart`

mock UpdateService 和 UpdatePreferencesRepository，测试状态机：
- `checkForUpdate()` 节流
- `checkForUpdate(force: true)` 跳过节流
- 发现新版本 → available
- 跳过版本 → skipped
- 下载流程 → downloading → downloaded

---

## 三、文件变更清单

### 新增文件（9 个）
| 文件 | 用途 |
|------|------|
| `lib/features/update/update_state.dart` | 状态与数据模型 |
| `lib/features/update/update_service.dart` | GitHub API + 下载安装核心逻辑 |
| `lib/features/update/update_controller.dart` | StateNotifier 状态机 |
| `lib/features/update/update_providers.dart` | Provider 注册 |
| `lib/features/update/update_dialog.dart` | 更新提示弹窗 UI（frontend-design 重点） |
| `lib/data/repositories/update_preferences_repository.dart` | SharedPreferences 节流/跳过 |
| `android/app/src/main/res/xml/file_paths.xml` | FileProvider 路径 |
| `test/features/update/update_service_test.dart` | 服务测试 |
| `test/features/update/update_controller_test.dart` | 控制器测试 |

### 修改文件（7 个）
| 文件 | 改动 |
|------|------|
| `pubspec.yaml` | +3 依赖 |
| `lib/core/constants/app_constants.dart` | +5 更新常量 |
| `lib/features/learning/learning_path_page.dart` | _levelGradient 改用 levelColor 派生 |
| `lib/features/mascot/mascot_widget.dart` | _MascotPainter bodyTop 改构造注入 |
| `lib/features/settings/settings_page.dart` | 移除重复常量 + 新增检查更新入口 |
| `lib/features/home/home_page.dart` | initState 启动自动检查 + 监听弹窗 |
| `android/app/src/main/AndroidManifest.xml` | +权限 + FileProvider |
| `AGENTS.md` | 同步依赖版本表 |

---

## 四、假设与决策

1. **仓库地址**：`YJLZSL/polaris-learn`（来自 settings_page.dart 现有定义，假设正确）。
2. **不新建 Drift 表**：更新状态临时性，SharedPreferences 足够，避免 schemaVersion 迁移。
3. **不硬编码 GitHub token**：未认证 API 限速 60 次/小时/IP，配合 24h 节流足够。token 暴露客户端有安全风险。
4. **Windows 替换式更新无自动回滚**：第一版不做回滚保护（备份目录会创建但无自动回滚逻辑）。
5. **Android ABI 优先级**：arm64-v8a > armeabi-v7a > x86_64。
6. **版本比较用 Semver**：major.minor.patch 三段，不支持预发布标签。
7. **更新弹窗不阻塞 onboarding**：若引导未完成，不触发更新检查。
8. **dio 请求经 SecureLogInterceptor**：保持一致性，虽无敏感信息。
9. **A1 修正**：不新增 LingxiColors 字段，复用 `course_level_extensions.dart` 的 `levelColor()`，与 `home_page.dart` 统一。
10. **A2 简化**：只注入 `bodyTop` 主色，`bodyBottom`/`bodyOuter` 在 painter 内部用 alpha 派生，减少参数。

---

## 五、验证步骤

1. **静态分析**：`flutter analyze` 零 error（warnings 在 PR 说明）
2. **单元测试**：`flutter test test/features/update/` 全部通过
3. **Android 手动验证**：
   - mock GitHub API 返回更高版本，验证弹窗弹出
   - 验证 APK 下载到临时目录
   - 验证点击"安装"后系统安装器弹出
4. **Windows 手动验证**：
   - mock 验证弹窗
   - 验证 ZIP 下载与解压
   - 验证 `updater.bat` 生成正确
   - 验证应用退出后文件被替换并重启
5. **节流验证**：启动后 3s 触发检查，24h 内第二次启动不重复检查
6. **跳过版本验证**：点击"跳过此版本"后，下次启动不弹窗（除非有更新版本）
7. **视觉验证**：
   - 更新弹窗 light/dark 双主题美观
   - 吉祥物 celebrate 状态在弹窗中正确显示
   - 下载进度条 60fps
   - `learning_path_page` 级别色在主题切换时正确变化
   - `mascot_widget` 身体色在 dark 模式下自动切换为 `#9D7CFF`

---

## 六、实施顺序

1. **A3 统一常量**（前置清理，最小改动）
2. **A1 learning_path 级别渐变**（修复硬编码）
3. **A2 MascotWidget 主题接入**（修复硬编码）
4. **B1 新增依赖** + **B9 Android 平台配置**（基础设施）
5. **B2 UpdateState** + **B4 UpdatePreferencesRepository**（数据层）
6. **B3 UpdateService**（核心逻辑）
7. **B5 UpdateController** + Provider 注册（状态层）
8. **B6 更新弹窗 UI**（frontend-design 重点）
9. **B7 设置页入口** + **B8 启动自动检查**（集成层）
10. **B10 测试**（质量保障）
11. 全量 `flutter analyze` + `flutter test` 验证
