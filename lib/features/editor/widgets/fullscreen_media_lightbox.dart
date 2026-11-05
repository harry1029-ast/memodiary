import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../domain/stationery_sheet_descriptor.dart';
import 'lightbox_caption_strip.dart';
import 'sandboxed_video_player.dart';

/// Immersive, distraction-free Fullscreen Lightbox viewer with pinch-to-zoom,
/// multi-photo carousel swiping, and video playback controls.
///
/// The lightbox is the only place a media attachment's caption is edited
/// (legacy inline-embed captions live in the Delta and are not covered here).
/// Captions are editable when [onCaptionChanged] is provided, else read-only.
class FullscreenMediaLightbox extends StatefulWidget {
  final List<SheetMediaItem> items;
  final int initialIndex;
  final MediaSandboxService mediaSandboxService;
  final void Function(String mediaId, String newCaption)? onCaptionChanged;

  FullscreenMediaLightbox({
    super.key,
    SheetMediaItem? item,
    List<SheetMediaItem>? items,
    this.initialIndex = 0,
    required this.mediaSandboxService,
    this.onCaptionChanged,
  }) : items = items ?? (item != null ? [item] : const <SheetMediaItem>[]);

  /// Displays the [FullscreenMediaLightbox] as an accessible full-screen modal dialog.
  static Future<void> show(
    BuildContext context, {
    SheetMediaItem? item,
    List<SheetMediaItem>? items,
    int initialIndex = 0,
    required MediaSandboxService mediaSandboxService,
    void Function(String mediaId, String newCaption)? onCaptionChanged,
  }) {
    final effectiveItems = items ?? (item != null ? [item] : const <SheetMediaItem>[]);
    if (effectiveItems.isEmpty) return Future.value();

    return showDialog<void>(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.90),
      builder: (dialogContext) => FullscreenMediaLightbox(
        items: effectiveItems,
        initialIndex: initialIndex.clamp(0, effectiveItems.length - 1),
        mediaSandboxService: mediaSandboxService,
        onCaptionChanged: onCaptionChanged,
      ),
    );
  }

  @override
  State<FullscreenMediaLightbox> createState() => _FullscreenMediaLightboxState();
}

class _FullscreenMediaLightboxState extends State<FullscreenMediaLightbox> {
  late PageController _pageController;
  late int _currentIndex;

  /// Captions saved while this lightbox is open, keyed by media id, so the
  /// strip shows the new text without waiting for the caller to rebuild.
  final Map<String, String> _savedCaptions = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _saveCaption(String mediaId, String newCaption) {
    setState(() => _savedCaptions[mediaId] = newCaption);
    widget.onCaptionChanged?.call(mediaId, newCaption);
  }

  Future<File> _resolveMediaFile(MediaSandboxService service, String rawPath) async {
    if (rawPath.isNotEmpty && !MediaSandboxService.isStrictlyRelative(rawPath)) {
      return File(rawPath);
    }
    return service.getFileFromRelativePath(rawPath);
  }

  Widget _buildMediaPage(SheetMediaItem item) {
    return FutureBuilder<File>(
      future: _resolveMediaFile(widget.mediaSandboxService, item.relativePath),
      builder: (futureContext, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.white70));
        }
        final mediaFile = snapshot.data!;

        if (item.mediaType == EphemeraMediaType.video) {
          return Center(
            child: SandboxedVideoPlayer(
              videoFile: mediaFile,
              autoPlay: true,
            ),
          );
        }

        return InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.5,
          child: Center(
            child: Image.file(
              mediaFile,
              fit: BoxFit.contain,
              errorBuilder: (imageContext, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image_outlined, size: 48, color: Colors.white54),
                      const SizedBox(height: 8),
                      Text(
                        item.relativePath,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeItem = widget.items[_currentIndex];
    final totalCount = widget.items.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Center media content (single or multi-item PageView)
            if (totalCount == 1)
              _buildMediaPage(activeItem)
            else
              PageView.builder(
                controller: _pageController,
                itemCount: totalCount,
                onPageChanged: (pageIndex) => setState(() => _currentIndex = pageIndex),
                itemBuilder: (context, pageIndex) => _buildMediaPage(widget.items[pageIndex]),
              ),

            // Top navigation bar with counter and close button
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB83B2E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          activeItem.mediaType == EphemeraMediaType.video ? '随文短影' : '随文影札',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (totalCount > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / $totalCount',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    key: const Key('fullscreen_lightbox_close_button'),
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    tooltip: '关闭 · Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Bottom caption strip (the single caption editor)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: LightboxCaptionStrip(
                key: ValueKey('lightbox_caption_strip_${activeItem.id}'),
                caption: _savedCaptions[activeItem.id] ?? activeItem.caption,
                onSave: widget.onCaptionChanged == null ? null : (newCaption) => _saveCaption(activeItem.id, newCaption),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
