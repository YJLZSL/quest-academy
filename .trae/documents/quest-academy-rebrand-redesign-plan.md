# 「问学 Quest Academy」品牌改名 + 前端全面重设计实施计划

> 目标：将现有 Flutter AI 学习应用彻底改名为「问学 Quest Academy」（含全部技术标识符与文档描述），清理吉祥物与 rive 残留，并对全部页面做一次全面前端重设计，同时用 seedream 生成新品牌图标与启动图。
> 约束：Android + Windows 双端；遵循 AGENTS.md 安全红线与文档同步工作流；不引入新第三方依赖（seedream 仅为资产生成，不属于运行依赖）；每阶段通过 `flutter analyze` / 对应测试后再进入下一阶段。

---

## 一、Summary

本次改造做四件事：

1. **全面改名「问学 Quest Academy」**：pubspec 包名、Dart import、Android `applicationId`/`namespace`、Kotlin 包路径、Windows 工程名与 msix、数据库文件名、GitHub 仓库引用、全部文档（README / AGENTS.md / CHANGELOG / CONTRIBUTING / CODE_OF_CONDUCT / SECURITY / LICENSE / docs / .github CI），以及 `Lingxi*`/`lingxi*` 类名与文件名。
2. **吉祥物 / rive 残留清理**：lib 代码已移除吉祥物（未提交），本次清理 `pubspec.yaml` 死依赖 `rive`、删除 `docs/吉祥物设计.md`、删除 AGENTS.md 吉祥物两章及 README/架构/design-tokens 中的吉祥物描述。
3. **前端全面重设计**：主题 token 升级（新默认种子色 `questIndigo #3D5AFE`、排版、间距 token、柔和阴影）→ 共享组件视觉调优 → 全部页面（首页/学习路径/课时/对话/会话列表/笔记/成就/统计/设置/引导/帮助/更新弹窗）布局与视觉刷新。
4. **品牌资产生成**：用 seedream `GenerateImage` 生成新应用图标与启动图（含补齐当前缺失的 `splash_logo.png`），重跑 `flutter_launcher_icons` / `flutter_native_splash`。

版本：现有工作区 v0.5.0 游戏化重设计先提交为基线，本次改名+重设计发布为 **v0.6.0「问学」**。

---

## 二、Current State Analysis（现状基线，已调研确认）

| 项 | 现状 |
|----|------|
| Git 状态 | `main` 存在大量未提交改动：v0.5.0 游戏化重设计已在工作区（`lib/features/mascot/` 已删、新增 `theme_flavor_provider.dart`/`app_typography.dart`/`shape_tokens.dart`/`xp_progress_ring.dart`/`level_node.dart` 等、`assets/rive/.gitkeep` 已删） |
| lib 吉祥物 | 已彻底移除（grep `mascot|Mascot|MascotWidget|mascotControllerProvider` 在 lib/ 无结果） |
| rive 依赖 | `pubspec.yaml` 仍声明 `rive: ^0.13.13`，lib 无引用 → 死依赖 |
| 改名影响面 | `package:lingxi_academy` 引用 85 文件 / 410 处；`Lingxi*` 类 20+ 处；平台标识 6 个文件 |
| GitHub 引用 | `YJLZSL/polaris-learn` 出现在 `app_constants.dart`、README、CHANGELOG、CONTRIBUTING、SECURITY、CODE_OF_CONDUCT、`release.yml` |
| 数据库 | `connection.dart` 硬编码 `lingxi_academy.db`；Drift `LingxiDatabase` + 生成文件 `database.g.dart` |
| 种子色 | 三处默认 `#6750A4`（`app_theme.dart`、`theme_flavor_provider.dart`、`app_providers.dart`）；`SeedColorPresets` = starlightPurple/playfulCoral/playfulAqua/playfulLime |
| 图标 | `assets/images/app_icon.png` 存在；**`splash_logo.png` 缺失**（`flutter_native_splash` 引用导致 create 失败）；`design-assets/poco-app-icon/` 有旧图标先例 |
| 测试基线 | CI 存在 36 个预存失败用例（`continue-on-error`），改名与重设计不得新增失败 |

