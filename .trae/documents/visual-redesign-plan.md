# 灵犀学院视觉重设计完整计划

> 计划范围：Android + Windows 双端 Flutter 应用（lib/core/theme/、lib/features/mascot/、全部页面及共享组件）。
> 核心诉求：活泼亲和为主、支持极简模式、动画灵动、内嵌 Minecraft 彩蛋主题；可自由选色并改名。
> 计划性质：决策完备，执行者无需再做额外选择即可按步骤实施。

---

## 1. 目标与成功标准

### 1.1 目标
- 将现有以\"星空紫\"为主的视觉系统升级为\"活泼亲和、灵动有趣\"的学习伙伴风格。
- 提供一套可随时替换 seedColor 的完整主题 token，实现\"完全自由选色\"。
- 新增\"极简模式\"开关，一键切换为低饱和、低动效、高信息密度的学习专注界面。
- 新增 Minecraft 彩蛋主题：在特定触发条件下全局切换为像素块/体素风格，包括吉祥物、图标、卡片、背景纹理。
- 吉祥物\"小犀\"在保留 6 种核心情绪的基础上，形象更圆润、表情更夸张、动作更富弹性。
- 所有页面（首页、学习路径、课时、对话、笔记、成就、统计、设置、引导）统一接入新主题与吉祥物状态。

### 1.2 成功标准
- Flutter analyze 零 error、零 warning。
- Flutter test 全部通过（含新增主题/吉祥物/彩蛋测试）。
- 浅色/深色/Minecraft 三种主题在 Android 与 Windows 上视觉一致。
- reduceMotion（系统移除动画）与极简模式下，所有动效降级为即时切换或静态态。
- 主题 seedColor 修改后，除 Minecraft 主题固定风格外，其余页面无需改代码即可自动换色。
- 吉祥物 6 状态动画帧率稳定 60fps（PerformanceOverlay 无红条）。

---

## 2. 当前状态分析

### 2.1 主题系统现状
| 文件 | 现状 | 问题/机会 |
|------|------|-----------|
| lib/core/theme/app_theme.dart | 以 #6750A4 为 seedColor，使用 ColorScheme.fromSeed + GoogleFonts.notoSansScTextTheme + Quicksand 标题 | seed 与语义扩展分离；字体偏普通，缺乏活泼感 |
| lib/core/theme/lingxi_colors.dart | 6 个语义色（mascotPrimary、streakFire、achievementGold、socraticBlue、misconceptionRed 等） | 颜色偏紫/金，活泼度不足；缺少对话场景色 |
| lib/core/theme/lingxi_gradients.dart | 6 个语义渐变 | 渐变透明度写死，难以随 seedColor 自动变化 |
| lib/core/theme/lingxi_elevations.dart | 3 档语义阴影 + 5 级兼容层级 | 阴影在浅色下偏脏，暗色下发光感弱 |
| lib/core/theme/shape_variants.dart | 35 种形状变体 | capsule/octagon 仅近似，可补全真八角形与胶囊形 |

### 2.2 吉祥物现状
- 文件：lib/features/mascot/mascot_widget.dart（状态机见 mascot_controller.dart / mascot_state.dart）。
- 实现：_MascotPainter 使用 CustomPainter 纯矢量绘制一只戴学士帽的小犀牛。
- 6 状态：idle / happy / thinking / sad / celebrate / curious，已有完整动画。
- 问题：形象偏\"学士/星空\"，与\"活泼亲和\"诉求有距离；颜色硬编码在 painter 中，无法随主题自由换色。

### 2.3 页面现状
- 主要页面已使用 LingxiCard、LingxiButton、LingxiBadge、LingxiChip 等共享组件。
- home_page.dart、learning_path_page.dart、chat_page.dart、settings_page.dart 等存在不同程度的硬编码颜色、间距、圆角。
- 引导页视觉相对朴素，可强化吉祥物陪伴感。

### 2.4 动效现状
- SpringMotion 已提供六档弹簧 + 多种过渡组件。
- 机会：增加页面入场编排、列表 stagger、mascot 全身弹性动画、聊天消息气泡入场。

---

## 3. 风格方向：\"玩伴式学习宇宙\"

### 3.1 总体美学
- **Tone**：Playful / Toy-like / Friendly，但保留教育产品的清晰可读性。
- **关键词**：圆润、高饱和、 soft-shadow、轻微拟态、游戏化徽章、惊喜彩蛋。
- **设计语言**：
  - **圆润**：所有卡片、按钮、输入框采用大圆角（16~28dp）；吉祥物身体更球状。
  - **高饱和点缀**：主背景保持柔和（米白/浅灰/纯黑），用高饱和强调色点缀 CTA、徽章、进度、火焰。
  - **层次**：通过柔和的彩色渐变光晕、轻微阴影、毛玻璃分隔，而非生硬分割线。
  - **游戏化**：成就徽章、连续学习火焰、经验条采用 RPG 游戏风格，增强成就感。

