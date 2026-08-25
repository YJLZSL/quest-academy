# 波可学园游戏化视觉重设计计划

> 目标：将现有「吉祥物陪伴式」界面全面转向 Duolingo 式现代游戏化 aesthetic；彻底移除吉祥物；把 Minecraft 彩蛋升级为可直接切换的完整 Pixel MC 主题。

## 一、Summary

本次重设计聚焦三件事：

1. **移除吉祥物**：彻底移除 `MascotWidget` 及其状态机在所有页面中的使用，替换为非角色化的游戏化反馈（streak 火焰、进度环、XP、成就徽章、粒子庆祝）。
2. **三档主题切换器**：把现有的 `ThemeFlavor.standard/minimal/minecraft` 重新定义为三个完整的一级主题：
   - **Default**：Duolingo 风格——高饱和、大圆角、卡片堆叠、强烈的进度可视化、弹簧微交互。
   - **Minimal**：现有低饱和、低动效、高信息密度的专注模式，保留并整理。
   - **Pixel MC**：把原本的「Minecraft 彩蛋」升级为完整主题——直角/小圆角、像素厚边阴影、方块感、8-bit 配色、像素字体，贯穿所有组件。
3. **目标用户 K12–大学**：默认主题活泼但不幼稚，Minimal 适合深度专注，Pixel MC 满足年轻用户趣味需求。

成功标准：
- 所有页面不再引用 `MascotWidget` / `mascotControllerProvider` / `MascotHero`。
- 三种主题均能在设置页一键切换，且颜色、形状、动效、字体随主题完整切换。
- 首页与学习路径页具备 Duolingo 风格的进度节点、streak、成就入口。
- `flutter analyze` 零 error/warning，`flutter test` 全部通过。

## 二、Current State Analysis

### 2.1 已具备的良好基础

| 能力 | 现状 | 价值 |
|---|---|---|
| 主题风味系统 | `ThemeFlavor` 已有 `standard/minimal/minecraft`；`themeFlavorProvider` 持久化到 `SharedPreferences` | 可直接复用枚举与持久化 |
| 主题 Token 体系 | `AppTheme.themeFor()` 根据 brightness + seed + flavor 生成 ThemeData；已注册 LingxiColors / LingxiGradients / LingxiElevations / ShapeTokens / MotionTokens | 三主题差异都通过 Token 派生 |
| 形状/动效 Token | `ShapeTokens.forFlavor()`、`MotionTokens.forFlavor()` 已按风味返回不同圆角与缩放；`LingxiElevations.pixelBorder` 已存在 | Pixel MC 可直接复用直角 + 厚边阴影 |
| 共享组件 | `LingxiCard`、`LingxiButton`、`LingxiChip` 已读取 Token | 修改 Token 即可批量影响外观 |
| Streak 徽章 | `HomePage._StreakBadge` 已使用渐变火焰 + 数字动画 | 可作为游戏化核心元素保留并强化 |

### 2.2 需要解决的问题

| 问题 | 影响 | 处理方向 |
|---|---|---|
| 吉祥物深度耦合 | `home_page.dart`、`learning_path_page.dart`、`chat_controller.dart`、`lesson_page.dart`、`empty_state_widget.dart`、`onboarding_page.dart` 等引用吉祥物 | 全部移除，状态联动点用 toast/SnackBar、进度脉冲、成就弹窗、粒子庆祝替代 |
| `minecraft` 只是彩蛋 | 当前仅在 `LingxiCard` / `LingxiButton` / `MascotWidget` 中做局部直角和像素绘制 | 扩展为覆盖字体、颜色、对话框、输入框的完整 Pixel MC 主题 |
| 学习路径不是游戏关卡路径 | 当前 `LearningPathPage` 是垂直列表 + 左侧时间线 | 改为横向/纵向关卡节点路径，已解锁/当前/锁定状态分明 |
| 缺少 XP/每日任务等游戏化元素 | 首页仅有 streak | 增加 XP 进度条、每日目标环、最近成就徽章入口 |
| 颜色语义围绕吉祥物 | `lingxi_colors.dart` 有 `mascotPrimary` | 替换为课程/游戏化语义色 |

