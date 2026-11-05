import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../domain/stationery_sheet_descriptor.dart';
import 'fullscreen_media_lightbox.dart';
import 'sheet_mount_strip.dart';
import 'staging_handscroll.dart';

/// The desk area beneath the active Stationery Sheet: that sheet's Sheet Mount
/// Strip, then the entry-wide Staging Handscroll. Tapping any item opens the
/// fullscreen lightbox; mount and erase bubble up through callbacks.
class EditorDeskMediaArea extends StatelessWidget {
  final List<SheetMediaItem> mountedItems;
  final List<SheetMediaItem> stagedItems;
  final MediaSandboxService mediaSandboxService;

  /// 1-based number of the active Stationery Sheet.
  final int activeSheetNumber;
  final bool isPaperDark;
  final ValueChanged<String>? onMountMedia;
  final ValueChanged<String>? onEraseMedia;
  final void Function(String mediaId, String newCaption)? onCaptionChanged;

  static const double kStripHeight = 72.0;
  static const double kHandscrollMinHeight = 100.0;
  static const double kGap = 8.0;

  const EditorDeskMediaArea({
    super.key,
    required this.mountedItems,
    required this.stagedItems,
    required this.mediaSandboxService,
    required this.activeSheetNumber,
    this.isPaperDark = false,
    this.onMountMedia,
    this.onEraseMedia,
    this.onCaptionChanged,
  });

  bool get isEmpty => mountedItems.isEmpty && stagedItems.isEmpty;

  void _openLightbox(BuildContext context, List<SheetMediaItem> items, SheetMediaItem item) {
    FullscreenMediaLightbox.show(
      context,
      items: items,
      initialIndex: items.indexOf(item),
      mediaSandboxService: mediaSandboxService,
      onCaptionChanged: onCaptionChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (layoutContext, constraints) {
        final stripBlock = mountedItems.isEmpty ? 0.0 : kStripHeight + kGap;
        final handscrollHeight = math.max(
          kHandscrollMinHeight,
          constraints.maxHeight - stripBlock,
        );
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mountedItems.isNotEmpty) ...[
                SizedBox(
                  height: kStripHeight,
                  child: Center(
                    child: SheetMountStrip(
                      items: mountedItems,
                      mediaSandboxService: mediaSandboxService,
                      isPaperDark: isPaperDark,
                      onTapItem: (item) => _openLightbox(context, mountedItems, item),
                    ),
                  ),
                ),
                const SizedBox(height: kGap),
              ],
              if (stagedItems.isNotEmpty)
                SizedBox(
                  height: handscrollHeight,
                  child: StagingHandscroll(
                    items: stagedItems,
                    mediaSandboxService: mediaSandboxService,
                    activeSheetNumber: activeSheetNumber,
                    isPaperDark: isPaperDark,
                    onTapItem: (item) => _openLightbox(context, stagedItems, item),
                    onMountItem: (item) => onMountMedia?.call(item.id),
                    onEraseItem: (item) => onEraseMedia?.call(item.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