### 3.2 与前端设计技能对齐
- **Typography**：放弃 Quicksand + Noto Sans SC 的常规组合，改用更有辨识度的组合：
  - 中文标题/正文：ZCOOL KuaiLe（快乐体）或 ZCOOL QingKe HuangYou（圆润可爱）用于大标题；正文仍用 Noto Sans SC 保证可读性。
  - 英文/数字：Fredoka 或 Nunito（圆润、带游戏感）。
  - 极简模式下回退到 Noto Sans SC + Roboto，去除装饰字体。
- **Color**：以 seedColor 为核心，但引入\"活泼版\"语义色：主色保持 seedColor；辅色采用互补/分裂互补色自动生成。
- **Motion**：
  - 页面级：staggered 入场（100ms 间隔），大标题从下方滑入 + 轻微弹跳。
  - 组件级：卡片 hover/pressed 缩放 + 阴影抬升；徽章解锁弹性放大 + 星光粒子。
  - mascot 级：全身 squash & stretch，庆祝时旋转跳跃。
- **Spatial Composition**：
  - 首页：非对称布局， mascot 位于左上或右上，学习卡片倾斜 2° 排列。
  - 聊天页： mascot 气泡与消息气泡错落分布。
- **Backgrounds & Details**：
  - 浅色背景加入极淡的网点/网格纹理或渐变光晕。
  - 暗色背景保留纯黑，但在 mascot 区域加入径向彩色辉光。

### 3.3 极简模式
- 通过设置开关 minimalModeProvider（bool）控制。
- 效果：颜色去色 30%~50%；禁用呼吸/脉冲/星光/渐变背景；圆角减小；mascot 隐藏或静态小图标；阴影降级为 1dp。
- 实现：新增 MinimalThemeExtension，在 AppTheme._buildTheme 中根据 minimalMode 选择实例。


---

## 4. 命名策略：从\"灵犀\"到\"波可学园\"（建议方案）

### 4.1 应用品牌名建议
用户要求\"可完全自由选色并改名\"，因此命名提供三套候选，最终由决策者选择。

| 候选名 | 英文名 | 含义与调性 | 适合方向 |
|--------|--------|------------|----------|
| **波可学园** | Poco Academy | \"Poco\"=小、一点点；波可谐音\"破壳\"，寓意突破、孵化 | 活泼、低龄友好 |
| **奇点学园** | Singularity Academy | 奇点=AI 与知识的爆发点 | 科技感、进阶学习者 |
| **萤火学院** | Firefly Academy | 萤火=微光、陪伴、探索 | 温暖、亲和、治愈 |
| **方块学园** | Block Academy | 直接呼应 Minecraft 彩蛋 | 游戏化、青少年 |

**推荐**：波可学园 / Poco Academy。
- 新包名可保持 lingxi_academy（技术不变）或改为 poco_academy（需同步 Android applicationId、Windows 包名、CI）。
- 若保留包名，仅改显示名称与应用内文案。

### 4.2 吉祥物名建议
- 现有：\"小犀\"
- 建议：保留并升级，但增加昵称 Poco（波可）。
- 文档中统一称为：\"波可（Poco）—— 你的 AI 学习伙伴\"。

### 4.3 组件命名调整
- 现有 LingxiColors / LingxiGradients / LingxiElevations 可保留类名（技术债务小），但对外文案全部替换。
- 若执行\"彻底改名\"，则：
  - LingxiColors -> PocoColors
  - LingxiGradients -> PocoGradients
  - LingxiElevations -> PocoElevations
  - LingxiCard -> PocoCard
  - LingxiButton -> PocoButton
  - 以此类推。
- **决策**：本次重设计推荐保留类名前缀 Lingxi（减少重构量），但所有用户可见字符串、文档、README 改用新名。

---

## 5. 设计 Token 系统

所有 Token 以 ThemeExtension 形式注册到 ThemeData.extensions，并通过 BuildContext 扩展读取。禁止在业务代码中硬编码颜色/字体/阴影/形状。

### 5.1 颜色 Token（Color Tokens）

#### 5.1.1 Seed Color 策略
- 文件：lib/core/theme/app_theme.dart
- 修改：
  - 将 static const Color seedColor = Color(0xFF6750A4); 改为可由构建时配置。
  - 提供三种预设种子色，可通过 SharedPreferences 切换：
    - playfulCoral = #FF6B6B
    - playfulAqua = #4ECDC4
    - playfulLime = #A8E063
    - 默认保留 starlightPurple = #6750A4 作为怀旧色。
  - 新增 seedColorProvider（StateProvider<Color>），在 app.dart 中注入 ProviderScope。
  - AppTheme.lightTheme / darkTheme 改为方法：AppTheme.themeFor(Brightness brightness, {Color? seed, bool minimal = false})。

#### 5.1.2 语义色扩展 LingxiColors
在现有 6 个语义色基础上扩展为 12 个，全部从 seedColor 派生：

