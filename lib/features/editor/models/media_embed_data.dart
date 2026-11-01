import 'dart:convert';

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

  double? get explicitAspectRatio {
    switch (aspect) {
      case '4:3':
        return 4.0 / 3.0;
      case '1:1':
        return 1.0;
      case 'auto':
      default:
        return null;
    }
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
        final map = jsonDecode(str) as Map<String, dynamic>;
        return MediaEmbedData(
          path: map['path']?.toString() ?? '',
          caption: map['caption']?.toString() ?? '',
          aspect: map['aspect']?.toString() ?? 'auto',
        );
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
  }) {
    return MediaEmbedData(
      path: path ?? this.path,
      caption: caption ?? this.caption,
      aspect: aspect ?? this.aspect,
    );
  }
}
