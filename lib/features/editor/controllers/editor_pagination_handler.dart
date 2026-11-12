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
      if (!spillResult.caretFollowsOverflow) {
        // Only text after the caret moved on: keep writing where the caret is.
        attachSheetListeners();
        autosaveManager.markDirty();
        onStateChanged();
        return;
      }
      currentSheetIndex = spillResult.destinationSheetIndex;
      coordinator.activeSheetIndex = spillResult.destinationSheetIndex;
      attachSheetListeners();
      autosaveManager.markDirty();
      onStateChanged();

      WidgetsBinding.instance.addPostFrameCallback((_) {
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
      });
    };
    coordinator.onSpillBack = _handleSpillBackResult;

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
          _onSheetDocumentChanged(sheet, docChange);
        });
        _subscriptions.add(docSub);

        void onControllerNotified() {
          if (!identical(sheet.controller.document, boundDocument)) {
            _subscriptions.remove(docSub);
            docSub.cancel();
            boundDocument = sheet.controller.document;
            docSub = boundDocument.changes.listen((docChange) {
              _onSheetDocumentChanged(sheet, docChange);
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

  void _onSheetDocumentChanged(TextStationerySheet sheet, DocChange docChange) {
    if (_isMutatingSheets) return;
    autosaveManager.markDirty();
    if (coordinator.isSheetComposing(sheet.sheetIndex)) return;

    final liveIndex = coordinator.sheets.indexOf(sheet);
    if (liveIndex < 0) return;

    final hasDeletions = docChange.change.operations.any((op) => op.isDelete);
    if (liveIndex > 0 && sheet.isEmpty && hasDeletions) {
      _runGuardedMutation(() {
        final didCollapse = coordinator.collapseEmptyContinuationSheets(allowActive: true);
        if (didCollapse) {
          attachSheetListeners();
          final targetIndex = coordinator.activeSheetIndex
              .clamp(0, math.max(0, coordinator.totalSheets - 1))
              .toInt();
          currentSheetIndex = targetIndex;
          onStateChanged();
          WidgetsBinding.instance.addPostFrameCallback((_) {
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
          });
        }
      });
      return;
    }

    _runGuardedMutation(() {
      coordinator.checkAndPerformAutoSpill(liveIndex);
    });
    // Mounted items follow their markers: a deleted passage unmounts its item,
    // an undo remounts it, and reflow cascades or unmounts extras. Run outside
    // the guard so a changed mount notifies the stage to rebuild.
    if (!_isMutatingSheets) coordinator.reflowMounts();
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
    _runGuardedMutation(() {
      final didCollapse = coordinator.collapseEmptyContinuationSheets();
      if (didCollapse) {
        attachSheetListeners();
      }
    });
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
      _runGuardedMutation(() {
        final didCollapse = coordinator.collapseEmptyContinuationSheets();
        if (didCollapse) {
          attachSheetListeners();
        }
      });
      onStateChanged();
    }
  }

  void handleSpillBack(int sheetIndex) {
    _runGuardedMutation(() {
      coordinator.handleSpillBack(sheetIndex);
    });
  }

  void _handleSpillBackResult(SpillBackResult spillBackResult) {
    currentSheetIndex = spillBackResult.destinationSheetIndex;
    coordinator.activeSheetIndex = spillBackResult.destinationSheetIndex;
    attachSheetListeners();
    autosaveManager.saveDraft();
    onStateChanged();

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });
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
