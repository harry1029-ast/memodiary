import 'dart:convert';
import '../../../core/database/app_database.dart';
import 'stationery_sheet_descriptor.dart';

/// Represents a sandboxed photograph or short video keepsake attached directly
/// to a discrete Stationery Sheet ($Sheet\ N \leftrightarrow Photo\ N$).
class SheetMediaItem {
  final String id;
  final EphemeraMediaType mediaType;
  final String relativePath;
  final String caption;
  final String aspect; // 'auto', '4:3', '1:1'
  final String? thumbnailPath;

  const SheetMediaItem({
    required this.id,
    required this.mediaType,
    required this.relativePath,
    this.caption = '',
    this.aspect = 'auto',
    this.thumbnailPath,
  });

  /// Factory constructing a [SheetMediaItem] from a Drift [MediaAttachment] record.
  factory SheetMediaItem.fromMediaAttachment(MediaAttachment attachment) {
    return SheetMediaItem(
      id: attachment.id,
      mediaType: EphemeraMediaType.fromEmbedKey(attachment.mediaType),
      relativePath: attachment.relativePath,
      caption: attachment.caption ?? '',
      thumbnailPath: attachment.thumbnailPath,
    );
  }

  /// Creates a shallow copy with modified fields.
  SheetMediaItem copyWith({
    String? id,
    EphemeraMediaType? mediaType,
    String? relativePath,
    String? caption,
    String? aspect,
    String? thumbnailPath,
  }) {
    return SheetMediaItem(
      id: id ?? this.id,
      mediaType: mediaType ?? this.mediaType,
      relativePath: relativePath ?? this.relativePath,
      caption: caption ?? this.caption,
      aspect: aspect ?? this.aspect,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  /// Formats this item as a continuous Delta JSON embed string.
  String toEmbedValue() {
    if (caption.trim().isEmpty && aspect == 'auto') {
      return relativePath;
    }
    return jsonEncode({
      'path': relativePath,
      if (caption.trim().isNotEmpty) 'caption': caption.trim(),
      if (aspect != 'auto') 'aspect': aspect,
    });
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SheetMediaItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          mediaType == other.mediaType &&
          relativePath == other.relativePath &&
          caption == other.caption &&
          aspect == other.aspect &&
          thumbnailPath == other.thumbnailPath;

  @override
  int get hashCode => Object.hash(id, mediaType, relativePath, caption, aspect, thumbnailPath);
}