| Token | 用途 | 生成规则 |
|-------|------|----------|
| mascotPrimary | 吉祥物身体、主图标 | seedColor 偏亮 |
| mascotSecondary | 吉祥物高光、腮红 | seedColor 的补色/邻近色 |
| streakFire | 连续学习火焰 | 固定高饱和橙红，保证激励感 |
| achievementGold | 成就徽章 | 固定金色，保证识别度 |
| socraticBlue | 苏格拉底引导气泡 | seedColor 的冷色分裂补色 |
| misconceptionRed | 错误提示 | 固定红 |
| successGreen | 成功/完成 | 固定绿 |
| infoTeal | 提示/信息 | seedColor 调和后的青蓝 |
| chatUserBubble | 用户消息气泡背景 | seedColor 容器色 |
| chatAssistantBubble | AI 消息气泡背景 | surfaceContainerHighest |
| highlightYellow | 高亮标记 | 固定黄 |
| minecraftGrass | Minecraft 彩蛋草地绿 | 固定 #5D8C22 |

light/dark/minimal 三个实例均需提供。minimal 实例中所有语义色饱和度降低 35%。

#### 5.1.3 动态生成辅助
新增 lib/core/theme/color_utils.dart：
- Color harmonyComplementary(Color c)：生成补色。
- Color harmonySplitComplementary(Color c, bool left)：生成分裂补色。
- Color desaturate(Color c, double amount)：去色。
- Color withLightness(Color c, double lightness)：调整 HSL 亮度。

### 5.2 字体 Token（Typography Tokens）

#### 5.2.1 字体选择
| 场景 | 默认主题字体 | 极简模式字体 |
|------|--------------|--------------|
| 中文大标题 | ZCOOL KuaiLe | Noto Sans SC |
| 中文正文 | Noto Sans SC | Noto Sans SC |
| 英文/数字标题 | Fredoka | Roboto |
| 英文/数字正文 | Nunito | Roboto |

#### 5.2.2 实现
- 在 app_theme.dart 中：
  - 默认主题：GoogleFonts.zcoolKuaiLeTextTheme 覆盖 display/headline/title；正文用 
otoSansScTextTheme。
  - 极简主题：全部回退 
otoSansScTextTheme + 
obotoTextTheme。
- 新增 AppTypography extends ThemeExtension<AppTypography>：
  - fontFamilyDisplay、fontFamilyBody、fontFamilyMono。
  - 提供 playful 与 minimal 两个实例。

### 5.3 形状 Token（Shape Tokens）
- 保留 ShapeVariants 枚举，但补充：
  - capsule 系列返回真实 StadiumBorder 而非近似圆角矩形。
  - octagon 系列返回真实 OctagonBorder（已在 lingxi_badge.dart 内部实现，提取到 shape_variants.dart）。
- 新增 ShapeTokens extends ThemeExtension<ShapeTokens>：
  - cardRadius、buttonRadius、dialogRadius、chipRadius、inputRadius、vatarRadius。
  - 默认 playful：card=24，button=16，dialog=28，chip=12，input=16，avatar=9999。
  - 极简模式：所有 radius 减半。

### 5.4 动效 Token（Motion Tokens）
- 现有 SpringMotion 已覆盖，新增 MotionTokens extends ThemeExtension<MotionTokens>：
  - pageEntranceDelay、listStaggerDelay、cardHoverScale、buttonPressedScale、mascotSquashScale。
  - playful：pageEntranceDelay=80ms，listStaggerDelay=60ms，cardHoverScale=1.02，buttonPressedScale=0.95，mascotSquashScale=1.12。
  - minimal：所有 scale=1.0，所有 delay=0ms。

### 5.5 阴影/海拔 Token（Elevation Tokens）
- 重构 LingxiElevations：
  - subtle、elevated、highlighted 三档保留。
  - 阴影颜色改为带 seedColor 色调的黑色/白色（更柔和）。
  - 暗色模式阴影使用半透明 seedColor 代替纯白，避免脏感。
- 新增 AmbientGlow token：控制 mascot 区域径向辉光的透明度与尺寸。

### 5.6 纹理/背景 Token
- 新增 BackgroundTextures extends ThemeExtension<BackgroundTextures>：
  - dotPattern：极淡网点（light mode）。
  - gridPattern：淡网格（dark mode / minimal）。
  - minecraftDirt：Minecraft 彩蛋 dirt 纹理（仅在彩蛋主题启用）。
- 实现方式：使用 CustomPainter 绘制背景图案，而非大图片，保证性能。


---

## 6. 吉祥物重设计：\"波可 Poco\"

### 6.1 形象方向
- **物种**：保留犀牛，但造型从\"学士\"转向\"玩伴\"：
  - 身体更圆润、更矮胖（头部占比从 60% 降到 55%，身体占比提升）。
  - 学士帽可选保留（作为\"小学者\"标志），但增加一个可切换的\"探险帽\"变体。
  - 角变小变圆，颜色可随 mascotPrimary 变化。
  - 翅膀保留，但形状更 Q，增加拍打幅度。
  - 新增\"肚皮\"高光与腮红，增强亲和力。
