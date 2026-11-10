import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../domain/stationery_sheet_descriptor.dart';

/// Cover-fit preview of a sandboxed photo or video keepsake, shared by the
/// Staging Handscroll and the Tucked Prints.
class KeepsakeThumbnail extends StatefulWidget {
  final SheetMediaItem item;
  final MediaSandboxService mediaSandboxService;
  final bool isPaperDark;

  /// Whether a video shows the play glyph; the Staging Handscroll marks videos
  /// with its cinnabar seal play stamp instead.
  final bool showPlayGlyph;

  const KeepsakeThumbnail({
    super.key,
    required this.item,
    required this.mediaSandboxService,
    this.isPaperDark = false,
    this.showPlayGlyph = true,
  });

  @override
  State<KeepsakeThumbnail> createState() => _KeepsakeThumbnailState();
}

class _KeepsakeThumbnailState extends State<KeepsakeThumbnail> {
  late Future<File> _fileFuture;

  @override
  void initState() {
    super.initState();
    _fileFuture = _resolveFile();
  }

  @override
  void didUpdateWidget(covariant KeepsakeThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.relativePath != widget.item.relativePath) {
      _fileFuture = _resolveFile();
    }
  }

  Future<File> _resolveFile() async {
    final rawPath = widget.item.relativePath;
    if (rawPath.isNotEmpty && !MediaSandboxService.isStrictlyRelative(rawPath)) {
      return File(rawPath);
    }
    return widget.mediaSandboxService.getFileFromRelativePath(rawPath);
  }

  @override
  Widget build(BuildContext context) {
    final placeholderColor = widget.isPaperDark ? Colors.black26 : Colors.black12;
    if (widget.item.mediaType == EphemeraMediaType.video) {
      return Container(
        color: widget.isPaperDark ? const Color(0xFF101010) : const Color(0xFF202020),
        child: widget.showPlayGlyph
            ? const Center(
                child: Icon(Icons.play_circle_fill, size: 28, color: Colors.white70),
              )
            : null,
      );
    }
    return FutureBuilder<File>(
      future: _fileFuture,
      builder: (futureContext, snapshot) {
        if (!snapshot.hasData) {
          return ColoredBox(color: placeholderColor);
        }
        return Image.file(
          snapshot.data!,
          fit: BoxFit.cover,
          errorBuilder: (imageContext, error, stackTrace) => ColoredBox(
            color: placeholderColor,
            child: const Center(
              child: Icon(Icons.image_not_supported_outlined, size: 24),
            ),
          ),
        );
      },
    );
  }
}
