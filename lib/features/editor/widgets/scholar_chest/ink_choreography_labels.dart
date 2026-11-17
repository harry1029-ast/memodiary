import '../../ink_choreography/ink_choreography_config.dart';

typedef _ModeLabels = ({String title, String badge, String icon, String description});

/// One label record per mode; an exhaustive switch so a new mode cannot go
/// unlabelled.
_ModeLabels _modeLabels(InkDeliveryMode mode) => switch (mode) {
      InkDeliveryMode.singleFluent => const (
          title: '逐笔书写',
          badge: '笔刷动画 · 逐笔',
          icon: '🖌️',
          description: '依次逐笔书写，展示连续笔顺动画。',
        ),
      InkDeliveryMode.multiConcurrent => const (
          title: '同时书写',
          badge: '笔刷动画 · 同时',
          icon: '🖌️🖌️',
          description: '每个字同时开始书写。',
        ),
      InkDeliveryMode.inkOnly => const (
          title: '仅墨迹',
          badge: '笔刷动画 · 仅墨迹',
          icon: '✨',
          description: '不显示笔杆，只显示墨迹渐显效果。',
        ),
      InkDeliveryMode.off => const (
          title: '无动画',
          badge: '笔刷动画 · 关闭',
          icon: '🪷',
          description: '直接显示文字，不播放书写动画。',
        ),
    };

/// The diarist-facing names of the Ink Choreography delivery modes.
extension InkDeliveryModeLabels on InkDeliveryMode {
  _ModeLabels get _labels => _modeLabels(this);

  /// The full mode name, e.g. `逐笔书写`.
  String get title => _labels.title;

  /// The Twin Bamboo Brushes badge, e.g. `笔刷动画 · 逐笔`.
  String get badge => _labels.badge;

  String get icon => _labels.icon;

  String get description => _labels.description;
}

extension BristleStiffnessLabels on BristleStiffness {
  String get title => switch (this) {
        BristleStiffness.wolf => '狼毫 (偏硬)',
        BristleStiffness.mixed => '兼毫 (适中)',
        BristleStiffness.goat => '羊毫 (偏软)',
      };
}

extension WritingCadenceLabels on WritingCadence {
  String get title => switch (this) {
        WritingCadence.slow => '0.5x 慢速',
        WritingCadence.standard => '1.0x 标准',
        WritingCadence.swift => '1.8x 快速',
      };
}
