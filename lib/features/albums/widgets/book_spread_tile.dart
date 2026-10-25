import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/cinnabar_seal_badge.dart';
import '../models/album_studio_models.dart';
import 'interactive_canvas/album_page_canvas.dart';
import 'sandboxed_album_image.dart';

/// Renders an open 2-page facing photobook spread in `AlbumBookOverviewScreen`
/// (matching Journi Image 10).
///
/// Features a realistic central spine crease shadow, subtle paper deckle borders,
/// page numbering labels, and live non-interactive `AlbumPageCanvas` thumbnails.
class BookSpreadTile extends StatelessWidget {
  final int spreadIndex;
  final AlbumCollection collection;
  final bool isCoverLeft;
  final AlbumPageModel? leftPage;
  final int? leftPageIndex;
  final AlbumPageModel? rightPage;
  final int? rightPageIndex;
  final Map<String, AlbumPhoto> photoById;
  final MediaSandboxService mediaService;
  final ValueChanged<int> onTapPage;
  final VoidCallback? onAddBlankPage;

  const BookSpreadTile({
    super.key,
    required this.spreadIndex,
    required this.collection,
    this.isCoverLeft = false,
    this.leftPage,
    this.leftPageIndex,
    this.rightPage,
    this.rightPageIndex,
    required this.photoById,
    required this.mediaService,
    required this.onTapPage,
    this.onAddBlankPage,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final leftLabel = isCoverLeft
        ? '封面 · Cover'
        : (leftPage != null ? 'Page ${leftPage!.pageNumber}' : '');
    final rightLabel = rightPage != null
        ? 'Page ${rightPage!.pageNumber}'
        : '卷尾留白 · Endpaper';

    return Column(
      key: Key('book_spread_tile_$spreadIndex'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Open 2-page book spread container
        AspectRatio(
          aspectRatio: 1.96,
          child: Container(
            decoration: BoxDecoration(
              color: tokens.xuanPureLeaf,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: tokens.deckleBorder,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: tokens.jiaomo.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Leaf
                      Expanded(
                        child: isCoverLeft
                            ? _buildCoverLeaf(tokens)
                            : (leftPage != null && leftPageIndex != null)
                                ? _buildPageLeaf(
                                    page: leftPage!,
                                    pageIndex: leftPageIndex!,
                                  )
                                : _buildEndpaperLeaf(tokens),
                      ),
                      // Right Leaf
                      Expanded(
                        child: (rightPage != null && rightPageIndex != null)
                            ? _buildPageLeaf(
                                page: rightPage!,
                                pageIndex: rightPageIndex!,
                              )
                            : _buildEndpaperLeaf(tokens),
                      ),
                    ],
                  ),

                  // Central Book Spine Crease Shadow
                  Center(
                    child: IgnorePointer(
                      child: Container(
                        key: Key('spread_spine_crease_$spreadIndex'),
                        width: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.0),
                              Colors.black.withValues(alpha: 0.09),
                              Colors.black.withValues(alpha: 0.22),
                              Colors.white.withValues(alpha: 0.14),
                              Colors.black.withValues(alpha: 0.06),
                              Colors.black.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.35, 0.50, 0.54, 0.70, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Page Number Captions under Left and Right Leaves
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  leftLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: tokens.danmo,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  rightLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: tokens.danmo,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverLeaf(InkDiaryTokens tokens) {
    final destination = collection.destinationTag?.trim();

    return Container(
      key: const Key('spread_cover_leaf'),
      padding: const EdgeInsets.all(12),
      color: tokens.xuanGround,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (collection.coverImagePath != null &&
              collection.coverImagePath!.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SandboxedAlbumImage(
                  relativePath: collection.coverImagePath,
                  mediaService: mediaService,
                  cacheWidth: 240,
                  borderRadius: 4,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Icon(
                Icons.auto_stories_outlined,
                size: 28,
                color: tokens.cinnabar.withValues(alpha: 0.75),
              ),
            ),
          Text(
            collection.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: tokens.jiaomo,
            ),
          ),
          if (destination != null && destination.isNotEmpty) ...[
            const SizedBox(height: 4),
            CinnabarSealBadge.compact(
              text: destination,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageLeaf({
    required AlbumPageModel page,
    required int pageIndex,
  }) {
    return GestureDetector(
      key: Key('spread_page_tile_$pageIndex'),
      behavior: HitTestBehavior.opaque,
      onTap: () => onTapPage(pageIndex),
      child: AlbumPageCanvas(
        page: page,
        photoById: photoById,
        mediaService: mediaService,
        isInteractive: false,
      ),
    );
  }

  Widget _buildEndpaperLeaf(InkDiaryTokens tokens) {
    return Container(
      color: tokens.agedFiber.withValues(alpha: 0.55),
      child: Center(
        child: onAddBlankPage != null
            ? InkWell(
                key: const Key('spread_add_trailing_page_button'),
                onTap: onAddBlankPage,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 22,
                        color: tokens.danmo,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '新增书页',
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontNotoSerif,
                          fontSize: 11,
                          color: tokens.danmo,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Text(
                '拾光印记',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 11,
                  color: tokens.qingmo,
                ),
              ),
      ),
    );
  }
}

