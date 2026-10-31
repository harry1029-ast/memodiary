import 'dart:async';
import 'dart:collection';
import '../../database/app_database.dart';
import '../media_sandbox_service.dart';
import 'ocr_models.dart';
import 'ocr_service.dart';

/// Manages asynchronous, non-blocking on-device OCR background queue processing.
///
/// Features:
/// - FIFO sequential processing with inter-job microtask yielding to preserve 60 FPS.
/// - In-memory and stateful deduplication by image ID.
/// - Error & empty-text sentinel assignment (`ocr_text = ''`, `ocr_blocks_json = '[]'`)
///   to prevent infinite re-scan loops.
/// - Launch-bound reactive subscription to [AppDatabase.watchUnindexedImagesSince].
/// - Sequential, cancelable historical backfill via [runBackfill].
class OcrQueueManager {
  final AppDatabase _database;
  final MediaSandboxService _mediaSandboxService;
  final OcrService _ocrService;
  final DateTime Function() _clock;

  final Queue<UnindexedImageItem> _queue = Queue<UnindexedImageItem>();
  final Set<String> _pendingOrProcessingIds = <String>{};
  final List<Completer<void>> _idleCompleters = <Completer<void>>[];

  StreamSubscription<List<UnindexedImageItem>>? _streamSubscription;
  int _pendingResolutionCount = 0;
  bool _isDisposed = false;
  bool _isProcessing = false;

  OcrQueueManager({
    required AppDatabase database,
    required MediaSandboxService mediaSandboxService,
    required OcrService ocrService,
    DateTime Function()? clock,
  })  : _database = database,
        _mediaSandboxService = mediaSandboxService,
        _ocrService = ocrService,
        _clock = clock ?? DateTime.now;

  /// Whether the queue manager has been disposed.
  bool get isDisposed => _isDisposed;

  /// Whether a background item is currently being processed or resolved.
  bool get isProcessing => _isProcessing || _pendingResolutionCount > 0;

  /// Returns the current number of pending items in the in-memory queue.
  int get queueLength => _queue.length;

  /// Starts reactively monitoring for unindexed images created since launch.
  ///
  /// Safe to call multiple times; redundant calls are ignored.
  void start() {
    if (_isDisposed || _streamSubscription != null) {
      return;
    }
    final launchTime = _clock();
    _streamSubscription = _database
        .watchUnindexedImagesSince(launchTime)
        .listen(_handleUnindexedImagesStream);
  }

  void _handleUnindexedImagesStream(List<UnindexedImageItem> items) {
    if (_isDisposed) {
      return;
    }
    for (final item in items) {
      enqueueItem(item);
    }
  }

  /// Enqueues an unindexed item directly for sequential FIFO OCR processing.
  void enqueueItem(UnindexedImageItem item) {
    if (_isDisposed) {
      return;
    }
    if (_pendingOrProcessingIds.contains(item.id)) {
      return;
    }
    _pendingOrProcessingIds.add(item.id);
    _queue.add(item);
    _scheduleProcessing();
  }

  /// Enqueues an unindexed entry media attachment by its ID.
  void enqueueMediaAttachment(String attachmentId) {
    if (_isDisposed) {
      return;
    }
    if (_pendingOrProcessingIds.contains(attachmentId)) {
      return;
    }
    _pendingOrProcessingIds.add(attachmentId);
    _pendingResolutionCount++;
    unawaited(_resolveAndEnqueueMediaAttachment(attachmentId));
  }

  Future<void> _resolveAndEnqueueMediaAttachment(String attachmentId) async {
    try {
      final row = await (_database.select(_database.mediaAttachments)
            ..where((tbl) => tbl.id.equals(attachmentId)))
          .getSingleOrNull();

      if (_isDisposed ||
          row == null ||
          row.ocrText != null ||
          row.mediaType != 'image') {
        _pendingOrProcessingIds.remove(attachmentId);
        return;
      }

      final item = UnindexedImageItem(
        id: row.id,
        sourceType: 'entry_media',
        relativePath: row.relativePath,
        createdAt: row.createdAt,
      );
      _queue.add(item);
      _scheduleProcessing();
    } catch (_) {
      _pendingOrProcessingIds.remove(attachmentId);
    } finally {
      _pendingResolutionCount--;
      _checkIdle();
    }
  }

  /// Enqueues an unindexed album photo by its ID.
  void enqueueAlbumPhoto(String photoId) {
    if (_isDisposed) {
      return;
    }
    if (_pendingOrProcessingIds.contains(photoId)) {
      return;
    }
    _pendingOrProcessingIds.add(photoId);
    _pendingResolutionCount++;
    unawaited(_resolveAndEnqueueAlbumPhoto(photoId));
  }

