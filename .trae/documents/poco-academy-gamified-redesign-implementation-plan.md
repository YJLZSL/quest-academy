# 波可学园游戏化重设计实施计划

> **目标**：将现有吉祥物陪伴式 UI 全面转向 Duolingo 式现代游戏化设计，彻底移除吉祥物，并把 Minecraft 彩蛋升级为设置页可直接切换的完整 Pixel MC 主题。
> **约束**：不引入新第三方依赖；目标平台 Android + Windows；遵循现有 ThemeExtension Token 体系；安全移除所有 mascot 引用。

---

## 1. 调研结论

### 1.1 Duolingo 游戏化 UI 关键模式

根据 Duolingo 官方品牌指南（Duolingo Brand Guidelines）及产品形态分析，核心模式包括：

| 模式 | 作用 | 设计特征 |
|------|------|----------|
| **Streak（连续学习）** |  habit 养成、日活激励 | 顶部火焰徽章、连续天数数字、中断风险提示 |
| **XP（经验值）** | 学习量化、即时反馈 | 每日目标环、完成动画、+XP 浮层 |
| **关卡路径（Lesson Path）** | 进度可视化、目标感 | 纵向/横向节点、当前节点高亮、已完成打勾、锁定节点灰显 |
| **成就徽章** | 长期激励、收集欲 | 徽章网格、解锁动画、进度条 |
| **排行榜/联赛** | 竞争激励 | 分段头像、名次变化 |
| **视觉风格** | 品牌识别 | 大圆角（rounded rectangle 为基础形状）、高饱和色、简洁形状语言、药丸形阴影（pill shadow）、无尖角 |

Duolingo 形状语言以 **rounded rectangle、circle、rounded triangle** 为基础，强调 rhythm（形状节奏变化）与 simplicity（6-15 个形状为宜），阴影为底部药丸形，颜色高饱和且活泼（如 Owl #58CC02、Bee #FFC800、Cardinal #FF4B4B）。

### 1.2 Minecraft / Pixel UI 视觉特征

| 特征 | 实现方式 |
|------|----------|
| **方块阴影** | 无模糊（blurRadius: 0）、硬边 offset 阴影模拟体素挤出 |
| **像素字体** | 等宽像素风格显示字体（Press Start 2P / VT323） |
| **直角/小圆角** | BorderRadius.zero 或 2-4px |
| **厚边框** | 2-4px 实线边框，常配合 inset/outset 视觉 |
| **8-bit 配色** | 草地绿 #5D8C22、泥土棕 #8B5A2B、石头灰 #707070、天空蓝 #87CEEB |
| **按钮按压反馈** | 整体下移 2-4px 模拟方块按下 |

---

## 2. 现状分析

### 2.1 已具备基础

- `ThemeFlavor.standard/minimal/minecraft` 枚举与持久化已存在（`theme_flavor_provider.dart`）。
- `AppTheme.themeFor()` 已根据 brightness + seed + flavor 生成 ThemeData，并注册 LingxiColors / LingxiGradients / LingxiElevations / ShapeTokens / MotionTokens / AppTypography / BackgroundTextures。
- `ShapeTokens.forFlavor()`、`MotionTokens.forFlavor()` 已按风味返回不同圆角与缩放；`LingxiElevations.pixelBorder` 已存在。
- 共享组件 `LingxiCard`、`LingxiButton`、`LingxiChip` 已读取 Token。
- `StreakService` 与 `HomePage._StreakBadge` 已具备连续学习天数展示能力。
- `CelebrationService` 已提供全局粒子/纸屑庆祝。

### 2.2 核心问题

- **吉祥物深度耦合**：`mascotControllerProvider` / `MascotWidget` / `MascotHero` / `MascotOverlay` 遍布首页、学习路径、对话、课时、引导、空状态、更新弹窗、成就服务。
- **Minecraft 只是局部彩蛋**：仅在卡片/按钮/吉祥物绘制中做局部直角，未覆盖字体、对话框、输入框、AppBar。
- **Minimal 模式与 ThemeFlavor 冲突**：`minimalModeProvider` 与 `themeFlavorProvider` 独立持久化，app.dart 中 `minimalMode` 会覆盖 flavor，导致设置页主题切换语义混乱。
- **颜色语义围绕吉祥物**：`lingxi_colors.dart` 中 `mascotPrimary`、`mascotSecondary` 等字段需替换为游戏化语义色。
- **学习路径不是关卡路径**：当前为垂直列表 + 左侧时间线，缺少 Duolingo 式节点路径。
- **缺少 XP/每日目标**：首页仅有 streak，缺少 XP 进度环、每日目标、最近成就入口。

