import 'package:flutter/material.dart';

import '../../../../core/services/media_sandbox_service.dart';
import '../../domain/stationery_sheet_descriptor.dart';
import '../desk_media_control.dart';
import '../fullscreen_media_lightbox.dart';
import 'tucked_print.dart';
import 'tucked_prints_fan.dart';

/// The fanned overlay of Tucked Prints: a modal over the desk that lays out
/// every item mounted on the active Stationery Sheet (legacy overflow beyond
/// three included) at a recognisable size. Tapping a print opens the
/// fullscreen lightbox, the only caption editor; each print's ↩ 揭回 returns
/// it to the Staging Handscroll. Tapping outside, or the back gesture,
/// dismisses it.
///
/// The overlay keeps its own list of prints, so an unmount updates the open
/// route in place instead of relying on the desk to rebuild it. It closes when
/// the last print is unmounted.
class TuckedPrintsOverlay extends StatefulWidget {
  final List<SheetMediaItem> items;
  final MediaSandboxService mediaSandboxService;
  final bool isPaperDark;

  /// Unmounts an item (by attachment id) back into the Staging Handscroll.
  final ValueChanged<String>? onUnmount;
  final void Function(String mediaId, String newCaption)? onCaptionChanged;

  /// Runs before the lightbox opens, so the sheet gives up writing focus.
  final VoidCallback? onDeskInteraction;

  static const double kPrintWidth = 96.0;
  static const double kPrintHeight = 114.0;
  static const double kSpacing = 20.0;

  const TuckedPrintsOverlay({
    super.key,
    required this.items,
    required this.mediaSandboxService,
    this.isPaperDark = false,
    this.onUnmount,
    this.onCaptionChanged,
    this.onDeskInteraction,
  });

  /// Opens the overlay over the desk.
  static Future<void> show(
    BuildContext context, {
    required List<SheetMediaItem> items,
    required MediaSandboxService mediaSandboxService,
    bool isPaperDark = false,
    ValueChanged<String>? onUnmount,
    void Function(String mediaId, String newCaption)? onCaptionChanged,
    VoidCallback? onDeskInteraction,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '收起夹页影札',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (transitionContext, animation, secondaryAnimation, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
      pageBuilder: (dialogContext, animation, secondaryAnimation) => TuckedPrintsOverlay(
        items: items,
        mediaSandboxService: mediaSandboxService,
        isPaperDark: isPaperDark,
        onUnmount: onUnmount,
        onCaptionChanged: onCaptionChanged,
        onDeskInteraction: onDeskInteraction,
      ),
    );
  }

  @override
  State<TuckedPrintsOverlay> createState() => _TuckedPrintsOverlayState();
}

class _TuckedPrintsOverlayState extends State<TuckedPrintsOverlay> {
  late List<SheetMediaItem> _items = List<SheetMediaItem>.of(widget.items);

  void _openLightbox(SheetMediaItem item) {
    widget.onDeskInteraction?.call();
    FullscreenMediaLightbox.show(
      context,
      items: _items,
      initialIndex: _items.indexOf(item),
      mediaSandboxService: widget.mediaSandboxService,
      onCaptionChanged: widget.onCaptionChanged,
    );
  }

  void _unmount(SheetMediaItem item) {
    widget.onUnmount?.call(item.id);
    final remaining = _items.where((candidate) => candidate.id != item.id).toList();
    if (remaining.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _items = remaining);
  }

  void _dismiss() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Material(
        type: MaterialType.transparency,
        // Tapping anywhere off a print dismisses; screen readers get the same
        // action named as such.
        child: Semantics(
          container: true,
          label: '收起夹页影札',
          onTap: _dismiss,
          child: GestureDetector(
            key: const Key('tucked_prints_overlay'),
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: _dismiss,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(TuckedPrintsOverlay.kSpacing),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: TuckedPrintsOverlay.kSpacing,
                    runSpacing: TuckedPrintsOverlay.kSpacing,
                    children: [
                      for (final (printIndex, item) in _items.indexed)
                        _FannedPrint(
                          key: ValueKey(item.id),
                          item: item,
                          ordinal: printIndex + 1,
                          tiltInDegrees:
                              TuckedPrintsFan.kTiltsInDegrees[printIndex % TuckedPrintsFan.kTiltsInDegrees.length],
                          mediaSandboxService: widget.mediaSandboxService,
                          isPaperDark: widget.isPaperDark,
                          onOpen: () => _openLightbox(item),
                          onUnmount: () => _unmount(item),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One print of the overlay with its ↩ 揭回 control beneath, so the photo is
/// never covered. The control sits on the dim barrier, so it takes the light
/// ink tone.
class _FannedPrint extends StatelessWidget {
  final SheetMediaItem item;
  final int ordinal;
  final double tiltInDegrees;
  final MediaSandboxService mediaSandboxService;
  final bool isPaperDark;
  final VoidCallback onOpen;
  final VoidCallback onUnmount;

  const _FannedPrint({
    super.key,
    required this.item,
    required this.ordinal,
    required this.tiltInDegrees,
    required this.mediaSandboxService,
    required this.isPaperDark,
    required this.onOpen,
    required this.onUnmount,
  });

  @override
  Widget build(BuildContext context) {
    final kind = item.mediaType == EphemeraMediaType.video ? '短影' : '影札';
    return SizedBox(
      width: TuckedPrintsOverlay.kPrintWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: '本页第 $ordinal 影 · $kind，点按查看',
            onTap: onOpen,
            excludeSemantics: true,
            child: GestureDetector(
              key: Key('tucked_overlay_print_${item.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: onOpen,
              child: SizedBox(
                width: TuckedPrintsOverlay.kPrintWidth,
                height: TuckedPrintsOverlay.kPrintHeight,
                child: TuckedPrint(
                  item: item,
                  mediaSandboxService: mediaSandboxService,
                  tiltInDegrees: tiltInDegrees,
                  isPaperDark: isPaperDark,
                  width: TuckedPrintsOverlay.kPrintWidth,
                  height: TuckedPrintsOverlay.kPrintHeight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4.0),
          DeskMediaControl(
            key: Key('tucked_overlay_unmount_${item.id}'),
            icon: Icons.undo,
            isPaperDark: true,
            semanticLabel: '揭回画卷：本页第 $ordinal 影 · $kind',
            onPressed: onUnmount,
          ),
          const ExcludeSemantics(
            child: Text('揭回', style: TextStyle(fontSize: 12.0, color: Color(0xFFD6D1C7))),
          ),
        ],
      ),
    );
  }
}
