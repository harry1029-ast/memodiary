import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:uuid/uuid.dart';

import '../../../core/database/daos/media_ocr_dao.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../services/editor_pagination_coordinator.dart';
import 'brush_reveal_queue.dart';
import 'editor_autosave_manager.dart';

/// Immutable outcome of a headless image or video Collect operation.
@immutable
class MediaCollectResult {
  final int collectedCount;
  final int rejectedByCapacity;

  const MediaCollectResult({
    required this.collectedCount,
    required this.rejectedByCapacity,
  });

  bool get isEmpty => collectedCount == 0 && rejectedByCapacity == 0;
  bool get hasRejected => rejectedByCapacity > 0;
  bool get wasFull => collectedCount == 0 && rejectedByCapacity > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaCollectResult &&
          runtimeType == other.runtimeType &&
          collectedCount == other.collectedCount &&
          rejectedByCapacity == other.rejectedByCapacity;

  @override
  int get hashCode => Object.hash(collectedCount, rejectedByCapacity);

  @override
  String toString() =>
      'MediaCollectResult(collectedCount: $collectedCount, rejectedByCapacity: $rejectedByCapacity)';
}

/// UI-free media lifecycle controller binding Collect, Mount, Unmount,
/// timed Erase-with-Undo, and Caption updates over [MediaOcrDao] and
/// [MediaSandboxService].
class EditorMediaBinding {
  final MediaOcrDao mediaOcrDao;
  final MediaSandboxService mediaSandboxService;
  final String entryId;
  final EditorPaginationCoordinator coordinator;
  final EditorAutosaveManager autosaveManager;

  /// Requests a rebuild of the hosting screen (only invoked while mounted).
  final VoidCallback onStateChanged;

  final Uuid _uuid;

  /// How long an erased item can be restored before it is purged.
  static const Duration kEraseUndoWindow = Duration(seconds: 4);

  /// Ticks each time a mount is refused because the active sheet is full, so
  /// its Tucked Prints can shake.
  final ValueNotifier<int> mountRefusals = ValueNotifier<int>(0);

  /// Items collected in this session awaiting their one-time Brush Reveal.
  final BrushRevealQueue brushReveals = BrushRevealQueue();

  /// Erased items still inside their undo window, by attachment id.
  final Map<String, SheetMediaItem> _pendingErasures = <String, SheetMediaItem>{};

  /// Active per-attachment purge timers while inside [kEraseUndoWindow].
  final Map<String, Timer> _eraseTimers = <String, Timer>{};

  bool _isDisposed = false;