---

## 3. 吉祥物引用清单

### 3.1 需要删除的目录

- `lib/features/mascot/`
  - `mascot_controller.dart`
  - `mascot_state.dart`
  - `mascot_widget.dart`
  - `mascot_overlay.dart`
  - `poco_painter.dart`
  - `pixel_poco_painter.dart`
  - `rive_mascot_widget.dart`

### 3.2 引用 mascot 的文件及处理

| 文件 | 引用内容 | 处理方式 |
|------|----------|----------|
| `lib/shared/widgets/empty_state_widget.dart` | `MascotWidget`、`mascotControllerProvider` | 移除吉祥物，改为图标/插图 + 标题 + 描述 + CTA；保留粒子场但改为独立庆祝装饰 |
| `lib/shared/widgets/guide_bubble.dart` | `colors.mascotPrimary` | 重命名为 `colors.brandPrimary` |
| `lib/shared/widgets/lingxi_app_bar.dart` | 可能含 mascot 引用 | 检查并清理 |
| `lib/shared/widgets/lingxi_dialog.dart` | 可能含 mascot 引用 | 检查并清理 |
| `lib/core/motion/page_transitions.dart` | `MascotHero`、`mascotHeroFlightShuttleBuilder` | 删除 Hero 相关代码 |
| `lib/core/theme/lingxi_colors.dart` | `mascotPrimary`、`mascotSecondary` | 重命名/删除 |
| `lib/core/theme/lingxi_gradients.dart` | `mascotHero` 渐变 | 重命名为 `brandGlow` |
| `lib/core/theme/motion_tokens.dart` | `mascotSquashScale` | 删除该字段 |
| `lib/features/home/home_page.dart` | `mascotControllerProvider`、`MascotWidget`、`MascotMood` | 移除吉祥物，改为 streak/XP/成就入口 |
| `lib/features/learning/learning_path_page.dart` | `MascotWidget`、`MascotHero` | 移除吉祥物，改为关卡节点路径 |
| `lib/features/learning/lesson_page.dart` | `MascotWidget`、`mascotControllerProvider` | 移除吉祥物，保留 CelebrationService |
| `lib/features/learning/widgets/socratic_dialog_panel.dart` | `mascotControllerProvider` | 移除吉祥物，改为输入区状态指示器 |
| `lib/features/chat/chat_controller.dart` | `mascotControllerProvider` | 移除吉祥物联动，改为状态字段 |
| `lib/features/chat/chat_page.dart` | `MascotWidget` | 移除右下角吉祥物/Overlay |
| `lib/features/onboarding/onboarding_page.dart` | `MascotWidget`、`mascotControllerProvider` | 移除吉祥物，改为大图标 + 步骤指示器 |
| `lib/features/progress/achievement_service.dart` | `MascotController` 依赖 | 移除构造函数依赖与调用 |
| `lib/features/update/update_dialog.dart` | `MascotWidget` | 移除吉祥物，改为版本图标/庆祝渐变 |
| `lib/features/notes/notes_page.dart` | 可能含 mascot 引用 | 检查并清理 |
| `lib/features/chat/chat_list_page.dart` | 可能含 mascot 引用 | 检查并清理 |
| `lib/features/settings/api_settings_page.dart` | 可能含 mascot 引用 | 检查并清理 |
| `lib/features/learning/course_level_extensions.dart` | 可能含 mascot 引用 | 检查并清理 |
| `lib/features/learning/widgets/learning_card_widget.dart` | 可能含 mascot 引用 | 检查并清理 |

### 3.3 `mascotControllerProvider` 精确引用位置