---

## 三、决策记录（决策完备，执行者无需再选择）

### D1 品牌与应用标识

| 维度 | 旧 | 新 |
|------|----|----|
| 中文显示名 | 波可学园 | **问学** |
| 英文品牌 | Poco Academy | **Quest Academy** |
| pubspec `name` | `lingxi_academy` | `quest_academy` |
| Dart import | `package:lingxi_academy/...` | `package:quest_academy/...` |
| Android `namespace`/`applicationId` | `com.lingxiacademy.lingxi_academy` | `com.questacademy.quest_academy` |
| Kotlin 包路径 | `com/lingxiacademy/lingxi_academy/` | `com/questacademy/quest_academy/` |
| Windows `project`/`BINARY_NAME` | `lingxi_academy` | `quest_academy` |
| Windows `OriginalFilename` | `lingxi_academy.exe` | `quest_academy.exe` |
| msix `identity_name` | `com.lingxiacademy.lingxiacademy` | `com.questacademy.quest_academy` |
| msix `display_name` / `publisher_display_name` | 波可学园 / Poco Academy | 问学 / Quest Academy |
| 版本 | 0.4.0（工作区 v0.5.0 未提交） | 基线提交 v0.5.0，本次发布 **v0.6.0**（`pubspec.yaml` version + `msix_version` 同步 `0.6.0.0`，`app_constants.dart` `kAppVersion`） |
| GitHub 仓库引用 | `YJLZSL/polaris-learn` | `YJLZSL/quest-academy` |

**影响提示（须写入 CHANGELOG/README「升级说明」）**：Android `applicationId` 变更后，旧包已装应用无法收到新包自动更新（Android 不允许跨 applicationId 覆盖），v0.4/v0.5 用户数据（SecureStorage/SharedPreferences/DB 按包隔离）不迁移。本项目 pre-1.0，接受该影响；Windows 端数据位于「文档目录」不按包隔离，通过 D4 迁移保留。

### D2 GitHub 仓库实际改名（外部协调，发布前置）

- 代码与文档统一指向 `YJLZSL/quest-academy`（`kRepoOwner`/`kRepoName`/`kRepoUrl` 是自动更新与"关于"页唯一数据源）。
- **发布前需用户到 GitHub 将仓库改名/新建为 `quest-academy`**（`Settings → Rename` 后旧链接自动重定向）。若不执行，自动更新会指向 404。本次实施只改代码与文档引用，不改 GitHub 实际仓库名（需用户/授权后操作）。

### D3 `Lingxi*` / `lingxi*` 类名与文件名映射

| 旧 | 新 |
|----|----|
| `LingxiApp` / `_LingxiAppState`（`lib/app.dart`） | `QuestApp` / `_QuestAppState` |
| `LingxiDatabase`（`database.dart`，含 `database.g.dart` 生成物） | `QuestDatabase` |
| `LingxiColors` / `LingxiColorsX`（`context.lingxiColors`） | `QuestColors` / `QuestColorsX`（`context.questColors`） |
| `LingxiGradients` / `context.lingxiGradients` | `QuestGradients` / `context.questGradients` |
| `LingxiElevations` / `LingxiElevationsX`（`context.lingxiElevations`） | `QuestElevations` / `QuestElevationsX`（`context.questElevations`） |
| `LingxiCard` / `LingxiCardVariant` | `QuestCard` / `QuestCardVariant` |
| `LingxiButton` / `LingxiButtonVariant` / `LingxiButtonSize` | `QuestButton` / `QuestButtonVariant` / `QuestButtonSize` |
| `LingxiChip` | `QuestChip` |
| `LingxiAppBar` | `QuestAppBar` |
| `LingxiDialog` | `QuestDialog` |
| `LingxiTextField` | `QuestTextField` |
| `LingxiToast` / `LingxiToastVariant` | `QuestToast` / `QuestToastVariant` |
| `LingxiBadge` | `QuestBadge` |
| `LingxiPageTransitions`（`page_transitions.dart`） | `QuestPageTransitions` |
| 私有 `_Lingxi*State` | `_Quest*State` |
| 文件 `lingxi_colors.dart`/`lingxi_gradients.dart`/`lingxi_elevations.dart` | `quest_colors.dart`/`quest_gradients.dart`/`quest_elevations.dart` |
| 文件 `lingxi_card.dart`/`lingxi_button.dart`/`lingxi_chip.dart`/`lingxi_app_bar.dart`/`lingxi_dialog.dart`/`lingxi_text_field.dart`/`lingxi_toast.dart`/`lingxi_badge.dart` | `quest_card.dart`/`quest_button.dart`/`quest_chip.dart`/`quest_app_bar.dart`/`quest_dialog.dart`/`quest_text_field.dart`/`quest_toast.dart`/`quest_badge.dart` |

