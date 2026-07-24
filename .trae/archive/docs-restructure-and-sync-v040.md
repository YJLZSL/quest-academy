# 文档体系重整理与同步至 v0.4.0 计划

> **目标**：将项目所有文档同步至 v0.4.0 实际代码状态，重写 AGENTS.md，新建缺失社区文档，更新过时设计文档，清理历史规划文档，并建立"做完任务即同步文档"的长效机制。
>
> **执行原则**：所有文档使用中文；基于 Phase 1 探索的实际代码状态，不臆测；改动以最小风险恢复文档与代码一致性。

---

## 一、当前状态分析（Phase 1 探索结论）

### 1.1 AGENTS.md 的 11 处不一致

| # | 不一致项 | 位置 | 严重度 |
|---|---------|------|--------|
| 1 | 版本演进历史缺失 v0.4.0 | 第 25-29 行 | 高 |
| 2 | 表清单缺 `LearnerProfiles` 表 | 第 350-359 行 | 高 |
| 3 | 表清单缺 `LearningEvents` 表 | 第 350-359 行 | 高 |
| 4 | 技术栈缺 `package_info_plus ^8.0.0` | 第 58-76 行 | 中 |
| 5 | 技术栈缺 `open_filex ^4.7.0` | 第 58-76 行 | 中 |
| 6 | 技术栈缺 `archive ^3.6.1` | 第 58-76 行 | 中 |
| 7 | dev 依赖缺 `msix ^3.16.7` | 第 80-89 行 | 中 |
| 8 | 目录结构缺 `update/` 模块 | 第 100-130 行 | 中 |
| 9 | migration 示例为空，实际已实现 v2/v3 迁移 | 第 380-395 行 | 中 |
| 10 | 课程技术债称"仅 L0"，实际已有 L0+L1 | 第 600 行 | 低 |
| 11 | 安全红线未记录 `REQUEST_INSTALL_PACKAGES` 权限 | 第 500 行 | 中 |

### 1.2 其他文档状态

| 文档 | 状态 | 问题 |
|------|------|------|
| README.md | 部分滞后 | 技术栈表列 10 项（AGENTS 列 17 项），项目结构树缺 update 模块 |
| CONTRIBUTING.md | 部分过时 | 目录树示例路径偏差（`data/database/` vs 实际 `data/db/`） |
| docs/架构设计.md | 较新（2026-07-23） | 基本同步，无需大改 |
| docs/代码百科.md | 较新（2026-07-23） | 基本同步，无需大改 |
| docs/前端重设计指南.md | 过时（2026-07-11） | 早于 v0.2.0，"现状"章节已被超越 |
| docs/吉祥物设计.md | 过时（2026-07-11） | 早于 v0.2.0，"当前实现"章节已过时 |
| CHANGELOG.md | **缺失** | 版本变更散落在 commit message |
| SECURITY.md | **缺失** | 安全规范散落在 AGENTS.md |
| CODE_OF_CONDUCT.md | **缺失** | 行为准则散落在 CONTRIBUTING.md |
| .trae/documents/ | 堆积 | 4 个历史规划文档 + 本计划文件 |
| .trae/specs/ | 堆积 | 5 个历史 spec 子目录 |

### 1.3 测试覆盖缺口（文档应记录）

- `lib/features/update/` 4 个文件无测试
- `learner_profile_repository.dart` 无独立测试
- `learning_event_repository.dart` 无独立测试
- `update_preferences_repository.dart` 无独立测试

---

## 二、Proposed Changes（按执行顺序）

### 阶段 A：重写 AGENTS.md（核心任务）

**文件**：`d:\AIKFCC\AI  Classroom\AGENTS.md`

**新结构（25 章节，重新组织信息架构）**：

```
1. 项目概述与定位                    [保留+更新版本到 v0.4.0]
2. 版本演进历史                      [补充 v0.4.0 行]
3. 环境要求                          [保留]
4. 技术栈与版本约束                  [补 4 个新依赖]
5. 目录结构与分层约定                [补 update 模块、补 core/motion 完整文件]
6. 命名规范                          [保留]
7. 状态管理约定（Riverpod）          [保留]
8. 路由约定（GoRouter）              [保留]
9. 数据层约定（Drift）               [表清单 8→10，补实际 migration 代码]
10. AI Provider 扩展约定             [保留]
11. 自动更新模块约定                 [★新增章节，记录 update 模块设计]
12. 吉祥物集成约定                   [保留]
13. 安全红线                         [补 REQUEST_INSTALL_PACKAGES 权限边界]
14. 测试约定                         [更新测试目录结构]
15. 代码风格与 lint 规则             [保留]
16. 提交规范                         [保留]
17. 分支策略                         [保留]
18. 已知技术债与待优化项             [更新课程为 L0+L1，补测试缺口]
19. 常用命令速查                     [保留]
20. AI 协作建议                      [保留+强化文档同步要求]
21. ★文档同步工作流                  [★新增章节，定义 PR 文档检查清单]
22. AI 助手行为规范（面向不同年龄段） [保留]
23. 课程内容编写规范                 [保留]
24. 吉祥物交互扩展规范               [保留]
25. 性能预算                         [保留]
```