  Future<void> _resolveAndEnqueueAlbumPhoto(String photoId) async {
    try {
      final row = await (_database.select(_database.albumPhotos)
            ..where((tbl) => tbl.id.equals(photoId)))
          .getSingleOrNull();

      if (_isDisposed || row == null || row.ocrText != null) {
        _pendingOrProcessingIds.remove(photoId);
        return;
      }

      final item = UnindexedImageItem(
        id: row.id,
        sourceType: 'album_photo',
        relativePath: row.relativeImagePath,
        createdAt: row.createdAt,
      );
      _queue.add(item);
      _scheduleProcessing();
    } catch (_) {
      _pendingOrProcessingIds.remove(photoId);
    } finally {
      _pendingResolutionCount--;
      _checkIdle();
    }
  }

  void _scheduleProcessing() {
    if (_isProcessing || _isDisposed || _queue.isEmpty) {
      _checkIdle();
      return;
    }
    _isProcessing = true;
    scheduleMicrotask(_processLoop);
  }

  Future<void> _processLoop() async {
    while (!_isDisposed && _queue.isNotEmpty) {
      final item = _queue.removeFirst();
      try {
        await _processSingleItem(item);
      } finally {
        _pendingOrProcessingIds.remove(item.id);
      }
      // Non-blocking inter-job yield to maintain 60 FPS
      await Future<void>.delayed(Duration.zero);
    }
    _isProcessing = false;
    _checkIdle();
  }

  Future<void> _processSingleItem(UnindexedImageItem item) async {
    final file =
        await _mediaSandboxService.getFileFromRelativePath(item.relativePath);

    OcrResult result;
    if (!file.existsSync()) {
      result = OcrResult.empty;
    } else {
      try {
        result = await _ocrService.recognizeText(file.path);
      } catch (_) {
        result = OcrResult.empty;
      }
    }

    final hasText = result.plainText.trim().isNotEmpty;
    final ocrText = hasText ? result.plainText : '';
    final ocrBlocksJson = hasText ? result.toBlocksJson() : '[]';

    if (item.sourceType == 'album_photo') {
      await _database.updateAlbumPhotoOcr(
        item.id,
        ocrText: ocrText,
        ocrBlocksJson: ocrBlocksJson,
      );
    } else {
      await _database.updateMediaOcr(
        item.id,
        ocrText: ocrText,
        ocrBlocksJson: ocrBlocksJson,
      );
    }
  }

  void _checkIdle() {
    if (!_isProcessing &&
        _pendingResolutionCount == 0 &&
        _queue.isEmpty &&
        _idleCompleters.isNotEmpty) {
      final activeCompleters = List<Completer<void>>.from(_idleCompleters);
      _idleCompleters.clear();
      for (final completer in activeCompleters) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }
  }

  /// Waits until all active queue items finish processing and the queue is idle.
  Future<void> waitUntilIdle() async {
    if (!_isProcessing && _pendingResolutionCount == 0 && _queue.isEmpty) {
      return;
    }
    final completer = Completer<void>();
    _idleCompleters.add(completer);
    return completer.future;
  }

  /// Returns the number of unindexed images across entries and albums.
  Future<int> pendingBackfillCount() async {
    return _database.countUnindexedImages();
  }

  /// Sequentially indexes all unindexed historical images across entries and albums.
  ///
  /// Periodically invokes [onProgress] with `(current, total)` after each item.
  /// Checks [isCancelled] and aborts cleanly if requested.
  Future<void> runBackfill({
    void Function(int current, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    if (_isDisposed) {
      return;
    }

    final items = await _database.getUnindexedImages();
    final total = items.length;
    if (total == 0) {
      return;
    }

    for (var index = 0; index < total; index++) {
      if (_isDisposed || (isCancelled?.call() == true)) {
        break;
      }

      final item = items[index];
      _pendingOrProcessingIds.add(item.id);
      try {
        await _processSingleItem(item);
      } finally {
        _pendingOrProcessingIds.remove(item.id);
      }

      onProgress?.call(index + 1, total);

      if (_isDisposed || (isCancelled?.call() == true)) {
        break;
      }

      // Non-blocking inter-job yield to maintain 60 FPS
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Cancels any active subscriptions, flushes completers, and releases resources.
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    _queue.clear();
    _pendingOrProcessingIds.clear();
    _checkIdle();
  }
}
