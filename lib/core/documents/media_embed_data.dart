import 'dart:convert';

/// Typed aspect ratio options for tipped-in media ephemera cards.
enum MediaAspectRatio {
  auto('auto', null),
  standard43('4:3', 4.0 / 3.0),
  square11('1:1', 1.0);

  final String code;
  final double? ratio;
  const MediaAspectRatio(this.code, this.ratio);

  static MediaAspectRatio fromCode(String? code) {
    switch (code) {
      case '4:3':
        return MediaAspectRatio.standard43;
      case '1:1':
        return MediaAspectRatio.square11;
      case 'auto':
      default:
        return MediaAspectRatio.auto;
    }
  }

  MediaAspectRatio get next {
    switch (this) {
      case MediaAspectRatio.auto:
        return MediaAspectRatio.standard43;
      case MediaAspectRatio.standard43:
        return MediaAspectRatio.square11;
      case MediaAspectRatio.square11:
        return MediaAspectRatio.auto;
    }
  }
}

/// Represents parsed embed metadata for photos and short videos
/// supporting backward-compatible serialization in Quill Delta documents.
class MediaEmbedData {
  final String path;
  final String caption;
  final String aspect; // 'auto', '4:3', '1:1'

  const MediaEmbedData({
    required this.path,
    this.caption = '',
    this.aspect = 'auto',
  });

  MediaAspectRatio get aspectRatio => MediaAspectRatio.fromCode(aspect);

  double? get explicitAspectRatio => aspectRatio.ratio;

  /// Returns the companion `_thumb.webp` path for `.mp4` videos when
  /// [isVideo] is true; otherwise returns [path] unchanged.
  String thumbnailPath({bool isVideo = false}) {
    if (isVideo && path.endsWith('.mp4')) {
      return '${path.substring(0, path.length - 4)}_thumb.webp';
    }
    return path;
  }

  static MediaEmbedData fromRaw(dynamic raw) {
    if (raw == null) return const MediaEmbedData(path: '');
    if (raw is Map) {
      return MediaEmbedData(
        path: raw['path']?.toString() ?? '',
        caption: raw['caption']?.toString() ?? '',
        aspect: raw['aspect']?.toString() ?? 'auto',
      );
    }
    final str = raw.toString().trim();
    if (str.startsWith('{') && str.endsWith('}')) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is Map) {
          return MediaEmbedData(
            path: decoded['path']?.toString() ?? '',
            caption: decoded['caption']?.toString() ?? '',
            aspect: decoded['aspect']?.toString() ?? 'auto',
          );
        }
      } catch (_) {
        // Fall back to treating as path
      }
    }
    return MediaEmbedData(path: str);
  }

  String toEmbedValue() {
    if (caption.trim().isEmpty && aspect == 'auto') {
      return path;
    }
    return jsonEncode({
      'path': path,
      if (caption.trim().isNotEmpty) 'caption': caption.trim(),
      if (aspect != 'auto') 'aspect': aspect,
    });
  }

  MediaEmbedData copyWith({
    String? path,
    String? caption,
    String? aspect,
    MediaAspectRatio? aspectRatio,
  }) {
    return MediaEmbedData(
      path: path ?? this.path,
      caption: caption ?? this.caption,
      aspect: aspectRatio?.code ?? aspect ?? this.aspect,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaEmbedData &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          caption == other.caption &&
          aspect == other.aspect;

  @override
  int get hashCode => Object.hash(path, caption, aspect);

  @override
  String toString() =>
      'MediaEmbedData(path: $path, caption: $caption, aspect: $aspect)';
}
