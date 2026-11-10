import 'package:flutter/material.dart';

/// One tool of the Writing Dock or the keyboard accessory row: a 44dp-wide
/// icon button whose backdrop lights up while its tool is active. Taps never
/// touch focus, so the software keyboard stays as it is.
class WritingDockToolButton extends StatelessWidget {
  final Key buttonKey;
  final Widget icon;
  final String tooltip;
  final bool isActive;
  final Color? activeBackground;
  final VoidCallback onTap;
  final double minHeight;

  const WritingDockToolButton({
    super.key,
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
    this.activeBackground,
    this.minHeight = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? (activeBackground ?? Colors.transparent) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        key: buttonKey,
        icon: icon,
        onPressed: onTap,
        tooltip: tooltip,
        constraints: BoxConstraints(minWidth: 44, minHeight: minHeight),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
