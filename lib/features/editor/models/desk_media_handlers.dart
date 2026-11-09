import 'package:flutter/foundation.dart';

import '../controllers/brush_reveal_queue.dart';

/// The desk's media actions and signals, travelling together from the editor
/// screen through the paper canvas to the Sheet Mount Strip, the Desk
/// Workstation and the Staging Handscroll. Actions take attachment ids.
@immutable
class DeskMediaHandlers {
  /// Collects a new photo into the Staging Handscroll.
  final VoidCallback? onCollect;

  /// Mounts a staged item onto the active Stationery Sheet.
  final ValueChanged<String>? onMount;

  /// Erases a staged item (with undo).
  final ValueChanged<String>? onErase;

  /// Unmounts an item from its sheet back into the Staging Handscroll.
  final ValueChanged<String>? onUnmount;

  /// Ticks when a mount onto the active sheet is refused, shaking its strip.
  final ValueListenable<int>? mountRefusals;

  /// Items awaiting their Brush Reveal in the Staging Handscroll.
  final BrushRevealQueue? brushReveals;

  /// Runs before any desk interaction (mount, erase, unmount, opening an item)
  /// so the sheet gives up writing focus and the edit does not summon the
  /// keyboard.
  final VoidCallback? onDeskInteraction;

  const DeskMediaHandlers({
    this.onCollect,
    this.onMount,
    this.onErase,
    this.onUnmount,
    this.mountRefusals,
    this.brushReveals,
    this.onDeskInteraction,
  });
}
