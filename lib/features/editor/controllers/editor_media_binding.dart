import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../services/editor_pagination_coordinator.dart';
import '../widgets/editor_media_actions.dart';
import 'editor_autosave_manager.dart';

/// Binds the entry editor's media interactions (collect, mount, erase, caption) to the
/// pagination coordinator, database and autosave pipeline, keeping
/// `EntryEditorScreen` free of media plumbing.
class EditorMediaBinding {
  final AppDatabase database;
  final MediaSandboxService mediaSandboxService;
  final String entryId;
  final ImagePicker imagePicker;
  final EditorPaginationCoordinator coordinator;
  final EditorAutosaveManager autosaveManager;

  /// Requests a rebuild of the hosting screen (only invoked while mounted).
  final VoidCallback onStateChanged;

  const EditorMediaBinding({
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
      );
    }
  }

  /// Mounts the staged item [mediaId] onto the active Stationery Sheet.
  Future<void> mountMedia(BuildContext context, String mediaId) async {
    final didMount = coordinator.media.mountOnActiveSheet(mediaId);
    onStateChanged();
    if (!didMount) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('本页已满三影')));
      }
      return;
    }
    await autosaveManager.saveDraft();
  }

  /// Erases the staged item [mediaId] and its database record.
  Future<void> eraseStagedMedia(String mediaId) async {
    await EditorMediaActions.handleEraseStagedMedia(
      coordinator: coordinator,
      database: database,
      entryId: entryId,
      mediaId: mediaId,
      autosaveManager: autosaveManager,
      onStateChanged: onStateChanged,
    );
  }

  /// Persists an edited caption for [mediaId].
  Future<void> updateCaption(String mediaId, String newCaption) async {
    await database.updateMediaCaption(mediaId, caption: newCaption);
  }
}