- **眼睛**：更大、更圆，不同情绪下瞳孔形状变化更丰富。
- **颜色**：全部从 LingxiColors 读取，不再硬编码；Minecraft 主题下转为 8-bit 像素块风格。

### 6.2 6 种情绪升级
| 情绪 | 旧表现 | 新表现 | 动画升级 |
|------|--------|--------|----------|
| idle | 眨眼 + 轻微摇摆 | 慢速呼吸起伏 + 偶尔眨眼 + 翅膀轻扇 | 加入 squash & stretch 呼吸 |
| happy | 跳跃 + 微笑 | 原地小跳 + 张嘴笑 + 腮红加深 + 星星眼 | 落地时身体压扁反弹 |
| thinking | 托腮 + 问号 | 歪头 + 头顶灯泡/问号渐变出现 + 翅膀收起 | 灯泡淡入 + 头部小幅度晃动 |
| sad | 低头 + 泪滴 | 耳朵下垂 + 大眼睛含泪 + 泪滴沿脸颊滑落 | 泪滴使用弹簧下落 |
| celebrate | 欢呼 + 星星 | 旋转跳跃 + 彩色纸屑喷发 + 身体彩虹高光 | 全身旋转 + 粒子爆发 |
| curious | 歪头 + 放大镜 | 一只眼睛放大 + 放大镜举起 + 头倾斜 15° | 放大镜跟随头部晃动 |

### 6.3 新增状态与彩蛋
- **Minecraft 情绪 blocky**：彩蛋主题下，吉祥物变成像素风体素角色，所有动作改为 8-bit 跳跃/转身。
- **Sleepy 状态**（可选）：长时间无操作后打哈欠。
- **Surprised 状态**（可选）：解锁隐藏成就时震惊。

### 6.4 实现文件
- lib/features/mascot/poco_painter.dart：新的 CustomPainter，完全替换 _MascotPainter。
- lib/features/mascot/mascot_theme.dart：定义吉祥物颜色/纹理配置，支持 pixel/blocky 模式。
- lib/features/mascot/mascot_widget.dart：改造为 PocoWidget，支持 style: PocoStyle.smooth | PocoStyle.pixel。
- lib/features/mascot/particle_field.dart：将彩蛋粒子从 painter 内部分离，复用 shared/widgets/particles/particle_painter.dart。

### 6.5 性能要求
- PocoPainter 使用 RepaintBoundary 隔离。
- 动画使用 AnimationController + AnimatedBuilder，避免 setState 重绘父级。
- 粒子数量上限：默认 16 个，彩蛋 32 个。
- 60fps 验证：在 home/chat/achievements 三页滑动时 PerformanceOverlay 无红条。

---

## 7. Minecraft 彩蛋主题

### 7.1 触发方式
提供三种触发方案，推荐全部实现：
1. **设置页开关**：Settings -> 外观 -> 开启方块模式。
2. **秘钥手势**：连续点击首页 mascot 7 次，弹窗确认进入。
3. **特殊日期/成就**：解锁\"方块大师\"成就后永久开启入口。

### 7.2 视觉表现
- **全局**：
  - 背景替换为 Minecraft 风格 dirt/grass 纹理或像素天空渐变。
  - 所有卡片变为直角或 4px 小圆角，带像素边框。
  - 阴影消失，改为底部/右侧像素厚边（类似体素挤出效果）。
  - 字体切换为像素风字体（中文用 ZCOOL KuaiLe 已有方块感；英文用 Press Start 2P 或 VT323）。
- **图标**：
  - Material Icons 保持，但增加 IconTheme 描边/像素化滤镜。
  - 或使用自定义像素图标集（用户提供 SVG/PNG）。
- **吉祥物**：
  - 全身转为 8-bit 像素块，保留 6 情绪。
  - idle 时轻微上下浮动；happy 时 8-bit 跳跃；celebrate 时周身掉落像素方块。
- **交互**：
  - 按钮点击时播放 8-bit 音效（需要 audioplayers 依赖，**需用户确认是否引入**）。
  - 若不引入音效，可用触觉反馈替代。

### 7.3 实现架构
- 新增 lib/core/theme/theme_mode_provider.dart 扩展：
  - ThemeFlavor 枚举：standard、minimal、minecraft。
  - themeFlavorProvider（StateNotifierProvider 或 StateProvider）。
- AppTheme 根据 ThemeFlavor 生成对应 ThemeData。
- PocoWidget.style 读取 ThemeFlavor，自动切换 smooth/pixel。
- LingxiCard / LingxiButton 内部读取 ThemeFlavor，在 minecraft 模式下调整圆角、阴影、边框。

### 7.4 资源需求
| 资源 | 来源 | 说明 |
|------|------|------|
| 像素 dirt/grass 纹理 | 用户提供或程序生成 | 可用 CustomPainter 绘制 16x16 像素块重复图案 |
| 像素字体 | Google Fonts | Press Start 2P（英文）、ZCOOL KuaiLe（中文） |
| 8-bit 音效 | 可选 | 若引入 audioplayers，需提供 .wav 文件 |
| 像素图标 | 用户提供或 Material Icons | 可用 Material Icons + 描边模拟 |

