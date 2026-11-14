import '../models/album_studio_models.dart';
import 'page_layout_catalog.dart';

/// Pure photo-slot, holding-tray, collage-layout, and pan/zoom mutation helpers
/// for [AlbumStudioDocument].
abstract final class AlbumStudioLayoutMutations {
  static String _adaptLayoutForSlotCount(int slotCount) {
    if (slotCount <= 0) return 'solo_full_bleed';
    return PageLayoutCatalog.defaultTemplateForPhotoCount(slotCount).id;
  }

  /// Appends [additions] to [existing] while preserving order and uniqueness.
  static List<String> appendUniqueIds(
    List<String> existing,
    Iterable<String> additions,
  ) {
    final updated = List<String>.from(existing);
    for (final id in additions) {
      if (!updated.contains(id)) {
        updated.add(id);
      }
    }
    return updated;
  }

  static ({AlbumPageModel page, String removedPhotoId}) _removeSlotAndAdapt(
    AlbumPageModel page,
    int slotIndex,
  ) {
    final removedPhotoId = page.photoSlots[slotIndex].photoId;
    final remainingSlots = <PhotoSlotAssignment>[];
    for (var i = 0; i < page.photoSlots.length; i++) {
      if (i == slotIndex) continue;
      remainingSlots.add(
        page.photoSlots[i].copyWith(slotIndex: remainingSlots.length),
      );
    }
    return (
      page: page.copyWith(
        layoutTemplateId: _adaptLayoutForSlotCount(remainingSlots.length),
        photoSlots: remainingSlots,
      ),
      removedPhotoId: removedPhotoId,
    );
  }

  /// Applies [updater] to the page matching [pageId] in [doc].
  static AlbumStudioDocument updatePage(
    AlbumStudioDocument doc,
    String pageId,
    AlbumPageModel Function(AlbumPageModel page) updater, {
    List<String>? nextRemovedPhotoIds,
    List<int>? nextRecentColors,
    String? nextActiveThemeId,
  }) {
    final pageIdx = doc.pages.indexWhere((page) => page.id == pageId);
    if (pageIdx < 0) return doc;

    final updatedPages = List<AlbumPageModel>.from(doc.pages);
    updatedPages[pageIdx] = updater(doc.pages[pageIdx]);

    return doc.copyWith(
      pages: updatedPages,
      removedPhotoIds: nextRemovedPhotoIds,
      recentBackgroundColors: nextRecentColors,
      activeThemeId: nextActiveThemeId,
    );
  }

  /// Swaps two photo assignments within [pageId] between [firstSlotIndex] and
  /// [secondSlotIndex].
  static AlbumStudioDocument swapPhotoSlots(
    AlbumStudioDocument doc, {
    required String pageId,
    required int firstSlotIndex,
    required int secondSlotIndex,
  }) {
    if (firstSlotIndex == secondSlotIndex) return doc;
    return updatePage(doc, pageId, (page) {
      if (firstSlotIndex < 0 ||
          firstSlotIndex >= page.photoSlots.length ||
          secondSlotIndex < 0 ||
          secondSlotIndex >= page.photoSlots.length) {
        return page;
      }

      final updatedSlots = List<PhotoSlotAssignment>.from(page.photoSlots);
      final firstSlot = updatedSlots[firstSlotIndex];
      final secondSlot = updatedSlots[secondSlotIndex];

      updatedSlots[firstSlotIndex] =
          secondSlot.copyWith(slotIndex: firstSlotIndex);
      updatedSlots[secondSlotIndex] =
          firstSlot.copyWith(slotIndex: secondSlotIndex);
      return page.copyWith(photoSlots: updatedSlots);
    });
  }

  /// Removes the photo at [slotIndex] on [pageId] into `removedPhotoIds` and
  /// adapts the page layout to `(N - 1)`.
  static AlbumStudioDocument removePhotoToTray(
    AlbumStudioDocument doc, {
    required String pageId,
    required int slotIndex,
  }) {
    final pageIdx = doc.pages.indexWhere((page) => page.id == pageId);
    if (pageIdx < 0) return doc;

    final page = doc.pages[pageIdx];
    if (slotIndex < 0 || slotIndex >= page.photoSlots.length) return doc;

    final result = _removeSlotAndAdapt(page, slotIndex);
    final updatedRemoved =
        appendUniqueIds(doc.removedPhotoIds, [result.removedPhotoId]);

    return updatePage(
      doc,
      pageId,
      (_) => result.page,
      nextRemovedPhotoIds: updatedRemoved,
    );
  }

  /// Restores [photoId] from `removedPhotoIds` onto [targetPageId] and adapts
  /// the page layout to `(N + 1)`.
  static AlbumStudioDocument restorePhotoFromTray(
    AlbumStudioDocument doc, {
    required String photoId,
    required String targetPageId,
  }) {
    if (!doc.removedPhotoIds.contains(photoId)) return doc;
    final pageIdx = doc.pages.indexWhere((page) => page.id == targetPageId);
    if (pageIdx < 0) return doc;

    final page = doc.pages[pageIdx];
    if (page.photoSlots.length >= PageLayoutCatalog.maxPhotosPerPage) {
      return doc;
    }

    final updatedSlots = List<PhotoSlotAssignment>.from(page.photoSlots)
      ..add(
        PhotoSlotAssignment(
          slotIndex: page.photoSlots.length,
          photoId: photoId,
        ),
      );
    final updatedRemoved = doc.removedPhotoIds
        .where((id) => id != photoId)
        .toList(growable: false);

    return updatePage(
      doc,
      targetPageId,
      (existing) => existing.copyWith(
        layoutTemplateId: _adaptLayoutForSlotCount(updatedSlots.length),
        photoSlots: updatedSlots,
      ),
      nextRemovedPhotoIds: updatedRemoved,
    );
  }

