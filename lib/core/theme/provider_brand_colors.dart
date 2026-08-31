import 'package:flutter/material.dart';

import '../../data/models/provider_config.dart';

/// AI 服务商品牌色板。
///
/// 各服务商的官方品牌色用于设置向导中的服务商卡片图标底色，属于**品牌识别**
/// 而非主题语义色，因此不随浅色/深色主题切换。集中在此定义可避免色值散落
/// 在业务页面中，便于统一维护与后续扩展新服务商。
///
/// 使用方式：
/// ```dart
/// final color = ProviderBrandColors.forType(ProviderType.openaiCompatible);
/// ```
class ProviderBrandColors {
  const ProviderBrandColors._();

  /// OpenAI 品牌绿。
  static const Color openai = Color(0xFF10A37F);

  /// Anthropic 品牌橙。
  static const Color anthropic = Color(0xFFD97757);

  /// Google Gemini 品牌蓝。
  static const Color gemini = Color(0xFF4285F4);

  /// Ollama 品牌灰。
  static const Color ollama = Color(0xFF6B7280);

  /// DeepSeek 品牌蓝。
  static const Color deepseek = Color(0xFF4D6BFE);

  /// Kimi（Moonshot）品牌黑蓝。
  static const Color moonshot = Color(0xFF1B1B1F);

  /// 通义千问（Qwen）品牌紫。
  static const Color qwen = Color(0xFF6B57FF);

  /// 智谱 GLM 品牌蓝。
  static const Color zhipu = Color(0xFF3957FF);

  /// Groq 品牌橙。
  static const Color groq = Color(0xFFF55036);

  /// 兜底色：未登记品牌色的服务商使用中性灰蓝。
  static const Color fallback = Color(0xFF607D8B);

  /// 按服务商类型返回对应品牌色；未知类型返回 [fallback]。
  static Color forType(ProviderType type) {
    return switch (type) {
      ProviderType.openaiCompatible => openai,
      ProviderType.anthropic => anthropic,
      ProviderType.gemini => gemini,
      ProviderType.deepseek => deepseek,
      ProviderType.moonshot => moonshot,
      ProviderType.qwen => qwen,
      ProviderType.zhipu => zhipu,
      ProviderType.groq => groq,
      ProviderType.ollama => ollama,
    };
  }
}