**不改**：`ShapeTokens`/`MotionTokens`/`BackgroundTextures`/`AppTypography`（无 Lingxi 前缀）；Drift 表名与字段名（磁盘 schema 不变）；SharedPreferences 键名（`theme_flavor`/`seed_color` 等，保持兼容）；路由 path。

### D4 数据库文件名与迁移

- 新文件名：`quest_academy.db`。
- 迁移：`lib/data/db/connection.dart` 的 `getDatabaseFile()` 中，首次启动检测新文件不存在且旧 `lingxi_academy.db` 存在时，**一次性 copy** 旧文件到新文件（复制而非移动，保留回退机会）。
- Windows 数据因此保留；Android 新包按包隔离自动 no-op。**不递增 schemaVersion**（表结构未变）。
- 新增迁移测试三路径：新文件不存在+旧文件存在→复制成功；新文件已存在→不覆盖；旧文件不存在→正常新建。

### D5 新默认种子色与预设色

- 新默认种子色（`app_theme.dart` `seedColor`、`theme_flavor_provider.dart` 默认值、`app_providers.dart` 默认值三处同步）：**`Color(0xFF3D5AFE)`（questIndigo 求知靛蓝）**，与旧紫 #6750A4 清晰区隔。
- `SeedColorPresets`：
  | 名 | 值 |
  |----|----|
  | questIndigo（默认） | `0xFF3D5AFE` |
  | questTeal | `0xFF009688` |
  | questCoral | `0xFFFF6B6B` |
  | questAmber | `0xFFFFB300` |
- 同步 `docs/design-tokens.json` 的 `meta.seedColor` 与 `color.primary`。

### D6 视觉方向：问学「求知探索 · 学园风」

- **排版**：display 中文 ZCOOL KuaiLe（w700）、英文/数字 Fredoka（`google_fonts` 已支持，不新增依赖）；正文 Noto Sans SC；minimal 风味全部回退 Noto Sans SC + Roboto。标题字重统一 w700、letterSpacing 收敛（display -0.5 / headline -0.25 / title 0）。
- **间距**：**新增 `QuestSpacing extends ThemeExtension<QuestSpacing>`**（填补无 Dart 间距 token 缺口），取值 `xs4/sm8/md12/lg16/xl24/2xl32/3xl48/4xl64` + `context.questSpacing` 扩展；页面/组件逐步把硬编码 `SizedBox(height:16)` 等替换为 token。
- **阴影**：`QuestElevations` 三档保留；light 模式降低浑浊度（seed 色调极低饱和黑），dark 模式半透明 seed 色柔和辉光；`level0~4` 兼容层保留。
- **卡片**：统一大圆角（ShapeTokens）、去重影、以「浅色填充 + 细分隔线 + 高亮边缘」分层，减少廉价感。

### D7 图标与启动图（seedream）

