import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../templates/models/template_style.dart';
import '../controllers/editor_autosave_manager.dart';
import '../models/thought_spark.dart';
import '../services/editor_pagination_coordinator.dart';
import '../services/thought_spark_service.dart';
import 'keepsake_scroll_view.dart';

/// Synthesizes live multi-sheet draft content into a transient [Entry] snapshot
/// to launch the classical [KeepsakeScrollView] contemplation overlay, and
/// coordinates Thought Spark Ghost Prompt shuffle/insertion actions.
class EditorOverlayActions {
  const EditorOverlayActions._();

  /// Opens the Keepsake Scroll View preview from the active paginated draft.
  static void openKeepsakeScroll({
    required BuildContext context,
    required Entry? entry,
    required Template? currentTemplate,
    required EditorPaginationCoordinator coordinator,
    required TextEditingController titleController,
    required MediaSandboxService mediaSandboxService,
    required AppDatabase database,
  }) {
    if (entry == null || currentTemplate == null) return;
    final templateStyle = TemplateStyle.fromTemplate(currentTemplate);
    final (currentDelta, currentPlain) = coordinator.reSynthesize();
    final currentTitle = titleController.text.trim();

    final previewEntry = entry.copyWith(
      title: Value(currentTitle),
      contentDelta: currentDelta,
      plainText: currentPlain,
      templateId: currentTemplate.id,
    );

    KeepsakeScrollView.show(
      context: context,
      entry: previewEntry,
      style: templateStyle,
      mediaService: mediaSandboxService,
      database: database,
    );
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
}