## 三、Proposed Changes

### 3.1 主题层：`lib/core/theme/`

#### `theme_flavor_provider.dart`
- 保留 `ThemeFlavor` 枚举与持久化，把语义从「彩蛋/辅助风味」提升为「一级主题」。
- 删除 `minimalModeProvider` 的独立开关逻辑，或将其作为「Default ↔ Minimal」的快速切换，避免与 `themeFlavorProvider` 冲突。
- 在种子色预设中新增 Pixel MC 专属种子色（草绿 `#5D8C22`、泥土棕 `#8B5A2B`）。

#### `app_theme.dart`
- `themeFor()` 让三种主题产生明显区分：
  - **Default**：Material 3 Expressive，强化卡片阴影、按钮圆角 16–20、标题加粗、导航栏 indicator 更圆润。
  - **Minimal**：降低阴影透明度、圆角 8–12、禁用按压缩放、颜色去饱和。
  - **Pixel MC**：直角组件、深绿色 app bar、像素厚边阴影、方块状 FAB/按钮、输入框直角无圆角。
- `TextTheme` 按 flavor 切换字体：Pixel MC 使用 `GoogleFonts.pressStart2p()` 或 `vt323`；其余使用 Noto Sans SC + Quicksand。

#### `lingxi_colors.dart`
- 删除 `mascotPrimary`、`mascotSecondary`。
- 新增语义色：`coursePrimary`、`xpBlue`、`streakFire`、`achievementGold`、`successGreen`、`misconceptionRed`、`socraticBlue`、`pixelGrass`、`pixelDirt`、`pixelStone`。
- `fromSeed()` 中根据 flavor 分支：Pixel MC 使用固定 MC 调色板，Default/Minimal 使用 seed 派生。

#### `lingxi_gradients.dart` / `lingxi_elevations.dart` / `shape_tokens.dart` / `motion_tokens.dart`
- `ShapeTokens`：Default 圆角更大，Minimal 更小，Pixel MC 基本直角。
- `MotionTokens`：Default 按压缩放 0.96；Minimal 全部 1.0；Pixel MC 按压 0.9、切换动画更短。
- `LingxiElevations`：Default 阴影更明显；Pixel MC 使用 `pixelBorder` 厚边阴影模拟 3D 挤出。

### 3.2 共享组件层：`lib/shared/widgets/`

#### `lingxi_card.dart`
- Default：大圆角、柔和阴影、可选渐变背景。
- Minimal：扁平、细边框、无阴影。
- Pixel MC：直角、厚边阴影、可选像素边框描边。
- 新增 `LingxiCardVariant.gamified` 变体，用于首页 XP/每日目标卡。

#### `lingxi_button.dart`
- Default：大 padding、大圆角、可选 `pulse` CTA 呼吸，disabled 灰显。
- Pixel MC：直角、厚边阴影、按压时整体下移 2–4px 模拟方块按下。

#### `lingxi_chip.dart` / `lingxi_app_bar.dart`
- Chip：Default 圆角大、选中态彩色；Pixel MC 直角或 2px 圆角。
- AppBar：Pixel MC 深绿背景 + 白色标题；Default/Minimal 保持 surface。

### 3.3 页面层：移除吉祥物 + 游戏化重设计

#### `lib/features/home/home_page.dart`
- 删除 `MascotWidget` 及 hero 区吉祥物。
- Hero 区改为：欢迎语 + 今日学习目标进度（环形/条形）+ streak 火焰徽章 + 连续学习天数。
- 课程进度卡片增强：完成百分比、下一个推荐知识点、最近解锁成就图标。
- 快捷入口网格增加「每日任务/成就」入口。
- `_recordStudyActivity` 不再调用 `mascotControllerProvider`，改为触发 `CelebrationService` 或显示 SnackBar。

