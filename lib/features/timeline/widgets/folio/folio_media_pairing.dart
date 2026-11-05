import '../../../../core/database/app_database.dart';
import '../../../editor/domain/stationery_sheet_descriptor.dart';
import 'folio_leaf_model.dart';

/// Pure pairing rules deciding which attachments appear on which Folio leaf.
///
/// Used by the Folio pagination engine. PDF export does not route through it
/// yet; SPEC-010 (ticket 06) moves both onto this unit for marker-based pairing.
class FolioMediaPairing {
  const FolioMediaPairing._();

  /// Appends a [FolioTippedInEphemeraLeaf] for every attachment not already
  /// placed inline by the content parser.
  static void appendUnplacedAttachmentLeaves({
    required List<MediaAttachment> attachments,
    required List<FolioLeaf> contentLeaves,
    required String title,
    required String lunarDate,
  }) {
    final existingMediaPaths = contentLeaves
        .whereType<FolioTippedInEphemeraLeaf>()
        .map((ephemera) => ephemera.sandboxedRelativePath)
        .toSet();

    for (final attachment in attachments) {
      if (existingMediaPaths.contains(attachment.relativePath)) continue;
      contentLeaves.add(
        FolioTippedInEphemeraLeaf(
          leafIndex: 0,
          totalLeaves: 0,
          mediaType: attachment.mediaType,
          sandboxedRelativePath: attachment.relativePath,
          caption: attachment.caption?.trim().isNotEmpty == true
              ? '「图注 · ${attachment.caption!.trim().split('\n').first}」'
              : null,
          title: title,
          lunarDate: lunarDate,
        ),
      );
    }
  }

  /// Distributes curated photos across body leaves (Sheet N ↔ Photo N, up to 3 per leaf).
  static List<FolioPhotoAttachment> photosForBodyIndex(
    List<FolioPhotoAttachment> allPhotos,
    int bodyIndex,
    int totalBodyCount,
  ) {
    if (allPhotos.isEmpty || totalBodyCount <= 0) return const [];
    if (totalBodyCount == 1) {
      return allPhotos.take(3).toList();
    }
    if (allPhotos.length <= totalBodyCount) {
      return bodyIndex < allPhotos.length ? [allPhotos[bodyIndex]] : const [];
    }
    final perLeaf = (allPhotos.length / totalBodyCount).ceil().clamp(1, 3);
    final start = bodyIndex * perLeaf;
    if (start >= allPhotos.length) return const [];
    return allPhotos.skip(start).take(perLeaf).toList();
  }

  /// Builds the ordered photo list for the Frontispiece and leaves, resolving each
  /// attachment's target leaf from body-leaf photos or tipped-in ephemera leaves.
  static List<FolioPhotoAttachment> curatePhotos({
    required List<MediaAttachment> attachments,
    required List<FolioLeaf> contentLeaves,
    String? fallbackHeroPath,
    String? fallbackMediaType,
    required String entryDateStr,
  }) {
    final results = <FolioPhotoAttachment>[];
    final seenPaths = <String>{};

    if (attachments.isNotEmpty) {
      for (int index = 0; index < attachments.length; index++) {
        final attachment = attachments[index];
        seenPaths.add(attachment.relativePath);
        final bodyMatch = contentLeaves
            .whereType<FolioContentBodyLeaf>()
            .cast<FolioContentBodyLeaf?>()
            .firstWhere(
              (leaf) => leaf != null && leaf.photos.any((photo) => photo.relativePath == attachment.relativePath),
              orElse: () => null,
            );
        final leafMatch = contentLeaves
            .whereType<FolioTippedInEphemeraLeaf>()
            .cast<FolioTippedInEphemeraLeaf?>()
            .firstWhere(
              (leaf) => leaf?.sandboxedRelativePath == attachment.relativePath,
              orElse: () => null,
            );
        final targetLeafIndex = bodyMatch?.leafIndex ?? leafMatch?.leafIndex ?? (index + 1);
        final caption = attachment.caption?.trim() ?? '';
        final title = caption.isNotEmpty ? caption.split('\n').first : '随文影札 ${index + 1}';
        results.add(
          FolioPhotoAttachment(
            id: attachment.id,
            relativePath: attachment.relativePath,
            mediaType: EphemeraMediaType.fromEmbedKey(attachment.mediaType),
            title: title,
            caption: caption.isNotEmpty ? caption : '随文影札 · 拾光留影',
            date: entryDateStr,
            pageNumber: index + 1,
            targetLeafIndex: targetLeafIndex,
            overlayXRatio: attachment.overlayXRatio,
            overlayYRatio: attachment.overlayYRatio,
          ),
        );
      }
    }

    final ephemeraLeaves = contentLeaves.whereType<FolioTippedInEphemeraLeaf>().toList();
    for (final leaf in ephemeraLeaves) {
      if (!seenPaths.contains(leaf.sandboxedRelativePath)) {
        seenPaths.add(leaf.sandboxedRelativePath);
        final pageNum = results.length + 1;
        final caption = leaf.caption?.trim() ?? '';
        final title = caption.isNotEmpty
            ? caption.replaceAll('「图注 · ', '').replaceAll('」', '')
            : '随文影札 $pageNum';
        results.add(
          FolioPhotoAttachment(
            id: 'ephemera_${leaf.leafIndex}',
            relativePath: leaf.sandboxedRelativePath,
            mediaType: EphemeraMediaType.fromEmbedKey(leaf.mediaType),
            title: title,
            caption: caption.isNotEmpty ? caption : '随文影札 · 拾光留影',
            date: entryDateStr,
            pageNumber: pageNum,
            targetLeafIndex: leaf.leafIndex,
          ),
        );
      }
    }

    if (results.isEmpty && fallbackHeroPath != null && fallbackHeroPath.isNotEmpty) {
      results.add(
        FolioPhotoAttachment(
          id: 'hero_fallback',
          relativePath: fallbackHeroPath,
          mediaType: EphemeraMediaType.fromEmbedKey(fallbackMediaType ?? 'image'),
          title: '随文影札 1',
          caption: '随文影札 · 拾光留影',
          date: entryDateStr,
          pageNumber: 1,
          targetLeafIndex: contentLeaves.isNotEmpty ? 1 : 0,
        ),
      );
    }

    return results;
  }
}
