import 'package:flutter/material.dart';

/// Makes the active Stationery Sheet the drop target for a Staging Handscroll
/// item dragged by long-press (data: the attachment id). While an item hovers
/// the sheet a cinnabar frame lights up; dropping reports [onDrop], which is the
/// same mount path as 📌 (including refusal on a full sheet). Inactive sheets
/// never accept, so there is no drag between sheets. Pure presentation.
class SheetDropTarget extends StatelessWidget {
  final bool isActive;
  final int sheetIndex;
  final ValueChanged<String>? onDrop;
  final Widget child;

  const SheetDropTarget({
    super.key,
    required this.isActive,
    required this.sheetIndex,
    required this.onDrop,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) return child;
    return DragTarget<String>(
      key: Key('sheet_drop_target_$sheetIndex'),
      onWillAcceptWithDetails: (details) => onDrop != null,
      onAcceptWithDetails: (details) => onDrop?.call(details.data),
      builder: (targetContext, candidates, rejected) {
        final isHovered = candidates.isNotEmpty;
        return Stack(
          fit: StackFit.passthrough,
          children: [
            child,
            if (isHovered)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const Key('sheet_drop_highlight'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: const Color(0xFFB5362B), width: 2.5),
                      color: const Color(0x14B5362B),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
