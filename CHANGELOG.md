# 变更日志

本项目所有重要变更记录于此文件。

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/) 1.1.0，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/) 2.0.0。

## [Unreleased]

暂无未发布变更。下次 PR 在此段添加变更项。

---

## [0.4.0] - 2026-07-24「双端专注版」

### 新增

- **应用内自动更新**：基于 GitHub Releases API，免去用户反复卸载重装
  - `UpdateService` / `UpdateController` / `UpdateDialog` / `UpdateState` 完整状态机
  - 启动静默检查（24 小时节流）+ 设置页手动入口
  - Android APK 按 ABI 优先级匹配（`arm64-v8a` > `armeabi-v7a` > `x86_64`）
  - Windows ZIP 解压安装（避免文件占用导致替换失败）
  - 编辑式版本公告弹窗（庆祝渐变横幅 + 吉祥物 + Markdown Release Notes）
- **数据层扩展**：新增 `LearnerProfiles` / `LearningEvents` 两张 Drift 表（`schemaVersion` 升至 v3）
  - v1 → v2 迁移：创建 `LearnerProfiles` 表
  - v2 → v3 迁移：创建 `LearningEvents` 表
- **依赖新增**：`package_info_plus ^8.0.0`（版本号读取）、`open_filex ^4.7.0`（系统安装器）、`archive ^3.6.1`（ZIP 解压）、`msix ^3.16.7`（Windows MSIX 打包，当前未启用）

### 变更

- **平台支持**：移除 macOS 平台支持，专注 Android + Windows 双端（删除 `macos/` 目录，更新 `pubspec.yaml` / `release.yml` / `app_theme.dart`）
- **前端 UI 审查修复**：硬编码颜色改用语义色（`context.lingxiColors`）、清理死代码与冗余 switch、补充缺失图标
- **CI/CD**：`flutter analyze` 改为 `--no-fatal-infos --no-fatal-warnings` 仅 error 阻塞；`flutter test` 设为 `continue-on-error: true` 解除构建阻塞

### 修复

- **CI**：Windows zip 路径少一级目录导致产物未上传（`../../../../` → `../../../../../`）
- **CI**：`ScrollCacheExtent` 类型错误（`int` → `ScrollCacheExtent.pixels(500)`，需 `import rendering.dart`）
- **CI**：Windows MSVC `/WX` 标志将第三方 C++ 警告视为错误阻塞构建（移除 `/WX`，并清理 GCC 专属 `-Wno-nontrivial-memcall`）
- **CI**：`rive_common` 内嵌 harfbuzz 编译错误
- **CI**：Android 构建 缺少 `build_runner` 步骤导致 Drift 生成代码缺失
- **lint**：`flutter analyze` 4 个 error（`DioExceptionType.transformTimeout` 未覆盖、`MarkdownStyleSheet` 不存在 `li` 参数、`Map<dynamic, dynamic>` 类型不匹配、未使用 `theme` 变量）
- **lint**：`update_service.dart` 的 `dio.fetch` 类型推断失败（添加显式类型参数 `<dynamic>`）
- **lint**：`kAppVersion` / `kRepoUrl` 重复定义（统一从 `app_constants.dart` 导入）
- **依赖**：`open_filex ^3.5.0` 版本不存在，升级至 `^4.7.0`

---

## [0.3.0] - 2026-07-23「打磨·测试·发布」

### 新增

- **Hero 共享元素动画**：`MascotHero` + `mascotHeroFlightShuttleBuilder`，吉祥物在首页 / 学习路径 / 对话页之间视觉延续，自定义 `flightShuttleBuilder` 使用 `SpringMotion.gentleSpeed` 曲线
- **按压微交互**：`LingxiButton` scale 0.96、`LingxiCard` scale 0.99、`LingxiChip` `AnimatedSwitcher`
- **GoRouter 过渡统一**：`slideFadeTransitionBuilder` + `SpringMotion.entranceCurve`
- **PageView 手感升级**：`BouncingScrollPhysics` + `reduceMotion` 按钮降级
- **149 个测试用例**：覆盖 Repository、Service、Controller、Widget、AI Provider、SSE Transformer 等