### 7.5 不引入新依赖的备选
- 不使用 audioplayers，音效用系统触感（Haptic）+ 视觉反馈（按钮缩放 0.9 + 像素粒子）。
- 纹理全部程序生成，不引入图片资源。


---

## 8. 页面重设计优先级与策略

按\"用户高频 + 视觉影响大\"排序，分三阶段实施。

### 8.1 P0：首页 + 吉祥物壳 + 主题系统
**目标**：建立新的视觉基线，所有其他页面依赖于此。

| 文件 | 修改内容 |
|------|----------|
| lib/core/theme/app_theme.dart | 改为 themeFor(Brightness, seed, flavor)；注册新 ThemeExtensions |
| lib/core/theme/lingxi_colors.dart | 扩展为 12 语义色，支持 desaturate |
| lib/core/theme/lingxi_gradients.dart | 渐变颜色从 seedColor 派生，支持 minecraft |
| lib/core/theme/lingxi_elevations.dart | 阴影改为 seedColor 色调，支持 pixel 边框替代 |
| lib/core/theme/shape_variants.dart | capsule 返回 StadiumBorder；octagon 提取公共 Border |
| lib/core/theme/theme_flavor_provider.dart | 新增 ThemeFlavor 与 Provider |
| lib/core/theme/color_utils.dart | 新增色彩和谐工具 |
| lib/core/theme/app_typography.dart | 新增字体 ThemeExtension |
| lib/core/theme/background_textures.dart | 新增背景纹理 ThemeExtension |
| lib/features/mascot/mascot_widget.dart | 重构为 PocoWidget，接入 ThemeFlavor |
| lib/features/mascot/poco_painter.dart | 新 painter，圆润玩伴风格 |
| lib/features/mascot/pixel_poco_painter.dart | Minecraft 主题 pixel painter |
| lib/features/home/home_page.dart | 新布局：非对称、大 mascot、倾斜卡片、stagger 入场 |
| lib/shared/widgets/lingxi_card.dart | 支持 flavor、阴影/像素边框切换 |
| lib/shared/widgets/lingxi_button.dart | 支持 flavor、按压 scale 可调 |

### 8.2 P1：学习路径 + 课时 + 对话
**目标**：核心学习流程视觉升级。

| 文件 | 修改内容 |
|------|----------|
| lib/features/learning/learning_path_page.dart | 课程卡片改为横向滚动 + 进度环 + 解锁动画 |
| lib/features/learning/widgets/learning_card_widget.dart | 新课程卡片：封面渐变、等级徽章、完成彩带 |
| lib/features/learning/lesson_page.dart | 顶部 mascot 提示气泡、知识点卡片大圆角、测验选项弹性反馈 |
| lib/features/learning/widgets/quiz_widget.dart | 选项卡片选中态缩放 + 颜色反馈 |
| lib/features/chat/chat_page.dart | 消息气泡新样式、输入框悬浮、mascot 状态联动 |
| lib/features/chat/chat_desktop_layout.dart | 桌面端侧边栏卡片样式统一 |
| lib/features/chat/chat_list_page.dart | 会话列表项改为头像 + 摘要 + 时间戳 |

### 8.3 P2：笔记 + 成就 + 统计 + 设置 + 引导
**目标**：周边页面风格统一。

| 文件 | 修改内容 |
|------|----------|
| lib/features/notes/notes_page.dart | 笔记卡片网格布局、新建按钮悬浮 |
| lib/features/notes/note_editor_page.dart | 编辑器工具栏图标主题色、保存成功 mascot 庆祝 |
| lib/features/progress/achievements_page.dart | 徽章墙、解锁动画、连续点击彩蛋 |
| lib/features/progress/statistics_page.dart | 图表配色接主题、卡片布局 |
| lib/features/settings/settings_page.dart | 新增\"主题与外观\"分组：seedColor、flavor、minimal 开关 |
| lib/features/settings/api_settings_page.dart | 卡片与按钮样式统一 |
| lib/features/onboarding/onboarding_page.dart | 全屏插图 + mascot 对话气泡 + 分页指示器 |
| lib/features/onboarding/api_setup_wizard_page.dart | 步骤卡片 + mascot 鼓励态 |
| lib/features/onboarding/learner_profile_setup_page.dart | 年龄选择器改为大图标卡片 |
| lib/features/help/help_center_page.dart | 可折叠卡片、搜索高亮 |

### 8.4 P3：空状态 + 加载 + 错误态
**目标**：覆盖所有边缘状态。

