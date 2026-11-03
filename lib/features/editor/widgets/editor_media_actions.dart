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
import '../models/media_embed_data.dart';
import '../models/thought_spark.dart';
import '../services/editor_pagination_coordinator.dart';
import '../services/thought_spark_service.dart';

/// Modular helpers for sandboxed media ingestion (photos and short videos)
/// and rotating Thought Spark prompt ingestion inside the diary editor.
class EditorMediaActions {
  const EditorMediaActions._();

  /// Prompts the user to pick an image (camera or gallery), compresses to WebP,
  /// copies into private sandbox storage, and embeds into the Quill Delta or coordinator.
  static Future<void> handleImagePick({
    required BuildContext context,
    required ImagePicker imagePicker,
    QuillController? controller,
    EditorPaginationCoordinator? coordinator,
    PageController? pageController,
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
              leading: Icon(Icons.camera_alt_outlined, color: tokens.jiaomo),
              title: Text(
                '即时拓影 · Take Photo',
                style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, color: tokens.jiaomo),
              ),
              onTap: () => Navigator.pop(modalContext, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: tokens.jiaomo),
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

      await database.attachMediaToEntry(
        id: const Uuid().v4(),
        entryId: entryId,
        relativePath: relativePath,
        mediaType: 'image',
      );

      if (coordinator != null) {
        final targetIndex = coordinator.activeSheetIndex + 1;
        coordinator.insertEphemeraSheet(
          mediaType: 'image',
          mediaData: MediaEmbedData(
            path: relativePath,
            caption: '',
            aspect: 'auto',
          ),
          atIndex: targetIndex,
        );
        onStateChanged?.call();
      } else if (controller != null) {
        final index = controller.selection.baseOffset.clamp(
          0,
          controller.document.length - 1,
        );
        controller.document.insert(index, BlockEmbed.image(relativePath));
      }

      autosaveManager?.saveDraft();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to insert photo: $error')),
        );
      }
    }
  }

  /// Prompts the user to pick or record a video (camera or gallery, <= 60s),
  /// sandboxes into private storage, and embeds into the Quill Delta or coordinator.
  static Future<void> handleVideoPick({
    required BuildContext context,
    required ImagePicker imagePicker,
    QuillController? controller,
    EditorPaginationCoordinator? coordinator,
    PageController? pageController,
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
              leading: Icon(Icons.videocam_outlined, color: tokens.jiaomo),
              title: Text(
                '录制短影 · Record Video (≤60s)',
                style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, color: tokens.jiaomo),
              ),
              onTap: () => Navigator.pop(modalContext, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.video_library_outlined, color: tokens.jiaomo),
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

      await database.attachMediaToEntry(
        id: const Uuid().v4(),
        entryId: entryId,
        relativePath: result.relativePath,
        mediaType: 'video',
        thumbnailPath: result.thumbnailPath,
      );

      if (coordinator != null) {
        final targetIndex = coordinator.activeSheetIndex + 1;
        coordinator.insertEphemeraSheet(
          mediaType: 'video',
          mediaData: MediaEmbedData(
            path: result.relativePath,
            caption: '',
            aspect: 'auto',
          ),
          atIndex: targetIndex,
        );
        onStateChanged?.call();
      } else if (controller != null) {
        final index = controller.selection.baseOffset.clamp(
          0,
          controller.document.length - 1,
        );
        controller.document.insert(index, BlockEmbed.video(result.relativePath));
      }

      autosaveManager?.saveDraft();
    } on VideoDurationExceededException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
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
}
