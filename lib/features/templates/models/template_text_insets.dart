import 'package:flutter/foundation.dart';
import 'template_style.dart';

/// The canonical horizontal inset for the vertical vermilion margin rule on lined stationery.
const double kLinedMarginRuleInset = 24.0;

/// Immutable value object representing template-specific horizontal text insets
/// applied inside the bounded Paper Heart (版心).
@immutable
class TemplateTextInsets {
  /// Left inset in pixels inside the Paper Heart.
  final double left;

  /// Right inset in pixels inside the Paper Heart.
  final double right;

  const TemplateTextInsets({
    required this.left,
    required this.right,
  });

  /// Resolves the canonical [TemplateTextInsets] for a given [TemplateBackgroundType].
  ///
  /// - [TemplateBackgroundType.grid] & [TemplateBackgroundType.dotGrid]: 0.0 left, 0.0 right (align with cells)
  /// - [TemplateBackgroundType.lined]: 32.0 left (margin line at 24.0 + 8.0 breathing clearance), 20.0 right
  /// - [TemplateBackgroundType.color], [TemplateBackgroundType.paperTexture], and others: 20.0 left, 20.0 right
  factory TemplateTextInsets.forType(TemplateBackgroundType type) {
    switch (type) {
      case TemplateBackgroundType.grid:
      case TemplateBackgroundType.dotGrid:
        return const TemplateTextInsets(left: 0.0, right: 0.0);
      case TemplateBackgroundType.lined:
        return const TemplateTextInsets(
          left: kLinedMarginRuleInset + 8.0,
          right: 20.0,
        );
      case TemplateBackgroundType.color:
      case TemplateBackgroundType.paperTexture:
        return const TemplateTextInsets(left: 20.0, right: 20.0);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateTextInsets &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          right == other.right;

  @override
  int get hashCode => Object.hash(left, right);

  @override
  String toString() => 'TemplateTextInsets(left: $left, right: $right)';
}
