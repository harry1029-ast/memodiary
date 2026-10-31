import 'package:flutter/foundation.dart';

/// Immutable search result record sourced from `media_fts` representing text
/// recognized inside an entry media attachment or an album photo.
@immutable
class PhotoTextMatch {
  static const String sourceEntryMedia = 'entry_media';
  static const String sourceAlbumPhoto = 'album_photo';

  final String id;
  final String sourceType;
  final String parentId;
  final String relativePath;
  final String? thumbnailPath;
  final String ocrText;
  final String? ocrBlocksJson;
  final String? parentTitle;
  final DateTime? parentDate;

  const PhotoTextMatch({
    required this.id,
    required this.sourceType,
    required this.parentId,
    required this.relativePath,
    this.thumbnailPath,
    required this.ocrText,
    this.ocrBlocksJson,
    this.parentTitle,
    this.parentDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhotoTextMatch &&
        other.id == id &&
        other.sourceType == sourceType &&
        other.parentId == parentId &&
        other.relativePath == relativePath &&
        other.thumbnailPath == thumbnailPath &&
        other.ocrText == ocrText &&
        other.ocrBlocksJson == ocrBlocksJson &&
        other.parentTitle == parentTitle &&
        other.parentDate == parentDate;
  }

  @override
  int get hashCode => Object.hash(
        id,
        sourceType,
        parentId,
        relativePath,
        thumbnailPath,
        ocrText,
        ocrBlocksJson,
        parentTitle,
        parentDate,
      );

  @override
  String toString() {
    return 'PhotoTextMatch(id: $id, sourceType: $sourceType, '
        'parentId: $parentId, relativePath: $relativePath)';
  }
}

/// Immutable descriptor for an image in `media_attachments` or `album_photos`
/// whose `ocr_text` is still `NULL` (unindexed).
@immutable
class UnindexedImageItem {
  final String id;
  final String sourceType;
  final String relativePath;
  final DateTime createdAt;

  const UnindexedImageItem({
    required this.id,
    required this.sourceType,
    required this.relativePath,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnindexedImageItem &&
        other.id == id &&
        other.sourceType == sourceType &&
        other.relativePath == relativePath &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, sourceType, relativePath, createdAt);

  @override
  String toString() {
    return 'UnindexedImageItem(id: $id, sourceType: $sourceType, '
        'relativePath: $relativePath, createdAt: $createdAt)';
  }
}