| 文件 | 修改内容 |
|------|----------|
| lib/shared/widgets/empty_state_widget.dart | 新空状态：mascot 居中 + 渐变背景 + CTA 按钮 |
| lib/shared/widgets/shimmer_loading.dart |  shimmer 颜色接主题 |
| lib/shared/widgets/lingxi_toast.dart |  toast 圆角、图标、动效 |
| lib/shared/widgets/lingxi_dialog.dart |  dialog 大圆角、阴影、入场动画 |
| lib/shared/widgets/celebration_overlay.dart |  庆祝粒子接主题色 |

---

## 9. 状态与组件映射

### 9.1 情绪状态触发点（保留并扩展）
| 页面/事件 | 触发情绪 | 说明 |
|-----------|----------|------|
| 应用启动 | idle -> curious | mascot 歪头欢迎 |
| 进入首页 | happy / idle | 根据当天学习状态 |
| 开始学习 | thinking | AI 准备课程 |
| 答对测验 | celebrate | 弹出正确反馈 |
| 答错测验 | sad -> curious | 先难过再引导思考 |
| 发送消息 | thinking | AI 流式回复中 |
| 收到回复 | celebrate | 回复完成 |
| AI 出错 | sad | 持续显示直到下次交互 |
| 解锁成就 | celebrate | 触发庆祝覆盖层 |
| 连续学习 streak≥3 | happy | 火焰徽章旁 mascot 开心 |
| 进入 Minecraft 主题 | blocky | 专属像素情绪 |
| 长按/连续点击 mascot 7 次 | 弹窗 -> blocky | 彩蛋入口 |

### 9.2 主题 Flavor 对组件的影响矩阵
| 组件 | standard | minimal | minecraft |
|------|----------|---------|-----------|
| LingxiCard | 大圆角 24、彩色渐变光晕、柔和阴影 | 小圆角 12、无渐变、1dp 边框 | 直角/4px 圆角、像素边框、无阴影 |
| LingxiButton | 大圆角 16、按压 0.95、阴影抬升 | 小圆角 8、无缩放、无边框 | 直角、按压 0.9、像素厚边 |
| LingxiBadge | 八角形/圆形、金色呼吸、星光 | 灰色静态 | 像素块风格 |
| LingxiChip | 胶囊形、种子色背景 | 矩形小圆角、灰色背景 | 像素标签 |
| LingxiTextField | 圆角 16、聚焦 2dp 主题色边框 | 矩形 4dp、细边框 | 直角、像素边框 |
| LingxiAppBar | 透明/渐变、居中标题 | 纯白/纯黑、左对齐标题 | 像素 grass 纹理背景 |
| PocoWidget | 圆润矢量、 squash & stretch | 静态小图标 | 8-bit 像素、方块掉落 |


---

## 10. 文档同步清单

根据 AGENTS.md 第 21 章，任何架构/约定/版本变更必须同步以下文档。本计划实施前后必须完成：

### 10.1 代码实施前必须更新的文档
- [ ] docs/design-tokens.json
  - 更新 meta.seedColor 为可配置说明。
  - 新增 flavor（standard/minimal/minecraft）token 分组。
  - 新增 typography 下 zcoolKuaiLe、redoka、
unito 条目。
  - 新增 color 下 12 语义色（含 minecraft 固定色）。
  - 新增 	exture 分组。
- [ ] docs/前端重设计指南.md
  - 记录本次重设计目标、风格方向、命名策略。
  - 记录 ThemeFlavor 与 MinimalMode 架构。
  - 记录 Minecraft 彩蛋触发方式与视觉规则。
- [ ] docs/吉祥物设计.md
  - 更新波可（Poco）形象描述、6 情绪设计、pixel 模式。
  - 记录颜色读取方式（不再硬编码）。
- [ ] docs/代码百科.md
  - 新增 ThemeFlavorProvider、AppTypography、BackgroundTextures、PocoPainter 说明。
  - 更新 LingxiColors 字段说明。

### 10.2 代码实施后必须更新的文档
- [ ] AGENTS.md
  - 「主题系统约定」更新为新 ThemeExtension 列表与使用方式。
  - 「吉祥物交互扩展规范」更新为 Poco 6 情绪 + blocky 彩蛋。
  - 「已知技术债」增加：\"pixel 图标资源、8-bit 音效、Rive 资源待完善\"。
- [ ] CHANGELOG.md
  - 在 [Unreleased] 新增 ### 新增：主题 flavor、minimal 模式、Minecraft 彩蛋、Poco 新形象等。
- [ ] README.md
  - 更新应用名称、截图说明、主题特性。
- [ ] SECURITY.md
  - 若新增音效/网络资源，需说明资源来源与权限边界。

### 10.3 不更新文档的禁止项
- 任何新增 ThemeExtension 未在 docs/design-tokens.json 与 docs/代码百科.md 中说明，视为不完整。
- 任何新 Provider 未在 AGENTS.md 状态管理章节补充示例，视为不完整。

---

## 11. 验证步骤

### 11.1 静态验证
1. Flutter analyze
   - 期望：零 error、零 warning。
   - 若出现 prefer_const_constructors info，需在 PR 中说明。
2. Flutter pub run build_runner build --delete-conflicting-outputs
   - 确认无 Drift/Riverpod 生成错误。
