import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/album_repository.dart';
import '../models/album_studio_models.dart';
import 'album_theme_catalog.dart';
import 'page_layout_catalog.dart';

/// State and command controller for the DIY Photobook & Scrapbook Studio.
///
/// Maintains a 50-step Undo/Redo history stack and coordinates slot swapping,
/// the "Removed" holding tray lifecycle, collage layout switching, background
/// and graphic customization, global book themes, and overlay transformations.
class AlbumStudioController extends ChangeNotifier {
  static const int maxHistorySteps = 50;
  static const int maxRecentColors = 8;

  final String collectionId;
  final AlbumRepository? repository;
  final Future<void> Function(AlbumStudioDocument)? onPersist;
  final Duration debounceDuration;

  AlbumStudioDocument _document;
  final List<AlbumStudioDocument> _undoStack = [];
  final List<AlbumStudioDocument> _redoStack = [];
  int _selectedPageIndex = 0;
  Timer? _debounceTimer;

  AlbumStudioController({
    required this.collectionId,
    required AlbumStudioDocument initialDocument,
    this.repository,
    Future<void> Function(AlbumStudioDocument)? onPersist,
    this.debounceDuration = const Duration(milliseconds: 600),
  })  : _document = initialDocument,
        onPersist = onPersist ??
            (repository != null
                ? ((doc) => repository.saveStudioDocument(collectionId, doc))
                : null);

  AlbumStudioDocument get document => _document;

  List<AlbumPageModel> get pages => _document.pages;

  List<String> get removedPhotoIds => _document.removedPhotoIds;

  int get selectedPageIndex => _selectedPageIndex.clamp(
        0,
        _document.pages.isEmpty ? 0 : _document.pages.length - 1,
      );

  AlbumPageModel? get selectedPage =>
      _document.pages.isEmpty ? null : _document.pages[selectedPageIndex];

  bool get canUndo => _undoStack.isNotEmpty;

  bool get canRedo => _redoStack.isNotEmpty;

  int get undoCount => _undoStack.length;

  int get redoCount => _redoStack.length;

  void selectPage(int index) {
    if (_document.pages.isEmpty) return;
    final clamped = index.clamp(0, _document.pages.length - 1);
    if (clamped == _selectedPageIndex) return;
    _selectedPageIndex = clamped;
    notifyListeners();
  }

  void _commitMutation(AlbumStudioDocument nextDocument) {
    if (nextDocument == _document) return;
    _undoStack.add(_document);
    if (_undoStack.length > maxHistorySteps) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    _document = nextDocument;
    if (_selectedPageIndex >= _document.pages.length &&
        _document.pages.isNotEmpty) {
      _selectedPageIndex = _document.pages.length - 1;
    }
    _schedulePersist();
    notifyListeners();
  }

  /// Records [colorArgb] at the head of the MRU recent background colors list,
  /// capping at [maxRecentColors].
  List<int> _recordRecentColor(int colorArgb) {
    final updatedRecents = <int>[
      colorArgb,
      for (final existing in _document.recentBackgroundColors)
        if (existing != colorArgb) existing,
    ];
    if (updatedRecents.length > maxRecentColors) {
      updatedRecents.removeRange(maxRecentColors, updatedRecents.length);
    }
    return updatedRecents;
  }

  /// Helper to mutate an individual page identified by [pageId] and commit the mutation.
  bool _updatePage(
    String pageId,
    AlbumPageModel Function(AlbumPageModel page) updater, {
    List<String>? nextRemovedPhotoIds,
    List<int>? nextRecentColors,
    String? nextActiveThemeId,
  }) {
    final pageIdx = _document.pages.indexWhere((page) => page.id == pageId);
    if (pageIdx < 0) return false;

    final originalPage = _document.pages[pageIdx];
    final updatedPage = updater(originalPage);

    final updatedPages = List<AlbumPageModel>.from(_document.pages);
    updatedPages[pageIdx] = updatedPage;

    _commitMutation(
      _document.copyWith(
        pages: updatedPages,
        removedPhotoIds: nextRemovedPhotoIds,
        recentBackgroundColors: nextRecentColors,
        activeThemeId: nextActiveThemeId,
      ),
    );
    return true;
  }

