import '../../ink_choreography/ink_choreography_config.dart';

typedef _ModeLabels = ({String title, String badge, String icon, String description});

/// One label record per mode; an exhaustive switch so a new mode cannot go
/// unlabelled.
_ModeLabels _modeLabels(InkDeliveryMode mode) => switch (mode) {
      InkDeliveryMode.singleFluent => const (
          title: '单笔连绵',
          badge: '双管 · 单笔',
          icon: '🖌️',
          description: '一管毛笔依次书写，字与字间提笔飞渡。',
        ),
      InkDeliveryMode.multiConcurrent => const (
          title: '并笔齐书',
          badge: '双管 · 并笔',
          icon: '🖌️🖌️',
          description: '每字各生一笔，同时挥毫落墨。',
        ),
      InkDeliveryMode.inkOnly => const (
          title: '见墨不见笔',
          badge: '双管 · 纯墨',
          icon: '✨',
          description: '隐去笔杆，唯见水墨晕染成形。',
        ),
      InkDeliveryMode.off => const (
          title: '敛锋静书',
          badge: '双管 · 静书',
          icon: '🪷',
          description: '落字即成，不作运笔动效。',
        ),
    };

/// The diarist-facing names of the Ink Choreography delivery modes.
extension InkDeliveryModeLabels on InkDeliveryMode {
  _ModeLabels get _labels => _modeLabels(this);

  /// The full mode name (运笔模式), e.g. `单笔连绵`.
  String get title => _labels.title;

  /// The Twin Bamboo Brushes badge, e.g. `双管 · 单笔`.
  String get badge => _labels.badge;

  String get icon => _labels.icon;

  String get description => _labels.description;
}

extension BristleStiffnessLabels on BristleStiffness {
  String get title => switch (this) {
        BristleStiffness.wolf => '狼毫 · 劲健',
        BristleStiffness.mixed => '兼毫 · 温润',
        BristleStiffness.goat => '羊毫 · 柔婉',
      };
}

extension WritingCadenceLabels on WritingCadence {
  String get title => switch (this) {
        WritingCadence.slow => '0.5x 慢品',
        WritingCadence.standard => '1.0x 标准',
        WritingCadence.swift => '1.8x 疾书',
      };
}
