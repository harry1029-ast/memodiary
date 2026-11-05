import 'package:flutter/material.dart';

import 'desk_media_control.dart';
import 'staged_media_drag_data.dart';

/// Makes the active Stationery Sheet the drop target for a Staging Handscroll
/// item dragged by long-press ([StagedMediaDragData]). While an item hovers the
/// sheet a cinnabar frame lights up; dropping reports [onMount], which is the
/// same mount path as 📌 (including refusal on a full sheet). Callers wrap only
/// the active sheet, so there is no drag between sheets. Pure presentation.
class SheetDropTarget extends StatelessWidget {
  final int sheetIndex;
  final DeskMediaPalette palette;
  final ValueChanged<String> onMount;
  final Widget child;

  const SheetDropTarget({
    super.key,
    required this.sheetIndex,
    required this.palette,
    required this.onMount,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<StagedMediaDragData>(
      key: Key('sheet_drop_target_$sheetIndex'),
      onAcceptWithDetails: (details) => onMount(details.data.mediaId),
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
                      border: Border.all(color: palette.cinnabar, width: 2.5),
                      color: palette.cinnabar.withValues(alpha: 0.08),
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
