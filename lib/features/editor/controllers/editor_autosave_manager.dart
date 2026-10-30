import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../core/database/app_database.dart';

enum AutosaveStatus { saved, saving, unsaved }

/// Manages background autosave of entry title, Quill Delta, and plain text to SQLite
/// with debounced (2s) and periodic (≤10s) timers.
class EditorAutosaveManager {
  final AppDatabase database;
  final String entryId;
  final QuillController controller;
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
    required this.controller,
    this.titleController,
    this.debounceDuration = const Duration(seconds: 2),
    this.periodicDuration = const Duration(seconds: 8),
  }) {
    _init();
  }

  void _init() {
    titleController?.addListener(_handleTitleChange);

    _docSub = controller.document.changes.listen((change) {
      _isDirty = true;
      statusNotifier.value = AutosaveStatus.unsaved;

      // Debounce timer
      _debounceTimer?.cancel();
      _debounceTimer = Timer(debounceDuration, () {
        if (_isDirty) {
          saveDraft();
        }
      });
    });

    // Periodic safety timer
    _periodicTimer = Timer.periodic(periodicDuration, (timer) {
      if (_isDirty) {
        saveDraft();
      }
    });
  }

  void _handleTitleChange() {
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
      final deltaJson = jsonEncode(controller.document.toDelta().toJson());
      final plainText = controller.document.toPlainText().trim();
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
    statusNotifier.dispose();
  }
}

