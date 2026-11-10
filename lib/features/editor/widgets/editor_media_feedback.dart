import 'package:flutter/material.dart';

import '../controllers/editor_media_binding.dart';
import '../domain/sheet_media_item.dart';
import '../models/desk_media_handlers.dart';

/// Presents the desk's media feedback (refused mounts, erase undo, overflow
/// unmounts) for an [EditorMediaBinding], which owns the state and the purge
/// but no UI.
class EditorMediaFeedback {
  const EditorMediaFeedback._();

  /// The desk's handlers over [binding], with SnackBar feedback shown in [context].
  static DeskMediaHandlers handlersFor(
    BuildContext context,
    EditorMediaBinding binding, {
    VoidCallback? onCollect,
    VoidCallback? onDeskInteraction,
  }) {
    return DeskMediaHandlers(
      onCollect: onCollect,
      onDeskInteraction: onDeskInteraction,
      onMount: (mediaId) async {
        onDeskInteraction?.call();
        final didMount = await binding.mountMedia(mediaId);
        if (!didMount && context.mounted) _show(context, const SnackBar(content: Text('本页已满三影')));
      },
      onErase: (mediaId) {
        onDeskInteraction?.call();
        if (!binding.eraseStagedMedia(mediaId) || !context.mounted) return;
        _show(
          context,
          SnackBar(
            content: const Text('已舍弃一影'),
            duration: EditorMediaBinding.kEraseUndoWindow,
            persist: false,
            action: SnackBarAction(label: '撤销', onPressed: () => binding.undoErase(mediaId)),
          ),
        ).closed.then((reason) {
          if (reason != SnackBarClosedReason.action) binding.purgeErased(mediaId);
        });
      },
      onUnmount: (mediaId) {
        onDeskInteraction?.call();
        binding.unmountMedia(mediaId);
      },
      mountRefusals: binding.mountRefusals,
      brushReveals: binding.brushReveals,
    );
  }

  /// Tells the diarist which items reflow pushed past the last sheet and
  /// returned to the Staging Handscroll.
  static void showOverflowUnmountNotice(BuildContext context, List<SheetMediaItem> unmountedItems) {
    if (!context.mounted) return;
    _show(
      context,
      SnackBar(
        key: const Key('overflow_unmount_snackbar'),
        content: Text('末页已满三影 · ${unmountedItems.length} 影已揭回画卷'),
      ),
    );
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _show(BuildContext context, SnackBar snackBar) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    return messenger.showSnackBar(snackBar);
  }
}