- 用 seedream `GenerateImage` 生成「问学 Quest Academy」品牌图形（建议：圆角学士帽 + 翻开的书 + 指南针针尖 + 星光点缀，扁平 2D，indigo #3D5AFE 系，居中构图，纯品牌色背景；另生成一张含「问学」文字版本供选）。
- 落位：`assets/images/app_icon.png`（1024×1024）、`assets/images/splash_logo.png`（448×448，**补齐当前缺失**）。
- 生成后运行 `flutter pub run flutter_launcher_icons` 与 `flutter pub run flutter_native_splash:create`，重新生成 Android mipmap 系列与 `windows/runner/resources/app_icon.ico`。
- `pubspec.yaml` `flutter_native_splash.color` 由 `#6750A4` 改为 `#3D5AFE`（含 `android_12`）。
- 采用「品牌底色 + 居中图形」方案规避透明通道问题；保留旧 `app_icon.png` 可回滚。

### D8 rive 依赖移除

- `pubspec.yaml` 删除 `rive: ^0.13.13` → `flutter pub get` 更新 lock；Windows 构建 `generated_plugins.cmake` 自动不再含 rive_common；`windows/CMakeLists.txt` 注释中的 rive 描述改为通用说法；确认 `assets/rive/.gitkeep` 已删。

### D9 吉祥物残留文档处理

| 文件 | 处理 |
|------|------|
| `docs/吉祥物设计.md` | **删除** |
| `AGENTS.md` | 删「吉祥物集成约定」「吉祥物交互扩展规范」两章；依赖表删 rive；「已知技术债」删 Rive 行；「文档所有权矩阵」删吉祥物设计.md 行；「目录结构」删 mascot 注释 |
| `README.md` | 技术栈表删 rive 行；如有 mascot 文案一并清理 |
| `docs/架构设计.md` | 目录树删 `rive_mascot_widget.dart` 行 |
| `docs/design-tokens.json` | 删 `color.mascot` 分组、`gradient.mascotHero`、空状态吉祥物字样 |
| `.trae/` 归档、CHANGELOG 历史 | 保留为历史记录，不入改名范围（可文首加「已归档」标注） |

### D10 基线策略

先提交当前 v0.5.0 未提交改动为独立 commit（或独立分支），保证改名 diff 与重设计 diff 清晰可审。

---

## 四、Proposed Changes（分阶段文件级改动）

### Phase 0 — 基线提交

1. 确认工作区 v0.5.0 改动（`git status` 的 M/D/?? 项）无遗漏。
2. `flutter analyze`（零 error）+ `flutter test`（记录既有 36 失败清单为基线）。
3. 提交：`feat(redesign): 游戏化重设计与吉祥物移除（v0.5.0 Unreleased 基线）`。
4. 切分支 `feat/quest-rebrand`（禁止直推 main）。

### Phase 1 — 包名与应用标识改名（机械替换）

| 文件 | 改动 |
|------|------|
| `pubspec.yaml` | `name: quest_academy`；`description`：「问学 Quest Academy - 引导式 AI 学习应用」；`msix_config` 三项；`version: 0.6.0+1` |
| 全部 `lib/` 与 `test/` 文件 | `import 'package:lingxi_academy/...'` → `package:quest_academy/...`（85 文件 / 410 处） |
| `android/app/build.gradle.kts` | `namespace`、`applicationId` → `com.questacademy.quest_academy` |
| `android/app/src/main/kotlin/com/lingxiacademy/lingxi_academy/MainActivity.kt` | 目录与 `package` 改 `com/questacademy/quest_academy/` |
| `android/app/src/main/AndroidManifest.xml` | `android:label="问学"` |
| `windows/CMakeLists.txt` | `project(quest_academy ...)`、`set(BINARY_NAME "quest_academy")` |
| `windows/runner/main.cpp` | `window.Create(L"问学", ...)` |
| `windows/runner/Runner.rc` | `CompanyName com.questacademy`、`FileDescription/InternalName/ProductName 问学`、`OriginalFilename quest_academy.exe` |
| `lib/core/constants/app_constants.dart` | `kAppName='问学'`、`kRepoOwner='YJLZSL'`、`kRepoName='quest-academy'`、`kRepoUrl='https://github.com/YJLZSL/quest-academy'`、`kAppVersion='0.6.0'` |
| `.github/workflows/release.yml` | 产物名 `lingxi-academy-*` → `quest-academy-*`（约 9 处） |

