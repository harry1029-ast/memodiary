import '../../ink_choreography/ink_choreography_config.dart';

/// The diarist-facing names of the Ink Choreography delivery modes.
extension InkDeliveryModeLabels on InkDeliveryMode {
  /// The full mode name (运笔模式), e.g. `单笔连绵`.
  String get title => switch (this) {
        InkDeliveryMode.singleFluent => '单笔连绵',
        InkDeliveryMode.multiConcurrent => '并笔齐书',
        InkDeliveryMode.inkOnly => '见墨不见笔',
        InkDeliveryMode.off => '敛锋静书',
      };

  /// The Twin Bamboo Brushes badge, e.g. `双管 · 单笔`.
  String get badge => switch (this) {
        InkDeliveryMode.singleFluent => '双管 · 单笔',
        InkDeliveryMode.multiConcurrent => '双管 · 并笔',
        InkDeliveryMode.inkOnly => '双管 · 纯墨',
        InkDeliveryMode.off => '双管 · 静书',
      };

  String get icon => switch (this) {
        InkDeliveryMode.singleFluent => '🖌️',
        InkDeliveryMode.multiConcurrent => '🖌️🖌️',
        InkDeliveryMode.inkOnly => '✨',
        InkDeliveryMode.off => '🪷',
      };

  String get description => switch (this) {
        InkDeliveryMode.singleFluent => '一管毛笔依次书写，字与字间提笔飞渡。',
        InkDeliveryMode.multiConcurrent => '每字各生一笔，同时挥毫落墨。',
        InkDeliveryMode.inkOnly => '隐去笔杆，唯见水墨晕染成形。',
        InkDeliveryMode.off => '落字即成，不作运笔动效。',
      };
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
