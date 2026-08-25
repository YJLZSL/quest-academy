# 问学 Quest Academy

> 引导式 AI 学习应用 —— 让每个人都能在 AI 时代学会学习

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-blue)](#)
[![Flutter](https://img.shields.io/badge/Flutter-3.44.4-02569B?logo=flutter)](https://flutter.dev)
[![Version](https://img.shields.io/badge/Version-v0.6.0-3D5AFE)](#)

问学 Quest Academy 是一款开源的引导式 AI 学习应用，以**苏格拉底式对话**为核心教学方式——通过引导式提问而非直接给答案，培养批判性思维与自主学习能力。

## 项目状态

| 项 | 状态 |
|----|------|
| 当前版本 | v0.6.0（问学 Quest Academy 品牌版） |
| 支持平台 | Android + Windows |
| CI 状态 | GitHub Actions（质量门禁 + 双端构建发布） |
| 测试覆盖 | 149+ 测试用例 |
| 开源协议 | MIT |

## 核心理念

- **非商业化** —— MIT 协议开源，无付费墙、无广告
- **用户自备 API** —— 用户自行配置 API Key（OpenAI / Claude / Gemini / Ollama），仅本地加密存储，**永不上传**
- **苏格拉底式引导** —— AI 导师以提问引导思考，培养独立思考与问题拆解能力

## 学习路径 L0-L4

| 级别 | 定位 | 内容方向 |
|------|------|----------|
| **L0** | 启蒙 | AI 基础概念与工具入门 |
| **L1** | 基础 | 编程语言与提示词工程 |
| **L2** | 进阶 | 机器学习与数据处理 |
| **L3** | 实践 | 深度学习与模型训练 |
| **L4** | 应用 | AI 项目实战与部署 |

每个知识点包含：知识卡片学习 → 测验检验 → 苏格拉底式对话深化，完成即解锁下一节点。

## 功能特性

- 🤔 **引导式学习** —— 苏格拉底式问答，AI 不给答案给引导
- 💬 **自由对话** —— 支持 OpenAI / Claude / Gemini / Ollama 四类 Provider
- 📚 **学习路径** —— 结构化知识点卡片 + 测验 + 苏格拉底对话
- 🎮 **游戏化激励** —— Streak 连续打卡、每日 XP 目标、成就徽章、关卡路径、粒子庆祝反馈
- 🎨 **三档主题风格** —— 默认（Duolingo 式活泼）、极简（低动效专注）、Pixel MC（像素块体素风），设置页一键切换
- 🔥 **Streak 打卡** —— 连续学习天数追踪 + 成就徽章系统
- 🔍 **分级探索** —— 简化 / 深入 / 图示三按钮，按需调整回复详略
- 🔒 **数据安全** —— API Key 硬件级加密存储，日志自动脱敏
- 🖥️ **双端支持** —— Android + Windows
- 📝 **富文本渲染** —— Markdown + LaTeX 数学公式 + 代码高亮
- 🔄 **应用内自动更新** —— 基于 GitHub Releases API，启动自动检查 + 手动触发，Android APK / Windows ZIP 双端支持，无需反复卸载重装

## 动画亮点

v0.3.0 在动画与性能体验上全面打磨，目标 60fps 无丢帧：

- 🎮 **游戏化反馈动画** —— 知识点完成触发粒子爆发、+XP 浮层、Streak 火焰跳动、成就徽章弹性入场
- 🎨 **微交互反馈** —— 按压（`QuestButton` scale 0.96 / `QuestCard` scale 0.99）、选中（`QuestChip` `AnimatedSwitcher`）、过渡均有弹性动画
- 🌊 **流式响应节流** —— 首 token 立即渲染，后续 50ms 节流刷新，流式结束强制刷新，兼顾即时反馈与性能
- ♿ **无障碍降级** —— `reduceMotion` 全覆盖，开启系统"移除动画"后所有动画降级为即时切换或按钮切换
- 📊 **性能预算** —— 60fps 目标，`RepaintBoundary` 隔离持续动画，`cacheExtent` 优化列表滚动，`PerformanceOverlay` 静态审查无红条

## 下载安装

前往 [Releases](https://github.com/YJLZSL/quest-academy/releases) 下载最新版本：

- **Android**：下载 `.apk` 直接安装
- **Windows**：下载 `.zip` 解压后运行

> 首次启动后会进入引导页，带领完成 API 配置。
>
> **升级说明（v0.6.0）**：本次品牌升级将 Android `applicationId` 由 `com.lingxiacademy.lingxi_academy` 变更为 `com.questacademy.quest_academy`，旧版安装包将被视为不同应用，**旧版本数据（课程进度 / 笔记 / 对话 / API Key）不会自动迁移，需重新配置**；建议升级前在「设置 → 数据」中导出备份。Windows 端数据目录同步更新，同样建议先导出备份。

## 快速开始

1. **下载安装**：从 [Releases](https://github.com/YJLZSL/quest-academy/releases) 下载对应平台安装包
2. **首次引导**：5 步引导页（欢迎 → API 说明 → 主题选择 → 学习路径 → 苏格拉底介绍）
3. **配置 API**：选择服务商（OpenAI 兼容 / Anthropic / Gemini / Ollama），填入 API Key 与模型名，点击"测试连接"
4. **开始学习**：从首页进入"学习路径"选 L0 课程，或进入"对话"自由交流

## 构建指南

### 环境要求

| 项 | 要求 |
|----|------|
| Flutter SDK | 3.44.4（兼容 `sdk: '>=3.10.0 <4.0.0'`） |
| Dart SDK | 3.12.2（随 Flutter 自带） |
| Android | minSdkVersion 24 |
| Windows | Windows 10+，需 Visual Studio C++ build tools |

### 从源码构建

```bash
git clone https://github.com/YJLZSL/quest-academy.git
cd quest-academy
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run                          # 开发模式
flutter build apk --release          # Android
flutter build windows --release      # Windows
```

## 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| [Flutter](https://flutter.dev) | 3.44.4 | 跨平台 UI 框架 |
| [flutter_riverpod](https://riverpod.dev) | ^2.5.1 | 状态管理 |
| [go_router](https://pub.dev/packages/go_router) | ^14.2.0 | 声明式路由 |
| [drift](https://pub.dev/packages/drift) | ^2.18.0 | SQLite ORM |
| [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) | ^9.2.2 | API Key 加密存储 |
| [dio](https://pub.dev/packages/dio) | ^5.4.3+1 | HTTP 客户端 |
| [flutter_markdown](https://pub.dev/packages/flutter_markdown) | ^0.7.2+1 | Markdown 渲染 |
| [flutter_math_fork](https://pub.dev/packages/flutter_math_fork) | ^0.7.2 | 数学公式渲染 |
| [google_fonts](https://pub.dev/packages/google_fonts) | ^6.2.1 | 字体加载（Noto Sans SC + Quicksand + Press Start 2P + VT323） |
| [package_info_plus](https://pub.dev/packages/package_info_plus) | ^8.0.0 | 自动更新版本号读取 |
| [open_filex](https://pub.dev/packages/open_filex) | ^4.7.0 | 调用系统安装器（APK/ZIP） |
| [archive](https://pub.dev/packages/archive) | ^3.6.1 | 解压 Windows ZIP 更新包 |

## 项目结构

```
quest-academy/
├── lib/
│   ├── main.dart                     # 应用入口
│   ├── app.dart                      # MaterialApp 根 Widget
│   ├── core/                         # 核心层：主题、路由、常量、动画
│   ├── data/                         # 数据层：Drift 数据库、模型、仓库
│   ├── features/                     # 功能层：按业务模块组织
│   │   ├── ai/                       #   AI Provider 抽象与实现
│   │   ├── chat/                     #   对话
│   │   ├── home/                     #   首页
│   │   ├── learning/                 #   学习路径与课时
│   │   ├── notes/                    #   笔记
│   │   ├── onboarding/               #   引导与 API 配置
│   │   ├── progress/                 #   进度统计与成就
│   │   ├── recommendation/           #   推荐服务
│   │   ├── settings/                 #   设置
│   │   └── update/                   #   应用内自动更新
│   └── shared/                       # 共享层：跨 feature 复用组件
├── assets/                           # 静态资源
├── docs/                             # 项目文档
├── test/                             # 测试
└── pubspec.yaml
```

## 贡献

欢迎参与项目贡献！请阅读 [CONTRIBUTING.md](CONTRIBUTING.md) 了解提交流程。AI 协作者请额外阅读 [AGENTS.md](AGENTS.md) 了解项目约定与安全红线。

## 开源协议

本项目基于 [MIT License](LICENSE) 开源。

## 致谢

- [LearnLM](https://blog.google/technology/learnlm/) —— Google 的学习模型，引导式学习五原则方法论参考
- [Material 3 Expressive](https://m3.material.io/) —— Google 设计系统，动态配色与组件规范
- [Flutter](https://flutter.dev) —— 跨平台应用开发框架
- [Khanmigo](https://www.khanmigo.ai/) —— Khan Academy 的 AI 导师，启发式教学灵感来源
- [mlabonne/llm-course](https://github.com/mlabonne/llm-course) —— LLM 系统化课程结构参考

## 相关文档

- [AGENTS.md](AGENTS.md) —— AI 协作者规范（含安全红线与文档同步工作流）
- [CHANGELOG.md](CHANGELOG.md) —— 变更日志
- [SECURITY.md](SECURITY.md) —— 安全策略
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) —— 贡献者行为准则
- [CONTRIBUTING.md](CONTRIBUTING.md) —— 贡献指南
- [docs/架构设计.md](docs/架构设计.md) —— 架构设计
- [docs/游戏化重设计实施规范.md](docs/游戏化重设计实施规范.md) —— 游戏化重设计实施规范
- [docs/前端重设计指南.md](docs/前端重设计指南.md) —— 前端重设计指南（已归档，v0.2.0 前历史蓝图）
- [docs/代码百科.md](docs/代码百科.md) —— 代码百科