```
lib/shared/widgets/empty_state_widget.dart:91  onTap: () => ref.read(mascotControllerProvider.notifier).triggerTap()
lib/features/onboarding/onboarding_page.dart:34  注释
lib/features/onboarding/onboarding_page.dart:89  .read(mascotControllerProvider.notifier).setMood(...)
lib/features/onboarding/onboarding_page.dart:114 .read(mascotControllerProvider.notifier).setMood(...)
lib/features/onboarding/onboarding_page.dart:141 ref.read(mascotControllerProvider.notifier).triggerTap()
lib/features/chat/chat_controller.dart:136  _ref.read(mascotControllerProvider.notifier).setMood(MascotMood.sad)
lib/features/chat/chat_controller.dart:145  final mascot = _ref.read(mascotControllerProvider.notifier)
lib/features/chat/chat_controller.dart:316  _ref.read(mascotControllerProvider.notifier).celebrate()
lib/features/chat/chat_controller.dart:354  _ref.read(mascotControllerProvider.notifier).setMood(MascotMood.sad)
lib/features/chat/chat_controller.dart:390  _ref.read(mascotControllerProvider.notifier).celebrate()
lib/features/home/home_page.dart:71  ref.read(mascotControllerProvider.notifier).setMood(MascotMood.happy)
lib/features/progress/achievement_service.dart:252  mascot: ref.watch(mascotControllerProvider.notifier)
lib/features/learning/widgets/socratic_dialog_panel.dart:71  final mascotNotifier = ref.read(mascotControllerProvider.notifier)
lib/features/learning/lesson_page.dart:95  ref.read(mascotControllerProvider.notifier).celebrate()
lib/features/learning/lesson_page.dart:166 ref.read(mascotControllerProvider.notifier).triggerTap()
lib/features/mascot/mascot_widget.dart:20  注释
lib/features/mascot/mascot_widget.dart:158 final baseMood = widget.mood ?? ref.watch(mascotControllerProvider).mood
lib/features/mascot/mascot_controller.dart:8  注释
lib/features/mascot/mascot_controller.dart:69 final mascotControllerProvider = ...
lib/features/mascot/mascot_overlay.dart:21  final mascotState = ref.watch(mascotControllerProvider)
```

---

## 4. 主题 Token 重构

### 4.1 `lib/core/theme/theme_flavor_provider.dart`

- **保留** `ThemeFlavor` 枚举（`standard/minimal/minecraft`）及持久化逻辑。
- **删除** `minimalModeProvider` 及 `MinimalModeNotifier`，将其语义合并到 `ThemeFlavor.minimal`。
- **迁移旧数据**：启动时若读取到 `minimal_mode=true`，自动设置 `theme_flavor='minimal'` 并清除 `minimal_mode` 键。
- **文案映射**：UI 显示时将 `standard` → "默认"、`minimal` → "极简"、`minecraft` → "Pixel MC"。
- **新增 Pixel MC 种子色预设**（可选，若 Pixel MC 使用固定调色板则忽略 seed）：`pixelGrass`、`pixelDirt`、`pixelStone`。

### 4.2 `lib/core/theme/app_theme.dart`

- 删除 `effectiveFlavor` 对 `minimalModeProvider` 的读取，直接使用 `themeFlavorProvider`。
- **Default（standard）**：Material 3 Expressive，大圆角、强阴影、活泼字体 ZCOOLKuaiLe。
- **Minimal**：低饱和、低阴影、禁用 hover/press 缩放、系统字体。
- **Pixel MC**：
  - AppBar 深绿背景（`#5D8C22`）+ 白色标题（已在当前代码中实现）。
  - 所有组件读取 `ShapeTokens`（直角）。
  - 按钮/卡片使用 `LingxiElevations.pixelBorder`。
  - 标题字体使用 `PressStart2P`，正文字体保持 `NotoSansSC`。
  - 输入框直角、无圆角、2px 深色边框。
  - 对话框直角、厚边框。
- `TextTheme` 按 flavor 通过 `buildTextTheme()` 切换（当前已实现）。

### 4.3 `lib/core/theme/lingxi_colors.dart`

- **删除** `mascotPrimary`、`mascotSecondary`。
- **新增/重命名**字段：
  - `brandPrimary`：原 `mascotPrimary` 语义，用于品牌主色。
  - `brandSecondary`：可选，用于高光/强调（替代 `mascotSecondary`）。
  - `coursePrimary`：课程主色（与 `brandPrimary` 可相同或派生）。
  - `xpBlue`：XP 相关蓝色（可选，如 `#1CB0F6`）。
  - 保留 `streakFire`、`achievementGold`、`socraticBlue`、`misconceptionRed`、`successGreen`、`infoTeal`、`chatUserBubble`、`chatAssistantBubble`、`highlightYellow`。
  - 新增 `pixelGrass`、`pixelDirt`、`pixelStone`、`pixelWood` 用于 Pixel MC 主题固定色。
