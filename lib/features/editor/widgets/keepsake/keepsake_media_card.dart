import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/media_sandbox_service.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../../templates/models/template_style.dart';

/// Renders embedded photos and short videos as Tipped-In Ephemera Cards (贴片拓影)
/// in the Keepsake Scroll View.
class KeepsakeMediaCard extends StatelessWidget {
  final String path;
  final bool isVideo;
  final String? caption;
  final String? aspect;
  final MediaSandboxService? mediaService;
  final TemplateStyle style;
  final Color inkColor;

  const KeepsakeMediaCard({
    super.key,
    required this.path,
    this.isVideo = false,
    this.caption,
    this.aspect,
    this.mediaService,
    required this.style,
    required this.inkColor,
  });

  Future<File> _resolveFile(String rawPath) async {
    final service = mediaService ?? MediaSandboxService();
    if (MediaSandboxService.isStrictlyRelative(rawPath)) {
      return service.getFileFromRelativePath(rawPath);
    }
    return File(rawPath);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    final cardBg = style.tokens.substrate == PaperSubstrate.obsidian
        ? const Color(0xFF242220)
        : tokens.xuanGround;

    const double cardWidth = 220.0;
    const double cardHeight = 300.0;

    return Semantics(
      container: true,
      label: isVideo ? '短视频画幅: ${caption ?? "无题跋"}' : '贴片拓影: ${caption ?? "无题跋"}',
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 24.0),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: tokens.deckleBorder.withValues(alpha: 0.5),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(3, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Media Frame
            ClipRRect(
              borderRadius: BorderRadius.circular(5.0),
              child: SizedBox(
                width: double.infinity,
                height: cardHeight * 0.72,
                child: _buildMediaContent(tokens),
              ),
            ),

            // Colophon / Caption below
            if (caption != null && caption!.trim().isNotEmpty) ...[
              const SizedBox(height: 8.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  caption!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontKaiti,
                    fontSize: 12.0,
                    color: inkColor.withValues(alpha: 0.85),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(InkDiaryTokens tokens) {
    return FutureBuilder<File>(
      future: _resolveFile(path),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.existsSync()) {
          final file = snapshot.data!;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallback(tokens),
              ),
              if (isVideo)
                Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.cinnabar.withValues(alpha: 0.85),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
            ],
          );
        }

        return _buildFallback(tokens);
      },
    );
  }

  Widget _buildFallback(InkDiaryTokens tokens) {
    return Container(
      color: tokens.xuanGround.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVideo ? Icons.videocam_outlined : Icons.image_outlined,
              size: 32,
              color: tokens.danmo,
            ),
            const SizedBox(height: 4),
            Text(
              isVideo ? '短视频' : '图像',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 10,
                color: tokens.danmo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
