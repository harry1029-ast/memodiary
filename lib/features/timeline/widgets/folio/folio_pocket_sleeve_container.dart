import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/services/media_sandbox_service.dart';
import '../../../scenery/models/shanshui_atmosphere.dart';
import 'folio_leaf_model.dart';
import 'folio_reading_perspective.dart';
import 'folio_shanshui_art_painter.dart';

/// Brocade pocket sleeve container (*集锦匣*) displaying fanned photo cards.
class FolioPocketSleeveContainer extends StatelessWidget {
  final List<FolioPhotoAttachment> photos;
  final FolioSubstrateTheme theme;
  final MediaSandboxService? mediaService;
  final VoidCallback? onTap;
  final ShanshuiRealm atmosphereRealm;

  const FolioPocketSleeveContainer({
    super.key,
    required this.photos,
    required this.theme,
    this.mediaService,
    this.onTap,
    required this.atmosphereRealm,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = theme.isDark ? const Color(0xFFE07A6B) : const Color(0xFFB83B2E);

    return Semantics(
      button: true,
      label: '开启拾光画匣总览',
      child: GestureDetector(
        key: const Key('folio_cover_pocket_sleeve_container'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: theme.isDark
                  ? [const Color(0xFF23201D), const Color(0xFF181614)]
                  : [const Color(0xFFEDE3CE), const Color(0xFFE2D4B7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFF8C6D3F).withValues(alpha: 0.55),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          '集锦匣',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '📷 拾光画匣 · 已收录 ${photos.length} 枚随文影札',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: theme.inkPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '开启画匣总览 ➔',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: _buildFannedSpread(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFannedSpread() {
    final displayPhotos = photos.take(5).toList();
    final count = displayPhotos.length;
    const cardWidth = 52.0;
    const cardHeight = 64.0;
    const spacing = 32.0;
    final totalWidth = (count - 1) * spacing + cardWidth;

    return Center(
      child: SizedBox(
        width: totalWidth,
        height: cardHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: List.generate(count, (index) {
            final photo = displayPhotos[index];
            final normalized = count > 1 ? (index - (count - 1) / 2.0) : 0.0;
            final angle = normalized * 0.07;
            final left = index * spacing;

            return Positioned(
              left: left,
              top: (normalized.abs() * 3.0),
              child: Transform.rotate(
                angle: angle,
                child: Container(
                  width: cardWidth,
                  height: cardHeight,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFBF7),
                    border: Border.all(
                      color: const Color(0xFF8C7355).withValues(alpha: 0.45),
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: _buildFannedThumbnail(photo),
                      ),
                      Positioned(
                        left: 2,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 0.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            'P${photo.pageNumber}',
                            style: const TextStyle(
                              fontSize: 8.0,
                              fontFamily: 'monospace',
                              color: Color(0xFFFDE68A),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFannedThumbnail(FolioPhotoAttachment photo) {
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
          if (snapshot.hasData && snapshot.data!.existsSync()) {
            return Image.file(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (errCtx, err, stack) => _fallbackShanshui(),
            );
          }
          return _fallbackShanshui();
        },
      );
    }
    return _fallbackShanshui();
  }

  Widget _fallbackShanshui() {
    return CustomPaint(
      painter: FolioShanshuiArtPainter(
        realm: atmosphereRealm,
        isDark: theme.isDark,
      ),
    );
  }
}