### Phase 2 — `Lingxi*`/`lingxi*` 类名与文件名改名（Dart）

- 建议用 IDE Rename Symbol / Rename File 原子化执行（连带 import 同步），完成后全仓 grep 校验白名单。
- 主题层：`lingxi_colors.dart`→`quest_colors.dart`、`lingxi_gradients.dart`→`quest_gradients.dart`、`lingxi_elevations.dart`→`quest_elevations.dart`（含扩展与静态 `light/dark/minimal`）。
- 共享组件层：`lingxi_card/button/chip/app_bar/dialog/text_field/toast/badge.dart` → `quest_*`。
- 应用与路由：`lib/app.dart` `LingxiApp`→`QuestApp`；`lib/core/motion/page_transitions.dart` `LingxiPageTransitions`→`QuestPageTransitions`。
- 数据层：`LingxiDatabase`→`QuestDatabase`、`_$LingxiDatabase`（Drift 生成前缀）→ 运行 `flutter pub run build_runner build --delete-conflicting-outputs` 重新生成 `database.g.dart`（**禁止手改 .g.dart**）；`db_providers.dart`、各 Repository、`secure_database.dart` 引用同步。
- 测试层：`test/widget/lingxi_card_test.dart`→`quest_card_test.dart`、`lingxi_button_test.dart`→`quest_button_test.dart`；其余含 `Lingxi*`/`lingxi_academy` 测试统一替换。

### Phase 3 — 数据库文件名与迁移

| 文件 | 改动 |
|------|------|
| `lib/data/db/connection.dart` | `getDatabaseFile()` 返回 `quest_academy.db` + D4 copy 迁移；更新头注释 |
| `lib/data/db/secure_database.dart` | 文档注释 `LingxiDatabase` → `QuestDatabase` |
| 新增 `test/data/db/connection_migration_test.dart` | 覆盖 D4 三路径 |

### Phase 4 — 吉祥物 / rive 残留清理

- `pubspec.yaml` 删 `rive` → `flutter pub get`；`pubspec.lock` 自动移除 rive/rive_common。
- `windows/CMakeLists.txt` 注释清理；`docs/吉祥物设计.md` 删除；`docs/架构设计.md` 删 rive 行；`docs/design-tokens.json` 删 mascot 分组。
- `AGENTS.md`、`README.md` 按 D9 清理。
- 验证：全仓 grep `rive|Rive|\.riv|mascot|Mascot` 仅剩 CHANGELOG/`.trae/` 历史白名单。

### Phase 5 — 前端重设计：主题 token

| 文件 | 改动 |
|------|------|
| `lib/core/theme/app_theme.dart` | `seedColor` → `0xFF3D5AFE`；appBar/card/chip/input/dialog/nav 主题微调（圆角、填充、对比度） |
| `lib/core/theme/theme_flavor_provider.dart` | `SeedColorNotifier` 默认值 + `SeedColorPresets` 换 D5 四色（保留 `starlightPurple` 为历史预设） |
| `lib/core/providers/app_providers.dart` | `AppConfig` 默认 `0xFF3D5AFE` |
| `lib/core/theme/quest_colors.dart` | 语义色维持并随新 seed 派生；`toDark()` 复核 WCAG AA |
| `lib/core/theme/quest_gradients.dart` | 6 语义渐变色相微调与新 seed 协调 |
| `lib/core/theme/quest_elevations.dart` | D6 阴影柔和化 |
| **新增** `lib/core/theme/quest_spacing.dart` | `QuestSpacing` ThemeExtension + `context.questSpacing` |
| `lib/core/theme/app_theme.dart` | 注册 `QuestSpacing` |
| `lib/core/theme/app_typography.dart` | display 中文 ZCOOL KuaiLe w700、英文/数字 Fredoka、正文 Noto Sans SC；minimal 回退 |
| `docs/design-tokens.json` | 同步新 seed、QuestSpacing、排版、阴影 |