#### `lib/features/learning/learning_path_page.dart`
- 删除 AppBar 中的 `MascotWidget` 与空状态吉祥物。
- 新布局：顶部级别筛选 Chip + 下方「关卡路径」视图。
- 每个级别是一列关卡节点：当前节点高亮放大，已完成节点打勾并带绿色光环，锁定节点灰显。
- 节点样式：圆形/圆角方形（Default）、扁平圆形（Minimal）、方块（Pixel MC）。
- 节点之间用虚线/渐变线连接，当前关卡到下一关卡有流光动画。

#### `lib/features/settings/settings_page.dart`
- 在「外观」分组新增 `ThemeFlavor` 选择组件（Default / Minimal / Pixel MC）。
- Pixel MC 主题下隐藏或限制种子色选择。
- 删除任何与吉祥物相关的设置项。

#### 其他吉祥物引用点清理

| 文件 | 处理方式 |
|---|---|
| `lib/features/chat/chat_controller.dart` | 删除 `setAiThinking` / `celebrate` / `setMood(sad)` 调用；改为通过 state 字段驱动 UI 状态指示器 |
| `lib/features/chat/chat_page.dart` | 移除 `MascotOverlay`/右下角吉祥物；思考态使用顶部/输入区脉冲点 +「AI 思考中」文案 |
| `lib/features/learning/lesson_page.dart` | 移除知识点完成时的吉祥物庆祝；改为全局粒子庆祝 + SnackBar「知识点完成 +XP」 |
| `lib/features/onboarding/onboarding_page.dart` | 移除吉祥物插图；改为大图标、步骤指示器、渐变背景 |
| `lib/shared/widgets/empty_state_widget.dart` | 移除吉祥物参数；改为图标 + 标题 + 描述 + CTA |
| `lib/features/mascot/*` | 整目录移除或归档到 `.trae/archive/`，业务代码不再 import |

### 3.4 新增游戏化组件

| 组件 | 位置 | 用途 |
|---|---|---|
| `XpProgressRing` | `lib/shared/widgets/xp_progress_ring.dart` | 首页显示今日 XP / 每日目标完成度 |
| `StreakFlameBadge` | `lib/shared/widgets/streak_flame_badge.dart` | 抽象现有 `_StreakBadge`，供 AppBar 与首页使用 |
| `AchievementBadgeRow` | `lib/shared/widgets/achievement_badge_row.dart` | 横向滚动最近解锁成就 |
| `LevelNode` | `lib/features/learning/widgets/level_node.dart` | 学习路径单个关卡节点 |
| `DailyGoalCard` | `lib/shared/widgets/daily_goal_card.dart` | 首页「每日目标」卡片 |
| `ThemeFlavorSelector` | `lib/features/settings/widgets/theme_flavor_selector.dart` | 设置页主题切换器 |

**新增依赖**：不引入新包。字体走 `google_fonts`；图标走 Material Icons；图表先用 `CustomPainter` 实现 XP 环。

### 3.5 数据与状态层

- 本次原则上不改动数据库 schema。
- 如需新增「XP」和「每日目标」，建议新增 `GamificationService`（`lib/features/progress/gamification_service.dart`）统一计算。
- 若需持久化 XP，按 AGENTS.md 流程：递增 `schemaVersion`、写 migration、补 Repository 测试。

### 3.6 文档与测试

| 文档 | 更新内容 |
|---|---|
| `AGENTS.md` | 更新目录结构、主题系统约定、版本演进历史 |
| `docs/吉祥物设计.md` | 标记为已归档或删除 |
| `docs/代码百科.md` | 更新主题、共享组件、progress 服务章节 |
| `CHANGELOG.md` | 在 `[Unreleased]` 下新增「新增/变更/移除」项 |
| `README.md` | 更新截图描述与功能特性 |