- `fromSeed()` 中 Pixel MC 不使用 seed 派生，直接使用固定 MC 调色板；Default/Minimal 使用 seed 派生。
- `toDark()` 调整 `brandPrimary`、`brandSecondary`、`socraticBlue`、`infoTeal` 亮度，确保 WCAG AA。

### 4.4 `lib/core/theme/lingxi_gradients.dart`

- **重命名** `mascotHero` → `brandGlow`（径向辉光）。
- 保留 `streakFire`、`achievementGold`、`primarySurface`、`celebration`、`success`。
- `brandGlow` 在 Pixel MC 风味下使用更低透明度或不使用。

### 4.5 `lib/core/theme/lingxi_elevations.dart`

- 保留 `subtle`、`elevated`、`highlighted`、`pixelBorder`。
- 增强 `pixelBorder`：当前只有右下阴影，建议增加左/上浅色描边模拟体素 3D 挤出（可选）。
- Default 阴影可略微增强以匹配 Duolingo 卡片堆叠感。

### 4.6 `lib/core/theme/shape_tokens.dart`

- 已满足需求：
  - Default：cardRadius 24、buttonRadius 16、chipRadius 12。
  - Minimal：cardRadius 12、buttonRadius 8、chipRadius 4。
  - Pixel MC：全部 0-4px。
- 无需修改，但需确保所有组件统一读取 `ShapeTokens`。

### 4.7 `lib/core/theme/motion_tokens.dart`

- **删除** `mascotSquashScale` 字段（吉祥物相关）。
- 保留 `pageEntranceDelay`、`listStaggerDelay`、`cardHoverScale`、`buttonPressedScale`、`enableParticles`。
- Default：`buttonPressedScale=0.95`、`cardHoverScale=1.02`。
- Minimal：全部 1.0 / Duration.zero。
- Pixel MC：`buttonPressedScale=0.9`、`cardHoverScale=1.0`。
- 更新 `copyWith`、`lerp`。

### 4.8 `lib/core/theme/app_typography.dart`

- 当前已实现：
  - standard → ZCOOLKuaiLe 显示字体。
  - minimal → NotoSansSC。
  - minecraft → PressStart2P 显示字体 + VT323 等宽。
- 无需修改，但需确保所有标题读取 `appTypography.fontFamilyDisplay`。

---

## 5. 共享组件改造

### 5.1 `lib/shared/widgets/empty_state_widget.dart`

- 移除 `mascotMood`、`mascotSize` 参数，新增 `icon`、`illustration` 参数。
- 默认使用大图标（如 `Icons.sentiment_dissatisfied` / `Icons.construction`）替代吉祥物。
- 保留背景纹理与粒子场，但粒子不再围绕吉祥物分布，改为居中装饰。
- 保留光晕但改为 `brandGlow`。
- 移除 `onTap` 触发吉祥物彩蛋。

### 5.2 `lib/shared/widgets/lingxi_card.dart`

- 已按 flavor 使用 `ShapeTokens.cardRadius` 与 `LingxiElevations`。
- Pixel MC 下使用 `pixelBorder` 与直角。
- 新增 `LingxiCardVariant.gamified`：用于首页 XP/每日目标卡，可带渐变背景与强调边框。

### 5.3 `lib/shared/widgets/lingxi_button.dart`

- 已按 flavor 使用 `ShapeTokens.buttonRadius` 与 `MotionTokens.buttonPressedScale`。
- Pixel MC 下按压时除缩放外，可整体下移 2px 模拟方块按下（通过 `Transform.translate`）。
- 保持 `pulse` CTA 呼吸效果。

### 5.4 `lib/shared/widgets/lingxi_chip.dart`

- 按 flavor 调整圆角与选中态。
- Pixel MC 下直角或 2px 圆角、厚边框。

### 5.5 `lib/shared/widgets/lingxi_app_bar.dart`

- Pixel MC 下保持深绿背景 + 白色标题（已由 `app_theme.dart` 配置）。
- 确保无 mascot 引用。

### 5.6 `lib/shared/widgets/guide_bubble.dart`

- 将 `colors.mascotPrimary` 改为 `colors.brandPrimary`。
- 保持现有风味适配逻辑。

---

## 6. 页面层改造

### 6.1 `lib/features/home/home_page.dart`