3. 检查无硬编码颜色：
   - grep -r "Color(0xFF" lib/ --include="*.dart"
   - 期望：仅 app_theme.dart / lingxi_colors.dart / color_utils.dart 等主题层文件保留；业务代码无匹配。

### 11.2 单元/Widget 测试
1. Flutter test
   - 全部现有测试通过。
2. 新增测试：
   - test/core/theme/color_utils_test.dart：色彩和谐/去色函数。
   - test/core/theme/app_theme_test.dart：standard/minimal/minecraft 主题生成。
   - test/features/mascot/poco_painter_test.dart：painter 不崩溃、不同 size 下绘制。
   - test/features/mascot/pixel_poco_painter_test.dart：pixel 模式绘制。
   - test/features/mascot/mascot_controller_test.dart：7 次点击触发彩蛋。
   - test/shared/widgets/lingxi_card_test.dart：三种 flavor 下圆角/阴影正确。
   - test/shared/widgets/lingxi_button_test.dart：flavor 切换后按压 scale 正确。
   - test/features/settings/settings_page_test.dart：seedColor/flavor/minimal 切换生效。

### 11.3 手动视觉验证
1. **首页**：
   - mascot 呼吸、点击 happy、连续点击 7 次弹出 Minecraft 彩蛋确认。
   - 切换 seedColor（红/青/绿）， mascot 与卡片颜色自动变化。
2. **学习路径**：
   - 课程卡片入场 stagger；未解锁卡片灰色，已解锁带彩色光晕。
   - 点击课程 mascot 切换 thinking。
3. **课时页**：
   - 测验答对/答错 mascot 反馈；滚动时列表不丢帧。
4. **对话页**：
   - 发送消息 mascot thinking；AI 回复完成 celebrate。
   - 用户/AI 气泡颜色区分。
5. **设置页**：
   - standard/minimal/minecraft 切换即时生效。
   - minimal 下 mascot 隐藏、动画停止。
6. **成就页**：
   - 新解锁徽章弹性放大 + 星光粒子。
7. ** reduceMotion 验证**：
   - 在系统设置开启\"移除动画\"，确认所有动画即时切换，无残留循环动画。

### 11.4 性能验证
1. Flutter run --profile 打开 PerformanceOverlay。
2. 在首页、学习路径、对话列表、成就页快速滑动，UI 线程无红条。
3. mascot 区域使用 RepaintBoundary 隔离，父级 rebuild 不触发 mascot 重绘。

### 11.5 双端验证
- Android：真机/模拟器验证 NavigationBar、卡片阴影、APK 体积无明显增长。
- Windows：桌面窗口验证 NavigationRail、卡片 hover 效果、像素字体渲染。

---

## 12. 决策与假设

### 12.1 关键决策
1. **保留 Lingxi* 类名前缀**：减少重构量，仅用户可见字符串改名。
2. **Minecraft 彩蛋不引入 audioplayers**：使用 Haptic + 视觉反馈，避免新依赖与权限。
3. **纹理程序生成**：不引入图片资源，保证安装包体积与版权安全。
4. **字体从 Google Fonts 在线加载**：默认主题使用 ZCOOL KuaiLe / Fredoka，离线场景首次加载可能略有延迟， acceptable。
5. **seedColor 派生辅色**：不预设固定辅色，使用色彩和谐算法，确保任意 seedColor 都协调。
6. **mascot 保留 CustomPainter**：Rive 资源未就绪，继续用矢量 painter；pixel 模式用第二个 painter 实现。

### 12.2 假设
- 用户接受推荐名 波可学园 / Poco Academy，或会在实施前确认最终名称。
- 用户提供或确认不使用 Minecraft 官方素材（避免版权风险）；程序生成的像素块风格属于安全范围。
- 用户同意在 pubspec.yaml 中新增 google_fonts 已支持的字体（无需新增依赖）。
- 用户同意新增 ThemeFlavor 持久化到 SharedPreferences（不新增 Drift 表）。

### 12.3 需要用户确认的项
1. 最终应用名称（推荐 波可学园 / Poco Academy）。
2. 是否引入音效依赖 audioplayers（推荐否）。
3. 是否引入像素图标资源包（推荐否，程序生成替代）。
4. Minecraft 彩蛋触发手势是否保留 7 次点击（或其他方案）。


---

## 13. 风险与回退方案

| 风险 | 影响 | 回退方案 |
|------|------|----------|
| Google Fonts 在线字体在弱网加载失败 | 首次启动字体闪烁或 fallback | 在 app_theme.dart 中配置 fontFamilyFallback: ['Noto Sans SC', 'Roboto'] |
| 新 mascot painter 性能不达标 | 低端设备掉帧 | 保留旧 _MascotPainter 作为 PocoWidget.fallback，通过 feature flag 切换 |
| 任意 seedColor 导致对比度不足 | 可访问性失败 | color_utils.dart 中强制调整生成色的亮度，确保 WCAG AA |
| Minecraft 主题与 Material 3 组件冲突 | 部分组件样式不统一 | 为 Card、Button、Dialog 提供 minecraft 覆盖的 ThemeData 子集 |
| 重设计改动面过大导致回归 | 测试失败 | 分阶段合并，每阶段独立通过 CI；P0 完成后再进入 P1 |
| 用户不接受新名称 | 品牌混乱 | 类名保持 Lingxi*，仅文案可配置，随时回滚名称 |

