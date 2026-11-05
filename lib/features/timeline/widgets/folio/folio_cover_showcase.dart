import 'package:flutter/material.dart';

import '../../../../core/services/media_sandbox_service.dart';
import '../../../editor/domain/stationery_sheet_descriptor.dart';
import 'folio_leaf_model.dart';
import 'folio_mounted_photo_tile.dart';
import 'folio_pocket_sleeve_container.dart';
import 'folio_reading_perspective.dart';
import 'folio_shanshui_art_painter.dart';
import 'folio_silk_corner_mounts_painter.dart';

/// Dynamic, adaptive cover showcase mounting diary photos into classical formats.
///
/// Adapts dynamically based on photo count $N$:
/// - $N = 1$ (单幅立轴画心): Full-height hero artwork with silk borders and brass washi tape.
/// - $N = 2$ (双屏对幅册页): Symmetrical 50/50 vertical diptych with `P1·上卷` and `P2·下卷`.
/// - $N = 3$ (三景斗方拼贴): Asymmetrical album collage (60% hero leaf + two 40% stacked mini-leaves).
/// - $N \ge 4$ (主景画心 + 拾光集锦匣): Top 60% hero artwork + bottom 40% stationery pocket sleeve.
class FolioCoverShowcase extends StatelessWidget {
  final FolioFrontispieceCoverLeaf leaf;
  final FolioSubstrateTheme theme;
  final MediaSandboxService? mediaService;
  final VoidCallback? onOpenSleeveModal;
  final ValueChanged<FolioPhotoAttachment>? onPhotoTap;