  /// Reverts the last studio mutation if [canUndo] is true.
  void undo() {
    if (!canUndo) return;
    final previous = _undoStack.removeLast();
    _redoStack.add(_document);
    if (_redoStack.length > maxHistorySteps) {
      _redoStack.removeAt(0);
    }
    _document = previous;
    _schedulePersist();
    notifyListeners();
  }

  /// Re-applies the last undone mutation if [canRedo] is true.
  void redo() {
    if (!canRedo) return;
    final next = _redoStack.removeLast();
    _undoStack.add(_document);
    if (_undoStack.length > maxHistorySteps) {
      _undoStack.removeAt(0);
    }
    _document = next;
    _schedulePersist();
    notifyListeners();
  }

  /// Swaps two photo assignments within [pageId] between [firstSlotIndex] and [secondSlotIndex].
  void swapPhotoSlots({
    required String pageId,
    required int firstSlotIndex,
    required int secondSlotIndex,
  }) {
    if (firstSlotIndex == secondSlotIndex) return;
    _updatePage(pageId, (page) {
      if (firstSlotIndex < 0 ||
          firstSlotIndex >= page.photoSlots.length ||
          secondSlotIndex < 0 ||
          secondSlotIndex >= page.photoSlots.length) {
        return page;
      }

      final updatedSlots = List<PhotoSlotAssignment>.from(page.photoSlots);
      final firstSlot = updatedSlots[firstSlotIndex];
      final secondSlot = updatedSlots[secondSlotIndex];

      updatedSlots[firstSlotIndex] = secondSlot.copyWith(
        slotIndex: firstSlotIndex,
      );
      updatedSlots[secondSlotIndex] = firstSlot.copyWith(
        slotIndex: secondSlotIndex,
      );
      return page.copyWith(photoSlots: updatedSlots);
    });
  }

  /// Removes the photo at [slotIndex] on [pageId] into the "Removed" holding tray
  /// and automatically transitions the page to an `(N - 1)`-photo collage layout.
  void removePhotoToTray({
    required String pageId,
    required int slotIndex,
  }) {
    final pageIdx = _document.pages.indexWhere((page) => page.id == pageId);
    if (pageIdx < 0) return;

    final page = _document.pages[pageIdx];
    if (slotIndex < 0 || slotIndex >= page.photoSlots.length) return;

    final removedSlot = page.photoSlots[slotIndex];
    final remainingSlots = <PhotoSlotAssignment>[];
    for (var i = 0; i < page.photoSlots.length; i++) {
      if (i == slotIndex) continue;
      remainingSlots.add(
        page.photoSlots[i].copyWith(slotIndex: remainingSlots.length),
      );
    }

    final nextLayoutId = remainingSlots.isEmpty
        ? 'solo_full_bleed'
        : PageLayoutCatalog.defaultTemplateForPhotoCount(remainingSlots.length)
            .id;

    final updatedRemoved = List<String>.from(_document.removedPhotoIds);
    if (!updatedRemoved.contains(removedSlot.photoId)) {
      updatedRemoved.add(removedSlot.photoId);
    }

    _updatePage(
      pageId,
      (page) => page.copyWith(
        layoutTemplateId: nextLayoutId,
        photoSlots: remainingSlots,
      ),
      nextRemovedPhotoIds: updatedRemoved,
    );
  }

  /// Restores [photoId] from the "Removed" holding tray onto [targetPageId]
  /// and automatically transitions the page to an `(N + 1)`-photo collage layout.
  void restorePhotoFromTray({
    required String photoId,
    required String targetPageId,
  }) {
    if (!_document.removedPhotoIds.contains(photoId)) return;
    final pageIdx =
        _document.pages.indexWhere((page) => page.id == targetPageId);
    if (pageIdx < 0) return;

    final page = _document.pages[pageIdx];
    if (page.photoSlots.length >= PageLayoutCatalog.maxPhotosPerPage) {
      return;
    }

    final updatedSlots = List<PhotoSlotAssignment>.from(page.photoSlots)
      ..add(
        PhotoSlotAssignment(
          slotIndex: page.photoSlots.length,
          photoId: photoId,
        ),
      );

    final nextLayout =
        PageLayoutCatalog.defaultTemplateForPhotoCount(updatedSlots.length);

    final updatedRemoved = _document.removedPhotoIds
        .where((id) => id != photoId)
        .toList(growable: false);

    _updatePage(
      targetPageId,
      (page) => page.copyWith(
        layoutTemplateId: nextLayout.id,
        photoSlots: updatedSlots,
      ),
      nextRemovedPhotoIds: updatedRemoved,
    );
  }