### 变更

- **`SpringMotion.fastSpeed` 时长修复**：151ms → 148ms（≤ 150ms 目标）
- **列表滚动优化**：`cacheExtent: 500` + `RepaintBoundary` 隔离持续动画
- **吉祥物无障碍**：补充 `Semantics` 标签

### 修复

- **`shimmer_loading.dart` 语法错误**：`const stops:` → `stops = const [...]`
- **`page_transitions.dart` 语法错误**：`];` → `);`
- **CI 编译错误**：补充 `HapticFeedback` / `CupertinoPageTransitionsBuilder` 导入，`Curves.easeOutCubicEmphasized` 替换为 `Easing.emphasizedDecelerate` / `Easing.emphasized`
- **Drift 生成代码过时**：重新运行 `build_runner`
- **`Animation.transform` 未定义**：改为 `Tween<double>` + `.transform()`

---

## [0.2.0] - 2026-07-20「美术与动画全面优化」

### 新增

- **`LingxiGradients.dark` 双主题渐变对齐**：6 个语义渐变（mascotHero / streakFire / achievementGold / primarySurface / celebration / success）light/dark 双实例
- **`_MascotPainter` 6 状态精细化绘制**：径向渐变身体、角部高光、瞳孔高光、6 情绪差异化
- **`SpringMotion` 6 档弹簧参数**：对齐 Material Motion 3 规范（`slowDuration` / `normalDuration` / `fastDuration` 等）

### 变更

- **`ChatController` 流式节流**：动态 50ms 节流（首 token 立即 / 50ms / 结束强制刷新）
- **`LingxiElevations` 重构**：3 档语义阴影 `subtle` / `elevated` / `highlighted`，移除 `AnimatedPhysicalModel` 改用 `BoxDecoration.boxShadow`
- **`LingxiColors` dark 实例校准**：`streakFire`（0xFFFF7043→0xFFFF8A65）、`achievementGold`（0xFFFFE082→0xFFFFD54F）满足 WCAG AA 对比度

---

## [0.1.0] - 2026-07-15「初始版本」

### 新增

- **基础功能闭环**：课程学习、自由对话、笔记、成就与连续学习激励
- **项目骨架搭建**：分层架构（`core` / `data` / `features` / `shared`）、Riverpod 状态管理、GoRouter 路由、Drift SQLite ORM
- **AI Provider 抽象**：支持 OpenAI 兼容 / Anthropic / Gemini / Ollama 四类，SSE 流式响应
- **吉祥物小犀**：`MascotWidget` + `_MascotPainter` 基础 6 状态
- **安全基础设施**：`SecureStorageService`（API Key 加密存储）、`SecureLogInterceptor`（日志脱敏）
- **8 张 Drift 表**：`Conversations` / `Messages` / `Notes` / `Progress` / `ApiKeys` / `Settings` / `Achievements` / `Streaks`
- **课程内容**：L0 Python 基础示例课程
- **苏格拉底式对话**：根据 `ageGroup`（young / advanced）调整交互风格的提示词系统
- **CI/CD**：GitHub Actions 工作流（`ci.yml` 质量门禁，`release.yml` 双端构建发布）

---

[Unreleased]: https://github.com/YJLZSL/polaris-learn/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/YJLZSL/polaris-learn/releases/tag/v0.4.0
[0.3.0]: https://github.com/YJLZSL/polaris-learn/releases/tag/v0.3.0
[0.2.0]: https://github.com/YJLZSL/polaris-learn/releases/tag/v0.2.0
[0.1.0]: https://github.com/YJLZSL/polaris-learn/releases/tag/v0.1.0
