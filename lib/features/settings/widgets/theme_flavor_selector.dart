import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/motion/animation_utils.dart';
import '../../../../core/theme/theme_flavor_provider.dart';

/// 主题风格选择器。
///
/// 提供三选一：默认（Duolingo 式活泼）、极简（低动效专注）、Pixel MC（像素块）。
/// 直接操作 [themeFlavorProvider]，切换即时持久化。
class ThemeFlavorSelector extends ConsumerWidget {
  const ThemeFlavorSelector({super.key});

  String _label(ThemeFlavor flavor) => switch (flavor) {
        ThemeFlavor.standard => '默认',
        ThemeFlavor.minimal => '极简',
        ThemeFlavor.minecraft => 'Pixel MC',
      };

  IconData _icon(ThemeFlavor flavor) => switch (flavor) {
        ThemeFlavor.standard => Icons.auto_awesome_outlined,
        ThemeFlavor.minimal => Icons.minimize_outlined,
        ThemeFlavor.minecraft => Icons.grid_on_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavor = ref.watch(themeFlavorProvider);

    return SegmentedButton<ThemeFlavor>(
      segments: [
        for (final f in ThemeFlavor.values)
          ButtonSegment(
            value: f,
            label: Text(_label(f)),
            icon: Icon(_icon(f)),
          ),
      ],
      selected: {flavor},
      onSelectionChanged: (selection) {
        final selected = selection.first;
        if (selected != flavor) {
          AnimationUtils.hapticLight();
          ref.read(themeFlavorProvider.notifier).setFlavor(selected);
        }
      },
    );
  }
}
