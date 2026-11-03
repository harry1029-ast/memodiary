import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../core/database/app_database.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../services/editor_pagination_coordinator.dart';

enum AutosaveStatus { saved, saving, unsaved }

/// Manages background autosave of entry title, unified Quill Delta, and plain text to SQLite
/// with debounced (2s) and periodic (≤10s) timers.
class EditorAutosaveManager {
  final AppDatabase database;
  final String entryId;
  final EditorPaginationCoordinator coordinator;
  final TextEditingController? titleController;
  final Duration debounceDuration;
  final Duration periodicDuration;

  Timer? _debounceTimer;
  Timer? _periodicTimer;
  final List<StreamSubscription<DocChange>> _sheetDocSubscriptions =
      <StreamSubscription<DocChange>>[];
  final List<VoidCallback> _sheetListenerRemovers = <VoidCallback>[];
  bool _isDirty = false;

  final ValueNotifier<AutosaveStatus> statusNotifier =
      ValueNotifier<AutosaveStatus>(AutosaveStatus.saved);

  EditorAutosaveManager({
    required this.database,
    required this.entryId,
    required this.coordinator,
    this.titleController,
    this.debounceDuration = const Duration(seconds: 2),
    this.periodicDuration = const Duration(seconds: 8),
  }) {
    _init();
  }

  void _init() {
    titleController?.addListener(_handleTitleChange);
    coordinator.contentRevision.addListener(_handleContentRevisionChange);
    coordinator.addListener(_rebindSheetListeners);
    _rebindSheetListeners();

    _periodicTimer = Timer.periodic(periodicDuration, (timer) {
      if (_isDirty) {
        saveDraft();
      }
    });
  }

  void _rebindSheetListeners() {
    _clearSheetListeners();

    for (final sheet in coordinator.sheets) {
      if (sheet is TextStationerySheet) {
        Document boundDocument = sheet.controller.document;
        StreamSubscription<DocChange> activeDocSub =
            boundDocument.changes.listen((docChange) {
          _scheduleDebounce();
        });
        _sheetDocSubscriptions.add(activeDocSub);

        void handleControllerNotification() {
          if (!identical(sheet.controller.document, boundDocument)) {
            _sheetDocSubscriptions.remove(activeDocSub);
            activeDocSub.cancel();
            boundDocument = sheet.controller.document;
            activeDocSub = boundDocument.changes.listen((docChange) {
              _scheduleDebounce();
            });
            _sheetDocSubscriptions.add(activeDocSub);
          }
        }

        sheet.controller.addListener(handleControllerNotification);
        _sheetListenerRemovers.add(() {
          sheet.controller.removeListener(handleControllerNotification);
        });
      } else if (sheet is EphemeraSheet) {
        String lastCaption = sheet.captionController.text;
        void handleCaptionNotification() {
          if (sheet.captionController.text != lastCaption) {
            lastCaption = sheet.captionController.text;
            _scheduleDebounce();
          }
        }

        sheet.captionController.addListener(handleCaptionNotification);
        _sheetListenerRemovers.add(() {
          sheet.captionController.removeListener(handleCaptionNotification);
        });
      }
    }
  }

  void _clearSheetListeners() {
    for (final subscription in _sheetDocSubscriptions) {
      subscription.cancel();
    }
    _sheetDocSubscriptions.clear();

    for (final remover in _sheetListenerRemovers) {
      remover();
    }
    _sheetListenerRemovers.clear();
  }

  void _handleTitleChange() {
    _scheduleDebounce();
  }

  void _handleContentRevisionChange() {
    _scheduleDebounce();
  }

  /// Explicitly marks the autosave manager dirty, scheduling a debounced save.
  void markDirty() {
    _scheduleDebounce();
  }

  void _scheduleDebounce() {
    _isDirty = true;
    statusNotifier.value = AutosaveStatus.unsaved;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      if (_isDirty) {
        saveDraft();
      }
    });
  }

  /// Immediately serializes title, unified Delta JSON, and plain text, then saves to database.
  Future<void> saveDraft({bool force = false}) async {
    if (!_isDirty && !force) return;

    _debounceTimer?.cancel();
    statusNotifier.value = AutosaveStatus.saving;

    try {
      final (deltaJson, plainText) = coordinator.reSynthesize();
      final titleText = titleController?.text.trim();

      await database.transaction(() async {
        if (titleText != null) {
          await database.updateEntryMetadata(entryId, title: titleText);
        }
        await database.updateEntryContent(
          entryId,
          deltaJson,
          plainText,
        );
      });

      _isDirty = false;
      statusNotifier.value = AutosaveStatus.saved;
    } catch (_) {
      statusNotifier.value = AutosaveStatus.unsaved;
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    _periodicTimer?.cancel();
    _clearSheetListeners();
    titleController?.removeListener(_handleTitleChange);
    coordinator.contentRevision.removeListener(_handleContentRevisionChange);
    coordinator.removeListener(_rebindSheetListeners);
    statusNotifier.dispose();
  }
}