  /// Moves a photo assignment from [sourcePageId] at [sourceSlotIndex] to
  /// [targetPageId], swapping in-place when both pages match.
  static AlbumStudioDocument movePhotoBetweenPages(
    AlbumStudioDocument doc, {
    required String sourcePageId,
    required int sourceSlotIndex,
    required String targetPageId,
    int? targetSlotIndex,
  }) {
    if (sourcePageId == targetPageId) {
      if (targetSlotIndex == null) return doc;
      return swapPhotoSlots(
        doc,
        pageId: sourcePageId,
        firstSlotIndex: sourceSlotIndex,
        secondSlotIndex: targetSlotIndex,
      );
    }

    final sourceIdx = doc.pages.indexWhere((page) => page.id == sourcePageId);
    final targetIdx = doc.pages.indexWhere((page) => page.id == targetPageId);
    if (sourceIdx < 0 || targetIdx < 0) return doc;

    final sourcePage = doc.pages[sourceIdx];
    final targetPage = doc.pages[targetIdx];
    if (sourceSlotIndex < 0 ||
        sourceSlotIndex >= sourcePage.photoSlots.length ||
        targetPage.photoSlots.length >= PageLayoutCatalog.maxPhotosPerPage) {
      return doc;
    }

    final sourceResult = _removeSlotAndAdapt(sourcePage, sourceSlotIndex);
    final nextTargetSlots =
        List<PhotoSlotAssignment>.from(targetPage.photoSlots);
    final insertIdx = (targetSlotIndex ?? nextTargetSlots.length)
        .clamp(0, nextTargetSlots.length);
    nextTargetSlots.insert(
      insertIdx,
      PhotoSlotAssignment(
        slotIndex: insertIdx,
        photoId: sourceResult.removedPhotoId,
      ),
    );
    for (var i = 0; i < nextTargetSlots.length; i++) {
      nextTargetSlots[i] = nextTargetSlots[i].copyWith(slotIndex: i);
    }

    final updatedPages = List<AlbumPageModel>.from(doc.pages);
    updatedPages[sourceIdx] = sourceResult.page;
    updatedPages[targetIdx] = targetPage.copyWith(
      photoSlots: nextTargetSlots,
      layoutTemplateId: _adaptLayoutForSlotCount(nextTargetSlots.length),
    );

    return doc.copyWith(pages: updatedPages);
  }

  /// Switches the collage layout template for [pageId] to [layoutTemplateId],
  /// moving surplus slots into `removedPhotoIds`.
  static AlbumStudioDocument changePageLayout(
    AlbumStudioDocument doc, {
    required String pageId,
    required String layoutTemplateId,
  }) {
    final pageIdx = doc.pages.indexWhere((page) => page.id == pageId);
    if (pageIdx < 0) return doc;

    final page = doc.pages[pageIdx];
    if (page.layoutTemplateId == layoutTemplateId) return doc;

    final maxSlots = PageLayoutCatalog.getById(layoutTemplateId).slots.length;
    var updatedSlots = page.photoSlots;
    List<String>? nextRemoved;

    if (page.photoSlots.length > maxSlots) {
      updatedSlots = [
        for (var i = 0; i < maxSlots; i++)
          page.photoSlots[i].copyWith(slotIndex: i),
      ];
      nextRemoved = appendUniqueIds(
        doc.removedPhotoIds,
        page.photoSlots.skip(maxSlots).map((slot) => slot.photoId),
      );
    }

    return updatePage(
      doc,
      pageId,
      (existing) => existing.copyWith(
        layoutTemplateId: layoutTemplateId,
        photoSlots: updatedSlots,
      ),
      nextRemovedPhotoIds: nextRemoved,
    );
  }

  /// Updates the non-destructive pan and zoom crop parameters for [slotIndex]
  /// on [pageId].
  static AlbumStudioDocument updatePhotoPanZoom(
    AlbumStudioDocument doc, {
    required String pageId,
    required int slotIndex,
    double? panOffsetX,
    double? panOffsetY,
    double? zoomScale,
  }) {
    return updatePage(doc, pageId, (page) {
      if (slotIndex < 0 || slotIndex >= page.photoSlots.length) return page;
      final updatedSlots = List<PhotoSlotAssignment>.from(page.photoSlots);
      updatedSlots[slotIndex] = updatedSlots[slotIndex].copyWith(
        panOffsetX: panOffsetX,
        panOffsetY: panOffsetY,
        zoomScale: zoomScale?.clamp(1.0, 4.0),
      );
      return page.copyWith(photoSlots: updatedSlots);
    });
  }
}
