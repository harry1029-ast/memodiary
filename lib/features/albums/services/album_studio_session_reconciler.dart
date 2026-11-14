import 'package:flutter/foundation.dart';
import '../../../core/database/app_database.dart';
import '../models/album_studio_models.dart';

/// Immutable result of reconciling live SQLite photos against the open
/// [AlbumStudioDocument] and its Undo/Redo history stacks.
class AlbumStudioReconcileResult {
  final List<AlbumPhoto> photos;
  final Map<String, AlbumPhoto> photoById;
  final AlbumStudioDocument document;
  final List<AlbumStudioDocument> undoStack;
  final List<AlbumStudioDocument> redoStack;
  final bool photosChanged;
  final bool docChanged;
  final bool historyChanged;

  const AlbumStudioReconcileResult({
    required this.photos,
    required this.photoById,
    required this.document,
    required this.undoStack,
    required this.redoStack,
    required this.photosChanged,
    required this.docChanged,
    required this.historyChanged,
  });

  bool get hasChanges => photosChanged || docChanged || historyChanged;
}

/// Bounded Undo/Redo history stack for [AlbumStudioController].
class AlbumStudioHistory {
  final int maxSteps;
  final List<AlbumStudioDocument> _undoStack = [];
  final List<AlbumStudioDocument> _redoStack = [];

  AlbumStudioHistory({this.maxSteps = 50});

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;
  List<AlbumStudioDocument> get undoStack => List.unmodifiable(_undoStack);
  List<AlbumStudioDocument> get redoStack => List.unmodifiable(_redoStack);

  void push(AlbumStudioDocument previous) {
    _undoStack.add(previous);
    if (_undoStack.length > maxSteps) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  AlbumStudioDocument? undo(AlbumStudioDocument current) {
    if (!canUndo) return null;
    final previous = _undoStack.removeLast();
    _redoStack.add(current);
    if (_redoStack.length > maxSteps) _redoStack.removeAt(0);
    return previous;
  }

  AlbumStudioDocument? redo(AlbumStudioDocument current) {
    if (!canRedo) return null;
    final next = _redoStack.removeLast();
    _undoStack.add(current);
    if (_undoStack.length > maxSteps) _undoStack.removeAt(0);
    return next;
  }

  void replace(
    List<AlbumStudioDocument> undoSnapshots,
    List<AlbumStudioDocument> redoSnapshots,
  ) {
    _undoStack
      ..clear()
      ..addAll(undoSnapshots);
    _redoStack
      ..clear()
      ..addAll(redoSnapshots);
  }
}

/// Pure reconciliation helpers for [AlbumStudioController] live sessions and
/// Undo/Redo history stacks.
abstract final class AlbumStudioSessionReconciler {
  /// Builds an unmodifiable lookup map of [AlbumPhoto] keyed by `photo.id`.
  static Map<String, AlbumPhoto> buildPhotoLookup(List<AlbumPhoto> photos) {
    return Map<String, AlbumPhoto>.unmodifiable({
      for (final photo in photos) photo.id: photo,
    });
  }

  /// Reconciles every snapshot in [stack] against [photoIds], collapsing adjacent
  /// duplicates and trailing snapshots equal to [currentDoc].
  static List<AlbumStudioDocument> reconcileHistoryStack(
    List<AlbumStudioDocument> stack,
    List<String> photoIds,
    AlbumStudioDocument currentDoc,
  ) {
    final reconciled = <AlbumStudioDocument>[];
    for (final snapshot in stack) {
      final updated = snapshot.reconcileWithPhotoIds(photoIds);
      if (reconciled.isEmpty || reconciled.last != updated) {
        reconciled.add(updated);
      }
    }
    while (reconciled.isNotEmpty && reconciled.last == currentDoc) {
      reconciled.removeLast();
    }
    return reconciled;
  }

  /// Reconciles [currentDocument] and [history] against an updated [nextPhotos]
  /// emission from SQLite.
  static AlbumStudioReconcileResult reconcileSessionPhotos({
    required List<AlbumPhoto> currentPhotos,
    required Map<String, AlbumPhoto> currentPhotoById,
    required AlbumStudioDocument currentDocument,
    required AlbumStudioHistory history,
    required List<AlbumPhoto> nextPhotos,
  }) {
    final photosChanged = !listEquals(currentPhotos, nextPhotos);
    final resolvedPhotos = photosChanged
        ? List<AlbumPhoto>.unmodifiable(nextPhotos)
        : currentPhotos;
    final resolvedPhotoById =
        photosChanged ? buildPhotoLookup(resolvedPhotos) : currentPhotoById;

    final photoIds =
        nextPhotos.map((photo) => photo.id).toList(growable: false);
    final reconciledDoc = currentDocument.reconcileWithPhotoIds(photoIds);
    final docChanged = reconciledDoc != currentDocument;
    final prevUndo = history.undoStack;
    final prevRedo = history.redoStack;
    final reconciledUndo =
        reconcileHistoryStack(prevUndo, photoIds, reconciledDoc);
    final reconciledRedo =
        reconcileHistoryStack(prevRedo, photoIds, reconciledDoc);
    final historyChanged = !listEquals(prevUndo, reconciledUndo) ||
        !listEquals(prevRedo, reconciledRedo);

    return AlbumStudioReconcileResult(
      photos: resolvedPhotos,
      photoById: resolvedPhotoById,
      document: reconciledDoc,
      undoStack: reconciledUndo,
      redoStack: reconciledRedo,
      photosChanged: photosChanged,
      docChanged: docChanged,
      historyChanged: historyChanged,
    );
  }
}