  /// Moves a photo assignment from [sourcePageId] at [sourceSlotIndex] to [targetPageId].
  ///
  /// If [sourcePageId] == [targetPageId], delegates to [swapPhotoSlots].
  /// Otherwise, removes the photo from the source page (adapting its layout to N-1),
  /// and places it on the target page (at [targetSlotIndex] or appended, adapting layout to N+1).
  void movePhotoBetweenPages({
    required String sourcePageId,
    required int sourceSlotIndex,
    required String targetPageId,
    int? targetSlotIndex,
  }) {
    if (sourcePageId == targetPageId) {
      if (targetSlotIndex != null) {
        swapPhotoSlots(
          pageId: sourcePageId,
          firstSlotIndex: sourceSlotIndex,
          secondSlotIndex: targetSlotIndex,
        );
      }
      return;
    }

    final sourceIdx =
        _document.pages.indexWhere((page) => page.id == sourcePageId);
    final targetIdx =
        _document.pages.indexWhere((page) => page.id == targetPageId);
    if (sourceIdx < 0 || targetIdx < 0) return;

    final sourcePage = _document.pages[sourceIdx];
    final targetPage = _document.pages[targetIdx];

    if (sourceSlotIndex < 0 || sourceSlotIndex >= sourcePage.photoSlots.length) {
      return;
    }
    if (targetPage.photoSlots.length >= PageLayoutCatalog.maxPhotosPerPage) {
      return;
    }

    final movedPhoto = sourcePage.photoSlots[sourceSlotIndex];

    // 1. Compute updated source page
    final nextSourceSlots = <PhotoSlotAssignment>[];
    for (var i = 0; i < sourcePage.photoSlots.length; i++) {
      if (i == sourceSlotIndex) continue;
      nextSourceSlots.add(
        sourcePage.photoSlots[i].copyWith(slotIndex: nextSourceSlots.length),
      );
    }
    final nextSourceLayout = nextSourceSlots.isEmpty
        ? 'solo_full_bleed'
        : PageLayoutCatalog.defaultTemplateForPhotoCount(nextSourceSlots.length)
            .id;
    final updatedSourcePage = sourcePage.copyWith(
      photoSlots: nextSourceSlots,
      layoutTemplateId: nextSourceLayout,
    );

    // 2. Compute updated target page
    final nextTargetSlots =
        List<PhotoSlotAssignment>.from(targetPage.photoSlots);
    final insertIdx = (targetSlotIndex ?? nextTargetSlots.length)
        .clamp(0, nextTargetSlots.length);
    nextTargetSlots.insert(
      insertIdx,
      PhotoSlotAssignment(
        slotIndex: insertIdx,
        photoId: movedPhoto.photoId,
      ),
    );
    for (var i = 0; i < nextTargetSlots.length; i++) {
      nextTargetSlots[i] = nextTargetSlots[i].copyWith(slotIndex: i);
    }
    final nextTargetLayout =
        PageLayoutCatalog.defaultTemplateForPhotoCount(nextTargetSlots.length)
            .id;
    final updatedTargetPage = targetPage.copyWith(
      photoSlots: nextTargetSlots,
      layoutTemplateId: nextTargetLayout,
    );

    final updatedPages = List<AlbumPageModel>.from(_document.pages);
    updatedPages[sourceIdx] = updatedSourcePage;
    updatedPages[targetIdx] = updatedTargetPage;

    _commitMutation(_document.copyWith(pages: updatedPages));
  }