  EditorMediaBinding({
    required this.mediaOcrDao,
    required this.mediaSandboxService,
    required this.entryId,
    required this.coordinator,
    required this.autosaveManager,
    required this.onStateChanged,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  /// Compresses and sandboxes picked image files up to `coordinator.handscrollRoom`,
  /// inserts attachment rows atomically via [MediaOcrDao], stages items in input
  /// order, queues [BrushRevealQueue] animations, and saves the draft.
  Future<MediaCollectResult> collectImages(List<XFile> picks) async {
    if (picks.isEmpty) {
      return const MediaCollectResult(collectedCount: 0, rejectedByCapacity: 0);
    }

    final room = coordinator.handscrollRoom;
    if (room <= 0) {
      return MediaCollectResult(
        collectedCount: 0,
        rejectedByCapacity: picks.length,
      );
    }

    final acceptedPicks = picks.take(room);
    final rejectedByCapacity = math.max(0, picks.length - room);
    final createdPaths = <String>[];
    final collected = <SheetMediaItem>[];

    try {
      for (final picked in acceptedPicks) {
        final relativePath = await mediaSandboxService.copyAndCompressImage(
          File(picked.path),
        );
        createdPaths.add(relativePath);
        collected.add(
          SheetMediaItem(
            id: _uuid.v4(),
            mediaType: EphemeraMediaType.image,
            relativePath: relativePath,
          ),
        );
      }

      await mediaOcrDao.attachMediaBatch(
        entryId: entryId,
        attachments: [
          for (final item in collected)
            MediaAttachmentDraft(
              id: item.id,
              relativePath: item.relativePath,
              mediaType: EphemeraMediaType.image.embedKey,
            ),
        ],
      );
    } catch (_) {
      if (createdPaths.isNotEmpty) {
        await mediaSandboxService.deleteMediaPaths(createdPaths);
      }
      rethrow;
    }

    for (final item in collected) {
      if (coordinator.collectMedia(item)) {
        brushReveals.enqueue(item.id);
      }
    }
    onStateChanged();
    await autosaveManager.saveDraft();
    return MediaCollectResult(
      collectedCount: collected.length,
      rejectedByCapacity: rejectedByCapacity,
    );
  }

  /// Sandboxes a short video (<=60s) and its companion poster thumbnail,
  /// inserts its SQLite attachment row, stages it in the handscroll, queues
  /// its Brush Reveal, and saves the draft.
  Future<MediaCollectResult> collectVideo(XFile pick) async {
    if (coordinator.handscrollRoom <= 0) {
      return const MediaCollectResult(collectedCount: 0, rejectedByCapacity: 1);
    }

    final createdPaths = <String>[];
    late final SheetMediaItem item;

    try {
      final result = await mediaSandboxService.copyAndSandboxVideo(
        File(pick.path),
      );
      createdPaths.add(result.relativePath);
      final String? thumbnailPath =
          result.thumbnailPath.isNotEmpty ? result.thumbnailPath : null;
      if (thumbnailPath != null) {
        createdPaths.add(thumbnailPath);
      }

      final mediaId = _uuid.v4();
      await mediaOcrDao.attachMediaBatch(
        entryId: entryId,
        attachments: [
          MediaAttachmentDraft(
            id: mediaId,
            relativePath: result.relativePath,
            mediaType: EphemeraMediaType.video.embedKey,
            thumbnailPath: thumbnailPath,
          ),
        ],
      );
      item = SheetMediaItem(
        id: mediaId,
        mediaType: EphemeraMediaType.video,
        relativePath: result.relativePath,
        thumbnailPath: thumbnailPath,
      );
    } catch (_) {
      if (createdPaths.isNotEmpty) {
        await mediaSandboxService.deleteMediaPaths(createdPaths);
      }
      rethrow;
    }

    if (coordinator.collectMedia(item)) {
      brushReveals.enqueue(item.id);
    }
    onStateChanged();
    await autosaveManager.saveDraft();
    return const MediaCollectResult(collectedCount: 1, rejectedByCapacity: 0);
  }

  /// Mounts the staged item [mediaId] onto the active Stationery Sheet and
  /// returns whether it mounted. A full sheet refuses (ticking [mountRefusals]
  /// so its Tucked Prints shake), leaving the item staged.
  Future<bool> mountMedia(String mediaId) async {
    final didMount = coordinator.mountOnActiveSheet(mediaId);
    if (didMount) brushReveals.complete(mediaId);
    onStateChanged();
    if (!didMount) {
      mountRefusals.value++;
      return false;
    }
    await autosaveManager.saveDraft();
    return true;
  }

  /// Unmounts [mediaId] from its sheet back into the Staging Handscroll.
  Future<void> unmountMedia(String mediaId) async {
    if (!coordinator.unmountMedia(mediaId)) return;
    onStateChanged();
    await autosaveManager.saveDraft();
  }

  /// Erases the staged item [mediaId] from the handscroll and starts an
  /// internal [kEraseUndoWindow] purge timer. Calling [undoErase] before the
  /// timer fires restores the item; otherwise [purgeErased] deletes its SQLite
  /// row first and then removes both primary and thumbnail sandbox files.
  bool eraseStagedMedia(String mediaId) {
    if (_isDisposed) return false;
    final removed = coordinator.removeStaged(mediaId);
    if (removed == null) return false;
    brushReveals.complete(mediaId);
    _pendingErasures[mediaId] = removed;
    _eraseTimers.remove(mediaId)?.cancel();
    _eraseTimers[mediaId] = Timer(kEraseUndoWindow, () {
      unawaited(purgeErased(mediaId));
    });
    onStateChanged();
    return true;
  }

  /// Erases every item still staged and purges each immediately (there is no
  /// undo: the editor is being left). Items already erased and awaiting their
  /// undo window are purged too, so none outlives the editor. Mounted items are
  /// untouched.
  Future<void> discardAllStaged() async {
    for (final item in coordinator.stagedItems.toList()) {
      eraseStagedMedia(item.id);
    }
    for (final mediaId in _pendingErasures.keys.toList()) {
      await _purge(mediaId);
    }
  }

  /// Restores the erased item [mediaId] to the handscroll, cancelling its
  /// pending purge timer if still inside [kEraseUndoWindow].
  void undoErase(String mediaId) {
    _eraseTimers.remove(mediaId)?.cancel();
    final item = _pendingErasures.remove(mediaId);
    if (item == null) return;
    coordinator.restoreStaged(item);
    onStateChanged();
  }

  /// Purges the erased item [mediaId] once its undo window has passed.
  Future<void> purgeErased(String mediaId) => _purge(mediaId);

  Future<void> _purge(String mediaId) async {
    _eraseTimers.remove(mediaId)?.cancel();
    final item = _pendingErasures.remove(mediaId);
    if (item == null) return;
    await _deleteSqlAndSandboxFiles(
      item.relativePath,
      knownThumbnailPath: item.thumbnailPath,
    );
  }

  /// Removes a legacy full-sheet [EphemeraSheet] at [sheetIndex], deletes its
  /// SQLite `mediaAttachments` records first (collecting any companion
  /// `thumbnailPath`), deletes primary and thumbnail sandbox files, and forces
  /// a draft save.
  Future<void> deleteLegacyEphemera(int sheetIndex) async {
    if (_isDisposed) return;
    if (sheetIndex < 0 || sheetIndex >= coordinator.sheets.length) return;
    final targetSheet = coordinator.sheets[sheetIndex];
    if (targetSheet is! EphemeraSheet) return;
    final relativePath = targetSheet.sandboxedRelativePath;

    coordinator.removeEphemeraSheet(sheetIndex);
    onStateChanged();

    if (relativePath.isNotEmpty) {
      await _deleteSqlAndSandboxFiles(relativePath);
    }
    await autosaveManager.saveDraft(force: true);
  }

  Future<void> _deleteSqlAndSandboxFiles(
    String relativePath, {
    String? knownThumbnailPath,
  }) async {
    final dbThumbnails = await mediaOcrDao.deleteMediaForEntryByPath(
      entryId: entryId,
      relativePath: relativePath,
    );
    await mediaSandboxService.deleteMediaPaths({
      relativePath,
      if (knownThumbnailPath != null && knownThumbnailPath.isNotEmpty)
        knownThumbnailPath,
      ...dbThumbnails,
    });
  }

  /// Updates the in-memory and persisted caption for [mediaId].
  Future<void> updateCaption(String mediaId, String newCaption) async {
    if (coordinator.updateCaption(mediaId, newCaption)) onStateChanged();
    await mediaOcrDao.updateMediaCaption(mediaId, caption: newCaption);
  }

  /// Cancels active timers and purges erasures still inside their undo window,
  /// since the editor that could restore them is going away.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    for (final timer in _eraseTimers.values) {
      timer.cancel();
    }
    _eraseTimers.clear();
    for (final mediaId in _pendingErasures.keys.toList()) {
      unawaited(_purge(mediaId));
    }
    mountRefusals.dispose();
    brushReveals.dispose();
  }
}
