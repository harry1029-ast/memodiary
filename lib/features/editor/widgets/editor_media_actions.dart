import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../controllers/editor_autosave_manager.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/media_embed_data.dart';
import '../models/thought_spark.dart';
import '../services/editor_pagination_coordinator.dart';
import '../services/thought_spark_service.dart';

/// Modular helpers for sandboxed media ingestion (photos and short videos)
/// and rotating Thought Spark prompt ingestion inside the diary editor.
class EditorMediaActions {
  const EditorMediaActions._();

  /// Prompts the user to pick an image (camera or gallery), compresses to WebP,
  /// copies into private sandbox storage, and mounts onto a dedicated EphemeraSheet.
  static Future<void> handleImagePick({
    required BuildContext context,
    required ImagePicker imagePicker,
    required EditorPaginationCoordinator coordinator,
    required MediaSandboxService mediaSandboxService,
    required AppDatabase database,
    required String entryId,
    EditorAutosaveManager? autosaveManager,
    VoidCallback? onStateChanged,
  }) async {
    final tokens = InkDiaryTheme.tokensOf(context);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: tokens.xuanGround,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, size: 20, color: tokens.jiaomo),
              title: Text(
                '即时拓影 · Take Photo',
                style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, color: tokens.jiaomo),
              ),
              onTap: () => Navigator.pop(modalContext, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, size: 20, color: tokens.jiaomo),
              title: Text(
                '相册选撷 · Photo Gallery',
                style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, color: tokens.jiaomo),
              ),
              onTap: () => Navigator.pop(modalContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !context.mounted) return;

    try {
      final picked = await imagePicker.pickImage(source: source);
      if (picked == null) return;

      final relativePath = await mediaSandboxService.copyAndCompressImage(
        File(picked.path),
      );

      final mediaId = const Uuid().v4();
      await database.attachMediaToEntry(
        id: mediaId,
        entryId: entryId,
        relativePath: relativePath,
        mediaType: EphemeraMediaType.image.embedKey,
      );

      final activeSheet = coordinator.sheets.isNotEmpty &&
              coordinator.activeSheetIndex < coordinator.sheets.length
          ? coordinator.sheets[coordinator.activeSheetIndex]
          : null;

      if (activeSheet is TextStationerySheet && !activeSheet.isAtMediaCapacity) {
        coordinator.attachMediaToActiveSheet(
          SheetMediaItem(
            id: mediaId,
            mediaType: EphemeraMediaType.image,
            relativePath: relativePath,
          ),
        );
      } else {
        coordinator.insertMediaAtCurrentSelection(
          mediaType: EphemeraMediaType.image,
          mediaData: MediaEmbedData(
            path: relativePath,
            caption: '',
            aspect: 'auto',
          ),
        );
      }
      onStateChanged?.call();
      await autosaveManager?.saveDraft();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Failed to insert photo: $error')),
          );
      }
    }
  }

  /// Prompts the user to pick or record a video (camera or gallery, <= 60s),
  /// sandboxes into private storage, and mounts onto a dedicated EphemeraSheet.
  static Future<void> handleVideoPick({
    required BuildContext context,
    required ImagePicker imagePicker,
    required EditorPaginationCoordinator coordinator,
    required MediaSandboxService mediaSandboxService,
    required AppDatabase database,
    required String entryId,
    EditorAutosaveManager? autosaveManager,
    VoidCallback? onStateChanged,
  }) async {
    final tokens = InkDiaryTheme.tokensOf(context);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: tokens.xuanGround,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.videocam_outlined, size: 20, color: tokens.jiaomo),
              title: Text(
                '录制短影 · Record Video (≤60s)',
                style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, color: tokens.jiaomo),
              ),
              onTap: () => Navigator.pop(modalContext, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.video_library_outlined, size: 20, color: tokens.jiaomo),
              title: Text(
                '相册选取短影 · Video Gallery (≤60s)',
                style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, color: tokens.jiaomo),
              ),
              onTap: () => Navigator.pop(modalContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !context.mounted) return;

    try {
      final picked = await imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );
      if (picked == null) return;

      final result = await mediaSandboxService.copyAndSandboxVideo(
        File(picked.path),
      );

      final mediaId = const Uuid().v4();
      await database.attachMediaToEntry(
        id: mediaId,
        entryId: entryId,
        relativePath: result.relativePath,
        mediaType: EphemeraMediaType.video.embedKey,
        thumbnailPath: result.thumbnailPath,
      );

      final activeSheet = coordinator.sheets.isNotEmpty &&
              coordinator.activeSheetIndex < coordinator.sheets.length
          ? coordinator.sheets[coordinator.activeSheetIndex]
          : null;

      if (activeSheet is TextStationerySheet && !activeSheet.isAtMediaCapacity) {
        coordinator.attachMediaToActiveSheet(
          SheetMediaItem(
            id: mediaId,
            mediaType: EphemeraMediaType.video,
            relativePath: result.relativePath,
            thumbnailPath: result.thumbnailPath,
          ),
        );
      } else {
        coordinator.insertMediaAtCurrentSelection(
          mediaType: EphemeraMediaType.video,
          mediaData: MediaEmbedData(
            path: result.relativePath,
            caption: '',
            aspect: 'auto',
          ),
        );
      }
      onStateChanged?.call();
      await autosaveManager?.saveDraft();
    } on VideoDurationExceededException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(error.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Failed to insert video: $error')),
          );
      }
    }
  }

  /// Shuffles the active Thought Spark prompt and presents the SnackBar trigger.
  static ThoughtSpark handleShuffleSpark({
    required BuildContext context,
    required ThoughtSparkService thoughtSparkService,
    required void Function(String prompt) onAdoptPrompt,
  }) {
    HapticFeedback.selectionClick();
    final nextSpark = thoughtSparkService.nextSpark();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '“${nextSpark.localizedPrompt}”',
            style: const TextStyle(fontFamily: InkDiaryTheme.fontKaiti),
          ),
          action: SnackBarAction(
            label: '由此题落墨',
            onPressed: () => onAdoptPrompt(nextSpark.localizedPrompt),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    return nextSpark;
  }

  /// Inserts a Thought Spark prompt blockquote into the Quill document.
  static void handleInsertPrompt({
    required QuillController? controller,
    required String prompt,
    EditorAutosaveManager? autosaveManager,
    VoidCallback? onStateChanged,
  }) {
    if (controller == null) return;
    final index = controller.selection.baseOffset.clamp(
      0,
      controller.document.length - 1,
    );
    controller.document.insert(index, '【灵感拾遗】$prompt\n');
    controller.formatText(index, prompt.length + 6, Attribute.blockQuote);
    autosaveManager?.saveDraft(force: true);
    onStateChanged?.call();
  }

  /// Deletes an attached media item from the given sheet, removes it from SQLite,
  /// and saves a draft.
  static Future<void> handleDeleteMedia({
    required EditorPaginationCoordinator coordinator,
    required AppDatabase database,
    required String entryId,
    required int sheetIndex,
    required String mediaId,
    EditorAutosaveManager? autosaveManager,
    VoidCallback? onStateChanged,
  }) async {
    if (sheetIndex >= 0 && sheetIndex < coordinator.sheets.length) {
      final sheet = coordinator.sheets[sheetIndex];
      if (sheet is TextStationerySheet) {
        final items = sheet.mediaAttachments.where((item) => item.id == mediaId).toList();
        coordinator.removeMediaAttachment(sheetIndex, mediaId);
        for (final item in items) {
          await database.deleteMediaForEntryByPath(
            entryId: entryId,
            relativePath: item.relativePath,
          );
        }
        await autosaveManager?.saveDraft();
        onStateChanged?.call();
      }
    }
  }
}
