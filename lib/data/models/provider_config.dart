/// AI 服务商类型枚举。
///
/// 每个枚举值包含：
/// - [value]：持久化存储用的字符串标识（如 `openai_compatible`）
/// - [displayName]：UI 展示名称（中文）
/// - [defaultBaseUrl]：该服务商默认 baseUrl
/// - [defaultModel]：该服务商默认模型
///
/// DeepSeek / Moonshot（Kimi）/ 通义千问 / 智谱 GLM / Groq 均兼容
/// OpenAI Chat Completions 协议，复用 [OpenAICompatibleProvider] 实现，
/// 仅预设各自的 baseUrl 与默认模型。
enum ProviderType {
  openaiCompatible(
    'openai',
    'OpenAI Compatible',
    'https://api.openai.com/v1',
    'gpt-4o-mini',
  ),
  anthropic(
    'anthropic',
    'Anthropic',
    'https://api.anthropic.com',
    'claude-3-5-sonnet-20241022',
  ),
  gemini(
    'gemini',
    'Gemini',
    'https://generativelanguage.googleapis.com',
    'gemini-1.5-flash',
  ),
  deepseek(
    'deepseek',
    'DeepSeek',
    'https://api.deepseek.com/v1',
    'deepseek-chat',
  ),
  moonshot(
    'moonshot',
    'Kimi（Moonshot）',
    'https://api.moonshot.cn/v1',
    'moonshot-v1-8k',
  ),
  qwen(
    'qwen',
    '通义千问（Qwen）',
    'https://dashscope.aliyuncs.com/compatible-mode/v1',
    'qwen-plus',
  ),
  zhipu(
    'zhipu',
    '智谱（GLM）',
    'https://open.bigmodel.cn/api/paas/v4',
    'glm-4-flash',
  ),
  groq(
    'groq',
    'Groq',
    'https://api.groq.com/openai/v1',
    'llama-3.3-70b-versatile',
  ),
  ollama(
    'ollama',
    'Ollama',
    'http://localhost:11434',
    'llama3.2',
  );

  const ProviderType(
    this.value,
    this.displayName,
    this.defaultBaseUrl,
    this.defaultModel,
  );

  /// 持久化存储用的字符串标识。
  final String value;

  /// UI 展示名称。
  final String displayName;

  /// 该服务商默认 baseUrl。
  final String defaultBaseUrl;

  /// 该服务商默认模型。
  final String defaultModel;

  /// 根据字符串值反查枚举，未匹配时回退到 [openaiCompatible]。
  static ProviderType fromValue(String value) {
    return ProviderType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProviderType.openaiCompatible,
    );
  }
}

/// 各服务商常见模型预设（用于设置页快速选择）。
///
/// 自动检测到的可用模型会优先于此列表展示；此列表作为离线兜底与常用推荐。
const Map<ProviderType, List<String>> kProviderModelPresets = {
  ProviderType.openaiCompatible: [
    'gpt-4o-mini',
    'gpt-4o',
    'gpt-4.1-mini',
    'gpt-4.1',
  ],
  ProviderType.anthropic: [
    'claude-3-5-sonnet-20241022',
    'claude-3-5-haiku-20241022',
    'claude-sonnet-4-20250514',
  ],
  ProviderType.gemini: [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-2.0-flash',
    'gemini-2.5-flash',
  ],
  ProviderType.deepseek: ['deepseek-chat', 'deepseek-reasoner'],
  ProviderType.moonshot: [
    'moonshot-v1-8k',
    'moonshot-v1-32k',
    'moonshot-v1-128k',
    'kimi-latest',
  ],
  ProviderType.qwen: ['qwen-plus', 'qwen-turbo', 'qwen-max', 'qwen-long'],
  ProviderType.zhipu: ['glm-4-flash', 'glm-4-plus', 'glm-4-air'],
  ProviderType.groq: [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'mixtral-8x7b-32768',
    'gemma2-9b-it',
  ],
  ProviderType.ollama: ['llama3.2', 'llama3.1', 'qwen2.5', 'mistral', 'gemma2'],
};

/// AI 服务商配置。
///
/// 注意：[apiKey] 字段仅在内存中持有，**不会**参与 `toJson`/`fromJson` 序列化。
/// API Key 通过 [SecureStorageService] 单独加密存储，避免明文落盘。
class ProviderConfig {
  /// 创建一份指定服务商类型的默认配置（用于首次初始化）。
  factory ProviderConfig.defaultFor(ProviderType type) {
    return ProviderConfig(
      providerType: type,
      baseUrl: type.defaultBaseUrl,
      apiKey: '',
      model: type.defaultModel,
    );
  }

  const ProviderConfig({
    required this.providerType,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.enabled = true,
  });

  final ProviderType providerType;
  final String baseUrl;

  /// 仅在内存中持有，序列化时跳过。
  final String apiKey;
  final String model;
  final double temperature;
  final int maxTokens;
  final bool enabled;

  /// 从 JSON 反序列化（不含 apiKey，apiKey 由 SecureStorage 单独读取）。
  factory ProviderConfig.fromJson(Map<String, dynamic> json) {
    return ProviderConfig(
      providerType: ProviderType.fromValue(json['providerType'] as String? ?? ''),
      baseUrl: json['baseUrl'] as String? ?? '',
      apiKey: '',
      model: json['model'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['maxTokens'] as int? ?? 2048,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  /// 序列化为 JSON（**不含** apiKey，安全考虑）。
  Map<String, dynamic> toJson() {
    return {
      'providerType': providerType.value,
      'baseUrl': baseUrl,
      'model': model,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'enabled': enabled,
    };
  }

  /// 复制并修改部分字段。
  ProviderConfig copyWith({
    ProviderType? providerType,
    String? baseUrl,
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
    bool? enabled,
  }) {
    return ProviderConfig(
      providerType: providerType ?? this.providerType,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      enabled: enabled ?? this.enabled,
    );
  }
}
