import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../domain/stationery_sheet_descriptor.dart';
import '../services/editor_pagination_coordinator.dart';
import 'editor_autosave_manager.dart';

/// Viewport and focus adapter for the paginated Stationery Sheet stage,
/// reacting to [EditorPaginationCoordinator] transitions and user page turns.
class EditorPaginationHandler {
  final EditorPaginationCoordinator coordinator;
  final PageController pageController;
  final EditorAutosaveManager autosaveManager;
  final VoidCallback onStateChanged;

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
    coordinator.addListener(_handleCoordinatorNotification);
    coordinator.onAutoSpill = _handleAutoSpillResult;
    coordinator.onSpillBack = _handleSpillBackResult;
  }

  void _handleAutoSpillResult(AutoSpillResult spillResult) {
    if (!spillResult.caretFollowsOverflow) {
      // Only text after the caret moved on: keep writing where the caret is.
      autosaveManager.markDirty();
      onStateChanged();
      return;
    }
    currentSheetIndex = spillResult.destinationSheetIndex;
    coordinator.activeSheetIndex = spillResult.destinationSheetIndex;
    autosaveManager.markDirty();
    onStateChanged();
    _animateAndFocusSheet(
      spillResult.destinationSheetIndex,
      spillResult.destinationCaretOffset,
    );
  }

  void _animateAndFocusSheet(int sheetIndex, int caretOffset) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients) {
        pageController.animateToPage(
          sheetIndex,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      if (sheetIndex < coordinator.sheets.length) {
        final destSheet = coordinator.sheets[sheetIndex];
        if (destSheet is TextStationerySheet) {
          destSheet.focusNode.requestFocus();
          destSheet.controller.updateSelection(
            TextSelection.collapsed(offset: caretOffset),
            ChangeSource.local,
          );
        }
      }
    });
  }

  void _handleCoordinatorNotification() {
    final clampedIndex = coordinator.activeSheetIndex
        .clamp(0, math.max(0, coordinator.totalSheets - 1))
        .toInt();
    if (currentSheetIndex != clampedIndex) {
      currentSheetIndex = clampedIndex;
    }
    onStateChanged();
  }

  QuillController get activeTextController {
    if (currentSheetIndex < coordinator.sheets.length) {
      final activeSheet = coordinator.sheets[currentSheetIndex];
      if (activeSheet is TextStationerySheet) {
        return activeSheet.controller;
      }
    }
    for (int index = currentSheetIndex + 1; index < coordinator.sheets.length; index++) {
      final sheet = coordinator.sheets[index];
      if (sheet is TextStationerySheet) {
        return sheet.controller;
      }
    }
    for (int index = currentSheetIndex - 1; index >= 0; index--) {
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
    goToSheet(nextTextSheet.sheetIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nextTextSheet.focusNode.requestFocus();
    });
    return nextTextSheet.controller;
  }

  /// Whether the diarist is writing on some sheet (its editor holds focus), so
  /// a page turn should carry the caret, and the open keyboard, along.
  bool get _isWriting => coordinator.sheets
      .any((sheet) => sheet is TextStationerySheet && sheet.focusNode.hasFocus);

  /// Hands focus to [sheet] when the diarist was writing. The focus moves in one
  /// step, so the keyboard stays open; browsing with it closed keeps it closed.
  void _carryFocusTo(StationerySheetDescriptor sheet) {
    if (sheet is TextStationerySheet && _isWriting && !sheet.focusNode.hasFocus) {
      sheet.focusNode.requestFocus();
    }
  }

  void goToSheet(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= coordinator.totalSheets) return;
    coordinator.activeSheetIndex = targetIndex;
    currentSheetIndex = targetIndex;
    _carryFocusTo(coordinator.sheets[targetIndex]);
    coordinator.collapseEmptyContinuationSheets();
    onStateChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients) {
        pageController.animateToPage(
          targetIndex.clamp(0, math.max(0, coordinator.totalSheets - 1)),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void handlePageChanged(int newPageIndex) {
    coordinator.activeSheetIndex = newPageIndex;
    if (currentSheetIndex != newPageIndex) {
      currentSheetIndex = newPageIndex;
      _carryFocusTo(coordinator.sheets[newPageIndex.clamp(0, coordinator.sheets.length - 1)]);
      coordinator.collapseEmptyContinuationSheets();
      onStateChanged();
    }
  }

  void _handleSpillBackResult(SpillBackResult spillBackResult) {
    currentSheetIndex = spillBackResult.destinationSheetIndex;
    coordinator.activeSheetIndex = spillBackResult.destinationSheetIndex;
    autosaveManager.saveDraft();
    onStateChanged();
    _animateAndFocusSheet(
      spillBackResult.destinationSheetIndex,
      spillBackResult.destinationCaretOffset,
    );
  }

  Future<void> handleDeleteEphemera(int sheetIndex) async {
    if (sheetIndex < 0 || sheetIndex >= coordinator.sheets.length) return;
    final targetSheet = coordinator.sheets[sheetIndex];
    final deletedRelativePath =
        targetSheet is EphemeraSheet ? targetSheet.sandboxedRelativePath : null;

    coordinator.removeEphemeraSheet(sheetIndex);

    final targetIndex = coordinator.activeSheetIndex
        .clamp(0, math.max(0, coordinator.totalSheets - 1))
        .toInt();
    currentSheetIndex = targetIndex;
    onStateChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients) {
        pageController.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });

    if (deletedRelativePath != null && deletedRelativePath.isNotEmpty) {
      await autosaveManager.database.deleteMediaForEntryByPath(
        entryId: autosaveManager.entryId,
        relativePath: deletedRelativePath,
      );
    }
    await autosaveManager.saveDraft(force: true);
  }

  void dispose() {
    coordinator.removeListener(_handleCoordinatorNotification);
    if (identical(coordinator.onAutoSpill, _handleAutoSpillResult)) {
      coordinator.onAutoSpill = null;
    }
    if (identical(coordinator.onSpillBack, _handleSpillBackResult)) {
      coordinator.onSpillBack = null;
    }
  }
}
