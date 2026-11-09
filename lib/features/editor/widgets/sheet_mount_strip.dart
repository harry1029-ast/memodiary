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
/// Drawn as a slip of paper laid on the desk under the sheet: a vertical
/// colophon with the mount count, each print tipped in with washi tape at a
/// slight tilt, and dashed empty places up to [TextStationerySheet.kMountCapacity].
/// Each print carries a "↩ 揭回" control that Unmounts it back to the Staging
/// Handscroll; the strip has no delete control. Every tick of [refusalSignal]
/// shakes the strip to say the sheet is full.
class SheetMountStrip extends StatelessWidget {
  final List<SheetMediaItem> items;
  final MediaSandboxService mediaSandboxService;
  final ValueChanged<SheetMediaItem>? onTapItem;
  final ValueChanged<SheetMediaItem>? onUnmountItem;
  final ValueListenable<int>? refusalSignal;
  final bool isPaperDark;

  /// Edge of each square mounted print; above the 44px touch target.
  static const double kItemExtent = 60.0;

  /// Height of the ↩ touch target beneath each print.
  static const double kControlExtent = DeskMediaControl.kExtent;

  /// Vertical padding inside the paper slip.
  static const double kSlipPadding = 4.0;

  /// Hairline border of the paper slip.
  static const double kSlipBorderWidth = 0.8;

  /// Total strip height: print plus its ↩ control, inside the slip.
  static const double kStripHeight =
      kItemExtent + kControlExtent + 2 * (kSlipPadding + kSlipBorderWidth);

  static const List<double> _kTiltsInDegrees = [-1.8, 1.4, -1.2];

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

    final palette = _SlipPalette(isPaperDark: isPaperDark);
    const capacity = TextStationerySheet.kMountCapacity;