- **移除** Hero 区 `MascotWidget` 与所有 `mascotControllerProvider` 调用。
- **新增 Hero 区**：
  - 欢迎语（使用 `appTypography.fontFamilyDisplay`）。
  - 今日学习目标进度（`XpProgressRing` 或条形进度）。
  - Streak 火焰徽章（复用/抽离 `_StreakBadge` 为 `StreakFlameBadge`）。
  - 最近成就徽章横向滚动（`AchievementBadgeRow`）。
- **课程进度卡片增强**：完成百分比、下一个推荐知识点、最近解锁成就图标。
- **快捷入口网格**：增加「每日任务/成就」入口。
- `_recordStudyActivity` 中：
  - streak >= 3 时显示 SnackBar「连续学习 X 天」或触发 `CelebrationService.sparkles`。
  - 不再调用 `mascotControllerProvider`。

### 6.2 `lib/features/learning/learning_path_page.dart`

- **移除** AppBar 中的 `MascotWidget` 与空状态吉祥物。
- **新布局**：
  - 顶部级别筛选 Chip（L0-L4 / 全部）。
  - 下方「关卡路径」视图：每个级别一列关卡节点。
  - 节点状态：已完成（绿色打勾 + 光环）、当前（高亮放大 + 脉冲）、锁定（灰显 + 锁图标）。
  - 节点之间用虚线/渐变线连接，当前关卡到下一关卡有流光动画。
  - 节点样式：Default 圆角方形、Minimal 扁平圆形、Pixel MC 方块。
- 空状态改为大图标 + 文案。

### 6.3 `lib/features/settings/settings_page.dart`

- **新增「主题风格」分组**：
  - `ThemeFlavorSelector` 组件，三选一：默认 / 极简 / Pixel MC。
  - 选择后立即通过 `themeFlavorProvider.setFlavor()` 切换并持久化。
- **删除** 原有「极简模式」独立开关（若存在）。
- Pixel MC 主题下隐藏或禁用种子色选择（因为 Pixel MC 使用固定调色板）。
- 移除任何与吉祥物相关的设置项。

### 6.4 `lib/features/chat/chat_page.dart`

- 移除 `MascotOverlay`/右下角吉祥物（若存在）。
- AI 思考态使用输入框上方脉冲点 +「AI 思考中」文案。
- AI 出错时使用 SnackBar + 输入框边框变红。
- AI 完成时使用全局粒子庆祝（可选）。

### 6.5 `lib/features/chat/chat_controller.dart`

- 移除所有 `mascotControllerProvider` 调用。
- 错误时仅设置 `state.error`；完成时仅设置 `state.isStreaming=false`。
-  celebrations 由页面层根据状态变化触发（`ref.listen(chatControllerProvider, ...)`）。

### 6.6 `lib/features/learning/lesson_page.dart`

- 移除 AppBar 中的 `MascotWidget`。
- 知识点完成时：
  - 保留 `CelebrationService.sparkles`。
  - 显示 SnackBar「知识点完成 +10 XP」。
  - 章节完成时保留 `CelebrationService.confetti`。

### 6.7 `lib/features/learning/widgets/socratic_dialog_panel.dart`

- 移除 `mascotControllerProvider` 调用。
- AI 思考态使用输入区上方脉冲指示条。
- AI 出错时显示错误文本（已有）。

### 6.8 `lib/features/onboarding/onboarding_page.dart`

- 移除 `MascotWidget` 与 `mascotControllerProvider`。
- 改为大图标（每步不同 Material Icon）+ 步骤指示器 + 渐变背景。
- 步骤数据模型 `_OnboardingStep` 移除 `mood` 字段，新增 `icon` 字段。
- 「试试点我」步骤改为「体验主题切换」或删除。

### 6.9 `lib/features/update/update_dialog.dart`

- 移除 `MascotWidget`。
- 头部横幅使用版本图标（如 `Icons.system_update`）+ 庆祝渐变条带。
- 保持其他状态机逻辑不变。

### 6.10 `lib/features/progress/achievement_service.dart`

- 从构造函数中移除 `MascotController mascot` 参数。
- 移除成就解锁时对吉祥物的调用。
- 成就解锁反馈改为返回事件（调用方决定是否触发庆祝）。
- 更新 `achievementServiceProvider` 的依赖注入。

---

## 7. 新增组件清单