**关键修复点**：

1. **版本演进历史**（第 2 章）新增行：
   ```
   | v0.4.0 | 2026-07-24 | 双端专注版：移除 macOS 支持、新增应用内自动更新（UpdateService/Controller/Dialog，基于 GitHub Releases API）、前端 UI 审查修复、CI/CD 修复 |
   ```

2. **技术栈**（第 4 章）核心依赖表新增 3 行：
   ```
   | package_info_plus | ^8.0.0 | 自动更新版本号读取 |
   | open_filex | ^4.7.0 | 调用系统安装器（APK/ZIP） |
   | archive | ^3.6.1 | 解压 Windows ZIP 更新包 |
   ```
   dev 依赖表新增 1 行：
   ```
   | msix | ^3.16.7 | Windows MSIX 安装包打包 |
   ```

3. **目录结构**（第 5 章）features/ 下补充：
   ```
   ├── update/                    #   应用内自动更新（controller, dialog, service, state）
   ```
   core/motion/ 补充：
   ```
   ├── animation_utils.dart       #   动画工具（reduceMotion 判断、haptic）
   ├── page_transitions.dart      #   页面过渡动画
   ```

4. **数据层表清单**（第 9 章）从 8 张更新为 10 张：
   ```
   | LearnerProfiles | 学习者画像（ageGroup/skillLevel/learningGoal/dailyMinutes/pace） |
   | LearningEvents | 学习事件（lesson_start/quiz_attempt/socratic_turn，含 durationSeconds） |
   ```

5. **migration 策略**（第 9 章）替换空注释为实际代码：
   ```dart
   onUpgrade: (m, from, to) async {
     if (from < 2) {
       await m.createTable(learnerProfiles);
     }
     if (from < 3) {
       await m.createTable(learningEvents);
     }
   },
   ```

6. **新增第 11 章「自动更新模块约定」**：
   - 模块文件结构（update_controller/dialog/service/state）
   - 状态机流转图（idle→checking→available→downloading→downloaded→installing）
   - 节流规则（24h、force 跳过、silent 静默）
   - 平台资产匹配（Android APK 按 ABI 优先级、Windows ZIP）
   - 安全考量（仅访问公开 Release、不涉及 API Key、REQUEST_INSTALL_PACKAGES 权限边界）
   - 新增 Provider 步骤（注册位置：update_controller.dart 底部）

7. **安全红线**（第 13 章）新增第 6 条：
   ```
   ### 6. 自动更新权限边界
   - Android `REQUEST_INSTALL_PACKAGES` 权限仅用于安装来自自有 GitHub Release 的 APK
   - FileProvider 仅共享应用临时目录下的更新文件
   - UpdateService 不读取/写入 API Key，不经过 SecureLogInterceptor（无敏感信息）
   - 下载使用 HTTPS，仅访问 api.github.com 与 github.com
   ```

8. **测试约定**（第 14 章）目录结构更新为实际结构（含 core/、widget/、features/{learning,progress,recommendation,settings}/）。

9. **已知技术债**（第 18 章）更新：
   - 课程内容：`仅 L0 Python` → `L0 Python 基础 + L1 Python 数据结构`
   - 新增测试缺口行：update 模块、learner_profile_repository、learning_event_repository、update_preferences_repository

10. **新增第 21 章「文档同步工作流」**（见阶段 E 详细设计）。

---

### 阶段 B：新建缺失的社区文档

#### B1. CHANGELOG.md（新建）

**文件**：`d:\AIKFCC\AI  Classroom\CHANGELOG.md`

