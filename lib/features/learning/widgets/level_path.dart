// ignore_for_file: lines_longer_than_80_lines

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/animation_utils.dart';
import '../../../core/theme/quest_colors.dart';
import '../../../core/theme/theme_flavor_provider.dart';
import 'level_node.dart';

/// 关卡路径：将多个 [LevelNode] 按指定方向排列，并用主题色线条连接。
///
/// 支持垂直 / 水平两种布局，可附带分支节点（例如右侧课程卡片）。
/// - [standard]：平滑渐变连接线，带轻微流光。
/// - [minecraft]：粗像素折线，pixelDirt 轨道色。
/// - [minimal]：细线、低对比度、静态。
class LevelPath extends ConsumerStatefulWidget {
  const LevelPath({
    super.key,
    required this.nodes,
    this.axis = Axis.vertical,
    this.spacing = 80,
    this.lineThickness,
    this.branchOffsets,
    this.branchWidgets,
    this.padding = const EdgeInsets.all(16),
  });

  /// 节点列表。
  final List<LevelNode> nodes;

  /// 路径方向。
  final Axis axis;

  /// 相邻节点中心间距。
  final double spacing;

  /// 连接线粗细；null 时按主题风味自动选择。
  final double? lineThickness;

  /// 每个节点对应的分支端点偏移（相对节点中心）。
  /// null 表示该节点无分支。
  final List<Offset?>? branchOffsets;

  /// 分支端点处放置的 Widget，与 [branchOffsets] 一一对应。
  final List<Widget?>? branchWidgets;

  /// 外层内边距。
  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<LevelPath> createState() => _LevelPathState();
}

class _LevelPathState extends ConsumerState<LevelPath> {
  @override
  Widget build(BuildContext context) {
    final flavor = ref.watch(themeFlavorProvider);
    final colors = context.questColors;
    final theme = Theme.of(context);
    final reduceMotion = AnimationUtils.reduceMotionOf(context);
    final thickness = widget.lineThickness ??
        (flavor == ThemeFlavor.minimal ? 2.0 : 4.0);
    final trackColor = flavor == ThemeFlavor.minecraft
        ? colors.pixelDirt
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    final isVertical = widget.axis == Axis.vertical;
    final nodeSize = widget.nodes.isNotEmpty ? widget.nodes.first.size : 56.0;

    // 计算每个节点的中心坐标（在 Stack 坐标系内）。
    final nodeCenters = <Offset>[
      for (var i = 0; i < widget.nodes.length; i++)
        isVertical
            ? Offset(nodeSize / 2, nodeSize / 2 + i * widget.spacing)
            : Offset(nodeSize / 2 + i * widget.spacing, nodeSize / 2),
    ];

    // 计算布局尺寸。
    final pathLength = (widget.nodes.length - 1) * widget.spacing + nodeSize;
    final pathSize = isVertical
        ? Size(nodeSize, pathLength)
        : Size(pathLength, nodeSize);

    // 收集分支端点与 Widget。
    final branchPositions = <Offset>[];
    final branchChildren = <Widget>[];
    final branchOffsets = widget.branchOffsets;
    final branchWidgets = widget.branchWidgets;
    if (branchOffsets != null) {
      for (var i = 0; i < branchOffsets.length && i < nodeCenters.length; i++) {
        final offset = branchOffsets[i];
        if (offset == null) continue;
        final end = nodeCenters[i] + offset;
        branchPositions.add(end);
        final child = branchWidgets != null && i < branchWidgets.length
            ? branchWidgets[i]
            : null;
        if (child != null) {
          branchChildren.add(
            Positioned(
              left: end.dx - nodeSize / 2,
              top: end.dy - nodeSize / 2,
              child: child,
            ),
          );
        }
      }
    }

    return Padding(
      padding: widget.padding,
      child: SizedBox(
        width: isVertical ? null : pathSize.width,
        height: isVertical ? pathSize.height : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 连接线与分支线
            CustomPaint(
              size: pathSize,
              painter: _PathPainter(
                nodeCenters: nodeCenters,
                branchPositions: branchPositions,
                flavor: flavor,
                trackColor: trackColor,
                progressColor: colors.brandPrimary,
                thickness: thickness,
                reduceMotion: reduceMotion,
                isVertical: isVertical,
              ),
            ),
            // 节点
            isVertical
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _interleaveSpacers(widget.nodes, widget.spacing - nodeSize),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _interleaveSpacers(widget.nodes, widget.spacing - nodeSize),
                  ),
            // 分支 Widget
            ...branchChildren,
          ],
        ),
      ),
    );
  }

  /// 将节点用 Spacer 间隔开，实现相邻节点中心距为 [spacing]。
  List<Widget> _interleaveSpacers(List<Widget> nodes, double gap) {
    final result = <Widget>[];
    for (var i = 0; i < nodes.length; i++) {
      result.add(nodes[i]);
      if (i < nodes.length - 1) {
        result.add(
          widget.axis == Axis.vertical
              ? SizedBox(height: gap.clamp(0, double.infinity))
              : SizedBox(width: gap.clamp(0, double.infinity)),
        );
      }
    }
    return result;
  }
}

