import '../models/album_studio_models.dart';
import 'album_studio_layout_mutations.dart';
import 'album_theme_catalog.dart';

/// Pure background, theme, overlay, date-header, and page-order mutation
/// helpers for [AlbumStudioDocument].
abstract final class AlbumStudioPageMutations {
  static List<int> _recordRecentColor(
    List<int> recentColors,
    int colorArgb,
    int maxRecentColors,
  ) {
    final updated = <int>[
      colorArgb,
      for (final existing in recentColors)
        if (existing != colorArgb) existing,
    ];
    if (updated.length > maxRecentColors) {
      updated.removeRange(maxRecentColors, updated.length);
    }
    return updated;
  }

  static List<AlbumPageModel> _renumberPages(List<AlbumPageModel> source) {
    return [
      for (var i = 0; i < source.length; i++)
        source[i].copyWith(pageNumber: i + 1),
    ];
  }

  /// Updates the background configuration for [pageId] and records its color
  /// in `recentBackgroundColors`.
  static AlbumStudioDocument updatePageBackground(
    AlbumStudioDocument doc, {
    required String pageId,
    required PageBackgroundConfig backgroundConfig,
    int maxRecentColors = 8,
  }) {
    final updatedRecents = _recordRecentColor(
      doc.recentBackgroundColors,
      backgroundConfig.backgroundColorArgb,
      maxRecentColors,
    );
    return AlbumStudioLayoutMutations.updatePage(
      doc,
      pageId,
      (page) => page.copyWith(backgroundConfig: backgroundConfig),
      nextRecentColors: updatedRecents,
    );
  }

  /// Applies [themeId] across all pages in [doc].
  static AlbumStudioDocument applyGlobalTheme(
    AlbumStudioDocument doc,
    String themeId, {
    int maxRecentColors = 8,
  }) {
    final theme = AlbumThemeCatalog.getThemeById(themeId);
    final updatedPages = [
      for (var i = 0; i < doc.pages.length; i++)
        doc.pages[i]
            .copyWith(backgroundConfig: theme.backgroundConfigForIndex(i)),
    ];
    final updatedRecents = _recordRecentColor(
      doc.recentBackgroundColors,
      theme.defaultBackgroundConfig.backgroundColorArgb,
      maxRecentColors,
    );
    return doc.copyWith(
      pages: updatedPages,
      activeThemeId: theme.id,
      recentBackgroundColors: updatedRecents,
    );
  }

  /// Adds a sticker, text, date pill, or seal overlay to [pageId].
  static AlbumStudioDocument addOverlay(
    AlbumStudioDocument doc, {
    required String pageId,
    required PageOverlayElement overlay,
  }) {
    return AlbumStudioLayoutMutations.updatePage(doc, pageId, (page) {
      return page.copyWith(
        overlays: List<PageOverlayElement>.from(page.overlays)..add(overlay),
      );
    });
  }

  /// Updates an existing overlay on [pageId].
  static AlbumStudioDocument updateOverlay(
    AlbumStudioDocument doc, {
    required String pageId,
    required PageOverlayElement overlay,
  }) {
    return AlbumStudioLayoutMutations.updatePage(doc, pageId, (page) {
      final idx = page.overlays.indexWhere((item) => item.id == overlay.id);
      if (idx < 0) return page;
      final updatedOverlays = List<PageOverlayElement>.from(page.overlays);
      updatedOverlays[idx] = overlay;
      return page.copyWith(overlays: updatedOverlays);
    });
  }

  /// Removes [overlayId] from [pageId].
  static AlbumStudioDocument removeOverlay(
    AlbumStudioDocument doc, {
    required String pageId,
    required String overlayId,
  }) {
    return AlbumStudioLayoutMutations.updatePage(doc, pageId, (page) {
      final updatedOverlays = page.overlays
          .where((item) => item.id != overlayId)
          .toList(growable: false);
      if (updatedOverlays.length == page.overlays.length) return page;
      return page.copyWith(overlays: updatedOverlays);
    });
  }

  /// Updates the optional date header text on [pageId].
  static AlbumStudioDocument updateDateHeaderText(
    AlbumStudioDocument doc, {
    required String pageId,
    String? dateHeaderText,
  }) {
    return AlbumStudioLayoutMutations.updatePage(doc, pageId, (page) {
      final trimmed = dateHeaderText?.trim();
      return page.copyWith(
        dateHeaderText: trimmed,
        clearDateHeader: trimmed == null || trimmed.isEmpty,
      );
    });
  }

  /// Appends or inserts a blank page styled with the active theme's default background.
  static AlbumStudioDocument addBlankPage(
    AlbumStudioDocument doc, {
    int? insertAtIndex,
  }) {
    final theme = AlbumThemeCatalog.getThemeById(doc.activeThemeId);
    final updatedPages = List<AlbumPageModel>.from(doc.pages);
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
    return doc.copyWith(pages: _renumberPages(updatedPages));
  }

  /// Removes [pageId] from [doc], moving assigned photos into `removedPhotoIds`.
  static AlbumStudioDocument removePage(AlbumStudioDocument doc, String pageId) {
    if (doc.pages.length <= 1) return doc;
    final pageIdx = doc.pages.indexWhere((page) => page.id == pageId);
    if (pageIdx < 0) return doc;

    final removedPage = doc.pages[pageIdx];
    final updatedRemoved = AlbumStudioLayoutMutations.appendUniqueIds(
      doc.removedPhotoIds,
      removedPage.photoSlots.map((slot) => slot.photoId),
    );
    final updatedPages = List<AlbumPageModel>.from(doc.pages)
      ..removeAt(pageIdx);

    return doc.copyWith(
      pages: _renumberPages(updatedPages),
      removedPhotoIds: updatedRemoved,
    );
  }

  /// Reorders a page from [oldIndex] to [newIndex] and renumbers pages `1..N`.
  static AlbumStudioDocument reorderPages(
    AlbumStudioDocument doc,
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex < 0 ||
        oldIndex >= doc.pages.length ||
        newIndex < 0 ||
        newIndex >= doc.pages.length ||
        oldIndex == newIndex) {
      return doc;
    }

    final updatedPages = List<AlbumPageModel>.from(doc.pages);
    final moved = updatedPages.removeAt(oldIndex);
    updatedPages.insert(newIndex, moved);
    return doc.copyWith(pages: _renumberPages(updatedPages));
  }
}