**内容**：从 git tag 与 commit 历史提取，按 [Keep a Changelog](https://keepachangelog.com/zh-CN/) 格式组织：

```markdown
# 变更日志

本项目所有重要变更记录于此文件。格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [0.4.0] - 2026-07-24「双端专注版」

### 新增
- 应用内自动更新功能（基于 GitHub Releases API）
  - UpdateService/Controller/Dialog/State 完整状态机
  - 启动静默检查（24h 节流）+ 设置页手动入口
  - Android APK 按 ABI 优先级匹配 + Windows ZIP 解压安装
  - 编辑式版本公告弹窗（庆祝渐变横幅 + 吉祥物 + Markdown Release Notes）
- 新增依赖：package_info_plus、open_filex、archive
- 新增 LearnerProfiles、LearningEvents 两张 Drift 表（schemaVersion v3）

### 变更
- 移除 macOS 平台支持，专注 Android + Windows 双端
- 前端 UI 审查修复（硬编码颜色改用语义色、死代码清理）

### 修复
- CI: Windows zip 路径、ScrollCacheExtent 类型、MSVC /WX 标志、rive_common 编译错误
- Flutter analyze 4 个 error（DioExceptionType.transformTimeout、MarkdownStyleSheet li 参数等）

## [0.3.0] - 2026-07-23「打磨·测试·发布」
...（从 v0.3.0 发布 commit 提取）

## [0.2.0] - 2026-07-20「美术与动画全面优化」
...（从 v0.2.0 发布 commit 提取）

## [0.1.0] - 2026-07-15「初始版本」
...（从 v0.1.0 提取）
```

#### B2. SECURITY.md（新建）

**文件**：`d:\AIKFCC\AI  Classroom\SECURITY.md`

**内容**：从 AGENTS.md 安全红线抽取为独立文件，补充漏洞披露流程：

```markdown
# 安全策略

## 支持版本
| 版本 | 支持状态 |
|------|----------|
| 0.4.x | ✅ 支持 |
| < 0.4 | ❌ 不支持 |

## 报告漏洞
- 邮箱：（待补充）
- 响应时间：48 小时内确认

## 安全红线（强制约束）
1. API Key 处理（仅 SecureStorage，绝不入库/日志/导出）
2. 日志过滤（SecureLogInterceptor 脱敏）
3. 数据导出（ProviderConfig.toJson 跳过 apiKey）
4. .gitignore 敏感文件
5. 截图/错误报告不暴露 API Key
6. 自动更新权限边界（REQUEST_INSTALL_PACKAGES 仅用于自有 Release）
```

#### B3. CODE_OF_CONDUCT.md（新建）

**文件**：`d:\AIKFCC\AI  Classroom\CODE_OF_CONDUCT.md`

**内容**：从 CONTRIBUTING.md 行为准则抽取并扩展：

```markdown
# 贡献者行为准则

## 承诺
为所有人提供友善、安全、欢迎的社区环境。

## 准则
- 保持尊重与友善
- 开放包容
- 专注目标
- 接受建设性批评

## 不可接受行为
- 骚扰、歧视、人身攻击
- 发布他人隐私信息
- 其他违反职业道德的行为

## 执行
违规行为可报告至（邮箱待补充），维护者将调查并采取适当措施。
```

---

### 阶段 C：更新过时的 docs/ 设计文档

#### C1. docs/前端重设计指南.md

**操作**：在文件顶部添加归档说明，标注为历史参考文档。

```markdown
> ⚠️ **历史归档文档**（2026-07-11）
> 本文档为 v0.2.0 美术动画优化前的重设计蓝图，其"现状分析"章节已被 v0.2.0/v0.3.0 实际实现超越。
> 保留作为设计决策的历史参考，不代表当前代码状态。当前设计规范以 AGENTS.md「主题系统约定」章节为准。
```

#### C2. docs/吉祥物设计.md

**操作**：更新"当前实现"章节至 v0.3.0 状态。

具体修改：
- 径向渐变身体 / 角部高光 / 瞳孔高光 / 6 情绪差异化绘制（v0.2.0 已完成）
- Hero 共享元素动画（MascotHero + mascotHeroFlightShuttleBuilder，v0.3.0 已完成）
- 按压微交互（v0.3.0 已完成）
- Rive 升级方案仍为待办（与 AGENTS.md 技术债一致）

#### C3. CONTRIBUTING.md

**操作**：修复"文件组织"章节的过时目录树。

将 `data/database/` 改为 `data/db/`，补充 `core/motion/`、`features/mascot/`、`features/recommendation/`、`features/update/` 等实际路径，与 AGENTS.md 目录结构一致。

#### C4. docs/架构设计.md 与 docs/代码百科.md

**操作**：轻量更新，补充 update 模块与 LearnerProfiles/LearningEvents 表的简要说明。

---

### 阶段 D：清理 .trae 历史规划文档

**操作**：创建 `.trae/archive/` 目录，将历史规划文档移入归档。

**移动清单**：
```
.trae/documents/frontend-check-and-auto-update-plan.md  → .trae/archive/
.trae/documents/lingxi-academy-animation-upgrade-phase2-plan.md → .trae/archive/
.trae/documents/repo-cleanup-dual-platform-release.md → .trae/archive/
.trae/documents/ui-polish-and-auto-update.md → .trae/archive/
.trae/specs/art-animation-polish-and-release/ → .trae/archive/specs/
.trae/specs/build-lingxi-academy/ → .trae/archive/specs/
.trae/specs/comprehensive-optimization-cleanup/ → .trae/archive/specs/
.trae/specs/enhance-backend-reliability/ → .trae/archive/specs/
.trae/specs/polish-test-release-v030/ → .trae/archive/specs/
```

**保留**：
- `.trae/documents/docs-restructure-and-sync-v040.md`（本计划文件，执行完成后也移入 archive）

**新增**：在 `.trae/archive/README.md` 说明归档规则：
```markdown
# 归档文档

此目录存放已完成或已过期的规划文档与 spec，保留作为历史参考。
当前活跃文档请查看 `.trae/documents/`。
```

---

### 阶段 E：同步 README.md

**文件**：`d:\AIKFCC\AI  Classroom\README.md`

**修改**：

1. **技术栈表**：从 10 项扩展到与 AGENTS.md 一致的核心依赖（补充 package_info_plus、open_filex、archive）

2. **项目结构树**：在 features/ 下补充：
   ```
   ├── update/                    # 应用内自动更新
   ```

3. **功能特性**：在 9 项特性中补充第 10 项：
   ```
   - **应用内自动更新**：基于 GitHub Releases API，启动自动检查 + 手动触发，Android APK / Windows ZIP 双端支持，无需反复卸载重装
   ```

4. **版本徽章**：确认已为 v0.4.0（无需改动）

---

### 阶段 F：新增"文档同步工作流"机制（写入 AGENTS.md 第 21 章）

**目标**：建立"做完任务即同步文档"的长效机制，解决文档滞后的根本问题。

**AGENTS.md 第 21 章内容设计**：

```markdown
## 文档同步工作流

> 本章节定义每次代码变更必须同步更新的文档检查清单，确保文档与代码始终一致。
> 违反此工作流的 PR 将被要求补充文档更新后再 review。

### 21.1 PR 文档同步检查清单

每次提交 PR 时，作者必须在 PR 描述中勾选以下检查项：

#### 必查项（所有 PR）
- [ ] 若修改了 `pubspec.yaml` 依赖 → 已更新 AGENTS.md「技术栈与版本约束」
- [ ] 若新增/删除/修改了 Drift 表 → 已更新 AGENTS.md「当前表清单」与 migration 代码示例
- [ ] 若新增了 feature 模块 → 已更新 AGENTS.md「目录结构」与相应模块约定章节
- [ ] 若修改了 `lib/core/constants/app_constants.dart` → 已在 AGENTS.md 相关章节记录新常量
- [ ] 若修改了安全相关代码（SecureStorage/SecureLogInterceptor/权限）→ 已更新 AGENTS.md「安全红线」与 SECURITY.md
- [ ] 若新增了公开 API/Provider → 已更新 docs/代码百科.md

#### 版本发布时（打 tag 前）
- [ ] AGENTS.md「版本演进历史」已新增版本行
- [ ] CHANGELOG.md 已新增版本段落
- [ ] README.md 版本徽章已更新
- [ ] `lib/core/constants/app_constants.dart` 的 `kAppVersion` 已更新
- [ ] `pubspec.yaml` 的 `version` 已更新
- [ ] （可选）`msix_config.msix_version` 已同步

#### 测试相关
- [ ] 若新增了 Repository/Service → 已添加对应 `_test.dart` 文件
- [ ] 若修改了现有 Repository/Service → 已更新对应测试

### 21.2 文档所有权矩阵

| 文档 | 维护场景 | 主要维护者 |
|------|----------|-----------|
| AGENTS.md | 任何架构/约定变更 | PR 作者 |
| README.md | 版本发布、功能特性变更 | PR 作者 |
| CHANGELOG.md | 每次 PR（[Unreleased] 段）| PR 作者 |
| SECURITY.md | 安全相关变更 | PR 作者 |
| CONTRIBUTING.md | 贡献流程变更 | 仓库管理员 |
| docs/架构设计.md | 架构变更 | PR 作者 |
| docs/代码百科.md | 模块/Provider 变更 | PR 作者 |
| docs/吉祥物设计.md | 吉祥物相关变更 | PR 作者 |

### 21.3 CHANGELOG.md 维护规则

- 每次 PR 在 `[Unreleased]` 段添加变更项（Added/Changed/Fixed/Removed）
- 版本发布时将 `[Unreleased]` 改为 `[版本号] - 日期`，并新建空的 `[Unreleased]`
- 变更项来源：commit message 的 type 与 description

### 21.4 文档同步自动化（未来方向）

- 探索 GitHub Actions 在 PR 中自动检查文档同步（如检测 pubspec 变更则提示更新 AGENTS.md）
- 探索依赖版本自动同步脚本（pubspec → AGENTS.md 表格）
```

---

## 三、Assumptions & Decisions

### 假设
1. 项目当前版本确为 v0.4.0（pubspec.yaml + git tag 确认）
2. database.dart 的 10 张表与 schemaVersion=3 为最终状态
3. update 模块已通过 CI 验证（commit 8ce8a8a，CI success）
4. docs/架构设计.md 与 docs/代码百科.md 日期为 2026-07-23，与 v0.3.0 同步，需轻量更新到 v0.4.0

### 决策
1. **AGENTS.md 完全重写**：用户明确选择，重新组织 25 章节结构，新增第 11 章（update 模块）与第 21 章（文档同步工作流）
2. **历史文档归档而非删除**：移动到 `.trae/archive/` 保留历史参考价值
3. **CHANGELOG.md 格式**：采用 Keep a Changelog 规范，便于未来自动化
4. **不修改安全相关代码逻辑**：仅更新文档描述，不触碰 SecureStorageService/SecureLogInterceptor 等
5. **不补测试**：本计划聚焦文档整理，测试缺口仅在 AGENTS.md 技术债中记录，留待后续 PR

---

## 四、Verification Steps

执行完成后，按以下步骤验证：

### 4.1 文档一致性验证
- [ ] AGENTS.md 版本演进历史包含 v0.1.0-v0.4.0 四行
- [ ] AGENTS.md 表清单列出 10 张表（含 LearnerProfiles、LearningEvents）
- [ ] AGENTS.md 技术栈列出 21 项依赖（17 原有 + 3 自动更新 + 1 msix）
- [ ] AGENTS.md 目录结构包含 `features/update/`
- [ ] AGENTS.md migration 代码示例包含 v2/v3 实际迁移
- [ ] AGENTS.md 安全红线包含第 6 条「自动更新权限边界」
- [ ] AGENTS.md 第 21 章「文档同步工作流」存在且完整

### 4.2 新文档验证
- [ ] CHANGELOG.md 存在，包含 v0.1.0-v0.4.0 四个版本段落
- [ ] SECURITY.md 存在，包含 6 条安全红线
- [ ] CODE_OF_CONDUCT.md 存在，包含行为准则

### 4.3 过时文档验证
- [ ] docs/前端重设计指南.md 顶部有归档说明
- [ ] docs/吉祥物设计.md「当前实现」章节已更新到 v0.3.0
- [ ] CONTRIBUTING.md 目录树与 AGENTS.md 一致

### 4.4 归档验证
- [ ] `.trae/archive/` 目录存在
- [ ] `.trae/archive/README.md` 存在
- [ ] `.trae/documents/` 仅保留当前计划文件（执行后也归档）
- [ ] `.trae/specs/` 已清空（内容移至 `.trae/archive/specs/`）

### 4.5 README 验证
- [ ] README.md 技术栈表包含自动更新依赖
- [ ] README.md 项目结构树包含 `update/`
- [ ] README.md 功能特性包含自动更新

### 4.6 Git 验证
- [ ] `git status` 显示所有文档变更
- [ ] 提交遵循 Conventional Commits（`docs:` type）
- [ ] CI 通过（文档变更不影响代码，CI 应绿）

---

## 五、执行顺序与 TodoList

建议按以下顺序执行（每步完成后标记 todo）：

1. **阶段 A**：重写 AGENTS.md（核心，最大工作量）
2. **阶段 B**：新建 CHANGELOG.md、SECURITY.md、CODE_OF_CONDUCT.md
3. **阶段 C**：更新 docs/ 设计文档与 CONTRIBUTING.md
4. **阶段 D**：清理 .trae 历史文档（创建 archive，移动文件）
5. **阶段 E**：同步 README.md
6. **阶段 F**：已在阶段 A 中完成（AGENTS.md 第 21 章）
7. **验证**：按第四节检查清单逐项验证
8. **提交**：`docs: 重整理文档体系并同步至 v0.4.0`
9. **归档本计划**：将本文件移至 `.trae/archive/`

---

*本计划基于 2026-07-24 Phase 1 探索结果制定，执行时以实际代码状态为准。*