  /// Switches the collage layout template for [pageId] to [layoutTemplateId].
  ///
  /// If the new template accommodates fewer photos than the page currently contains,
  /// surplus photos are automatically placed into [AlbumStudioDocument.removedPhotoIds]
  /// so no photos are lost.
  void changePageLayout({
    required String pageId,
    required String layoutTemplateId,
  }) {
    final pageIdx = _document.pages.indexWhere((page) => page.id == pageId);
    if (pageIdx < 0) return;

    final page = _document.pages[pageIdx];
    if (page.layoutTemplateId == layoutTemplateId) return;

    final template = PageLayoutCatalog.getById(layoutTemplateId);
    final maxSlots = template.slots.length;

    var updatedSlots = page.photoSlots;
    List<String>? nextRemoved;

    if (page.photoSlots.length > maxSlots) {
      final keptSlots = <PhotoSlotAssignment>[];
      final surplusSlots = <PhotoSlotAssignment>[];

      for (var i = 0; i < page.photoSlots.length; i++) {
        if (i < maxSlots) {
          keptSlots.add(page.photoSlots[i].copyWith(slotIndex: i));
        } else {
          surplusSlots.add(page.photoSlots[i]);
        }
      }

      final updatedRemovedList = List<String>.from(_document.removedPhotoIds);
      for (final surplus in surplusSlots) {
        if (!updatedRemovedList.contains(surplus.photoId)) {
          updatedRemovedList.add(surplus.photoId);
        }
      }

      updatedSlots = keptSlots;
      nextRemoved = updatedRemovedList;
    }

    _updatePage(
      pageId,
      (page) => page.copyWith(
        layoutTemplateId: layoutTemplateId,
        photoSlots: updatedSlots,
      ),
      nextRemovedPhotoIds: nextRemoved,
    );
  }

  /// Updates the non-destructive pan and zoom crop parameters for [slotIndex] on [pageId].
  void updatePhotoPanZoom({
    required String pageId,
    required int slotIndex,
    double? panOffsetX,
    double? panOffsetY,
    double? zoomScale,
  }) {
    _updatePage(pageId, (page) {
      if (slotIndex < 0 || slotIndex >= page.photoSlots.length) return page;

      final slot = page.photoSlots[slotIndex];
      final updatedSlot = slot.copyWith(
        panOffsetX: panOffsetX,
        panOffsetY: panOffsetY,
        zoomScale: zoomScale?.clamp(1.0, 4.0),
      );

      final updatedSlots = List<PhotoSlotAssignment>.from(page.photoSlots);
      updatedSlots[slotIndex] = updatedSlot;

      return page.copyWith(photoSlots: updatedSlots);
    });
  }

  /// Updates the background color, contrasting text color, and vector graphic pattern
  /// for [pageId], recording the color in [AlbumStudioDocument.recentBackgroundColors].
  void updatePageBackground({
    required String pageId,
    required PageBackgroundConfig backgroundConfig,
  }) {
    final updatedRecents =
        _recordRecentColor(backgroundConfig.backgroundColorArgb);

    _updatePage(
      pageId,
      (page) => page.copyWith(backgroundConfig: backgroundConfig),
      nextRecentColors: updatedRecents,
    );
  }

  /// Applies [themeId] across all pages in the studio document, cycling through
  /// the theme's curated swatches and vector graphic patterns.
  void applyGlobalTheme(String themeId) {
    final theme = AlbumThemeCatalog.getThemeById(themeId);
    final updatedPages = <AlbumPageModel>[];

    for (var i = 0; i < _document.pages.length; i++) {
      final page = _document.pages[i];
      final bgConfig = theme.backgroundConfigForIndex(i);
      updatedPages.add(page.copyWith(backgroundConfig: bgConfig));
    }

    final updatedRecents =
        _recordRecentColor(theme.defaultBackgroundConfig.backgroundColorArgb);

    _commitMutation(
      _document.copyWith(
        pages: updatedPages,
        activeThemeId: theme.id,
        recentBackgroundColors: updatedRecents,
      ),
    );
  }

  /// Adds a new sticker, text, date pill, or seal overlay to [pageId].
  void addOverlay({
    required String pageId,
    required PageOverlayElement overlay,
  }) {
    _updatePage(pageId, (page) {
      final updatedOverlays = List<PageOverlayElement>.from(page.overlays)
        ..add(overlay);
      return page.copyWith(overlays: updatedOverlays);
    });
  }

  /// Updates an existing overlay's position, scale, rotation, or content on [pageId].
  void updateOverlay({
    required String pageId,
    required PageOverlayElement overlay,
  }) {
    _updatePage(pageId, (page) {
      final overlayIdx =
          page.overlays.indexWhere((item) => item.id == overlay.id);
      if (overlayIdx < 0) return page;

      final updatedOverlays = List<PageOverlayElement>.from(page.overlays);
      updatedOverlays[overlayIdx] = overlay;
      return page.copyWith(overlays: updatedOverlays);
    });
  }

