import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../core/database/app_database.dart';
import '../services/editor_pagination_coordinator.dart';

enum AutosaveStatus { saved, saving, unsaved }

/// Manages background autosave of entry title, Quill Delta, and plain text to SQLite
/// with debounced (2s) and periodic (≤10s) timers.
class EditorAutosaveManager {
  final AppDatabase database;
  final String entryId;
  final QuillController? controller;
  final EditorPaginationCoordinator? coordinator;
  final TextEditingController? titleController;
  final Duration debounceDuration;
  final Duration periodicDuration;

  Timer? _debounceTimer;
  Timer? _periodicTimer;
  StreamSubscription? _docSub;
  bool _isDirty = false;

  final ValueNotifier<AutosaveStatus> statusNotifier =
      ValueNotifier<AutosaveStatus>(AutosaveStatus.saved);

  EditorAutosaveManager({
    required this.database,
    required this.entryId,
    this.controller,
    this.coordinator,
    this.titleController,
    this.debounceDuration = const Duration(seconds: 2),
    this.periodicDuration = const Duration(seconds: 8),
  }) {
    _init();
  }

  void _init() {
    titleController?.addListener(_handleTitleChange);

    if (controller != null) {
      _docSub = controller!.document.changes.listen((change) {
        _scheduleDebounce();
      });
    }

    if (coordinator != null) {
      coordinator!.addListener(_handleCoordinatorChange);
    }

    // Periodic safety timer
    _periodicTimer = Timer.periodic(periodicDuration, (timer) {
      if (_isDirty) {
        saveDraft();
      }
    });
  }

  void _handleTitleChange() {
    _scheduleDebounce();
  }

  void _handleCoordinatorChange() {
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

  /// Immediately serializes title, Delta JSON, and plain text, then saves to database
  Future<void> saveDraft({bool force = false}) async {
    if (!_isDirty && !force) return;

    _debounceTimer?.cancel();
    statusNotifier.value = AutosaveStatus.saving;

    try {
      final String deltaJson;
      final String plainText;

      if (coordinator != null) {
        final synthesized = coordinator!.reSynthesize();
        deltaJson = synthesized.$1;
        plainText = synthesized.$2;
      } else if (controller != null) {
        deltaJson = jsonEncode(controller!.document.toDelta().toJson());
        plainText = controller!.document.toPlainText().trim();
      } else {
        statusNotifier.value = AutosaveStatus.saved;
        return;
      }

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
    _docSub?.cancel();
    titleController?.removeListener(_handleTitleChange);
    coordinator?.removeListener(_handleCoordinatorChange);
    statusNotifier.dispose();
  }
}