  const FolioCoverShowcase({
    super.key,
    required this.leaf,
    required this.theme,
    this.mediaService,
    this.onOpenSleeveModal,
    this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    final photos = leaf.photos.isNotEmpty
        ? leaf.photos
        : (leaf.heroPhotoPath != null && leaf.heroPhotoPath!.isNotEmpty
            ? [
                FolioPhotoAttachment(
                  id: 'hero',
                  relativePath: leaf.heroPhotoPath!,
                  mediaType: EphemeraMediaType.fromEmbedKey(leaf.heroMediaType ?? 'image'),
                  title: '随文画心',
                  caption: '随文影札 · 封面画心',
                  date: leaf.gregorianDate,
                  pageNumber: 1,
                  targetLeafIndex: 1,
                ),
              ]
            : <FolioPhotoAttachment>[]);
    final photoCount = photos.length;
    final accentColor = theme.isDark ? const Color(0xFFE07A6B) : const Color(0xFFB83B2E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                child: _buildAdaptiveMounting(context, photos, accentColor),
              ),
              Positioned(
                top: -8,
                child: _buildTopWashiTape(photoCount),
              ),
            ],
          ),
        ),
        if (photoCount > 1 && photoCount < 4) ...[
          const SizedBox(height: 8),
          _buildCompactSleeveBar(photoCount, accentColor),
        ],
      ],
    );
  }

  Widget _buildTopWashiTape(int photoCount) {
    final tapeText = switch (photoCount) {
      0 => '泥金和纸胶带 · 拾光·珍藏拓影',
      1 => '泥金和纸胶带 · 拾光·单幅立轴画心',
      2 => '泥金和纸胶带 · 拾光·双屏对幅册页',
      3 => '泥金和纸胶带 · 拾光·三景斗方册页',
      _ => '泥金和纸胶带 · 拾光·主景与藏影集锦匣',
    };

    return Transform.rotate(
      angle: -0.04,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xB8DEC183), Color(0xCCD2AD64), Color(0xADC8A055)],
          ),
          border: Border.symmetric(
            vertical: BorderSide(
              color: const Color(0xFFAA823C).withValues(alpha: 0.45),
            ),
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          tapeText,
          style: const TextStyle(
            fontSize: 8.5,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5A4418),
          ),
        ),
      ),
    );
  }

  Widget _buildAdaptiveMounting(
    BuildContext context,
    List<FolioPhotoAttachment> photos,
    Color accentColor,
  ) {
    if (photos.isEmpty) {
      return _buildZeroPhotoArtMount();
    } else if (photos.length == 1) {
      return _buildSingleHeroMount(context, photos[0]);
    } else if (photos.length == 2) {
      return _buildVerticalDiptychMount(context, photos[0], photos[1]);
    } else if (photos.length == 3) {
      return _buildAsymmetricalCollageMount(context, photos[0], photos[1], photos[2]);
    } else {
      return _buildPocketSleeveMount(context, photos, accentColor);
    }
  }

  Widget _buildZeroPhotoArtMount() {
    final silkColor = theme.isDark ? const Color(0xD0C8A055) : const Color(0xC0DFC898);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF141619) : const Color(0xFFFDFBF7),
        border: Border.all(color: const Color(0xFF8C7355).withValues(alpha: 0.35)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: FolioShanshuiArtPainter(
              realm: leaf.sceneryAtmosphere.realm,
              isDark: theme.isDark,
              atmosphere: leaf.sceneryAtmosphere,
            ),
          ),
          CustomPaint(painter: FolioSilkCornerMountsPainter(silkColor: silkColor)),
        ],
      ),
    );
  }

  Widget _buildSingleHeroMount(BuildContext context, FolioPhotoAttachment photo) {
    return FolioMountedPhotoTile(
      key: const Key('folio_cover_single_hero'),
      photo: photo,
      theme: theme,
      mediaService: mediaService,
      badgeText: 'P1 · 独幅立轴',
      showCaptionBar: true,
      isCenteredCaption: true,
      showAntiqueBrassPin: true,
      onTap: () => onPhotoTap?.call(photo),
      atmosphereRealm: leaf.sceneryAtmosphere.realm,
    );
  }

  Widget _buildVerticalDiptychMount(
    BuildContext context,
    FolioPhotoAttachment photo1,
    FolioPhotoAttachment photo2,
  ) {
    return Row(
      key: const Key('folio_cover_vertical_diptych'),
      children: [
        Expanded(
          child: FolioMountedPhotoTile(
            key: const Key('folio_cover_diptych_p1'),
            photo: photo1,
            theme: theme,
            mediaService: mediaService,
            badgeText: 'P1 · 上卷',
            showCaptionBar: true,
            showInnerShadow: true,
            onTap: () => onPhotoTap?.call(photo1),
            atmosphereRealm: leaf.sceneryAtmosphere.realm,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FolioMountedPhotoTile(
            key: const Key('folio_cover_diptych_p2'),
            photo: photo2,
            theme: theme,
            mediaService: mediaService,
            badgeText: 'P2 · 下卷',
            showCaptionBar: true,
            showInnerShadow: true,
            onTap: () => onPhotoTap?.call(photo2),
            atmosphereRealm: leaf.sceneryAtmosphere.realm,
          ),
        ),
      ],
    );
  }

  Widget _buildAsymmetricalCollageMount(
    BuildContext context,
    FolioPhotoAttachment heroPhoto,
    FolioPhotoAttachment photo2,
    FolioPhotoAttachment photo3,
  ) {
    return Row(
      key: const Key('folio_cover_asymmetrical_collage'),
      children: [
        Expanded(
          flex: 60,
          child: FolioMountedPhotoTile(
            key: const Key('folio_cover_collage_hero'),
            photo: heroPhoto,
            theme: theme,
            mediaService: mediaService,
            badgeText: 'P1 · 首卷主景',
            showCaptionBar: true,
            onTap: () => onPhotoTap?.call(heroPhoto),
            atmosphereRealm: leaf.sceneryAtmosphere.realm,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 40,
          child: Column(
            children: [
              Expanded(
                child: FolioMountedPhotoTile(
                  key: const Key('folio_cover_collage_p2'),
                  photo: photo2,
                  theme: theme,
                  mediaService: mediaService,
                  badgeText: 'P2 · 次卷',
                  showCaptionBar: false,
                  onTap: () => onPhotoTap?.call(photo2),
                  atmosphereRealm: leaf.sceneryAtmosphere.realm,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FolioMountedPhotoTile(
                  key: const Key('folio_cover_collage_p3'),
                  photo: photo3,
                  theme: theme,
                  mediaService: mediaService,
                  badgeText: 'P3 · 终卷',
                  showCaptionBar: false,
                  onTap: () => onPhotoTap?.call(photo3),
                  atmosphereRealm: leaf.sceneryAtmosphere.realm,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPocketSleeveMount(
    BuildContext context,
    List<FolioPhotoAttachment> photos,
    Color accentColor,
  ) {
    final heroPhoto = photos.first;

    return Column(
      key: const Key('folio_cover_pocket_sleeve_layout'),
      children: [
        Expanded(
          flex: 60,
          child: FolioMountedPhotoTile(
            key: const Key('folio_cover_pocket_hero'),
            photo: heroPhoto,
            theme: theme,
            mediaService: mediaService,
            badgeText: 'P1 · 卷首主景画心',
            showCaptionBar: true,
            onTap: () => onPhotoTap?.call(heroPhoto),
            atmosphereRealm: leaf.sceneryAtmosphere.realm,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          flex: 40,
          child: FolioPocketSleeveContainer(
            photos: photos,
            theme: theme,
            mediaService: mediaService,
            onTap: onOpenSleeveModal,
            atmosphereRealm: leaf.sceneryAtmosphere.realm,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSleeveBar(int photoCount, Color accentColor) {
    return GestureDetector(
      key: const Key('folio_cover_compact_sleeve_bar'),
      onTap: onOpenSleeveModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.06),
          border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🗂️ 拾光画匣 · 已收录 $photoCount 帧随文影札',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: theme.inkPrimary,
              ),
            ),
            Text(
              '展匣总览 ➔',
              style: TextStyle(
                fontSize: 10.0,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