| 组件 | 文件 | 用途 |
|------|------|------|
| `XpProgressRing` | `lib/shared/widgets/xp_progress_ring.dart` | 首页显示今日 XP / 每日目标完成度（CustomPainter 圆环） |
| `StreakFlameBadge` | `lib/shared/widgets/streak_flame_badge.dart` | 抽象现有 `_StreakBadge`，供 AppBar 与首页复用 |
| `AchievementBadgeRow` | `lib/shared/widgets/achievement_badge_row.dart` | 横向滚动最近解锁成就 |
| `LevelNode` | `lib/features/learning/widgets/level_node.dart` | 学习路径单个关卡节点 |
| `LevelPath` | `lib/features/learning/widgets/level_path.dart` | 关卡节点之间的连接线与流光动画 |
| `DailyGoalCard` | `lib/shared/widgets/daily_goal_card.dart` | 首页「每日目标」卡片 |
| `ThemeFlavorSelector` | `lib/features/settings/widgets/theme_flavor_selector.dart` | 设置页三主题切换器 |
| `AiThinkingIndicator` | `lib/shared/widgets/ai_thinking_indicator.dart` | 对话/苏格拉底面板 AI 思考脉冲指示器 |
| `PixelBorderDecoration` | `lib/shared/widgets/pixel_border_decoration.dart` | Pixel MC 通用方块阴影装饰（可选） |

---

## 8. 数据与状态层

### 8.1 数据库 Schema

- **本次不新增表**，避免扩大范围。
- XP、每日目标等数据通过现有 `Settings` 表键值对存储，或完全基于内存计算。

### 8.2 新增服务：`lib/features/progress/gamification_service.dart`

- 职责：
  - 计算今日 XP（基于学习事件 duration、测验分数、对话轮数）。
  - 计算每日目标完成度。
  - 提供最近成就列表。
- 依赖：`LearningEventRepository`、`ProgressRepository`、`AchievementRepository`、`SettingsRepository`。
- Provider：`gamificationServiceProvider`。

### 8.3 成就服务改造

- 移除 `MascotController` 依赖。
- 新增成就解锁事件流或回调，供 UI 层触发庆祝。

---

## 9. 分阶段实施顺序

### Phase A：主题 Token 与基础设施（必须先完成）

1. **修改 `lib/core/theme/theme_flavor_provider.dart`**
   - 删除 `minimalModeProvider`。
   - 新增旧 `minimal_mode` 数据迁移逻辑（可选一次性迁移函数）。
2. **修改 `lib/core/theme/lingxi_colors.dart`**
   - 重命名/删除 mascot 相关字段。
   - 新增 Pixel MC 固定色与 brand 语义色。
3. **修改 `lib/core/theme/lingxi_gradients.dart`**
   - 重命名 `mascotHero` → `brandGlow`。
4. **修改 `lib/core/theme/motion_tokens.dart`**
   - 删除 `mascotSquashScale`。
5. **修改 `lib/core/theme/lingxi_elevations.dart`**
   - 可选增强 `pixelBorder`。
6. **修改 `lib/core/theme/app_theme.dart`**
   - 移除 `minimalModeProvider` 读取。
   - 确保 Pixel MC 固定调色板生效。
7. **修改 `lib/app.dart`**
   - 移除 `minimalModeProvider` 对 `effectiveFlavor` 的覆盖。

### Phase B：共享组件去 mascot 化

8. **修改 `lib/shared/widgets/empty_state_widget.dart`**
   - 移除 mascot 参数与绘制。
9. **修改 `lib/shared/widgets/guide_bubble.dart`**
   - 替换 `mascotPrimary` 为 `brandPrimary`。
10. **修改 `lib/core/motion/page_transitions.dart`**
    - 删除 `MascotHero` 与 `mascotHeroFlightShuttleBuilder`。
11. **修改 `lib/shared/widgets/lingxi_card.dart`、`lingxi_button.dart`、`lingxi_chip.dart`**
    - 检查并清理 mascot 相关逻辑，确保 Pixel MC 风格完整。

### Phase C：设置页主题切换器

12. **新增 `lib/features/settings/widgets/theme_flavor_selector.dart`**
13. **修改 `lib/features/settings/settings_page.dart`**
    - 添加主题风格分组。
    - 删除极简模式独立开关。

### Phase D：移除吉祥物目录与页面清理

