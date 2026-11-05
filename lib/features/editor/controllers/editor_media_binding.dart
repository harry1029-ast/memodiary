import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../services/editor_pagination_coordinator.dart';
import '../widgets/editor_media_actions.dart';
import 'editor_autosave_manager.dart';
import 'editor_pagination_handler.dart';

/// Binds the entry editor's media interactions (pick, delete, caption) to the
/// pagination coordinator, database and autosave pipeline, keeping
/// `EntryEditorScreen` free of media plumbing.
class EditorMediaBinding {
  final AppDatabase database;
  final MediaSandboxService mediaSandboxService;
  final String entryId;
  final ImagePicker imagePicker;
  final EditorPaginationCoordinator coordinator;
  final PageController pageController;
  final EditorAutosaveManager autosaveManager;
  final EditorPaginationHandler paginationHandler;

  /// Requests a rebuild of the hosting screen (only invoked while mounted).
  final VoidCallback onStateChanged;

  const EditorMediaBinding({
    required this.database,
    required this.mediaSandboxService,
    required this.entryId,
    required this.imagePicker,
    required this.coordinator,
    required this.pageController,
    required this.autosaveManager,
    required this.paginationHandler,
    required this.onStateChanged,
  });

  /// Picks a photo or video and attaches it, then glides to the active sheet.
  Future<void> pickMedia(BuildContext context, {required bool isVideo}) async {
    void onDone() {
      paginationHandler.attachSheetListeners();
      if (!context.mounted) return;
      paginationHandler.currentSheetIndex = coordinator.activeSheetIndex;
      onStateChanged();
      if (pageController.hasClients) {
        pageController.animateToPage(
          coordinator.activeSheetIndex,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
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

  /// Removes a sheet-paired keepsake from [sheetIndex] and its database record.
  Future<void> deleteMedia(int sheetIndex, String mediaId) async {
    await EditorMediaActions.handleDeleteMedia(
      coordinator: coordinator,
      database: database,
      entryId: entryId,
      sheetIndex: sheetIndex,
      mediaId: mediaId,
      autosaveManager: autosaveManager,
      onStateChanged: onStateChanged,
    );
  }

  /// Persists an edited caption for [mediaId].
  Future<void> updateCaption(String mediaId, String newCaption) async {
    await database.updateMediaOcr(mediaId, ocrText: newCaption, ocrBlocksJson: '[]');
  }
}
