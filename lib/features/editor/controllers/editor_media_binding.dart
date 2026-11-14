import 'package:flutter/widgets.dart';
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
  /// its Tucked Prints can shake.
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

  /// Mounts the staged item [mediaId] onto the active Stationery Sheet and
  /// returns whether it mounted. A full sheet refuses (ticking [mountRefusals]
  /// so its Tucked Prints shake), leaving the item staged.
  Future<bool> mountMedia(String mediaId) async {
    final didMount = coordinator.mountOnActiveSheet(mediaId);
    if (didMount) brushReveals.complete(mediaId);
    onStateChanged();
    if (!didMount) {
      mountRefusals.value++;
      return false;
    }
    await autosaveManager.saveDraft();
    return true;
  }

  /// Unmounts [mediaId] from its sheet back into the Staging Handscroll.
  Future<void> unmountMedia(String mediaId) async {
    if (!coordinator.unmountMedia(mediaId)) return;
    onStateChanged();
    await autosaveManager.saveDraft();
  }

  /// Erases the staged item [mediaId] from the handscroll and returns whether
  /// it was erased. It stays restorable through [undoErase] for
  /// [kEraseUndoWindow]; [purgeErased] then deletes its `media_attachments` row
  /// and sandboxed file (Bidirectional Media Lifecycle Parity).
  bool eraseStagedMedia(String mediaId) {
    final removed = coordinator.removeStaged(mediaId);
    if (removed == null) return false;
    brushReveals.complete(mediaId);
    _pendingErasures[mediaId] = removed;
    onStateChanged();
    return true;
  }

  /// Erases every item still staged and purges each immediately (there is no
  /// undo: the editor is being left). Items already erased and awaiting their
  /// undo window are purged too, so none outlives the editor. Mounted items are
  /// untouched.
  Future<void> discardAllStaged() async {
    for (final item in coordinator.stagedItems.toList()) {
      eraseStagedMedia(item.id);
    }
    for (final mediaId in _pendingErasures.keys.toList()) {
      await _purge(mediaId);
    }
  }

  /// Restores the erased item [mediaId] to the handscroll, if still pending.
  void undoErase(String mediaId) {
    final item = _pendingErasures.remove(mediaId);
    if (item == null) return;
    coordinator.restoreStaged(item);
    onStateChanged();
  }

  /// Purges the erased item [mediaId] once its undo window has passed.
  Future<void> purgeErased(String mediaId) => _purge(mediaId);

  Future<void> _purge(String mediaId) async {
    final item = _pendingErasures.remove(mediaId);
    if (item == null) return;
    await database.mediaOcrDao.deleteMediaForEntryByPath(
      entryId: entryId,
      relativePath: item.relativePath,
    );
    await mediaSandboxService.deleteMedia(item.relativePath);
  }

  /// Updates the in-memory and persisted caption for [mediaId].
  Future<void> updateCaption(String mediaId, String newCaption) async {
    if (coordinator.updateCaption(mediaId, newCaption)) onStateChanged();
    await database.mediaOcrDao.updateMediaCaption(mediaId, caption: newCaption);
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
