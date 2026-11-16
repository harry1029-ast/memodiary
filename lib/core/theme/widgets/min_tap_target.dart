import 'package:flutter/material.dart';

/// Enforces WCAG / MemoDiary `44×44` minimum interactive hit-test bounds
/// around compact visual chips, badges, and buttons while preserving explicit
/// `Semantics` labelling.
class MinTapTarget extends StatelessWidget {
  static const double minDimension = 44.0;

  final Key? materialKey;
  final Key? inkWellKey;
  final String semanticLabel;
  final bool? selected;
  final bool? enabled;
  final bool excludeChildSemantics;
  final bool stretchWidth;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Widget child;

  const MinTapTarget({
    super.key,
    this.materialKey,
    this.inkWellKey,
    required this.semanticLabel,
    this.selected,
    this.enabled,
    this.excludeChildSemantics = false,
    this.stretchWidth = false,
    this.borderRadius,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);
    Widget inner = Material(
      key: materialKey,
      type: MaterialType.transparency,
      child: InkWell(
        key: inkWellKey,
        onTap: onTap,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: minDimension,
            minHeight: minDimension,
          ),
          child: Center(
            widthFactor: stretchWidth ? null : 1.0,
            heightFactor: 1.0,
            child: child,
          ),
        ),
      ),
    );

    if (excludeChildSemantics) {
      inner = ExcludeSemantics(child: inner);
    }

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: semanticLabel,
      child: inner,
    );
  }
}