  /// Removes [overlayId] from [pageId].
  void removeOverlay({
    required String pageId,
    required String overlayId,
  }) {
    _updatePage(pageId, (page) {
      final updatedOverlays = page.overlays
          .where((item) => item.id != overlayId)
          .toList(growable: false);
      if (updatedOverlays.length == page.overlays.length) return page;
      return page.copyWith(overlays: updatedOverlays);
    });
  }

  /// Updates the optional date header text on [pageId].
  void updateDateHeaderText({
    required String pageId,
    String? dateHeaderText,
  }) {
    _updatePage(pageId, (page) {
      final trimmed = dateHeaderText?.trim();
      return page.copyWith(
        dateHeaderText: trimmed,
        clearDateHeader: trimmed == null || trimmed.isEmpty,
      );
    });
  }

  /// Appends or inserts a blank page styled with the active theme's default background.
  void addBlankPage({int? insertAtIndex}) {
    final theme = AlbumThemeCatalog.getThemeById(_document.activeThemeId);
    final updatedPages = List<AlbumPageModel>.from(_document.pages);
    final insertIdx =
        (insertAtIndex ?? updatedPages.length).clamp(0, updatedPages.length);

    final newPageId =
        'page_${DateTime.now().microsecondsSinceEpoch}_${updatedPages.length + 1}';
    updatedPages.insert(
      insertIdx,
      AlbumPageModel(
        id: newPageId,
        pageNumber: insertIdx + 1,
        layoutTemplateId: 'solo_full_bleed',
        photoSlots: const [],
        backgroundConfig: theme.defaultBackgroundConfig,
      ),
    );

    _commitMutation(
      _document.copyWith(pages: _renumberPages(updatedPages)),
    );
  }

  /// Removes [pageId] from the document (moving any assigned photos into [removedPhotoIds]
  /// so no photos are lost). Keeps at least 1 page in the document.
  void removePage(String pageId) {
    if (_document.pages.length <= 1) return;
    final pageIdx = _document.pages.indexWhere((page) => page.id == pageId);
    if (pageIdx < 0) return;

    final removedPage = _document.pages[pageIdx];
    final updatedRemoved = List<String>.from(_document.removedPhotoIds);
    for (final slot in removedPage.photoSlots) {
      if (!updatedRemoved.contains(slot.photoId)) {
        updatedRemoved.add(slot.photoId);
      }
    }

    final updatedPages = List<AlbumPageModel>.from(_document.pages)
      ..removeAt(pageIdx);

    _commitMutation(
      _document.copyWith(
        pages: _renumberPages(updatedPages),
        removedPhotoIds: updatedRemoved,
      ),
    );
  }

  /// Reorders a page from [oldIndex] to [newIndex] and renumbers all pages `1..N`.
  void reorderPages(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _document.pages.length ||
        newIndex < 0 ||
        newIndex >= _document.pages.length ||
        oldIndex == newIndex) {
      return;
    }

    final updatedPages = List<AlbumPageModel>.from(_document.pages);
    final moved = updatedPages.removeAt(oldIndex);
    updatedPages.insert(newIndex, moved);

    _commitMutation(
      _document.copyWith(pages: _renumberPages(updatedPages)),
    );
  }

  List<AlbumPageModel> _renumberPages(List<AlbumPageModel> source) {
    return [
      for (var i = 0; i < source.length; i++)
        source[i].copyWith(pageNumber: i + 1),
    ];
  }

  void _schedulePersist() {
    if (onPersist == null) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      _executePersist();
    });
  }

  Future<void> _executePersist() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    final callback = onPersist;
    if (callback != null) {
      await callback(_document);
    }
  }

  /// Flushes any pending debounced persistence mutation immediately.
  Future<void> flush() async {
    if (_debounceTimer != null) {
      await _executePersist();
    }
  }

  /// Persists the current [document] to SQLite via [onPersist] or [repository].
  Future<void> saveToRepository() async {
    await _executePersist();
  }

  @override
  void dispose() {
    if (_debounceTimer != null) {
      _executePersist();
    }
    super.dispose();
  }
}
