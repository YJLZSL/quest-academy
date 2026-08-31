import 'package:flutter/material.dart';
import 'package:quest_academy/shared/utils/responsive.dart';
import 'package:quest_academy/shared/widgets/quest_card.dart';
import 'package:quest_academy/shared/widgets/quest_toast.dart';

/// "继续学习"侧边栏。
///
/// 桌面端显示为右侧侧栏（固定宽度），移动端折叠为底部抽屉
/// （通过 [showAsBottomSheet] 触发）。
class ContinueLearningSidebar extends StatelessWidget {
  const ContinueLearningSidebar({
    super.key,
    required this.relatedTopics,
    this.onTopicTap,
  });

  /// 相关主题列表。
  final List<String> relatedTopics;

  /// 主题点击回调。
  final VoidCallback? onTopicTap;

  /// 移动端通过 FAB 触发，展示为底部抽屉。
  static Future<void> showAsBottomSheet(
    BuildContext context, {
    required List<String> relatedTopics,
    VoidCallback? onTopicTap,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ContinueLearningSidebar(
          relatedTopics: relatedTopics,
          onTopicTap: onTopicTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.explore, size: 20),
              const SizedBox(width: 8),
              Text(
                '继续探索',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (relatedTopics.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('暂无相关主题'),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              itemCount: relatedTopics.length,
              itemBuilder: (context, index) {
                final topic = relatedTopics[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: QuestCard(
                    onTap: () {
                      onTopicTap?.call();
                      // 相关主题来自知识点的 relatedTopics 字段，未必能映射到
                      // 具体课程，因此给出中性提示而非承诺跳转。
                      QuestToast.info(context, '相关主题：$topic');
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_forward, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(topic)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );

    // 移动端：作为底部抽屉，直接返回内容（底部抽屉自带容器样式）。
    if (isMobile) {
      return SafeArea(child: content);
    }

    // 桌面端：固定宽度侧栏。
    return SizedBox(
      width: 280,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: QuestCard(
          padding: EdgeInsets.zero,
          child: content,
        ),
      ),
    );
  }
}
