import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../templates/models/template_style.dart';
import '../models/typography_settings.dart';
import '../services/audio_sanctum_service.dart';
import '../services/editor_pagination_coordinator.dart';
import 'keepsake_scroll_view.dart';
import 'scholar_chest/scholar_chest_drawer.dart';

/// Modal dialog and drawer integration for Scholar's Stationery Chest and Keepsake Scroll View.
class EditorOverlayActions {
  const EditorOverlayActions._();

  /// Opens the Scholar's Stationery Chest drawer.
  static Future<void> openScholarChest({
    required BuildContext context,
    required AppDatabase database,
    required Template? currentTemplate,
    required TypographySettings typography,
    required AudioSanctumService audioSanctumService,
    required DateTime? unlockAt,
    required bool isCenterAligned,
    required ScholarArtifactType initialArtifact,
    required ValueChanged<Template> onSelectTemplate,
    required ValueChanged<TypographySettings> onTypographyChanged,
    required ValueChanged<DateTime?> onLockChanged,
    required VoidCallback onToggleAlignment,
  }) async {
    if (currentTemplate == null) return;
    await ScholarChestDrawer.show(
      context: context,
      database: database,
      activeTemplateId: currentTemplate.id,
      typography: typography,
      audioSanctumService: audioSanctumService,
      unlockAt: unlockAt,
      isCenterAligned: isCenterAligned,
      initialArtifact: initialArtifact,
      onSelectTemplate: onSelectTemplate,
      onTypographyChanged: onTypographyChanged,
      onLockChanged: onLockChanged,
      onToggleAlignment: onToggleAlignment,
    );
  }

  /// Opens the Keepsake Scroll View preview.
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
