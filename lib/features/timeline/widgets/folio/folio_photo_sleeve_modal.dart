import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/services/media_sandbox_service.dart';
import '../../../editor/domain/stationery_sheet_descriptor.dart';
import '../../../editor/widgets/fullscreen_media_lightbox.dart';
import '../../../scenery/models/shanshui_atmosphere.dart';
import 'folio_leaf_model.dart';
import 'folio_reading_perspective.dart';
import 'folio_shanshui_art_painter.dart';

/// Photo Sleeve Overview Modal (画匣总览).
///
/// Displays a visual reel of all photos attached across the diary entry,
/// allowing one-tap jump navigation to the corresponding content page or
/// opening the Fullscreen Lightbox for high-resolution inspection.
class FolioPhotoSleeveModal extends StatelessWidget {
  final String entryTitle;
  final List<FolioPhotoAttachment> photos;
  final FolioSubstrateTheme theme;
  final MediaSandboxService? mediaService;
  final ValueChanged<int>? onJumpToPage;
  final ValueChanged<FolioPhotoAttachment>? onPhotoTap;

  const FolioPhotoSleeveModal({
    super.key,
    required this.entryTitle,
    required this.photos,
    required this.theme,
    this.mediaService,
    this.onJumpToPage,
    this.onPhotoTap,
  });

  /// Displays the Photo Sleeve Overview Modal as a centered scholar dialog.
  static Future<void> show({
    required BuildContext context,
    required String entryTitle,
    required List<FolioPhotoAttachment> photos,
    required FolioSubstrateTheme theme,
    MediaSandboxService? mediaService,
    ValueChanged<int>? onJumpToPage,
    ValueChanged<FolioPhotoAttachment>? onPhotoTap,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (dialogContext) => FolioPhotoSleeveModal(
        entryTitle: entryTitle,
        photos: photos,
        theme: theme,
        mediaService: mediaService,
        onJumpToPage: onJumpToPage,
        onPhotoTap: onPhotoTap,
      ),
    );
  }

  void _handleLightboxOpen(BuildContext context, FolioPhotoAttachment photo) {
    if (onPhotoTap != null) {
      onPhotoTap!(photo);
      return;
    }
    if (mediaService != null) {
      final sheetItem = SheetMediaItem(
        id: photo.id,
        mediaType: photo.mediaType,
        relativePath: photo.relativePath,
        caption: photo.caption,
      );
      FullscreenMediaLightbox.show(
        context,
        item: sheetItem,
        mediaSandboxService: mediaService!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = entryTitle.isNotEmpty ? entryTitle : '无题手稿';

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 580),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1917),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.50),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, titleText),
              const Divider(color: Color(0xFF292524), height: 20),
              Expanded(
                child: photos.isEmpty
                    ? _buildEmptyState()
                    : _buildPhotoGrid(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String titleText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🗂️ 拾光集锦匣 · 《$titleText》随文影札总览',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: Color(0xFFFEF3C7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '共收录 ${photos.length} 帧影札 · 点击可展读大图或跳至对应正文页',
                style: const TextStyle(
                  fontSize: 11.0,
                  color: Color(0xFFA8A29E),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: const Key('folio_sleeve_modal_close_button'),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '关闭画匣总览',
          icon: const Icon(Icons.close, size: 20, color: Color(0xFFA8A29E)),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        '此卷尚无随文影札',
        style: TextStyle(fontSize: 13, color: Color(0xFFA8A29E)),
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context) {
    return GridView.builder(
      key: const Key('folio_sleeve_photo_grid'),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.98,
      ),
      itemBuilder: (gridContext, index) {
        final photo = photos[index];
        return _buildPhotoCard(context, photo);
      },
    );
  }

  Widget _buildPhotoCard(BuildContext context, FolioPhotoAttachment photo) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF292524),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF44403C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: '放大展读影札 ${photo.title}',
              child: GestureDetector(
                key: Key('folio_sleeve_thumb_${photo.pageNumber}'),
                onTap: () => _handleLightboxOpen(context, photo),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: _buildThumbnail(photo),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'P${photo.pageNumber} · ${photo.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF5F5F4),
                  ),
                ),
              ),
              if (photo.date.isNotEmpty)
                Text(
                  photo.date,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: Color(0xFF78716C),
                  ),
                ),
            ],
          ),
          Text(
            photo.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFFA8A29E),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                key: Key('folio_sleeve_lightbox_${photo.pageNumber}'),
                onTap: () => _handleLightboxOpen(context, photo),
                child: const Text(
                  '🔍 放大展读',
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFCD34D),
                  ),
                ),
              ),
              GestureDetector(
                key: Key('folio_sleeve_jump_${photo.pageNumber}'),
                onTap: () {
                  Navigator.of(context).pop();
                  onJumpToPage?.call(photo.targetLeafIndex);
                },
                child: const Text(
                  '跳至该页 ➔',
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6EE7B7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(FolioPhotoAttachment photo) {
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
    return const CustomPaint(
      painter: FolioShanshuiArtPainter(
        realm: ShanshuiRealm.nature,
        isDark: true,
      ),
    );
  }
}