    final strip = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Semantics(
        container: true,
        label: '本页影札栏 · ${items.length} 影',
        child: Container(
          key: const Key('sheet_mount_strip'),
          height: kStripHeight,
          padding: const EdgeInsets.symmetric(vertical: kSlipPadding),
          decoration: BoxDecoration(
            color: palette.slip,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: palette.slipBorder, width: SheetMountStrip.kSlipBorderWidth),
            boxShadow: const [
              BoxShadow(color: Color(0x80000000), blurRadius: 10.0, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              _MountColophon(count: items.length, capacity: capacity, palette: palette),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (itemIndex, item) in items.indexed)
                      _MountedPrint(
                        item: item,
                        itemIndex: itemIndex,
                        tiltInDegrees: _kTiltsInDegrees[itemIndex % _kTiltsInDegrees.length],
                        mediaSandboxService: mediaSandboxService,
                        palette: palette,
                        onTap: onTapItem == null ? null : () => onTapItem!(item),
                        onUnmount: () => onUnmountItem?.call(item),
                      ),
                    for (int placeIndex = items.length; placeIndex < capacity; placeIndex++)
                      _EmptyMountPlace(palette: palette),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final signal = refusalSignal;
    if (signal == null) return strip;
    return _ShakeOnSignal(signal: signal, child: strip);
  }
}

/// Tones of the paper slip the strip is drawn on, light or dark with the paper.
class _SlipPalette {
  final bool isPaperDark;
  const _SlipPalette({required this.isPaperDark});

  DeskMediaPalette get desk => DeskMediaPalette(isPaperDark: isPaperDark);
  Color get slip => isPaperDark ? const Color(0xFF26231F) : const Color(0xFFEFEAE0);
  Color get slipBorder => isPaperDark ? const Color(0x33FFFFFF) : const Color(0x52B83B2E);
  Color get ink => desk.ink;
  Color get muted => isPaperDark ? const Color(0x99D6D1C7) : const Color(0xA68C6D46);
  Color get washi => const Color(0x85D4AF37);
}

/// The slip's vertical colophon: 本页影札 over the mount count.
class _MountColophon extends StatelessWidget {
  final int count;
  final int capacity;
  final _SlipPalette palette;

  const _MountColophon({required this.count, required this.capacity, required this.palette});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 26.0,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: palette.slipBorder, width: 0.8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '本\n页\n影\n札',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.0, height: 1.15, color: palette.ink, fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.0),
              decoration: BoxDecoration(border: Border.all(color: palette.desk.cinnabar, width: 0.8)),
              child: Text(
                '$count/$capacity',
                style: TextStyle(fontSize: 8.0, color: palette.desk.cinnabar, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One print tipped onto the slip with washi tape, over its "↩ 揭回" control.
class _MountedPrint extends StatelessWidget {
  final SheetMediaItem item;
  final int itemIndex;
  final double tiltInDegrees;
  final MediaSandboxService mediaSandboxService;
  final _SlipPalette palette;
  final VoidCallback? onTap;
  final VoidCallback onUnmount;

  const _MountedPrint({
    required this.item,
    required this.itemIndex,
    required this.tiltInDegrees,
    required this.mediaSandboxService,
    required this.palette,
    required this.onTap,
    required this.onUnmount,
  });

  @override
  Widget build(BuildContext context) {
    final kindLabel = item.mediaType == EphemeraMediaType.video ? '短影' : '影札';
    return SizedBox(
      width: SheetMountStrip.kItemExtent + 8.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: '本页影札 · 第 ${itemIndex + 1} 影，点按查看',
            onTap: onTap,
            excludeSemantics: true,
            child: GestureDetector(
              key: Key('mount_strip_item_${item.id}'),
              onTap: onTap,
              child: Transform.rotate(
                angle: tiltInDegrees * math.pi / 180.0,
                child: SizedBox.square(
                  dimension: SheetMountStrip.kItemExtent,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Container(
                          padding: const EdgeInsets.all(3.0),
                          decoration: BoxDecoration(
                            color: palette.desk.matte,
                            borderRadius: BorderRadius.circular(2.0),
                            border: Border.all(color: const Color(0x73785830), width: 0.8),
                            boxShadow: const [
                              BoxShadow(color: Color(0x2924201C), blurRadius: 6.0, offset: Offset(0, 3)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(1.0),
                            child: KeepsakeThumbnail(
                              item: item,
                              mediaSandboxService: mediaSandboxService,
                              isPaperDark: palette.isPaperDark,
                            ),
                          ),
                        ),
                      ),
                      // Washi tape holding the print to the slip.
                      Positioned(
                        top: -4.0,
                        left: SheetMountStrip.kItemExtent / 2 - 13.0,
                        child: Transform.rotate(
                          angle: -2.0 * math.pi / 180.0,
                          child: Container(width: 26.0, height: 8.0, color: palette.washi),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: '揭回画卷：本页第 ${itemIndex + 1} 影 · $kindLabel',
            onTap: onUnmount,
            excludeSemantics: true,
            child: InkWell(
              key: Key('mount_strip_unmount_${item.id}'),
              onTap: onUnmount,
              borderRadius: BorderRadius.circular(10.0),
              child: SizedBox(
                height: SheetMountStrip.kControlExtent,
                width: SheetMountStrip.kItemExtent + 8.0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.undo, size: 14, color: palette.ink),
                      const SizedBox(width: 2.0),
                      Text('揭回', style: TextStyle(fontSize: 10.0, letterSpacing: 1.0, color: palette.ink)),
                    ],
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

/// A dashed place on the slip still free for a mount.
class _EmptyMountPlace extends StatelessWidget {
  final _SlipPalette palette;

  const _EmptyMountPlace({required this.palette});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: SheetMountStrip.kItemExtent + 8.0,
        child: Align(
          alignment: Alignment.topCenter,
          child: CustomPaint(
            painter: _DashedFramePainter(color: palette.muted),
            child: SizedBox.square(
              dimension: SheetMountStrip.kItemExtent - 6.0,
              child: Center(
                child: Text(
                  '空位\n可贴',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9.0, height: 1.3, color: palette.muted),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedFramePainter extends CustomPainter {
  final Color color;

  const _DashedFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 4.0;
    const gap = 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8;
    void dashed(Offset from, Offset to) {
      final length = (to - from).distance;
      final direction = (to - from) / length;
      for (double travelled = 0; travelled < length; travelled += dash + gap) {
        final end = math.min(travelled + dash, length);
        canvas.drawLine(from + direction * travelled, from + direction * end, paint);
      }
    }

    dashed(Offset.zero, Offset(size.width, 0));
    dashed(Offset(size.width, 0), Offset(size.width, size.height));
    dashed(Offset(size.width, size.height), Offset(0, size.height));
    dashed(Offset(0, size.height), Offset.zero);
  }

  @override
  bool shouldRepaint(_DashedFramePainter oldDelegate) => oldDelegate.color != color;
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
