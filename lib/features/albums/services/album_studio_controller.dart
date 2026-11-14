import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/database/app_database.dart';
import '../data/album_repository.dart';
import '../models/album_studio_models.dart';
import 'album_studio_layout_mutations.dart';
import 'album_studio_page_mutations.dart';
import 'album_studio_session_reconciler.dart';

/// State and command controller for the DIY Photobook & Scrapbook Studio.
///
/// Maintains a 50-step Undo/Redo history stack, binds reactive SQLite streams
/// when backed by [AlbumRepository], and coordinates slot swapping, holding
/// tray lifecycle, collage layout switching, backgrounds, themes, and overlays.
class AlbumStudioController extends ChangeNotifier {
  static const int maxHistorySteps = 50;
  static const int maxRecentColors = 8;

  final String collectionId;
  final AlbumRepository? repository;
  final Future<void> Function(AlbumStudioDocument)? onPersist;
  final Duration debounceDuration;

  AlbumStudioDocument _document;
  AlbumCollection? _collection;
  List<AlbumPhoto> _photos;
  Map<String, AlbumPhoto> _photoById;
  final AlbumStudioHistory _history = AlbumStudioHistory(maxSteps: maxHistorySteps);
  int _selectedPageIndex = 0;
  Timer? _debounceTimer;
  bool _hasPersistedCollection = false;
  List<AlbumPhoto>? _deferredEmptyPhotos;
  bool _isDisposed = false;
  StreamSubscription<AlbumCollection?>? _collectionSubscription;
  StreamSubscription<List<AlbumPhoto>>? _photosSubscription;

  AlbumStudioController({
    required this.collectionId,
    required AlbumStudioDocument initialDocument,
    AlbumCollection? initialCollection,
    List<AlbumPhoto> initialPhotos = const [],
    this.repository,
    Future<void> Function(AlbumStudioDocument)? onPersist,
    this.debounceDuration = const Duration(milliseconds: 600),
  })  : _document = initialDocument,
        _collection = initialCollection,
        _photos = List<AlbumPhoto>.unmodifiable(initialPhotos),
        _photoById = AlbumStudioSessionReconciler.buildPhotoLookup(initialPhotos),
        onPersist = onPersist ??
            (repository != null
                ? ((doc) => repository.saveStudioDocument(collectionId, doc))
                : null) {
    _bindRepositoryStreams();
  }

  AlbumCollection? get collection => _collection;
  List<AlbumPhoto> get photos => _photos;
  Map<String, AlbumPhoto> get photoById => _photoById;
  bool get _hasLivePhotos => _collection != null || _photos.isNotEmpty;

  /// Returns the live [AlbumCollection] when present, otherwise [fallback].
  AlbumCollection resolveCollection(AlbumCollection fallback) =>
      _collection ?? fallback;

  /// Returns the live session photos when active, otherwise [fallback].
  List<AlbumPhoto> resolvePhotos(List<AlbumPhoto> fallback) =>
      _hasLivePhotos ? _photos : fallback;

  /// Returns the live photo lookup map when active, otherwise builds one from [fallback].
  Map<String, AlbumPhoto> resolvePhotoById(List<AlbumPhoto> fallback) =>
      _hasLivePhotos
          ? _photoById
          : AlbumStudioSessionReconciler.buildPhotoLookup(fallback);

  List<BookSpreadData> get overviewSpreads =>
      _document.buildSpreads(includeBlankTrailing: true);
  List<BookSpreadData> get flipbookSpreads =>
      _document.buildSpreads(includeBlankTrailing: false);
  AlbumStudioDocument get document => _document;
  List<AlbumPageModel> get pages => _document.pages;
  List<String> get removedPhotoIds => _document.removedPhotoIds;
  int get selectedPageIndex => _selectedPageIndex.clamp(
        0,
        _document.pages.isEmpty ? 0 : _document.pages.length - 1,
      );
  AlbumPageModel? get selectedPage =>
      _document.pages.isEmpty ? null : _document.pages[selectedPageIndex];
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;
  int get undoCount => _history.undoCount;
  int get redoCount => _history.redoCount;