14. **删除 `lib/features/mascot/` 目录**
15. **修改 `lib/features/home/home_page.dart`**
16. **修改 `lib/features/learning/learning_path_page.dart`**
17. **修改 `lib/features/learning/lesson_page.dart`**
18. **修改 `lib/features/learning/widgets/socratic_dialog_panel.dart`**
19. **修改 `lib/features/chat/chat_page.dart`**
20. **修改 `lib/features/chat/chat_controller.dart`**
21. **修改 `lib/features/onboarding/onboarding_page.dart`**
22. **修改 `lib/features/update/update_dialog.dart`**
23. **修改 `lib/features/progress/achievement_service.dart`**

### Phase E：新增游戏化组件与页面重设计

24. **新增 `lib/shared/widgets/xp_progress_ring.dart`**
25. **新增 `lib/shared/widgets/streak_flame_badge.dart`**
26. **新增 `lib/shared/widgets/achievement_badge_row.dart`**
27. **新增 `lib/shared/widgets/daily_goal_card.dart`**
28. **新增 `lib/shared/widgets/ai_thinking_indicator.dart`**
29. **新增 `lib/features/learning/widgets/level_node.dart`**
30. **新增 `lib/features/learning/widgets/level_path.dart`**
31. **新增 `lib/features/progress/gamification_service.dart`**
32. **修改 `lib/features/home/home_page.dart`**：集成新组件。
33. **修改 `lib/features/learning/learning_path_page.dart`**：改为关卡路径。

### Phase F：测试与文档

34. **更新/删除测试**：
    - 删除 `test/features/mascot/mascot_controller_test.dart`
    - 删除 `test/widget/mascot_widget_test.dart`
    - 修改 `test/empty_state_widget_test.dart`
    - 修改 `test/chat_controller_test.dart`
    - 修改 `test/achievement_service_test.dart`
    - 修改 `test/features/learning/course_level_extensions_test.dart`
    - 新增 `test/core/theme/theme_flavor_provider_test.dart`
    - 新增 `test/shared/widgets/xp_progress_ring_test.dart`
    - 新增 `test/shared/widgets/level_node_test.dart`
    - 新增 `test/features/home/home_page_no_mascot_test.dart`
35. **文档同步**：
    - 更新 `AGENTS.md`（目录结构、主题系统、版本演进）。
    - 更新 `docs/代码百科.md`。
    - 归档/删除 `docs/吉祥物设计.md`。
    - 更新 `CHANGELOG.md`。
    - 更新 `README.md` 截图描述。

---

## 10. 测试策略

遵循 TDD 原则：先写测试，再写实现，观察测试从红变绿。

### 10.1 必须验证的静态检查

```bash
flutter analyze
```

- 零 error、零 warning。
- 无 `MascotWidget`、`mascotControllerProvider`、`MascotHero`、`MascotOverlay` 残留引用。

```bash
flutter test
```

- 现有测试通过或更新。
- 新增测试通过。

### 10.2 新增测试清单

| 测试文件 | 覆盖内容 |
|----------|----------|
| `test/core/theme/theme_flavor_provider_test.dart` | 三 flavor 持久化、旧 minimal_mode 迁移、fromString 回退 |
| `test/core/theme/lingxi_colors_test.dart` | brandPrimary 派生、Pixel MC 固定色、toDark 对比度 |
| `test/shared/widgets/lingxi_card_test.dart` | 三 flavor 圆角/阴影差异 |
| `test/shared/widgets/lingxi_button_test.dart` | Pixel MC 按压缩放、Default 圆角 |
| `test/shared/widgets/xp_progress_ring_test.dart` | 进度 0/50/100、颜色变化 |
| `test/shared/widgets/level_node_test.dart` | 已完成/当前/锁定状态渲染 |
| `test/features/home/home_page_test.dart` | 无吉祥物、XP 环渲染、streak 徽章 |
| `test/features/learning/learning_path_page_test.dart` | 关卡节点渲染、筛选 Chip |
| `test/features/settings/settings_page_test.dart` | 主题切换器存在、切换后持久化 |
| `test/features/progress/achievement_service_test.dart` | 移除 mascot 依赖后成就解锁流程 |

### 10.3 手动验证清单

- [ ] 设置页切换 Default / Minimal / Pixel MC，卡片/按钮/输入框/对话框外观正确变化。
- [ ] Pixel MC 下所有组件为直角 + 厚边阴影；标题字体像素化。
- [ ] 开启系统「移除动画」后，Minimal 风味下所有按压/入场降级为即时切换。
- [ ] 首页、学习路径、对话页、设置页、空状态、引导页均无吉祥物。
- [ ] 学习路径节点完成/当前/锁定视觉区分明显；点击当前节点跳转正确 lesson。
- [ ] 三种主题在暗色模式下文字对比度符合 WCAG AA（可用 DevTools 对比度检查）。
- [ ] `PerformanceOverlay` 在首页与学习路径滑动中不出现红条。

