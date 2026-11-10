import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/services/media_sandbox_service.dart';
import '../../domain/stationery_sheet_descriptor.dart';
import '../desk_media_control.dart';
import '../keepsake_thumbnail.dart';

/// One Tucked Print (夹页影札): a small photographic print on a paper matte,
/// held by a strip of gold washi tape and tilted slightly. The fan slips it
/// behind the sheet so only its top shows; a video's print carries a small
/// cinnabar ▶ stamp within that visible top.
class TuckedPrint extends StatelessWidget {
  final SheetMediaItem item;
  final MediaSandboxService mediaSandboxService;
  final double tiltInDegrees;
  final bool isPaperDark;

  /// Size of the print: the resting size by default, larger in the fanned overlay.
  final double width;
  final double height;

  static const double kWidth = 40.0;
  static const double kHeight = 48.0;

  /// Washi tape after the prototype's `.sheet-card-washi`: rgba(212,175,55,0.52), 28×8.
  static const Color kWashi = Color(0x85D4AF37);
  static const Size kWashiSize = Size(28.0, 8.0);

  const TuckedPrint({
    super.key,
    required this.item,
    required this.mediaSandboxService,
    required this.tiltInDegrees,
    this.isPaperDark = false,
    this.width = kWidth,
    this.height = kHeight,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DeskMediaPalette(isPaperDark: isPaperDark);
    return Transform.rotate(
      angle: tiltInDegrees * math.pi / 180.0,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: palette.matte,
                  borderRadius: BorderRadius.circular(2.0),
                  border: Border.all(color: const Color(0x73785830), width: 0.8),
                  boxShadow: const [
                    BoxShadow(color: Color(0x2924201C), blurRadius: 5.0, offset: Offset(0, 2)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(1.0),
                  child: KeepsakeThumbnail(
                    item: item,
                    mediaSandboxService: mediaSandboxService,
                    isPaperDark: isPaperDark,
                    showPlayGlyph: false,
                  ),
                ),
              ),
            ),
            if (item.mediaType == EphemeraMediaType.video)
              Positioned(
                // Within the visible top at rest; centred on a full-face print.
                top: height > kHeight ? (height - 13.0) / 2 : 7.0,
                left: (width - 13.0) / 2,
                child: _CinnabarPlayStamp(key: Key('tucked_print_play_${item.id}'), color: palette.cinnabar),
              ),
            Positioned(
              top: -4.0,
              left: (width - kWashiSize.width) / 2,
              child: Transform.rotate(
                angle: -2.0 * math.pi / 180.0,
                child: Container(width: kWashiSize.width, height: kWashiSize.height, color: kWashi),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small carved cinnabar square with a paper-white ▶.
class _CinnabarPlayStamp extends StatelessWidget {
  final Color color;

  const _CinnabarPlayStamp({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13.0,
      height: 13.0,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(2.0),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 2.0)],
      ),
      child: const Icon(Icons.play_arrow_rounded, size: 11.0, color: Color(0xFFFFF8E7)),
    );
  }
}
