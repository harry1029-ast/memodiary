import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../ink_choreography/ink_choreography_controller.dart';
import '../models/stationery_sheet_configs.dart';
import '../models/typography_settings.dart';
import '../services/audio_sanctum_service.dart';
import '../services/editor_pagination_coordinator.dart';
import '../services/editor_settings_service.dart';
import '../widgets/scholar_chest/scholar_chest_drawer.dart';

/// Binds one entry editor to the Scholar's Stationery Chest: owns the
/// editor's [InkChoreographyController] (restored from the app-wide settings
/// on construction) and opens the drawer, persisting template and seal
/// changes to the entry before reporting them back to the screen.
class EditorScholarChestBinding {
  final AppDatabase database;
  final String entryId;
  final AudioSanctumService audioSanctumService;

  /// The editor's live Ink Choreography preferences, shared by the drawer
  /// and the Stationery Sheet overlay.
  final InkChoreographyController inkChoreography;

  EditorScholarChestBinding({
    required this.database,
    required this.entryId,
    required this.audioSanctumService,
    required EditorSettingsService settings,
  }) : inkChoreography = InkChoreographyController(settings: settings) {
    inkChoreography.restorePreferences();
  }

  /// Opens the drawer over [context], dressed in [coordinator]'s live paper
  /// and typography. [onTemplateChanged] runs before the entry's template is
  /// persisted; [onUnlockAtChanged] after its seal is.
  Future<void> open(
    BuildContext context, {
    required Template template,
    required EditorPaginationCoordinator coordinator,
    required DateTime? unlockAt,
    required bool isCenterAligned,
    required ScholarArtifactType initialArtifact,
    required ValueChanged<Template> onTemplateChanged,
    required ValueChanged<TypographySettings> onTypographyChanged,
    required ValueChanged<DateTime?> onUnlockAtChanged,
    required VoidCallback onToggleAlignment,
  }) {
    final sheetTheme = StationerySheetThemeConfig.fromTemplateStyle(
      templateStyle: coordinator.templateStyle,
      typography: coordinator.typography,
    );
    final activeSheetIndex = coordinator.activeSheetIndex;
    final sheets = coordinator.sheets;
    return ScholarChestDrawer.show(
      context: context,
      database: database,
      activeTemplateId: template.id,
      typography: sheetTheme.typography,
      audioSanctumService: audioSanctumService,
      inkChoreography: inkChoreography,
      trialInk: TrialInkStyle.of(sheetTheme),
      unlockAt: unlockAt,
      isCenterAligned: isCenterAligned,
      isEphemeraSheetActive: activeSheetIndex < sheets.length && sheets[activeSheetIndex] is EphemeraSheet,
      initialArtifact: initialArtifact,
      onSelectTemplate: (newTemplate) async {
        onTemplateChanged(newTemplate);
        final newTheme = StationerySheetThemeConfig.fromTemplate(newTemplate);
        coordinator.updateTypography(newTheme.typography, newTemplateStyle: newTheme.templateStyle);
        await database.entriesDao.updateEntryTemplate(entryId, newTemplate.id);
      },
      onTypographyChanged: (newTypography) {
        onTypographyChanged(newTypography);
        coordinator.updateTypography(newTypography);
      },
      onLockChanged: (newUnlockAt) async {
        await database.entriesDao.updateEntryUnlockAt(entryId, newUnlockAt);
        onUnlockAtChanged(newUnlockAt);
      },
      onToggleAlignment: onToggleAlignment,
    );
  }

  void dispose() => inkChoreography.dispose();
}
