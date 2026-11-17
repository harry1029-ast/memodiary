import 'package:flutter/foundation.dart';

/// How Ink Choreography (挥毫落墨) delivers newly written characters onto a
/// Stationery Sheet (运笔模式).
enum InkDeliveryMode {
  /// 单笔连绵: one master brush writes the queued characters in order.
  singleFluent('single_fluent'),

  /// 并笔齐书: every committed character gets its own brush at once.
  multiConcurrent('multi_concurrent'),

  /// 见墨不见笔: wet ink only, no brush.
  inkOnly('ink_only'),

  /// 敛锋静书: no live stroke animation.
  off('off');

  /// The value persisted by `EditorSettingsService`.
  final String storageId;

  const InkDeliveryMode(this.storageId);

  /// Whether a bamboo brush accompanies the wet ink.
  bool get showsBrush => this == singleFluent || this == multiConcurrent;

  static InkDeliveryMode fromStorageId(String? storageId) =>
      _byStorageId(values, storageId, (mode) => mode.storageId, InkChoreographyConfig.defaultDeliveryMode);
}

/// Bristle elasticity presets (毫锋弹性). [lagFactor] is how much of the gap to
/// the tip the brush handle closes per 60 Hz frame.
enum BristleStiffness {
  /// 狼毫 · 劲健
  wolf('wolf', 0.28),

  /// 兼毫 · 温润
  mixed('mixed', 0.18),

  /// 羊毫 · 柔婉
  goat('goat', 0.11);

  final String storageId;
  final double lagFactor;

  const BristleStiffness(this.storageId, this.lagFactor);

  static BristleStiffness fromStorageId(String? storageId) =>
      _byStorageId(values, storageId, (stiffness) => stiffness.storageId, InkChoreographyConfig.defaultBristleStiffness);
}

/// Writing cadence presets (运笔疾徐).
enum WritingCadence {
  /// 慢品
  slow('slow', 0.55),

  /// 标准
  standard('standard', 1.0),

  /// 疾书
  swift('swift', 1.8);

  final String storageId;
  final double speedMultiplier;

  const WritingCadence(this.storageId, this.speedMultiplier);

  static WritingCadence fromStorageId(String? storageId) =>
      _byStorageId(values, storageId, (cadence) => cadence.storageId, InkChoreographyConfig.defaultCadence);
}

/// The preset in [values] persisted as [storageId], or [fallback] for a
/// missing or unknown value.
T _byStorageId<T>(List<T> values, String? storageId, String Function(T) storageIdOf, T fallback) =>
    values.firstWhere((value) => storageIdOf(value) == storageId, orElse: () => fallback);

/// The diarist's app-wide Ink Choreography preferences. Never part of an
/// entry: it is not serialized into `entries.content_delta` or SQLite.
@immutable
class InkChoreographyConfig {
  static const InkDeliveryMode defaultDeliveryMode = InkDeliveryMode.singleFluent;
  static const BristleStiffness defaultBristleStiffness = BristleStiffness.mixed;
  static const WritingCadence defaultCadence = WritingCadence.standard;

  final InkDeliveryMode deliveryMode;
  final BristleStiffness bristleStiffness;
  final WritingCadence cadence;

  /// Whether strokes rustle on the paper (运笔声效).
  final bool soundEnabled;

  const InkChoreographyConfig({
    this.deliveryMode = defaultDeliveryMode,
    this.bristleStiffness = defaultBristleStiffness,
    this.cadence = defaultCadence,
    this.soundEnabled = true,
  });

  InkChoreographyConfig copyWith({
    InkDeliveryMode? deliveryMode,
    BristleStiffness? bristleStiffness,
    WritingCadence? cadence,
    bool? soundEnabled,
  }) =>
      InkChoreographyConfig(
        deliveryMode: deliveryMode ?? this.deliveryMode,
        bristleStiffness: bristleStiffness ?? this.bristleStiffness,
        cadence: cadence ?? this.cadence,
        soundEnabled: soundEnabled ?? this.soundEnabled,
      );

  @override
  bool operator ==(Object other) =>
      other is InkChoreographyConfig &&
      other.deliveryMode == deliveryMode &&
      other.bristleStiffness == bristleStiffness &&
      other.cadence == cadence &&
      other.soundEnabled == soundEnabled;

  @override
  int get hashCode => Object.hash(deliveryMode, bristleStiffness, cadence, soundEnabled);

  @override
  String toString() =>
      'InkChoreographyConfig(${deliveryMode.name}, ${bristleStiffness.name}, ${cadence.name}, sound: $soundEnabled)';
}