测试要求：
- 新增 `theme_flavor_provider_test.dart`。
- 新增 `lingxi_card_test.dart`、`lingxi_button_test.dart` 的 Pixel MC / Default 分支 widget 测试。
- 更新 `mascot_widget_test.dart` 为删除测试，或改为验证首页无吉祥物。
- 运行 `flutter test`、`flutter analyze`。

## 四、Assumptions & Decisions

1. **吉祥物完全移除，不做降级保留**：不保留「小尺寸吉祥物」或「可选显示」开关。
2. **Pixel MC 主题复用现有 `ThemeFlavor.minecraft`**：保留枚举名 `minecraft`，UI 文案称「Pixel MC」。注意旧用户持久化值仍是 `'minecraft'`。
3. **不引入新的第三方依赖**：字体走 `google_fonts`；动画走 Flutter 内置 + `SpringMotion`。
4. **Duolingo 风格聚焦「路径 + 进度 + 激励」**：保留 streak、XP、成就三要素；排行榜/好友对战作为未来扩展。
5. **主题切换即时生效**：通过 `app.dart` 中 `ref.watch(themeFlavorProvider)` 驱动 `AppTheme.themeFor()` 重建。
6. **暗色模式与三种主题正交**：Default + dark、Minimal + dark、Pixel MC + dark 都需要单独调校对比度，确保 WCAG AA。
7. **AI 对话情绪反馈改为抽象状态**：`thinking` → 输入框上方脉冲指示条；`error` → SnackBar + 输入框边框变红；`celebrate` → 全局粒子庆祝 +「+XP」浮层。

## 五、Verification Steps

### 5.1 静态检查
```bash
flutter analyze
```
- 零 error、零 warning。
- 无 `MascotWidget`、`mascotControllerProvider`、`MascotHero` 残留引用。

### 5.2 测试运行
```bash
flutter test
```
- 现有测试通过；新增主题切换持久化、组件三主题外观、首页无吉祥物、学习路径节点渲染等测试。

### 5.3 手动验证清单
- 设置页切换 Default / Minimal / Pixel MC，观察卡片/按钮/输入框/对话框外观变化。
- Pixel MC 下所有组件为直角/小圆角 + 厚边阴影；字体像素化。
- 开启系统「移除动画」后 Minimal/reduceMotion 下所有按压/入场降级为即时切换。
- 首页、学习路径、对话页、设置页、空状态、引导页均无吉祥物。
- 学习路径节点完成/当前/锁定视觉区分明显；点击当前节点跳转正确 lesson。
- 三种主题在暗色模式下文字对比度符合 WCAG AA。

### 5.4 性能回归
- `flutter run --profile` + Dart DevTools Timeline 录制首页与学习路径滑动，UI 线程帧时间 ≤ 16ms。
- `PerformanceOverlay` 不出现红条。

### 5.5 文档同步
- PR 描述中勾选 AGENTS.md 文档同步检查清单。
- 更新 `CHANGELOG.md`、`docs/代码百科.md`、归档 `docs/吉祥物设计.md`。

## 六、建议实施顺序

1. 主题 Token 重构：`theme_flavor_provider` / `lingxi_colors` / `shape_tokens` / `motion_tokens` / `lingxi_elevations`。
2. 共享组件适配：`LingxiCard`、`LingxiButton`、`LingxiChip`、`LingxiAppBar`。
3. 设置页主题切换器：让用户能切换主题，便于后续手动验证。
4. 移除吉祥物：按引用清单逐页清理，替换为状态指示器/SnackBar/粒子庆祝。
5. 首页重设计：加入 XP 环、streak、每日目标、成就入口。
6. 学习路径重设计：改为关卡节点路径。
7. 补测试与文档：同步进行，最后统一跑 `flutter analyze` + `flutter test`。