### Phase 6 — 前端重设计：共享组件（视觉调优）

- `quest_card.dart`：圆角走 `ShapeTokens.cardRadius`、阴影走 `QuestElevations`、内边距 token 化；去廉价重影。
- `quest_button.dart`：大 CTA 可加主色渐变；按压反馈、loading 不变；间距 token 化。
- `quest_chip.dart`：胶囊/圆角跟随 ShapeTokens；选中态用 `secondaryContainer`。
- `quest_app_bar.dart`：standard 背景 `colorScheme.surface` + 滚动分隔线；minecraft 保留纹理分支。
- `quest_dialog.dart`：大圆角 + `QuestElevations.highlighted`；按钮换 `QuestButton`。
- `quest_text_field.dart`：聚焦 2dp 边框、填充 `surfaceContainerLow`、间距 token 化。
- `quest_toast.dart`：圆角 `chipRadius`、间距 token 化。
- 配套（随页面）：`empty_state_widget.dart`、`shimmer_loading.dart`、`celebration_overlay.dart`、`glass_container.dart`、`guide_bubble.dart` 同步换 Quest token。

### Phase 7 — 前端重设计：页面

按「用户高频 + 视觉影响大」排序，每页替换硬编码视觉常量为 Quest token + 新视觉方向：

| 页面 | 文件 | 关键改动 |
|------|------|---------|
| 首页 | `features/home/home_page.dart`、`daily_plan_widget.dart`、`learning_pace_reminder.dart` | Hero 区欢迎语 + XP 圆环 + Streak 火焰徽章 + 品牌光晕；间距 token 化；入场 stagger |
| 学习路径 | `learning_path_page.dart`、`widgets/level_node.dart`、`level_path.dart`、`learning_card_widget.dart`、`continue_learning_sidebar.dart` | 节点配色接新 seed；卡片封面渐变；锁定/当前/完成三态对比度复核 |
| 课时 | `lesson_page.dart`、`widgets/quiz_widget.dart`、`socratic_dialog_panel.dart` | 知识点卡片大圆角；测验选项选中缩放 + 对/错色反馈（`successGreen`/`misconceptionRed`） |
| 对话 | `chat_page.dart`、`chat_desktop_layout.dart` | 气泡 `chatUserBubble`/`chatAssistantBubble`；输入框悬浮卡片化；流式思考指示条 |
| 会话列表 | `chat_list_page.dart` | 头像圆角、标题/摘要/时间戳排版统一 |
| 笔记 | `notes_page.dart`、`note_editor_page.dart` | 卡片网格 + 新建 FAB；工具栏图标接主题色；保存成功粒子 |
| 成就 | `achievements_page.dart`、`achievement_badge_row.dart` | 徽章墙；解锁弹性动画 + 星光；金色保持 |
| 统计 | `statistics_page.dart` | 图表配色接新 seed（CustomPainter 手绘不动，只换色）；卡片布局 |
| 设置 | `settings_page.dart`、`widgets/theme_flavor_selector.dart`、`api_settings_page.dart`、`provider_edit_dialog.dart` | 分组排版；seed/风味选择器升级；API 设置卡片化 |
| 引导 | `onboarding_page.dart`、`api_setup_wizard_page.dart`、`learner_profile_setup_page.dart` | 大图标 + 步骤指示器；进度强调色接新 seed |
| 帮助 | `help_center_page.dart` | 可折叠卡片、搜索高亮 |
| 更新弹窗 | `features/update/update_dialog.dart` | 版本横幅渐变接 `questGradients.celebration`；按钮换 `QuestButton` |
| 导航壳 | `core/router/app_router.dart` | `_AppShell` 选中态与 NavigationBar/Rail 主题走 ThemeData；无需硬改逻辑 |

