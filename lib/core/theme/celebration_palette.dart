import 'package:flutter/material.dart';

/// 庆祝/粒子效果专用色板。
///
/// 粒子庆祝（彩带、星光、烟花）需要一组高饱和、彼此差异明显的彩虹色，
/// 属于**装饰性色板**而非主题语义色：它不随浅色/深色主题切换，也不需要
/// 满足正文对比度要求（仅用于瞬时动画的彩色图形）。
///
/// 集中在此定义，避免色值散落在动画组件内部。
class CelebrationPalette {
  const CelebrationPalette._();

  /// 庆祝粒子默认色板（7 色）。
  static const List<Color> defaultColors = <Color>[
    Color(0xFFFF5252), // 红
    Color(0xFFFFD740), // 黄
    Color(0xFF69F0AE), // 绿
    Color(0xFF40C4FF), // 蓝
    Color(0xFFE040FB), // 紫
    Color(0xFFFFAB40), // 橙
    Color(0xFFFF80AB), // 粉
  ];

  /// 成就解锁专用色板：以金/琥珀为主，突出"获得成就"的仪式感。
  static const List<Color> achievementColors = <Color>[
    Color(0xFFFFD700), // 金
    Color(0xFFFFC107), // 琥珀
    Color(0xFFFFAB40), // 橙金
    Color(0xFFFFE57F), // 浅金
  ];
}
