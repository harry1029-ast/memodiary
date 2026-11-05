import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../domain/stationery_sheet_descriptor.dart';
import 'keepsake_thumbnail.dart';

/// The Sheet Mount Strip (本页影札栏): up to three photos or videos mounted on one
/// Stationery Sheet, shown outside its Paper Heart in mount order so mounting
/// never changes the sheet's line capacity. Renders nothing when empty.
class SheetMountStrip extends StatelessWidget {
  final List<SheetMediaItem> items;
  final MediaSandboxService mediaSandboxService;
  final ValueChanged<SheetMediaItem>? onTapItem;
  final bool isPaperDark;

  /// Edge of each square mounted print; above the 44px touch target.
  static const double kItemExtent = 64.0;

  const SheetMountStrip({
    super.key,
    required this.items,
    required this.mediaSandboxService,
    this.onTapItem,
    this.isPaperDark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final matteColor = isPaperDark ? const Color(0xFF1E1D1B) : const Color(0xFFFBF8F1);
    final borderColor = isPaperDark ? const Color(0x33FFFFFF) : const Color(0x1F000000);

    return Semantics(
      container: true,
      label: '本页影札栏 · ${items.length} 影',
      child: Row(
        key: const Key('sheet_mount_strip'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (itemIndex, item) in items.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Semantics(
                button: true,
                label: '本页影札 · 第 ${itemIndex + 1} 影，点按查看',
                excludeSemantics: true,
                child: GestureDetector(
                  key: Key('mount_strip_item_${item.id}'),
                  onTap: () => onTapItem?.call(item),
                  child: Container(
                    width: kItemExtent,
                    height: kItemExtent,
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      color: matteColor,
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: borderColor, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isPaperDark ? 0.35 : 0.08),
                          blurRadius: 6.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2.0),
                      child: KeepsakeThumbnail(
                        item: item,
                        mediaSandboxService: mediaSandboxService,
                        isPaperDark: isPaperDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
