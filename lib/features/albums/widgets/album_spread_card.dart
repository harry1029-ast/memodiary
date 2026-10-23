import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/cinnabar_seal_badge.dart';
import '../../../core/theme/widgets/ink_metadata_pill.dart';
import '../../../core/theme/widgets/xuan_paper_card.dart';
import '../models/album_spread.dart';
import 'album_collection_card.dart';
import 'sandboxed_album_image.dart';

/// Renders a single [AlbumSpread] page inside a tactile Xuan-paper card
/// with double-hairline literati framing, `agedFiber` surfaces, and Cinnabar seals.
class AlbumSpreadCard extends StatelessWidget {
  final AlbumSpread spread;
  final int totalPages;
  final MediaSandboxService mediaService;

  const AlbumSpreadCard({
    super.key,
    required this.spread,
    required this.totalPages,
    required this.mediaService,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;

    return XuanPaperCard(
      key: Key('album_spread_page_${spread.pageNumber}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(6),
      borderRadius: 14,
      backgroundColor: tokens.xuanPureLeaf,
      borderColor: tokens.deckleBorder,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: tokens.xuanPureLeaf,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: tokens.deckleBorder.withValues(alpha: 0.85),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: switch (spread) {
                final CoverSpread coverSpread =>
                  _buildCoverSpread(tokens, coverSpread),
                final SingleHeroSpread heroSpread =>
                  _buildSingleHeroSpread(tokens, heroSpread),
                final DuoSpread duoSpread => _buildDuoSpread(tokens, duoSpread),
                final QuadSpread quadSpread =>
                  _buildQuadSpread(tokens, quadSpread),
                final EpilogueSpread epilogueSpread =>
                  _buildEpilogueSpread(tokens, epilogueSpread),
              },
            ),
            const SizedBox(height: 10),
            _buildPageFooter(tokens),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverSpread(InkDiaryTokens tokens, CoverSpread coverSpread) {
    final dateLabel = AlbumCollectionCard.formatDateRange(
      coverSpread.startDate,
      coverSpread.endDate,
    );
    final destination = coverSpread.destinationTag;
    final description = coverSpread.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '旅行影像纪念册',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 11,
                      letterSpacing: 2.0,
                      color: tokens.qingmo,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    coverSpread.title,
                    key: const Key('spread_cover_title'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: tokens.jiaomo,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CinnabarSealBadge(
              key: const Key('spread_cover_seal'),
              text: destination != null && destination.isNotEmpty
                  ? destination
                  : '拾光',
              size: 40,
            ),
          ],
        ),
        const SizedBox(height: 10),
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              InkMetadataPill(
                icon: Icons.calendar_today_outlined,
                label: dateLabel,
                maxWidth: 190,
              ),
              InkMetadataPill(
                icon: Icons.photo_camera_outlined,
                label: '${coverSpread.photoCount} 帧光影',
                isAccent: coverSpread.photoCount > 0,
                maxWidth: 120,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: SandboxedAlbumImage(
            key: const Key('spread_cover_image'),
            relativePath: coverSpread.coverImagePath,
            mediaService: mediaService,
            cacheWidth: 960,
            borderRadius: 10,
            width: double.infinity,
            placeholderLabel: '山河入卷，静候留影',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: tokens.agedFiber,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: tokens.deckleBorder.withValues(alpha: 0.7),
              width: 0.8,
            ),
          ),
          child: Text(
            description != null && description.isNotEmpty
                ? description
                : '山河沿路，笔底留痕。将旅途帧帧光影凝于宣纸之上。',
            key: const Key('spread_cover_description'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 13,
              color: tokens.nongmo,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleHeroSpread(
    InkDiaryTokens tokens,
    SingleHeroSpread heroSpread,
  ) {
    final photo = heroSpread.photo;
    final caption = photo.caption?.trim();
    final location = photo.locationTag?.trim();
    final shotDateLabel = photo.shotAt != null
        ? DateFormat('yyyy.MM.dd HH:mm').format(photo.shotAt!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 7,
          child: SandboxedAlbumImage(
            key: Key('spread_hero_image_${photo.id}'),
            relativePath: photo.relativeImagePath,
            mediaService: mediaService,
            cacheWidth: 1200,
            borderRadius: 10,
            width: double.infinity,
          ),
        ),
        const SizedBox(height: 12),
        if ((location != null && location.isNotEmpty) || shotDateLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (location != null && location.isNotEmpty)
                    InkMetadataPill(
                      icon: Icons.place_outlined,
                      label: location,
                      isAccent: true,
                      maxWidth: 160,
                    ),
                  if (shotDateLabel != null)
                    InkMetadataPill(
                      icon: Icons.schedule_outlined,
                      label: shotDateLabel,
                      maxWidth: 160,
                    ),
                ],
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.agedFiber,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: tokens.deckleBorder.withValues(alpha: 0.7),
              width: 0.8,
            ),
          ),
          child: Text(
            caption != null && caption.isNotEmpty ? caption : '静观山水，未题片语。',
            key: Key('spread_hero_caption_${photo.id}'),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 13,
              color: caption != null && caption.isNotEmpty
                  ? tokens.jiaomo
                  : tokens.qingmo,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDuoSpread(InkDiaryTokens tokens, DuoSpread duoSpread) {
    final firstTile = _buildDuoPhotoCell(tokens, duoSpread.firstPhoto);
    final secondTile = _buildDuoPhotoCell(tokens, duoSpread.secondPhoto);

    if (duoSpread.orientation == DuoLayoutOrientation.sideBySide) {
      return Row(
        key: const Key('spread_duo_side_by_side'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: firstTile),
          const SizedBox(width: 12),
          Expanded(child: secondTile),
        ],
      );
    }

    return Column(
      key: const Key('spread_duo_stacked'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: firstTile),
        const SizedBox(height: 12),
        Expanded(child: secondTile),
      ],
    );
  }

  Widget _buildDuoPhotoCell(InkDiaryTokens tokens, AlbumPhoto photo) {
    final caption = photo.caption?.trim();
    final location = photo.locationTag?.trim();

    return Container(
      key: Key('spread_duo_cell_${photo.id}'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tokens.agedFiber.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tokens.deckleBorder.withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SandboxedAlbumImage(
              relativePath: photo.relativeImagePath,
              mediaService: mediaService,
              cacheWidth: 720,
              borderRadius: 8,
              width: double.infinity,
            ),
          ),
          if ((location != null && location.isNotEmpty) ||
              (caption != null && caption.isNotEmpty)) ...[
            const SizedBox(height: 8),
            if (location != null && location.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 13,
                    color: tokens.cinnabar,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tokens.nongmo,
                      ),
                    ),
                  ),
                ],
              ),
            if (caption != null && caption.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 12,
                  color: tokens.jiaomo,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildQuadSpread(InkDiaryTokens tokens, QuadSpread quadSpread) {
    final photos = quadSpread.photos;
    final topRowPhotos = photos.take(2).toList();
    final bottomRowPhotos = photos.skip(2).toList();

    return Column(
      key: const Key('spread_quad_grid'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildQuadCell(tokens, topRowPhotos[0])),
              const SizedBox(width: 10),
              Expanded(child: _buildQuadCell(tokens, topRowPhotos[1])),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildQuadCell(tokens, bottomRowPhotos[0])),
              const SizedBox(width: 10),
              Expanded(
                child: bottomRowPhotos.length > 1
                    ? _buildQuadCell(tokens, bottomRowPhotos[1])
                    : _buildQuadOrnamentCell(tokens),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuadCell(InkDiaryTokens tokens, AlbumPhoto photo) {
    final location = photo.locationTag?.trim();
    final caption = photo.caption?.trim();
    final badgeLabel = (location != null && location.isNotEmpty)
        ? location
        : (caption != null && caption.isNotEmpty ? caption : null);

    return Container(
      key: Key('spread_quad_cell_${photo.id}'),
      decoration: BoxDecoration(
        color: tokens.agedFiber,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tokens.deckleBorder.withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          SandboxedAlbumImage(
            relativePath: photo.relativeThumbnailPath,
            mediaService: mediaService,
            cacheWidth: 400,
            borderRadius: 7,
          ),
          if (badgeLabel != null)
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.jiaomo.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  badgeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuadOrnamentCell(InkDiaryTokens tokens) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.agedFiber.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tokens.deckleBorder.withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Center(
        child: CinnabarSealBadge.wash(
          text: '拾光',
          size: 36,
        ),
      ),
    );
  }

  Widget _buildEpilogueSpread(
    InkDiaryTokens tokens,
    EpilogueSpread epilogueSpread,
  ) {
    final route = epilogueSpread.routeSummary;

    return Container(
      key: const Key('spread_epilogue_container'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: tokens.agedFiber.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tokens.deckleBorder.withValues(alpha: 0.75),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '卷末回望',
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 12,
              letterSpacing: 3.0,
              color: tokens.qingmo,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            epilogueSpread.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: tokens.jiaomo,
            ),
          ),
          const SizedBox(height: 16),
          if (route != null && route.isNotEmpty) ...[
            Container(
              key: const Key('spread_epilogue_route'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.xuanPureLeaf,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.deckleBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.route_outlined,
                    size: 16,
                    color: tokens.cinnabar,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      route,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.nongmo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            '共收录 ${epilogueSpread.totalPhotos} 帧旅途影像'
            '${epilogueSpread.totalLocations > 0 ? " · 途经 ${epilogueSpread.totalLocations} 处行迹" : ""}',
            key: const Key('spread_epilogue_stats'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 13,
              color: tokens.danmo,
            ),
          ),
          const SizedBox(height: 24),
          CinnabarSealBadge(
            key: const Key('spread_epilogue_seal'),
            text: epilogueSpread.sealText,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            '拾光日记 · 岁时留痕',
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 11,
              color: tokens.qingmo,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageFooter(InkDiaryTokens tokens) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '云笺影卷',
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontNotoSerif,
            fontSize: 10,
            color: tokens.qingmo,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          '— ${spread.pageNumber} / $totalPages —',
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontLiterata,
            fontSize: 11,
            color: tokens.danmo,
          ),
        ),
      ],
    );
  }
}