  void selectPage(int index) {
    if (_document.pages.isEmpty) return;
    final clamped = index.clamp(0, _document.pages.length - 1);
    if (clamped == _selectedPageIndex) return;
    _selectedPageIndex = clamped;
    notifyListeners();
  }

  void _clampSelectedPageIndex() {
    if (_selectedPageIndex >= _document.pages.length &&
        _document.pages.isNotEmpty) {
      _selectedPageIndex = _document.pages.length - 1;
    }
  }

  void _commitMutation(AlbumStudioDocument nextDocument) {
    if (nextDocument == _document) return;
    _history.push(_document);
    _document = nextDocument;
    _clampSelectedPageIndex();
    _schedulePersist();
    notifyListeners();
  }

  /// Reverts the last studio mutation if [canUndo] is true.
  void undo() {
    final previous = _history.undo(_document);
    if (previous == null) return;
    _document = previous;
    _schedulePersist();
    notifyListeners();
  }

  /// Re-applies the last undone mutation if [canRedo] is true.
  void redo() {
    final next = _history.redo(_document);
    if (next == null) return;
    _document = next;
    _schedulePersist();
    notifyListeners();
  }

  void swapPhotoSlots({
    required String pageId,
    required int firstSlotIndex,
    required int secondSlotIndex,
  }) =>
      _commitMutation(AlbumStudioLayoutMutations.swapPhotoSlots(
        _document,
        pageId: pageId,
        firstSlotIndex: firstSlotIndex,
        secondSlotIndex: secondSlotIndex,
      ));

  void removePhotoToTray({required String pageId, required int slotIndex}) =>
      _commitMutation(AlbumStudioLayoutMutations.removePhotoToTray(
        _document,
        pageId: pageId,
        slotIndex: slotIndex,
      ));

  void restorePhotoFromTray({
    required String photoId,
    required String targetPageId,
  }) =>
      _commitMutation(AlbumStudioLayoutMutations.restorePhotoFromTray(
        _document,
        photoId: photoId,
        targetPageId: targetPageId,
      ));

  void movePhotoBetweenPages({
    required String sourcePageId,
    required int sourceSlotIndex,
    required String targetPageId,
    int? targetSlotIndex,
  }) =>
      _commitMutation(AlbumStudioLayoutMutations.movePhotoBetweenPages(
        _document,
        sourcePageId: sourcePageId,
        sourceSlotIndex: sourceSlotIndex,
        targetPageId: targetPageId,
        targetSlotIndex: targetSlotIndex,
      ));

  void changePageLayout({
    required String pageId,
    required String layoutTemplateId,
  }) =>
      _commitMutation(AlbumStudioLayoutMutations.changePageLayout(
        _document,
        pageId: pageId,
        layoutTemplateId: layoutTemplateId,
      ));

  void updatePhotoPanZoom({
    required String pageId,
    required int slotIndex,
    double? panOffsetX,
    double? panOffsetY,
    double? zoomScale,
  }) =>
      _commitMutation(AlbumStudioLayoutMutations.updatePhotoPanZoom(
        _document,
        pageId: pageId,
        slotIndex: slotIndex,
        panOffsetX: panOffsetX,
        panOffsetY: panOffsetY,
        zoomScale: zoomScale,
      ));

  void updatePageBackground({
    required String pageId,
    required PageBackgroundConfig backgroundConfig,
  }) =>
      _commitMutation(AlbumStudioPageMutations.updatePageBackground(
        _document,
        pageId: pageId,
        backgroundConfig: backgroundConfig,
        maxRecentColors: maxRecentColors,
      ));

  void applyGlobalTheme(String themeId) =>
      _commitMutation(AlbumStudioPageMutations.applyGlobalTheme(
        _document,
        themeId,
        maxRecentColors: maxRecentColors,
      ));

  void addOverlay({
    required String pageId,
    required PageOverlayElement overlay,
  }) =>
      _commitMutation(AlbumStudioPageMutations.addOverlay(
        _document,
        pageId: pageId,
        overlay: overlay,
      ));

