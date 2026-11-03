import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../templates/models/template_style.dart';
import '../services/editor_pagination_coordinator.dart';
import 'keepsake_scroll_view.dart';

/// Synthesizes live multi-sheet draft content into a transient [Entry] snapshot
/// and launches the classical [KeepsakeScrollView] contemplation overlay.
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
}
