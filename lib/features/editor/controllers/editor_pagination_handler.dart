import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../domain/stationery_sheet_descriptor.dart';
import '../services/editor_pagination_coordinator.dart';
import 'editor_autosave_manager.dart';

/// Manages active page navigation, listener binding, auto-spill orchestration,
/// and spill-back handling for the paginated Stationery Sheet stage.
class EditorPaginationHandler {
  final EditorPaginationCoordinator coordinator;
  final PageController pageController;
  final EditorAutosaveManager autosaveManager;
  final VoidCallback onStateChanged;

  final List<StreamSubscription> _subscriptions = <StreamSubscription>[];
  int currentSheetIndex = 0;

  EditorPaginationHandler({
    required this.coordinator,
    required this.pageController,
    required this.autosaveManager,
    required this.onStateChanged,
  }) {
    _init();
  }

  void _init() {
    coordinator.onAutoSpill = (spillResult) {
      attachSheetListeners();
      if (pageController.hasClients) {
        pageController.animateToPage(
          spillResult.destinationSheetIndex,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      final destSheet = coordinator.sheets[spillResult.destinationSheetIndex];
      if (destSheet is TextStationerySheet) {
        destSheet.focusNode.requestFocus();
        destSheet.controller.updateSelection(
          TextSelection.collapsed(offset: spillResult.destinationCaretOffset),
          ChangeSource.local,
        );
      }
      autosaveManager.markDirty();
      currentSheetIndex = spillResult.destinationSheetIndex;
      onStateChanged();
    };

    attachSheetListeners();
  }

  void attachSheetListeners() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    for (final sheet in coordinator.sheets) {
      if (sheet is TextStationerySheet) {
        final docSub = sheet.controller.document.changes.listen((docChange) {
          autosaveManager.markDirty();
          if (!coordinator.isSheetComposing(sheet.sheetIndex)) {
            coordinator.checkAndPerformAutoSpill(sheet.sheetIndex);
          }
        });
        _subscriptions.add(docSub);

        sheet.controller.addListener(() {
          if (!sheet.controller.plainTextEditingValue.composing.isCollapsed) return;
          if (!coordinator.isSheetComposing(sheet.sheetIndex)) {
            coordinator.checkAndPerformAutoSpill(sheet.sheetIndex);
          }
        });
      } else if (sheet is EphemeraSheet) {
        sheet.captionController.addListener(() {
          autosaveManager.markDirty();
        });
      }
    }
  }

  QuillController get activeTextController {
    if (currentSheetIndex < coordinator.sheets.length) {
      final activeSheet = coordinator.sheets[currentSheetIndex];
      if (activeSheet is TextStationerySheet) {
        return activeSheet.controller;
      }
    }
    for (int index = currentSheetIndex - 1; index >= 0; index--) {
      final sheet = coordinator.sheets[index];
      if (sheet is TextStationerySheet) {
        return sheet.controller;
      }
    }
    for (int index = currentSheetIndex + 1; index < coordinator.sheets.length; index++) {
      final sheet = coordinator.sheets[index];
      if (sheet is TextStationerySheet) {
        return sheet.controller;
      }
    }
    return QuillController.basic();
  }

  QuillController ensureActiveTextSheet() {
    if (currentSheetIndex < coordinator.sheets.length) {
      final activeSheet = coordinator.sheets[currentSheetIndex];
      if (activeSheet is TextStationerySheet) {
        return activeSheet.controller;
      }
    }
    final nextTextSheet = coordinator.getOrCreateFollowingTextSheet(currentSheetIndex);
    attachSheetListeners();
    goToSheet(nextTextSheet.sheetIndex);
    nextTextSheet.focusNode.requestFocus();
    return nextTextSheet.controller;
  }

  void goToSheet(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= coordinator.totalSheets) return;
    coordinator.activeSheetIndex = targetIndex;
    currentSheetIndex = targetIndex;
    onStateChanged();
    if (pageController.hasClients) {
      pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void handlePageChanged(int newPageIndex) {
    coordinator.activeSheetIndex = newPageIndex;
    if (currentSheetIndex != newPageIndex) {
      currentSheetIndex = newPageIndex;
      onStateChanged();
    }
  }

  void handleSpillBack(int sheetIndex) {
    final result = coordinator.handleSpillBack(sheetIndex);
    if (result != null) {
      attachSheetListeners();
      if (pageController.hasClients) {
        pageController.animateToPage(
          result.destinationSheetIndex,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      final destSheet = coordinator.sheets[result.destinationSheetIndex];
      if (destSheet is TextStationerySheet) {
        destSheet.focusNode.requestFocus();
        destSheet.controller.updateSelection(
          TextSelection.collapsed(offset: result.destinationCaretOffset),
          ChangeSource.local,
        );
      }
      autosaveManager.saveDraft();
      currentSheetIndex = result.destinationSheetIndex;
      onStateChanged();
    }
  }

  void handleDeleteEphemera(int sheetIndex) {
    coordinator.removeEphemeraSheet(sheetIndex);
    attachSheetListeners();
    final targetIndex = coordinator.activeSheetIndex.clamp(0, coordinator.totalSheets - 1);
    currentSheetIndex = targetIndex;
    onStateChanged();
    if (pageController.hasClients) {
      pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    autosaveManager.saveDraft();
  }

  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}