### Phase 8 — 图标与启动图（seedream）

1. 调用 seedream `GenerateImage` 生成品牌图标（prompt 建议见 D7，英文提示词效果更稳）与文字版候选。
2. 落位 `assets/images/app_icon.png`（1024×1024）、`assets/images/splash_logo.png`（448×448）。
3. 运行 `flutter pub run flutter_launcher_icons`、`flutter pub run flutter_native_splash:create`；`pubspec.yaml` splash `color` 改 `#3D5AFE`。
4. 校验 Android 桌面图标/启动屏、`windows/runner/resources/app_icon.ico` 更新成功。

### Phase 9 — 文档与 GitHub 引用同步

| 文档 | 改动 |
|------|------|
| `AGENTS.md` | 全篇「灵犀/波可/lingxi/Lingxi」→「问学/Quest/quest」；依赖表删 rive 并改名；目录结构更新 `quest_*.dart`；主题章节更新 `QuestSpacing`/新 seed；删吉祥物两章；「版本演进历史」加 v0.6.0 行；安全红线第 6 条 GitHub 引用 `YJLZSL/quest-academy` |
| `README.md` | 标题、项目状态、下载/克隆链接（`quest-academy`）、目录结构、技术栈表（删 rive、改名组件）、版本徽章 v0.6.0；新增「升级说明」标注 applicationId 变更影响 |
| `CHANGELOG.md` | `[Unreleased]` 段新增「品牌改名」「前端重设计」「吉祥物/rive 清理」「新图标」条目；标注 applicationId 变更与数据影响；旧历史保留原名称 |
| `CONTRIBUTING.md` | 仓库名、组件名、克隆命令 |
| `CODE_OF_CONDUCT.md` | 问学 Quest Academy、Issue 链接 |
| `SECURITY.md` | 项目名、安全公告链接、GitHub Release 引用 |
| `LICENSE` | `Copyright (c) 2026 Lingxi Academy Contributors` → `Quest Academy Contributors` |
| `docs/代码百科.md` | 类名/Provider/模块段落更新为 Quest |
| `docs/架构设计.md` | 架构图、文件树更新（含 rive 行删除） |
| `.github/pull_request_template.md` | 项目名引用同步 |
| `docs/游戏化重设计实施规范.md`、`.trae/` 归档 | 保留历史，文首加「已归档」标注，不入改名范围 |

### Phase 10 — 全量验证与发布

1. `flutter pub get` → `flutter pub run build_runner build --delete-conflicting-outputs` → `flutter analyze` 零 error/warning。
2. `flutter test`：失败数 ≤ 基线 36，**不得新增失败**。
3. 双端构建：`flutter build apk --release`、`flutter build windows --release`、`dart run msix:create --version 0.6.0.0`。
4. 手动验收矩阵：双主题 × 三 flavor × reduceMotion × 400% 字体缩放，逐页过（首页/学习/对话/会话/笔记/成就/统计/设置/引导/帮助/更新弹窗）。
5. 打 tag `v0.6.0` 触发 release.yml（产物名已改 `quest-academy-*`）。
6. 提交拆多个 Conventional Commits（`refactor(rename)` / `feat(theme)` / `feat(ui)` / `docs(agents)` / `chore(rive)` / `style(icons)`），禁止直推 main。

---

## 五、Assumptions & Decisions

1. **吉祥物完全移除，不做降级保留**：lib 已删，文档按 D9 清理。
2. **技术标识符全部改名**：按 D1/D3 映射，含 `Lingxi*` 类名与文件名（机械替换 + build_runner 重生成 .g.dart）。
3. **不引入新第三方依赖**：字体走 `google_fonts`（Fredoka 已支持）；间距 token 自研；图标/启动图由 seedream 生成后落为静态资源。
4. **新默认种子色 questIndigo #3D5AFE**：用户偏好不同时仅需改 D5 一个色值。
5. **数据库不递增 schemaVersion**：仅改文件名 + 一次性 copy 迁移。
6. **Android applicationId 变更的数据重置影响被接受**（默认接受，写入升级说明）。
7. **GitHub 仓库实际改名 `quest-academy` 为用户外部操作**（发布前置；本次只改代码/文档引用）。
8. **既有 36 个测试失败为历史基线**：以基线 diff 为准，只要求不新增。

