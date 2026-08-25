# 安全策略

> 本文档定义问学 Quest Academy 的漏洞披露流程与安全红线。安全红线为强制约束，任何 PR 不得违反。

## 支持版本

| 版本 | 支持状态 |
|------|----------|
| 0.6.x | ✅ 支持 |
| < 0.6 | ❌ 不支持 |

## 报告漏洞

- **GitHub Security Advisory**：推荐通过 [GitHub 私密安全公告](https://github.com/YJLZSL/quest-academy/security/advisories/new) 提交
- **响应时间**：48 小时内确认收到，7 个工作日内给出初步评估
- **请不要**公开披露未修复的漏洞，给予我们修复与发布补丁的时间

## 安全红线（强制约束）

> 以下 6 条红线与 [AGENTS.md](AGENTS.md) 「安全红线」章节内容保持同步，任何修改若违反将导致 PR 被直接拒绝。

### 1. API Key 处理

- **API Key 只能通过 `SecureStorageService` 存储**（底层 `flutter_secure_storage`，依赖平台 Keychain / Keystore）
- **绝不**将 API Key 写入 Drift 数据库、`SharedPreferences`、文件、日志、导出 JSON
- `ApiKeys` 表只存元数据（`providerType` / `baseUrl` / `model` / `temperature` / `maxTokens` / `enabled`），**不含** `apiKey` 字段
- `ProviderConfig.apiKey` 字段仅在内存中持有，`toJson()` **必须**跳过 `apiKey`
- 构造 `AiProvider` 时从 `ProviderConfigRepository`（内部读 `SecureStorage`）获取 `apiKey` 传入

### 2. 日志过滤

- **所有 dio 请求必须经过 `SecureLogInterceptor`**
- 自动脱敏的请求头：`authorization` / `x-api-key` / `x-goog-api-key` → `[REDACTED]`
- 自动脱敏的查询参数：`key` / `api_key` → `[REDACTED]`
- 自动脱敏的请求体字段：`api_key` / `apikey` / `apiKey` / `key` → `[REDACTED]`
- URL 中的查询参数也会被脱敏（`redactUrl`）
- **禁止**绕过 `SecureLogInterceptor` 直接 `print` 请求/响应内容
- 使用 `debugPrint` 而非 `print`（lint 规则 `avoid_print` 已启用）

### 3. 数据导出

- `DataExportService.exportAll()` 中 `ProviderConfig.toJson()` **必须**不含 `apiKey`
- 代码中已有 `assert(!json.containsKey('apiKey'))` 断言，**不要移除**
- 导入时 `copyWith(apiKey: '')` 强制清空 `apiKey`（导出文件本身不含 `apiKey`）

### 4. .gitignore 敏感文件

`.gitignore` 已包含以下敏感文件规则，**禁止**移除：

```
*.keystore
*.jks
*.env
config.json
config.local.json
android/key.properties
macos/Runner/*.entitlements.priv
*.secure
```

新增包含敏感信息的文件时，同步在 `.gitignore` 添加规则。

### 5. 截图/错误报告不暴露 API Key

- 提交 Issue/PR 时，截图前确认无 API Key 残留（设置页、日志、调试控制台）
- 错误报告中若包含请求/响应，确保已通过 `SecureLogInterceptor` 脱敏
- **不要**在 Issue/PR 描述/commit message 中粘贴真实 API Key

### 6. 自动更新权限边界（v0.4.0 新增）

- Android `REQUEST_INSTALL_PACKAGES` 权限**仅**用于安装来自自有 GitHub Release（`YJLZSL/quest-academy`）的 APK
- `FileProvider` 仅共享应用临时目录下的更新文件（配置见 `android/app/src/main/res/xml/file_paths.xml`）
- `UpdateService` **不读取/写入 API Key**，**不经过** `SecureLogInterceptor`（GitHub Releases API 为公开接口）
- 下载**必须**使用 HTTPS，仅允许访问 `api.github.com` 与 `github.com` 域名
- Windows 仅允许解压 ZIP 后由用户手动替换，**禁止**执行远程脚本（`Process.run` 执行下载的 `.exe` / `.sh`）
- Release Notes 通过 `flutter_markdown` 渲染，**不得**启用其中的代码执行或链接跳转

## 相关文档

- [AGENTS.md](AGENTS.md) —— AI 协作者规范（含完整安全红线章节）
- [CONTRIBUTING.md](CONTRIBUTING.md) —— 贡献指南
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) —— 贡献者行为准则
