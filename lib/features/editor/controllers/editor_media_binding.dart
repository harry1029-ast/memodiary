import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../services/editor_pagination_coordinator.dart';
import '../widgets/editor_media_actions.dart';
import 'brush_reveal_queue.dart';
import 'editor_autosave_manager.dart';

/// Binds the entry editor's media interactions (collect, mount, unmount, erase,
/// caption) to the pagination coordinator, database and autosave pipeline,
/// keeping `EntryEditorScreen` free of media plumbing.
class EditorMediaBinding {
  final AppDatabase database;
  final MediaSandboxService mediaSandboxService;
  final String entryId;
  final ImagePicker imagePicker;
  final EditorPaginationCoordinator coordinator;
  final EditorAutosaveManager autosaveManager;

  /// Requests a rebuild of the hosting screen (only invoked while mounted).
  final VoidCallback onStateChanged;

  /// How long an erased item can be restored before it is purged.
  static const Duration kEraseUndoWindow = Duration(seconds: 4);

  /// Ticks each time a mount is refused because the active sheet is full, so
  /// its Sheet Mount Strip can shake.
  final ValueNotifier<int> mountRefusals = ValueNotifier<int>(0);

  /// Items collected in this session awaiting their one-time Brush Reveal.
  final BrushRevealQueue brushReveals = BrushRevealQueue();

  /// Erased items still inside their undo window, by attachment id.
  final Map<String, SheetMediaItem> _pendingErasures = <String, SheetMediaItem>{};

  EditorMediaBinding({
    required this.database,
    required this.mediaSandboxService,
    required this.entryId,
    required this.imagePicker,
    required this.coordinator,
    required this.autosaveManager,
    required this.onStateChanged,
  });

  /// Picks a photo or video and Collects it into the Staging Handscroll.
  Future<void> pickMedia(BuildContext context, {required bool isVideo}) async {
    void onDone() {
      if (context.mounted) onStateChanged();
    }

    if (isVideo) {
      await EditorMediaActions.handleVideoPick(
        context: context,
        imagePicker: imagePicker,
        coordinator: coordinator,
        mediaSandboxService: mediaSandboxService,
        database: database,
        entryId: entryId,
        autosaveManager: autosaveManager,
        onStateChanged: onDone,
        onCollected: brushReveals.enqueue,
      );
    } else {
      await EditorMediaActions.handleImagePick(
        context: context,
        imagePicker: imagePicker,
        coordinator: coordinator,
        mediaSandboxService: mediaSandboxService,
        database: database,
        entryId: entryId,
        autosaveManager: autosaveManager,
        onStateChanged: onDone,
        onCollected: brushReveals.enqueue,
      );
    }
  }

  /// Mounts the staged item [mediaId] onto the active Stationery Sheet; a full
  /// sheet refuses with a shake and "本页已满三影", leaving the item staged.
  Future<void> mountMedia(BuildContext context, String mediaId) async {
    final didMount = coordinator.media.mountOnActiveSheet(mediaId);
    if (didMount) brushReveals.complete(mediaId);
    onStateChanged();
    if (!didMount) {
      mountRefusals.value++;
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('本页已满三影')));
      }
      return;
    }
    await autosaveManager.saveDraft();
  }

  /// Unmounts [mediaId] from its sheet back into the Staging Handscroll.
  Future<void> unmountMedia(String mediaId) async {
    if (!coordinator.media.unmount(mediaId)) return;
    onStateChanged();
    await autosaveManager.saveDraft();
  }

  /// Erases the staged item [mediaId] from the handscroll and offers undo; once
  /// the undo window passes, its `media_attachments` row and sandboxed file are
  /// purged (Bidirectional Media Lifecycle Parity).
  void eraseStagedMedia(BuildContext context, String mediaId) {
    final removed = coordinator.media.removeStaged(mediaId);
    if (removed == null) return;
    brushReveals.complete(mediaId);
    _pendingErasures[mediaId] = removed;
    onStateChanged();

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger
        .showSnackBar(
          SnackBar(
            content: const Text('已舍弃一影'),
            duration: kEraseUndoWindow,
            persist: false,
            action: SnackBarAction(
              label: '撤销',
              onPressed: () => _undoErase(mediaId),
            ),
          ),
        )
        .closed
        .then((reason) {
      if (reason != SnackBarClosedReason.action) _purge(mediaId);
    });
  }

  void _undoErase(String mediaId) {
    final item = _pendingErasures.remove(mediaId);
    if (item == null) return;
    coordinator.media.restoreStaged(item);
    onStateChanged();
  }

  Future<void> _purge(String mediaId) async {
    final item = _pendingErasures.remove(mediaId);
    if (item == null) return;
    await database.deleteMediaForEntryByPath(
      entryId: entryId,
      relativePath: item.relativePath,
    );
    await mediaSandboxService.deleteMedia(item.relativePath);
  }

  /// Persists an edited caption for [mediaId].
  Future<void> updateCaption(String mediaId, String newCaption) async {
    await database.updateMediaCaption(mediaId, caption: newCaption);
  }

  /// Purges erasures still inside their undo window, since the editor that
  /// could restore them is going away.
  void dispose() {
    for (final mediaId in _pendingErasures.keys.toList()) {
      _purge(mediaId);
    }
    mountRefusals.dispose();
    brushReveals.dispose();
  }
}
