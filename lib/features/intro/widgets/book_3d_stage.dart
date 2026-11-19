import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/book_intro_folio_data.dart';
import 'book_intro_front_cover.dart';
import 'book_intro_portal_cards.dart';
import 'mount_hua_painting_painter.dart';

/// 3D Realistic Chinese thread-bound diary book with single-hinged cover flip,
/// authentic woodblock folio margins, Mount Hua Shanshui ink wash painting on the left,
/// and dual interactive portal buttons («私人日记» & «旅行相册») on the right.
class Book3DStage extends StatelessWidget {
  final double coverOpenRatio; // 0.0 (closed) to 1.0 (fully open)
  final BookIntroFolioData folioData;
  final VoidCallback onPersonalDiaryTap;
  final VoidCallback onTravelAlbumTap;
  final VoidCallback? onBookTap;
  final bool isNight;
  final double lightAngleDeg;

  const Book3DStage({
    super.key,
    required this.coverOpenRatio,
    this.folioData = const BookIntroFolioData(),
    required this.onPersonalDiaryTap,
    required this.onTravelAlbumTap,
    this.onBookTap,
    this.isNight = true,
    this.lightAngleDeg = 105.0,
  });

  String get lunarDateText => folioData.lunarDateText;
  String get travelTripTitle => folioData.travelTripTitle;
  String get travelRouteSummary => folioData.travelRouteSummary;
  String get travelDestinationTag => folioData.travelDestinationTag;

  @override
  Widget build(BuildContext context) {
    final clampedRatio = coverOpenRatio.clamp(0.0, 1.0);
    final coverAngleDeg = -10.0 - clampedRatio * 170.0;
    final coverAngleRad = coverAngleDeg * math.pi / 180.0;
    final bookCenterOffsetPct = (1.0 - clampedRatio) * 0.23;
    final tiltAngleRad = (1.0 - clampedRatio) * 4.0 * math.pi / 180.0;

    return Center(
      child: SizedBox(
        width: 356,
        height: 420,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, -0.0008)
            ..setTranslationRaw(-356 * bookCenterOffsetPct, 0.0, 0.0)
            ..rotateX(tiltAngleRad),
          child: Stack(
            children: [
              if (clampedRatio > 0.15)
                Positioned(
                  left: 0,
                  top: 4,
                  bottom: 4,
                  width: 6,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(2)),
                      gradient: LinearGradient(
                        colors: [Color(0xFF5E503C), Color(0xFFC8B799), Color(0xFF8E7C5D)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x47000000),
                          blurRadius: 18,
                          offset: Offset(-8, 12),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 178,
                top: 0,
                right: 0,
                bottom: 0,
                child: _buildRightBasePage(context, clampedRatio),
              ),
              Positioned(
                left: 173,
                top: 4,
                bottom: 4,
                width: 10,
                child: _buildSpineHinge(),
              ),
              Positioned(
                left: 178,
                top: 0,
                width: 178,
                bottom: 0,
                child: Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, -0.0008)
                    ..rotateY(coverAngleRad),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (coverAngleDeg > -90.0)
                        BookIntroFrontCover(
                          openRatio: clampedRatio,
                          isNight: isNight,
                          lightAngleDeg: lightAngleDeg,
                          onBookTap: onBookTap,
                        ),
                      if (coverAngleDeg <= -90.0)
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(math.pi),
                          child: _buildLeftFolioPage(clampedRatio),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Center Book Spine with Traditional Fishtail Folding Marks (版心黑鱼尾).
  Widget _buildSpineHinge() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1.5),
        gradient: const LinearGradient(
          colors: [Color(0xFF6E5D45), Color(0xFF1E1912), Color(0xFF7A684E)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 16),
          Container(width: 5, height: 10, color: const Color(0xFF1A1612)),
          Expanded(
            child: Container(
              width: 1.0,
              color: const Color(0x4DD8C8AE),
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          Container(width: 5, height: 10, color: const Color(0xFF1A1612)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Back Face of Flipping Leaf: Left Folio Page with Mount Hua Painting.
  Widget _buildLeftFolioPage(double openRatio) {
    final elevation = math.sin(openRatio.clamp(0.0, 1.0) * math.pi);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFE6D2),
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(2)),
        border: Border.all(color: const Color(0xFF8A795D), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25 + elevation * 0.20),
            blurRadius: 14.0 + elevation * 18.0,
            offset: Offset(-4.0 - elevation * 10.0, 6.0 + elevation * 10.0),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(7),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF241F19), width: 1.8),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xCC241F19), width: 0.8),
                ),
                child: const ClipRect(
                  child: CustomPaint(
                    painter: MountHuaPaintingPainter(),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 14,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Color(0x4D2A2116), Color(0x1A4A3B28), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Right Base Page containing the Two Interactive Entry Buttons.
  Widget _buildRightBasePage(BuildContext context, double openRatio) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFE6D2),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
        border: Border.all(color: const Color(0xFF8A795D), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x4D14110C), blurRadius: 20, offset: Offset(8, 12)),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(7),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF241F19), width: 1.8),
                color: const Color(0xF7F7F3EA),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xCC241F19), width: 0.8),
                  color: const Color(0xFFF7F3EA),
                ),
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '选择栏目',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1B18),
                            fontFamily: 'Noto Serif SC',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFE6D2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFC7B89B), width: 0.8),
                          ),
                          child: const Text(
                            '点击进入',
                            style: TextStyle(
                              fontSize: 6.5,
                              color: Color(0xFF5C5242),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Noto Serif SC',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFDED5C3), height: 8, thickness: 0.8),
                    Expanded(
                      child: IgnorePointer(
                        ignoring: openRatio < 0.65,
                        child: BookIntroPersonalDiaryCard(
                          lunarDateText: lunarDateText,
                          onTap: onPersonalDiaryTap,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: IgnorePointer(
                        ignoring: openRatio < 0.65,
                        child: BookIntroTravelAlbumCard(
                          travelDestinationTag: travelDestinationTag,
                          travelRouteSummary: travelRouteSummary,
                          onTap: onTravelAlbumTap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 12,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0x402A2116), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromRGBO(20, 16, 10, (1.0 - openRatio) * 0.55),
                      Color.fromRGBO(20, 16, 10, (1.0 - openRatio) * 0.18),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6E5F47),
                    Color(0xFFD8C9AE),
                    Color(0xFF8C7A5B),
                    Color(0xFFD8C9AE),
                  ],
                  stops: [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
