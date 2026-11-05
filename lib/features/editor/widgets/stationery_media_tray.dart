import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../../timeline/widgets/folio/folio_silk_corner_mounts_painter.dart';
import '../domain/stationery_sheet_descriptor.dart';

/// Tactile lower Media & Keepsake Tray presenting up to 3 attached photos/videos
/// in a horizontal snap-deck styled with paper-toned matte borders and classical silk corners.
class StationeryMediaTray extends StatefulWidget {
  final List<SheetMediaItem> items;
  final MediaSandboxService mediaSandboxService;
  final ValueChanged<SheetMediaItem>? onTapMedia;
  final ValueChanged<String>? onDeleteItem;
  final bool isPaperDark;
  final Color? inkColor;

  const StationeryMediaTray({
    super.key,
    required this.items,
    required this.mediaSandboxService,
    this.onTapMedia,
    this.onDeleteItem,
    this.isPaperDark = false,
    this.inkColor,
  });

  @override
  State<StationeryMediaTray> createState() => _StationeryMediaTrayState();
}

class _StationeryMediaTrayState extends State<StationeryMediaTray> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = widget.isPaperDark;
    final dotActiveColor = isDark ? const Color(0xFFC8A055) : const Color(0xFFB83B2E);
    final dotInactiveColor = isDark ? Colors.white24 : Colors.black12;

    return Semantics(
      label: '随文影札匣 · Media Keepsake Tray',
      container: true,
      child: Column(
        key: const Key('stationery_media_tray_content'),
        mainAxisSize: MainAxisSize.min,
        children: [
          // Horizontal snap-scrolling card deck
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              physics: const PageScrollPhysics(),
              onPageChanged: (pageIndex) {
                setState(() => _currentPage = pageIndex);
              },
              itemBuilder: (itemContext, itemIndex) {
                final item = widget.items[itemIndex];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                  child: _buildMediaCard(item, itemIndex),
                );
              },
            ),
          ),

          // Pagination indicator dots when multiple keepsakes exist
          if (widget.items.length > 1) ...[
            const SizedBox(height: 4),
            Row(
              key: const Key('media_tray_indicator_dots'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.items.length,
                (dotIndex) => Container(
                  key: Key('media_tray_dot_$dotIndex'),
                  width: dotIndex == _currentPage ? 14 : 6,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    color: dotIndex == _currentPage ? dotActiveColor : dotInactiveColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaCard(SheetMediaItem item, int index) {
    final isDark = widget.isPaperDark;
    final matteColor = isDark ? const Color(0xFF1E1D1B) : const Color(0xFFFBF8F1);
    final borderColor = isDark ? const Color(0x33FFFFFF) : const Color(0x1F000000);
    final silkColor = isDark ? const Color(0xD0C8A055) : const Color(0xC0DFC898);
    final textInk = widget.inkColor ?? (isDark ? const Color(0xFFD6D1C7) : const Color(0xFF3C3836));

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        key: Key('media_tray_card_${item.id}'),
        decoration: BoxDecoration(
          color: matteColor,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: borderColor, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (cardContext, constraints) {
            final hasVerticalRoomForCaption = constraints.maxHeight >= 60.0;

            return Stack(
              children: [
                // Card Body: Media Preview + Caption Strip
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onTapMedia?.call(item),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4.0),
                                child: FutureBuilder<File>(
                                  future: _resolveMediaFile(widget.mediaSandboxService, item.relativePath),
                                  builder: (futureContext, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Container(color: isDark ? Colors.black26 : Colors.black12);
                                    }
                                    final file = snapshot.data!;
                                    if (item.mediaType == EphemeraMediaType.video) {
                                      return _buildVideoThumbnail(file, isDark);
                                    }
                                    return Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                      errorBuilder: (imageContext, error, stackTrace) {
                                        return Container(
                                          color: isDark ? Colors.black26 : Colors.black12,
                                          child: const Center(
                                            child: Icon(Icons.image_not_supported_outlined, size: 28),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Classical Silk Corner Mounts
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: FolioSilkCornerMountsPainter(
                                    silkColor: silkColor,
                                    size: 13.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Caption Strip
                    if (hasVerticalRoomForCaption)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.caption.trim(),
                                key: Key('media_tray_caption_${item.id}'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11.5, color: textInk),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Semantics(
                              label: '删除此随文影札',
                              button: true,
                              child: IconButton(
                                key: Key('media_tray_delete_${item.id}'),
                                icon: const Icon(Icons.delete_outline, size: 17),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                color: isDark ? const Color(0xFFE57373) : const Color(0xFFB83B2E),
                                tooltip: '删除影札',
                                onPressed: () => widget.onDeleteItem?.call(item.id),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(File file, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF101010) : const Color(0xFF202020),
      child: const Center(
        child: Icon(Icons.play_circle_fill, size: 36, color: Colors.white70),
      ),
    );
  }

  Future<File> _resolveMediaFile(MediaSandboxService service, String rawPath) async {
    if (rawPath.isNotEmpty && !MediaSandboxService.isStrictlyRelative(rawPath)) {
      return File(rawPath);
    }
    return service.getFileFromRelativePath(rawPath);
  }
}
