import 'package:flutter/material.dart';

import '../../core/router/route_names.dart';

/// 教程内容版本号。
///
/// 当教程步骤或文案发生实质性更新时递增此常量。已完成教程的用户若本地
/// 记录的版本低于当前值，设置页入口会提示「教程有更新」，引导其重新查看，
/// 而不需要用户手动重置完成状态。
const int kGuideVersion = 1;

/// 单个教程步骤。
///
/// 信息结构遵循「一句话结论 → 要点列表 → 可选操作」三层递进，
/// 保证新用户能在 10 秒内抓住该步骤的核心，再按需展开细节。
class GuideStep {
  const GuideStep({
    required this.id,
    required this.icon,
    required this.title,
    required this.summary,
    required this.bullets,
    this.tips,
    this.actionLabel,
    this.actionRoute,
  });

  /// 步骤唯一标识。
  final String id;

  /// 步骤图标。
  final IconData icon;

  /// 步骤标题。
  final String title;

  /// 一句话结论：该步骤最核心的信息。
  final String summary;

  /// 要点列表（3–4 条）。
  final List<String> bullets;

  /// 可选小贴士（补充说明或常见疑问）。
  final String? tips;

  /// 可选操作按钮文案。
  final String? actionLabel;

  /// 可选操作跳转路由（来自 [RouteNames]）。
  final String? actionRoute;
}

/// 应用内教程内容（分步引导）。
///
/// 顺序经过重新梳理：先建立认知（是什么），再给出必要前置（配 API），
/// 然后是两条主路径（系统学习 / 自由对话），最后是长期价值（笔记与坚持）。
/// 每步控制在「一屏可读完」的信息量，避免长文案劝退。
const List<GuideStep> kGuideSteps = <GuideStep>[
  GuideStep(
    id: 'intro',
    icon: Icons.auto_stories_rounded,
    title: '问学是什么',
    summary: '一个「引导式」AI 学习应用：AI 不直接给答案，而是提问带你思考。',
    bullets: <String>[
      '学习路径覆盖 L0 启蒙到 L4 专家，每个知识点包含讲解、示例与测验。',
      'AI 助手默认采用苏格拉底式引导——先反问你的思路，再逐步提示。',
      '想直接看答案时，可随时关闭对话页右上角的「苏格拉底」开关。',
    ],
    tips: '卡住时别急着要答案：连续思考 3 次后，AI 会自动切换为直接讲解。',
  ),
  GuideStep(
    id: 'api',
    icon: Icons.vpn_key_rounded,
    title: '连接你的 AI 服务',
    summary: '问学不内置 AI，需要填入你自己的 API Key 才能对话。',
    bullets: <String>[
      '支持 OpenAI、DeepSeek、Kimi、通义千问、智谱、Groq、Claude、Gemini 等。',
      '本地 Ollama 也可接入，填 http://localhost:11434 即可离线使用。',
      '密钥仅保存在本机安全存储中，不上传服务器，也不写入导出文件。',
    ],
    tips: '还没准备好？也可以先浏览课程与笔记，配置 API 后再回来对话。',
    actionLabel: '去配置 API',
    actionRoute: RouteNames.settingsApiPath,
  ),
  GuideStep(
    id: 'learning',
    icon: Icons.map_rounded,
    title: '按路径系统学习',
    summary: '从「学习」页选一门课，按模块 → 课时 → 知识点逐级深入。',
    bullets: <String>[
      '每个知识点有讲解、代码示例和随堂测验，答错会给出解析。',
      '知识点读完后可点「和 AI 聊聊」，就该知识点继续追问。',
      '进度会自动保存，首页「继续学习」可直接回到上次的位置。',
    ],
    tips: '建议每次学 1–2 个知识点，比一次刷完一章记得更牢。',
    actionLabel: '看看学习路径',
    actionRoute: RouteNames.learningPath,
  ),
  GuideStep(
    id: 'chat',
    icon: Icons.forum_rounded,
    title: '自由对话与多模态',
    summary: '任何问题都可以问，还能上传图片/文件让 AI 帮你分析。',
    bullets: <String>[
      '拍照做题：拍下题目直接发问，AI 会给出思路与答案。',
      '文档识别：上传图片或文档，AI 提取并结构化其中内容。',
      '语音朗读：点消息右上角菜单选「朗读」，可调整语速与音色。',
    ],
    tips: '只发图片不写文字时，AI 会自动按「识别并讲解」来处理。',
    actionLabel: '开始对话',
    actionRoute: RouteNames.chatListPath,
  ),
  GuideStep(
    id: 'notes',
    icon: Icons.note_alt_rounded,
    title: '记录、成就与坚持',
    summary: '把学到的东西沉淀下来，用连续学习记录保持节奏。',
    bullets: <String>[
      '对话中任何一条 AI 回复都可一键「保存为笔记」。',
      '完成知识点、坚持学习会解锁成就，在「成就」页查看。',
      '首页显示连续学习天数与 XP 进度，中断了也不会清零记录。',
    ],
    tips: '笔记支持关联课程与对话，复习时能快速回到当时的上下文。',
    actionLabel: '查看笔记',
    actionRoute: RouteNames.notesPath,
  ),
];