  void updateOverlay({
    required String pageId,
    required PageOverlayElement overlay,
  }) =>
      _commitMutation(AlbumStudioPageMutations.updateOverlay(
        _document,
        pageId: pageId,
        overlay: overlay,
      ));

  void removeOverlay({required String pageId, required String overlayId}) =>
      _commitMutation(AlbumStudioPageMutations.removeOverlay(
        _document,
        pageId: pageId,
        overlayId: overlayId,
      ));

  void updateDateHeaderText({required String pageId, String? dateHeaderText}) =>
      _commitMutation(AlbumStudioPageMutations.updateDateHeaderText(
        _document,
        pageId: pageId,
        dateHeaderText: dateHeaderText,
      ));

  void addBlankPage({int? insertAtIndex}) =>
      _commitMutation(AlbumStudioPageMutations.addBlankPage(
        _document,
        insertAtIndex: insertAtIndex,
      ));

  void removePage(String pageId) =>
      _commitMutation(AlbumStudioPageMutations.removePage(_document, pageId));

  void reorderPages(int oldIndex, int newIndex) =>
      _commitMutation(AlbumStudioPageMutations.reorderPages(
        _document,
        oldIndex,
        newIndex,
      ));

  void _bindRepositoryStreams() {
    final repo = repository;
    if (repo == null) return;
    _collectionSubscription =
        repo.watchCollectionById(collectionId).listen(_handleCollectionChanged);
    _photosSubscription =
        repo.watchPhotosForCollection(collectionId).listen(_handlePhotosChanged);
  }

  void _handleCollectionChanged(AlbumCollection? nextCollection) {
    if (_isDisposed || nextCollection == null) return;
    final wasPersisted = _hasPersistedCollection;
    _hasPersistedCollection = true;
    final collectionChanged = _collection != nextCollection;
    _collection = nextCollection;
    if (!wasPersisted && _deferredEmptyPhotos != null) {
      final deferred = _deferredEmptyPhotos!;
      _deferredEmptyPhotos = null;
      _handlePhotosChanged(
        deferred,
        notifyIfCollectionChanged: collectionChanged,
      );
      return;
    }
    if (collectionChanged) {
      notifyListeners();
    }
  }

  void _handlePhotosChanged(
    List<AlbumPhoto> nextPhotos, {
    bool notifyIfCollectionChanged = false,
  }) {
    if (_isDisposed) return;
    if (!_hasPersistedCollection && nextPhotos.isEmpty && _photos.isNotEmpty) {
      _deferredEmptyPhotos = const [];
      if (notifyIfCollectionChanged) notifyListeners();
      return;
    }
    _deferredEmptyPhotos = null;

    final reconciled = AlbumStudioSessionReconciler.reconcileSessionPhotos(
      currentPhotos: _photos,
      currentPhotoById: _photoById,
      currentDocument: _document,
      history: _history,
      nextPhotos: nextPhotos,
    );

    if (reconciled.photosChanged) {
      _photos = reconciled.photos;
      _photoById = reconciled.photoById;
    }
    if (reconciled.historyChanged) {
      _history.replace(reconciled.undoStack, reconciled.redoStack);
    }
    if (reconciled.docChanged) {
      _document = reconciled.document;
      _clampSelectedPageIndex();
      _schedulePersist();
    }
    if (reconciled.hasChanges || notifyIfCollectionChanged) {
      notifyListeners();
    }
  }

  void _schedulePersist() {
    if (_isDisposed || onPersist == null) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      if (_isDisposed) return;
      _executePersist();
    });
  }

  Future<void> _executePersist() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    final callback = onPersist;
    if (callback != null) await callback(_document);
  }

  /// Flushes any pending debounced persistence mutation immediately.
  Future<void> flush() async {
    if (_debounceTimer != null) await _executePersist();
  }

  /// Persists the current [document] to SQLite via [onPersist] or [repository].
  Future<void> saveToRepository() async => _executePersist();

  @override
  void dispose() {
    _isDisposed = true;
    _collectionSubscription?.cancel();
    _collectionSubscription = null;
    _photosSubscription?.cancel();
    _photosSubscription = null;
    if (_debounceTimer != null) _executePersist();
    super.dispose();
  }
}
