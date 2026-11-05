import 'package:flutter/material.dart';

import '../controllers/editor_media_binding.dart';
import '../models/desk_media_handlers.dart';

/// Presents the desk's media feedback (refused mounts, erase undo) for an
/// [EditorMediaBinding], which owns the state and the purge but no UI.
class EditorMediaFeedback {
  const EditorMediaFeedback._();

  /// The desk's handlers over [binding], with SnackBar feedback shown in [context].
  static DeskMediaHandlers handlersFor(
    BuildContext context,
    EditorMediaBinding binding, {
    VoidCallback? onCollect,
  }) {
    return DeskMediaHandlers(
      onCollect: onCollect,
      onMount: (mediaId) async {
        final didMount = await binding.mountMedia(mediaId);
        if (!didMount && context.mounted) _show(context, const SnackBar(content: Text('本页已满三影')));
      },
      onErase: (mediaId) {
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
      onUnmount: binding.unmountMedia,
      mountRefusals: binding.mountRefusals,
      brushReveals: binding.brushReveals,
    );
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _show(BuildContext context, SnackBar snackBar) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    return messenger.showSnackBar(snackBar);
  }
}
