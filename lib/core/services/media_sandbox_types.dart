import 'dart:io';

typedef ImageCompressor = Future<File?> Function(
  String sourcePath,
  String targetPath, {
  int minWidth,
  int minHeight,
  int quality,
});

typedef VideoDurationExtractor = Future<Duration?> Function(File videoFile);

typedef VideoThumbnailGenerator = Future<File?> Function(
  File videoFile,
  String targetThumbnailPath, {
  int? durationSeconds,
});

typedef AspectRatioExtractor = Future<double> Function(File imageFile);

/// Exception thrown when a user selects or records a video exceeding the 60s limit.
class VideoDurationExceededException implements Exception {
  final int durationSeconds;
  final int maxAllowedSeconds;
  final String message;

  VideoDurationExceededException({
    required this.durationSeconds,
    this.maxAllowedSeconds = 60,
  }) : message =
            'Video duration (${durationSeconds}s) exceeds the maximum allowed limit of ${maxAllowedSeconds}s.';

  @override
  String toString() => 'VideoDurationExceededException: $message';
}

/// Result of sandboxing a video with its companion poster thumbnail.
class VideoSandboxResult {
  final String relativePath;
  final String thumbnailPath;
  final int durationSeconds;

  const VideoSandboxResult({
    required this.relativePath,
    required this.thumbnailPath,
    required this.durationSeconds,
  });
}

/// Result of sandboxing a travel album photo with its 1600px full-res WebP,
/// 300px preview thumbnail WebP, and cached width/height aspect ratio.
class AlbumPhotoSandboxResult {
  final String relativeImagePath;
  final String relativeThumbnailPath;
  final double aspectRatio;

  const AlbumPhotoSandboxResult({
    required this.relativeImagePath,
    required this.relativeThumbnailPath,
    required this.aspectRatio,
  });
}

/// Metadata for a single supported media file inside the sandboxed `media/` directory.
class MediaSandboxFile {
  final String relativePath;
  final int sizeBytes;

  const MediaSandboxFile({
    required this.relativePath,
    required this.sizeBytes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaSandboxFile &&
          runtimeType == other.runtimeType &&
          relativePath == other.relativePath &&
          sizeBytes == other.sizeBytes;

  @override
  int get hashCode => Object.hash(relativePath, sizeBytes);

  @override
  String toString() =>
      'MediaSandboxFile(relativePath: $relativePath, sizeBytes: $sizeBytes)';
}
