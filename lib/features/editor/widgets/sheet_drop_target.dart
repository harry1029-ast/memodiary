import 'package:flutter/material.dart';

import 'desk_media_control.dart';
import 'staged_media_drag_data.dart';

/// Makes the active Stationery Sheet the drop target for a Staging Handscroll
/// item dragged by long-press ([StagedMediaDragData]). While an item hovers the
/// sheet a cinnabar frame lights up; dropping reports [onMount], which is the
/// same mount path as 📌 (including refusal on a full sheet). Callers wrap every
/// sheet and enable only the active one, so there is no drag between sheets and
/// a page turn never restructures (and so never unmounts) a sheet's editor.
/// Pure presentation.
class SheetDropTarget extends StatelessWidget {
  final int sheetIndex;
  final DeskMediaPalette palette;

  /// Mounts the dropped item; null or [isEnabled] false refuses every drop.
  final ValueChanged<String>? onMount;
  final bool isEnabled;
  final Widget child;

  const SheetDropTarget({
    super.key,
    required this.sheetIndex,
    required this.palette,
    required this.onMount,
    this.isEnabled = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final mount = isEnabled ? onMount : null;
    return DragTarget<StagedMediaDragData>(
      key: Key('sheet_drop_target_$sheetIndex'),
      onWillAcceptWithDetails: (details) => mount != null,
      onAcceptWithDetails: (details) => mount?.call(details.data.mediaId),
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