---

## 14. 实施顺序摘要

### 阶段 A：主题基础设施（所有页面依赖）
1. 新增 color_utils.dart、pp_typography.dart、background_textures.dart、theme_flavor_provider.dart。
2. 重构 lingxi_colors.dart、lingxi_gradients.dart、lingxi_elevations.dart、shape_variants.dart。
3. 改造 app_theme.dart 为 themeFor(Brightness, seed, flavor)。
4. 在 app_providers.dart 注册 seedColorProvider、themeFlavorProvider、minimalModeProvider。
5. 更新 app.dart 读取这些 Provider 并注入主题。

### 阶段 B：吉祥物升级
1. 创建 poco_painter.dart 与 pixel_poco_painter.dart。
2. 改造 mascot_widget.dart 为 PocoWidget，支持 style 切换与 7 次点击彩蛋。
3. 更新 mascot_controller.dart：新增 blocky 状态切换、7 次点击检测。
4. 在 mascot_overlay.dart 等位置接入新 widget。

### 阶段 C：共享组件升级
1. 升级 lingxi_card.dart、lingxi_button.dart、lingxi_badge.dart、lingxi_chip.dart、lingxi_text_field.dart、lingxi_app_bar.dart。
2. 支持三种 flavor 的圆角/阴影/边框/按压反馈。
3. 新增空状态、toast、dialog、celebration overlay 的视觉风格。

### 阶段 D：页面重设计
1. P0：home_page.dart。
2. P1：learning_path_page.dart、lesson_page.dart、chat_page.dart。
3. P2：
otes_page.dart、achievements_page.dart、statistics_page.dart、settings_page.dart、引导页、help_center_page.dart。

### 阶段 E：测试与文档
1. 编写新增测试。
2. 运行 Flutter analyze 与 Flutter test。
3. 同步更新 docs/design-tokens.json、docs/前端重设计指南.md、docs/吉祥物设计.md、docs/代码百科.md、AGENTS.md、CHANGELOG.md、README.md。

---

## 15. 输出产物

本计划实施后应产生以下新增/修改文件（非 exhaustive）：

### 新增文件
- lib/core/theme/color_utils.dart
- lib/core/theme/app_typography.dart
- lib/core/theme/background_textures.dart
- lib/core/theme/theme_flavor_provider.dart
- lib/features/mascot/poco_painter.dart
- lib/features/mascot/pixel_poco_painter.dart
- test/core/theme/color_utils_test.dart
- test/core/theme/app_theme_test.dart
- test/features/mascot/poco_painter_test.dart
- test/features/mascot/pixel_poco_painter_test.dart

### 修改文件
- lib/core/theme/app_theme.dart
- lib/core/theme/lingxi_colors.dart
- lib/core/theme/lingxi_gradients.dart
- lib/core/theme/lingxi_elevations.dart
- lib/core/theme/shape_variants.dart
- lib/core/providers/app_providers.dart
- lib/features/mascot/mascot_widget.dart
- lib/features/mascot/mascot_controller.dart
- lib/features/mascot/mascot_state.dart
- lib/shared/widgets/lingxi_card.dart
- lib/shared/widgets/lingxi_button.dart
- lib/shared/widgets/lingxi_badge.dart
- lib/shared/widgets/lingxi_chip.dart
- lib/shared/widgets/lingxi_text_field.dart
- lib/shared/widgets/lingxi_app_bar.dart
- lib/shared/widgets/empty_state_widget.dart
- lib/shared/widgets/lingxi_toast.dart
- lib/shared/widgets/lingxi_dialog.dart
- lib/shared/widgets/celebration_overlay.dart
- lib/features/home/home_page.dart
- lib/features/learning/learning_path_page.dart
- lib/features/learning/lesson_page.dart
- lib/features/learning/widgets/learning_card_widget.dart
- lib/features/learning/widgets/quiz_widget.dart
- lib/features/chat/chat_page.dart
- lib/features/notes/notes_page.dart
- lib/features/progress/achievements_page.dart
- lib/features/progress/statistics_page.dart
- lib/features/settings/settings_page.dart
- lib/features/onboarding/onboarding_page.dart
- lib/app.dart
- docs/design-tokens.json
- docs/前端重设计指南.md
- docs/吉祥物设计.md
- docs/代码百科.md
- AGENTS.md
- CHANGELOG.md
- README.md

---

*本计划由 Trae Design 规划代理基于项目现状、frontend-design 技能要点及用户诉求制定。实施前请确认第 12.3 节中的待确认项。*