---

## 11. 文档同步要求

根据 AGENTS.md「文档同步工作流」：

| 文档 | 更新内容 |
|------|----------|
| `AGENTS.md` | 更新「目录结构」（移除 mascot 模块、新增 gamification 组件）、「主题系统约定」（重命名颜色/字段）、「版本演进历史」新增版本行 |
| `docs/代码百科.md` | 更新主题、共享组件、progress 服务、成就服务章节 |
| `docs/吉祥物设计.md` | 标记为已归档或删除 |
| `CHANGELOG.md` | 在 `[Unreleased]` 下新增「新增/变更/移除」项 |
| `README.md` | 更新截图描述、功能特性、主题说明 |

PR 描述中必须勾选 AGENTS.md 文档同步检查清单。

---

## 12. 决策与假设

1. **吉祥物完全移除，不做降级保留**：不保留「小尺寸吉祥物」或「可选显示」开关。
2. **Pixel MC 主题复用现有 `ThemeFlavor.minecraft`**：保留枚举名 `minecraft`，UI 文案称「Pixel MC」。旧用户持久化值 `'minecraft'` 仍然有效。
3. **不引入新依赖**：字体使用 `google_fonts`；动画使用 Flutter 内置 + `SpringMotion`；图表使用 `CustomPainter`。
4. **Minimal 模式合并到 ThemeFlavor**：删除 `minimalModeProvider`，避免与 `themeFlavorProvider` 冲突。
5. **Duolingo 风格聚焦「路径 + 进度 + 激励」**：保留 streak、XP、成就三要素；排行榜/好友对战作为未来扩展。
6. **暗色模式与三种主题正交**：Default + dark、Minimal + dark、Pixel MC + dark 都需要单独调校对比度，确保 WCAG AA。
7. **AI 对话情绪反馈改为抽象状态**：thinking → 脉冲指示条；error → SnackBar + 输入框红边；celebrate → 全局粒子庆祝 +「+XP」浮层。
8. **本次不改动数据库 schema**：XP、每日目标基于现有 `Settings` 键值对或 `LearningEvents` 表计算。

---

## 13. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 吉祥物移除遗漏引用 | `flutter analyze` 失败 | 删除目录后全局 grep `mascot`、`Mascot`；修复所有引用后再提交 |
| `minimalModeProvider` 删除导致旧用户设置丢失 | 极简模式用户升级后变回 standard | 启动时一次性迁移：`minimal_mode=true` → `theme_flavor='minimal'` |
| Pixel MC 字体导致中文显示异常 | 中文 readability 下降 | Pixel MC 正文字体保持 NotoSansSC，仅标题使用 PressStart2P |
| 学习路径重设计影响导航逻辑 | 用户无法进入 lesson | 保留课程 ID/课时 ID 路由参数；仅改视觉布局 |
| 成就服务移除 mascot 后缺少反馈 | 用户解锁成就无感知 | 由 AchievementService 返回解锁事件，UI 层触发 CelebrationService + SnackBar |
| 暗色模式 WCAG 对比度不达标 | 可访问性问题 | 使用 DevTools 对比度检查；对 Pixel MC 暗色单独校准固定色 |
| 大范围改动导致测试回归 | CI 失败 | 每阶段运行 `flutter test` 子集；最终运行完整测试 |

---

## 14. 成功标准

- [ ] 所有页面不再引用 `MascotWidget` / `mascotControllerProvider` / `MascotHero` / `MascotOverlay`。
- [ ] `lib/features/mascot/` 目录已删除。
- [ ] 三种主题均能在设置页一键切换，颜色、形状、动效、字体随主题完整切换。
- [ ] 首页具备 Duolingo 风格的 XP 环、streak 徽章、每日目标、成就入口。
- [ ] 学习路径页改为关卡节点路径，状态区分清晰。
- [ ] `flutter analyze` 零 error、零 warning。
- [ ] `flutter test` 全部通过。
- [ ] 文档同步完成。

---

*计划基于 Duolingo Brand Guidelines（https://design.duolingo.com/）、项目现有 ThemeExtension Token 体系及代码库 mascot 引用清单制定。*