class _PathPainter extends CustomPainter {
  const _PathPainter({
    required this.nodeCenters,
    required this.branchPositions,
    required this.flavor,
    required this.trackColor,
    required this.progressColor,
    required this.thickness,
    required this.reduceMotion,
    required this.isVertical,
  });

  final List<Offset> nodeCenters;
  final List<Offset> branchPositions;
  final ThemeFlavor flavor;
  final Color trackColor;
  final Color progressColor;
  final double thickness;
  final bool reduceMotion;
  final bool isVertical;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeCenters.length < 2) return;

    if (flavor == ThemeFlavor.minecraft) {
      _paintMinecraft(canvas);
    } else {
      _paintSmooth(canvas);
    }
  }

  void _paintSmooth(Canvas canvas) {
    final isMinimal = flavor == ThemeFlavor.minimal;
    final paint = Paint()
      ..color = trackColor
      ..strokeWidth = thickness
      ..strokeCap = isMinimal ? StrokeCap.butt : StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 主路径
    final path = Path();
    path.moveTo(nodeCenters.first.dx, nodeCenters.first.dy);
    for (var i = 1; i < nodeCenters.length; i++) {
      path.lineTo(nodeCenters[i].dx, nodeCenters[i].dy);
    }
    canvas.drawPath(path, paint);

    // 分支线
    for (var i = 0; i < branchPositions.length; i++) {
      final nodeIndex = i < nodeCenters.length ? i : nodeCenters.length - 1;
      final branchPaint = Paint()
        ..color = trackColor
        ..strokeWidth = thickness * 0.8
        ..strokeCap = isMinimal ? StrokeCap.butt : StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(nodeCenters[nodeIndex], branchPositions[i], branchPaint);
    }

    // 已完成段高亮（前 n 个已 completed 的节点之间使用 progressColor）
    // 这里简化：整条路径使用 trackColor；后续可根据业务状态传入 completedIndex 扩展。
  }

  void _paintMinecraft(Canvas canvas) {
    // 像素化路径：用短直线段模拟，禁用抗锯齿。
    final paint = Paint()
      ..color = trackColor
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false;

    final path = Path();
    path.moveTo(nodeCenters.first.dx, nodeCenters.first.dy);
    for (var i = 1; i < nodeCenters.length; i++) {
      path.lineTo(nodeCenters[i].dx, nodeCenters[i].dy);
    }
    canvas.drawPath(path, paint);

    // 分支线
    for (var i = 0; i < branchPositions.length; i++) {
      final nodeIndex = i < nodeCenters.length ? i : nodeCenters.length - 1;
      final branchPaint = Paint()
        ..color = trackColor
        ..strokeWidth = thickness * 0.8
        ..strokeCap = StrokeCap.square
        ..style = PaintingStyle.stroke
        ..isAntiAlias = false;
      canvas.drawLine(nodeCenters[nodeIndex], branchPositions[i], branchPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.nodeCenters != nodeCenters ||
        oldDelegate.branchPositions != branchPositions ||
        oldDelegate.flavor != flavor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.thickness != thickness;
  }
}
