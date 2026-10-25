import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/media_sandbox_service.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../sandboxed_album_image.dart';

/// Studio bottom drawer displaying photos currently placed in the `'Removed'`
/// holding tray (`removedPhotoIds`).
///
/// Tapping or dragging any photo onto the page canvas restores it and
/// automatically upgrades the page layout from `N` to `N + 1` slots.
class RemovedPhotosDrawer extends StatelessWidget {
  final List<String> removedPhotoIds;
  final Map<String, AlbumPhoto> photoById;
  final MediaSandboxService mediaService;
  final ValueChanged<String> onRestorePhoto;
  final VoidCallback onClose;

  const RemovedPhotosDrawer({
    super.key,
    required this.removedPhotoIds,
    required this.photoById,
    required this.mediaService,
    required this.onRestorePhoto,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;

    return Container(
      key: const Key('studio_removed_photos_drawer'),
      height: 210,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: tokens.xuanPureLeaf,
        border: Border(
          top: BorderSide(color: tokens.deckleBorder, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: tokens.cinnabar,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '暂存相册 · Removed (${removedPhotoIds.length})',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: tokens.jiaomo,
                  ),
                ),
              ),
              IconButton(
                key: const Key('close_removed_drawer_button'),
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.expand_more, color: tokens.danmo),
                tooltip: '收起面板',
                onPressed: onClose,
              ),
            ],
          ),
          Text(
            '点击或拖拽照片即可放回当前书页，版式将自动适配 (N → N+1)',
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 11.5,
              color: tokens.danmo,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: removedPhotoIds.isEmpty
                ? Center(
                    child: Text(
                      '暂无移出的照片，所有影像均已排入书页中',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 13,
                        color: tokens.qingmo,
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: removedPhotoIds.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final photoId = removedPhotoIds[index];
                      final photo = photoById[photoId];
                      return _buildTrayThumbnail(tokens, photoId, photo);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrayThumbnail(
    InkDiaryTokens tokens,
    String photoId,
    AlbumPhoto? photo,
  ) {
    final card = InkWell(
      key: Key('removed_tray_item_$photoId'),
      onTap: () => onRestorePhoto(photoId),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 96,
        decoration: BoxDecoration(
          color: tokens.agedFiber,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.deckleBorder),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SandboxedAlbumImage(
                relativePath: photo?.relativeThumbnailPath,
                mediaService: mediaService,
                cacheWidth: 240,
                borderRadius: 0,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.jiaomo.withValues(alpha: 0.76),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(7),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 12, color: Colors.white),
                    SizedBox(width: 2),
                    Text(
                      '放回本页',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 10.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return LongPressDraggable<String>(
      data: photoId,
      hapticFeedbackOnStart: true,
      feedback: Material(
        color: Colors.transparent,
        elevation: 8,
        child: SizedBox(
          width: 84,
          height: 84,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SandboxedAlbumImage(
              relativePath: photo?.relativeThumbnailPath,
              mediaService: mediaService,
              cacheWidth: 240,
              borderRadius: 8,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      child: card,
    );
  }
}

