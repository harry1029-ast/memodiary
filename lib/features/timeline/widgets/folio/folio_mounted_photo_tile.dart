import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/services/media_sandbox_service.dart';
import '../../../scenery/models/shanshui_atmosphere.dart';
import 'folio_leaf_model.dart';
import 'folio_reading_perspective.dart';
import 'folio_shanshui_art_painter.dart';
import 'folio_silk_corner_mounts_painter.dart';

/// Mounted photo card used across Folio Cover showcase layouts.
class FolioMountedPhotoTile extends StatelessWidget {
  final FolioPhotoAttachment photo;
  final FolioSubstrateTheme theme;
  final MediaSandboxService? mediaService;
  final String badgeText;
  final bool showCaptionBar;
  final bool isCenteredCaption;
  final bool showAntiqueBrassPin;
  final bool showInnerShadow;
  final VoidCallback? onTap;
  final ShanshuiRealm atmosphereRealm;

  const FolioMountedPhotoTile({
    super.key,
    required this.photo,
    required this.theme,
    this.mediaService,
    required this.badgeText,
    required this.showCaptionBar,
    this.isCenteredCaption = false,
    this.showAntiqueBrassPin = false,
    this.showInnerShadow = false,
    this.onTap,
    required this.atmosphereRealm,
  });

  @override
  Widget build(BuildContext context) {
    final silkColor = theme.isDark ? const Color(0xD0C8A055) : const Color(0xC0DFC898);

    return Semantics(
      button: true,
      label: '展读影札 ${photo.title}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.isDark ? const Color(0xFF141619) : const Color(0xFFFDFBF7),
            border: Border.all(color: const Color(0xFF8C7355).withValues(alpha: 0.40)),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: [
                    _buildPhotoContent(),
                    if (showInnerShadow)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              radius: 1.1,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: theme.isDark ? 0.35 : 0.15),
                              ],
                            ),
                          ),
                        ),
                      ),
                    CustomPaint(painter: FolioSilkCornerMountsPainter(silkColor: silkColor)),
                    Positioned(
                      top: 5,
                      left: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(fontSize: 9.0, color: Color(0xFFFEF3C7)),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 5,
                      bottom: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          '🔍 展读',
                          style: TextStyle(fontSize: 8.5, color: Colors.white),
                        ),
                      ),
                    ),
                    if (showAntiqueBrassPin)
                      const Positioned(
                        top: -12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: AntiqueBrassPin(key: Key('folio_cover_antique_brass_pin')),
                        ),
                      ),
                  ],
                ),
              ),
              if (showCaptionBar) ...[
                const SizedBox(height: 5),
                if (isCenteredCaption)
                  Column(
                    children: [
                      Text(
                        photo.title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          color: theme.inkPrimary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (photo.caption.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          photo.caption,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 9.5, color: theme.inkSecondary),
                        ),
                      ],
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          photo.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: theme.inkPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '第${photo.pageNumber}页附图',
                        style: TextStyle(fontSize: 9.5, color: theme.inkSecondary),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoContent() {
    if (photo.relativePath.isNotEmpty) {
      final immediateFile = !MediaSandboxService.isStrictlyRelative(photo.relativePath)
          ? File(photo.relativePath)
          : null;

      return FutureBuilder<File>(
        initialData: immediateFile,
        future: mediaService != null && MediaSandboxService.isStrictlyRelative(photo.relativePath)
            ? mediaService!.getFileFromRelativePath(photo.relativePath)
            : (immediateFile != null ? Future.value(immediateFile) : null),
        builder: (futureContext, snapshot) {
          if (snapshot.hasData) {
            return Image.file(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (errCtx, err, stack) => _fallbackPaint(),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          return _fallbackPaint();
        },
      );
    }
    return _fallbackPaint();
  }

  Widget _fallbackPaint() {
    return CustomPaint(
      painter: FolioShanshuiArtPainter(
        realm: atmosphereRealm,
        isDark: theme.isDark,
      ),
    );
  }
}

/// Classical decorative antique brass pin atop mount frames.
class AntiqueBrassPin extends StatelessWidget {
  const AntiqueBrassPin({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFDEC183), Color(0xFFC49A45), Color(0xFF6B4E1B)],
          stops: [0.0, 0.65, 1.0],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1.5)),
        ],
        border: Border.all(color: const Color(0xFF5A3E10), width: 0.8),
      ),
      child: Center(
        child: Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF4A340E),
          ),
        ),
      ),
    );
  }
}
