import 'dart:async';
import 'dart:math' as math;
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

  final List<StreamSubscription<DocChange>> _subscriptions =
      <StreamSubscription<DocChange>>[];
  final List<VoidCallback> _listenerRemovers = <VoidCallback>[];
  bool _isMutatingSheets = false;
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

  void _handleCoordinatorNotification() {
    if (_isMutatingSheets) return;
    attachSheetListeners();
    final clampedIndex = coordinator.activeSheetIndex
        .clamp(0, math.max(0, coordinator.totalSheets - 1))
        .toInt();
    if (currentSheetIndex != clampedIndex) {
      currentSheetIndex = clampedIndex;
    }
    onStateChanged();
  }

  void attachSheetListeners() {
    _clearAttachedListeners();

    for (final sheet in coordinator.sheets) {
      if (sheet is TextStationerySheet) {
        Document boundDocument = sheet.controller.document;
        StreamSubscription<DocChange> docSub =
            boundDocument.changes.listen((docChange) {
          _onSheetDocumentChanged(sheet);
        });
        _subscriptions.add(docSub);

        void onControllerNotified() {
          if (!identical(sheet.controller.document, boundDocument)) {
            _subscriptions.remove(docSub);
            docSub.cancel();
            boundDocument = sheet.controller.document;
            docSub = boundDocument.changes.listen((docChange) {
              _onSheetDocumentChanged(sheet);
            });
            _subscriptions.add(docSub);
            return;
          }
          if (_isMutatingSheets) return;
          if (!sheet.controller.plainTextEditingValue.composing.isCollapsed) {
            return;
          }
          if (!coordinator.isSheetComposing(sheet.sheetIndex)) {
            _runGuardedMutation(() {
              coordinator.checkAndPerformAutoSpill(sheet.sheetIndex);
            });
          }
        }

        sheet.controller.addListener(onControllerNotified);
        _listenerRemovers.add(() {
          sheet.controller.removeListener(onControllerNotified);
        });
      } else if (sheet is EphemeraSheet) {
        void onCaptionNotified() {
          autosaveManager.markDirty();
        }

        sheet.captionController.addListener(onCaptionNotified);
        _listenerRemovers.add(() {
          sheet.captionController.removeListener(onCaptionNotified);
        });
      }
    }
  }

  void _onSheetDocumentChanged(TextStationerySheet sheet) {
    if (_isMutatingSheets) return;
    autosaveManager.markDirty();
    if (coordinator.isSheetComposing(sheet.sheetIndex)) return;

    final liveIndex = coordinator.sheets.indexOf(sheet);
    if (liveIndex < 0) return;

    if (liveIndex > 0 && sheet.isEmpty) {
      _runGuardedMutation(() {
        final didCollapse = coordinator.collapseEmptyContinuationSheets();
        if (didCollapse) {
          attachSheetListeners();
          final targetIndex = coordinator.activeSheetIndex
              .clamp(0, math.max(0, coordinator.totalSheets - 1))
              .toInt();
          currentSheetIndex = targetIndex;
          final activeSheet = coordinator.sheets[targetIndex];
          if (activeSheet is TextStationerySheet) {
            activeSheet.focusNode.requestFocus();
            final endOffset = math.max(0, activeSheet.document.length - 1);
            activeSheet.controller.updateSelection(
              TextSelection.collapsed(offset: endOffset),
              ChangeSource.local,
            );
          }
          if (pageController.hasClients) {
            pageController.animateToPage(
              targetIndex,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            );
          }
          onStateChanged();
        }
      });
      return;
    }

    _runGuardedMutation(() {
      coordinator.checkAndPerformAutoSpill(liveIndex);
    });
  }

  void _runGuardedMutation(VoidCallback action) {
    if (_isMutatingSheets) return;
    _isMutatingSheets = true;
    try {
      action();
    } finally {
      _isMutatingSheets = false;
    }
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
    late final TextStationerySheet nextTextSheet;
    _runGuardedMutation(() {
      nextTextSheet = coordinator.getOrCreateFollowingTextSheet(currentSheetIndex);
    });
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
    SpillBackResult? result;
    _runGuardedMutation(() {
      result = coordinator.handleSpillBack(sheetIndex);
    });
    if (result != null) {
      final spillBackResult = result!;
      attachSheetListeners();
      if (pageController.hasClients) {
        pageController.animateToPage(
          spillBackResult.destinationSheetIndex,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      final destSheet = coordinator.sheets[spillBackResult.destinationSheetIndex];
      if (destSheet is TextStationerySheet) {
        destSheet.focusNode.requestFocus();
        destSheet.controller.updateSelection(
          TextSelection.collapsed(offset: spillBackResult.destinationCaretOffset),
          ChangeSource.local,
        );
      }
      autosaveManager.saveDraft();
      currentSheetIndex = spillBackResult.destinationSheetIndex;
      onStateChanged();
    }
  }

  Future<void> handleDeleteEphemera(int sheetIndex) async {
    if (sheetIndex < 0 || sheetIndex >= coordinator.sheets.length) return;
    final targetSheet = coordinator.sheets[sheetIndex];
    final deletedRelativePath =
        targetSheet is EphemeraSheet ? targetSheet.sandboxedRelativePath : null;

    _runGuardedMutation(() {
      coordinator.removeEphemeraSheet(sheetIndex);
    });
    attachSheetListeners();

    final targetIndex = coordinator.activeSheetIndex
        .clamp(0, math.max(0, coordinator.totalSheets - 1))
        .toInt();
    currentSheetIndex = targetIndex;
    onStateChanged();
    if (pageController.hasClients) {
      pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }

    if (deletedRelativePath != null && deletedRelativePath.isNotEmpty) {
      await autosaveManager.database.deleteMediaForEntryByPath(
        entryId: autosaveManager.entryId,
        relativePath: deletedRelativePath,
      );
    }
    await autosaveManager.saveDraft(force: true);
  }

  void _clearAttachedListeners() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    for (final remover in _listenerRemovers) {
      remover();
    }
    _listenerRemovers.clear();
  }

  void dispose() {
    coordinator.removeListener(_handleCoordinatorNotification);
    _clearAttachedListeners();
  }
}
