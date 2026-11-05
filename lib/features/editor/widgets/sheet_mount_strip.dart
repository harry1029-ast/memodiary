import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../domain/stationery_sheet_descriptor.dart';
import 'desk_media_control.dart';
import 'keepsake_thumbnail.dart';

/// The Sheet Mount Strip (本页影札栏): up to three photos or videos mounted on one
/// Stationery Sheet, shown outside its Paper Heart in mount order so mounting
/// never changes the sheet's line capacity. Renders nothing when empty.
///
/// Each item carries a ↩ that Unmounts it back to the Staging Handscroll; the
/// strip has no delete control. Every tick of [refusalSignal] shakes the strip
/// to say the sheet is full.
class SheetMountStrip extends StatelessWidget {
  final List<SheetMediaItem> items;
  final MediaSandboxService mediaSandboxService;
  final ValueChanged<SheetMediaItem>? onTapItem;
  final ValueChanged<SheetMediaItem>? onUnmountItem;
  final ValueListenable<int>? refusalSignal;
  final bool isPaperDark;

  /// Edge of each square mounted print; above the 44px touch target.
  static const double kItemExtent = 64.0;

  /// Edge of the ↩ touch target beneath each print.
  static const double kControlExtent = DeskMediaControl.kExtent;

  /// Total strip height: print plus its ↩ control.
  static const double kStripHeight = kItemExtent + kControlExtent;

  const SheetMountStrip({
    super.key,
    required this.items,
    required this.mediaSandboxService,
    this.onTapItem,
    this.onUnmountItem,
    this.refusalSignal,
    this.isPaperDark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final palette = DeskMediaPalette(isPaperDark: isPaperDark);

    final strip = Semantics(
      container: true,
      label: '本页影札栏 · ${items.length} 影',
      child: Row(
        key: const Key('sheet_mount_strip'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (itemIndex, item) in items.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
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
                          color: palette.matte,
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(color: palette.matteBorder, width: 0.8),
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
                  DeskMediaControl(
                    key: Key('mount_strip_unmount_${item.id}'),
                    icon: Icons.undo,
                    isPaperDark: isPaperDark,
                    semanticLabel: '揭回画卷：本页第 ${itemIndex + 1} 影 · '
                        '${item.mediaType == EphemeraMediaType.video ? '短影' : '影札'}',
                    onPressed: () => onUnmountItem?.call(item),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    final signal = refusalSignal;
    if (signal == null) return strip;
    return _ShakeOnSignal(signal: signal, child: strip);
  }
}

/// Shakes [child] sideways once per change of [signal] (skipped with reduce-motion).
class _ShakeOnSignal extends StatefulWidget {
  final ValueListenable<int> signal;
  final Widget child;

  const _ShakeOnSignal({required this.signal, required this.child});

  @override
  State<_ShakeOnSignal> createState() => _ShakeOnSignalState();
}

class _ShakeOnSignalState extends State<_ShakeOnSignal> with SingleTickerProviderStateMixin {
  static const double kAmplitude = 8.0;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    widget.signal.addListener(_onSignal);
  }

  @override
  void didUpdateWidget(_ShakeOnSignal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signal != widget.signal) {
      oldWidget.signal.removeListener(_onSignal);
      widget.signal.addListener(_onSignal);
    }
  }

  void _onSignal() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _shake.forward(from: 0.0);
  }

  @override
  void dispose() {
    widget.signal.removeListener(_onSignal);
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (animatedContext, child) {
        final progress = _shake.value;
        final dx = math.sin(progress * math.pi * 6) * kAmplitude * (1.0 - progress);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
