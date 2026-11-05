import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/media_sandbox_service.dart';
import '../../../scenery/models/shanshui_atmosphere.dart';
import 'folio_leaf_model.dart';
import 'folio_polaroid_card_painter.dart';
import 'folio_shanshui_art_painter.dart';

/// Renders a tactile Polaroid Mini-Card or fanned stack for paired photos
/// in the Folio Ephemera Overlay Layer without obstructing text lines.
class FolioPolaroidMiniCard extends StatelessWidget {
  final List<FolioPhotoAttachment> photos;
  final MediaSandboxService? mediaService;
  final ShanshuiRealm atmosphereRealm;
  final bool hasCustomPosition;
  final VoidCallback? onTap;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final VoidCallback? onReset;
  final VoidCallback? onHide;

  const FolioPolaroidMiniCard({
    super.key,
    required this.photos,
    this.mediaService,
    this.atmosphereRealm = ShanshuiRealm.nature,
    this.hasCustomPosition = false,
    this.onTap,
    this.onPanUpdate,
    this.onPanEnd,
    this.onReset,
    this.onHide,
  });

  static const double cardWidth = 72.0;
  static const double cardHeight = 94.0;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();

    final activePhoto = photos.first;
    final photoCount = photos.length;

    return Semantics(
      label: '随文微笺 · ${activePhoto.title}',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onPanUpdate: onPanUpdate,
        onPanEnd: (details) {
          HapticFeedback.selectionClick();
          onPanEnd?.call(details);
        },
        child: SizedBox(
          width: cardWidth + (photoCount > 1 ? 10.0 : 0.0),
          height: cardHeight + (photoCount > 1 ? 8.0 : 0.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Underneath fanned leaves for multi-photo stack (N = 2, 3)
              if (photoCount >= 3)
                Positioned(
                  left: 6,
                  top: 4,
                  child: Transform.rotate(
                    angle: 0.08,
                    child: _buildBackgroundCardShell(photos[2]),
                  ),
                ),
              if (photoCount >= 2)
                Positioned(
                  left: 3,
                  top: 2,
                  child: Transform.rotate(
                    angle: -0.025,
                    child: _buildBackgroundCardShell(photos[1]),
                  ),
                ),

              // Top active card
              Transform.rotate(
                angle: -0.055,
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: _buildFrontCard(activePhoto),
                      ),
                      // Gold washi tape at top
                      const Positioned(
                        top: -5,
                        left: 18,
                        child: GoldWashiTapeWidget(),
                      ),
                      // Antique brass paperclip holding stack
                      const Positioned(
                        top: -10,
                        left: 12,
                        child: SizedBox(
                          width: 14,
                          height: 26,
                          child: CustomPaint(
                            key: Key('folio_polaroid_paperclip'),
                            painter: AntiqueBrassPaperclipPainter(),
                          ),
                        ),
                      ),
                      // Hide button (✕)
                      Positioned(
                        top: -6,
                        left: -6,
                        child: _buildHideButton(),
                      ),
                      // Snap-back reset button (↺)
                      if (hasCustomPosition)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: _buildResetButton(),
                        ),
                      // Stack count pill if multi-photo (e.g. 1/3)
                      if (photoCount > 1)
                        Positioned(
                          right: 4,
                          bottom: 22,
                          child: _buildCounterBadge(photoCount),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard(FolioPhotoAttachment photo) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: const Color(0xFF8C7355).withValues(alpha: 0.55),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPhotoThumbnail(photo),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        'P${photo.pageNumber}',
                        style: const TextStyle(
                          fontSize: 7.5,
                          fontFamily: 'monospace',
                          color: Color(0xFFFDE68A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            photo.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B241D),
              height: 1.1,
            ),
          ),
          const Text(
            '✥ 拖拽 / 点展读',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 7.0,
              color: Color(0xFF8C7A6B),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCardShell(FolioPhotoAttachment photo) {
    return Container(
      width: cardWidth,
      height: cardHeight,
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFE0),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: const Color(0xFF8C7355).withValues(alpha: 0.40),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(1, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: _buildPhotoThumbnail(photo),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(FolioPhotoAttachment photo) {
    final directFile = !MediaSandboxService.isStrictlyRelative(photo.relativePath)
        ? File(photo.relativePath)
        : null;

    if (directFile != null && directFile.existsSync()) {
      return Image.file(
        directFile,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackPainter(),
      );
    }

    if (mediaService != null) {
      return FutureBuilder<File>(
        future: mediaService!.getFileFromRelativePath(photo.relativePath),
        builder: (context, snapshot) {
          final file = snapshot.data;
          if (file != null && file.existsSync()) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallbackPainter(),
            );
          }
          return _buildFallbackPainter();
        },
      );
    }

    return _buildFallbackPainter();
  }

  Widget _buildFallbackPainter() {
    return CustomPaint(
      painter: FolioShanshuiArtPainter(
        realm: atmosphereRealm,
        isDark: false,
      ),
    );
  }

  Widget _buildHideButton() {
    return Semantics(
      button: true,
      label: '隐藏微笺',
      child: GestureDetector(
        key: const Key('folio_polaroid_hide_button'),
        onTap: () {
          HapticFeedback.lightImpact();
          onHide?.call();
        },
        child: Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF292524),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white70, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: const Text(
            '✕',
            style: TextStyle(
              fontSize: 9,
              color: Colors.white,
              height: 1.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return Semantics(
      button: true,
      label: '归位微笺',
      child: GestureDetector(
        key: const Key('folio_polaroid_reset_button'),
        onTap: () {
          HapticFeedback.mediumImpact();
          onReset?.call();
        },
        child: Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFB45309),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFDE68A), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: const Text(
            '↺',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              height: 1.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounterBadge(int totalCount) {
    return Container(
      key: const Key('folio_polaroid_counter_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xE6292524),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 0.7,
        ),
      ),
      child: Text(
        '1/$totalCount',
        style: const TextStyle(
          fontSize: 7.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFDE68A),
        ),
      ),
    );
  }
}
