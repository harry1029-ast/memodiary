import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';

/// Widget resolving a strictly relative sandboxed image path (e.g. `media/{uuid}.webp`
/// or `media/{uuid}_thumb.webp`) via [MediaSandboxService] and decoding at [cacheWidth]
/// so thumbnail grids never decode full 1600px images into memory.
class SandboxedAlbumImage extends StatelessWidget {
  final String? relativePath;
  final MediaSandboxService mediaService;
  final int? cacheWidth;
  final BoxFit fit;
  final double borderRadius;
  final double? width;
  final double? height;
  final IconData placeholderIcon;
  final String? placeholderLabel;

  const SandboxedAlbumImage({
    super.key,
    required this.relativePath,
    required this.mediaService,
    this.cacheWidth,
    this.fit = BoxFit.cover,
    this.borderRadius = 8.0,
    this.width,
    this.height,
    this.placeholderIcon = Icons.landscape_outlined,
    this.placeholderLabel,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final path = relativePath?.trim();
    if (path == null || path.isEmpty || !MediaSandboxService.isStrictlyRelative(path)) {
      return _buildPlaceholder(tokens);
    }

    return FutureBuilder<File>(
      future: mediaService.getFileFromRelativePath(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder(tokens, isLoading: true);
        }

        final file = snapshot.data;
        if (snapshot.hasError || file == null || !file.existsSync()) {
          return _buildPlaceholder(tokens);
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: cacheWidth,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholder(tokens),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(InkDiaryTokens tokens, {bool isLoading = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: tokens.agedFiber,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: tokens.deckleBorder.withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: tokens.danmo,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    placeholderIcon,
                    size: 28,
                    color: tokens.qingmo,
                  ),
                  if (placeholderLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      placeholderLabel!,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 11,
                        color: tokens.danmo,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