---

## 六、Verification（验证步骤）

### 静态检查
- `flutter analyze` 零 error、零 warning。
- 全仓 grep 白名单：`lingxi|Lingxi|polaris|波可|Poco|mascot|Mascot|rive|Rive|\.riv` 仅剩 CHANGELOG 历史、`.trae/` 归档（执行时输出白名单报告存档到临时工作目录）。

### 测试
- `flutter test` 失败数 ≤ 基线 36，且 `diff` 无新增。
- 新增/更新：`connection_migration_test.dart`、`app_theme_test.dart`（新 seed 生成、暗色对比度 ≥4.5:1、QuestSpacing 取值）、`quest_card_test.dart`、`quest_button_test.dart`、`theme_flavor_provider_test.dart`（新默认色）。

### 手动验收
- Windows 窗口标题、Android 应用名显示「问学」；桌面/桌面图标与启动屏为新品牌图。
- 首页/学习路径/课时/对话/设置逐页双主题 + 三 flavor 视觉符合新方向；无吉祥物残留。
- 开启系统「移除动画」后交互可用；`PerformanceOverlay` 滑动无红条。
- 旧版本生成 `lingxi_academy.db` 后升级，Windows 数据保留且 `quest_academy.db` 生成。

---

## 七、风险与缓解

| 风险 | 影响 | 缓解 |
|------|------|------|
| applicationId 变更 → Android 旧用户无法自动更新/数据重置 | 老用户停留旧包 | 接受并写入升级说明；建议设置页推送手动引导；如不可接受回退为仅改显示名（但用户已要求改名） |
| GitHub 仓库未实际改名 | 自动更新指向 404 | 发布前置依赖，用户先 Rename；代码/文档先改 |
| 机械改名遗漏 | 编译错误散落 85 文件 | IDE Rename Symbol/File 原子化 + 全仓 grep 白名单 + CI analyze 兜底 |
| `database.g.dart` 手改损坏 | Drift 生成物不一致 | 一律 build_runner 重生成 |
| Windows 用户数据丢失 | 进度/笔记丢失 | D4 copy-on-first-launch + 三路径专项测试 |
| rive 移除后构建残留 | 编译引用 rive_common | `flutter pub get` + `flutter clean` 清缓存；检查 `windows/flutter/generated_plugins.cmake` |
| seedream 输出背景/透明不合规 | 图标白边/底色 | 纯品牌色背景 + 居中图形；必要时后处理；保留旧图回滚 |
| 新 seed 暗色对比度不足 | WCAG 失败 | `toDark()` 提亮 + 对比度断言测试 |
| 既有 36 失败被误判回归 | CI 噪音 | 基线 diff 为准，不阻塞发布 |
| msix identity 变更 | 新包无法覆盖旧 MSIX | 文档说明卸载旧版或新签名 |

---

## 八、执行说明

- 严格按 Phase 0→10 顺序，每阶段独立通过 `flutter analyze` + 对应测试再进入下一阶段（与 AGENTS.md 分阶段合并原则一致）。
- 建议拆两个 PR：`feat/quest-rebrand`（Phase 0-4、8-9 改名与清理）与 `feat/quest-redesign`（Phase 5-7 前端）。
- 中间产物（grep 白名单报告、对比截图、迁移测试脚本）放临时工作目录 `c:\Users\23501\.trae-cn\work\6a8d6efa622726de09d6d559`；最终交付物全部落于 `d:\AIKFCC\AI  Classroom`。
- Flutter SDK：`C:\Users\23501\AppData\Local\Temp\flutter\bin\flutter.bat`。
