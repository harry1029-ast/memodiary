import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/book_intro_folio_data.dart';
import 'mount_hua_painting_painter.dart';

/// 3D Realistic Chinese thread-bound diary book with single-hinged cover flip,
/// authentic woodblock folio margins, Mount Hua Shanshui ink wash painting on the left,
/// and dual interactive portal buttons («私人日记» & «旅行画册») on the right.
class Book3DStage extends StatelessWidget {
  final double coverOpenRatio; // 0.0 (closed) to 1.0 (fully open)
  final BookIntroFolioData folioData;
  final VoidCallback onPersonalDiaryTap;
  final VoidCallback onTravelAlbumTap;
  final VoidCallback? onBookTap;

  const Book3DStage({
    super.key,
    required this.coverOpenRatio,
    this.folioData = const BookIntroFolioData(),
    required this.onPersonalDiaryTap,
    required this.onTravelAlbumTap,
    this.onBookTap,
  });

  String get lunarDateText => folioData.lunarDateText;
  String get travelTripTitle => folioData.travelTripTitle;
  String get travelRouteSummary => folioData.travelRouteSummary;
  String get travelDestinationTag => folioData.travelDestinationTag;

  @override
  Widget build(BuildContext context) {
    // 0% -> 100% single flip:
    // Front cover rotates from -10deg (slightly ajar) to -180deg (fully open flat)
    final clampedRatio = coverOpenRatio.clamp(0.0, 1.0);
    final coverAngleDeg = -10.0 - clampedRatio * 170.0;
    final coverAngleRad = coverAngleDeg * math.pi / 180.0;

    // Centering offset: When closed, shift right by 23% so the single right-half book is centered.
    // As it opens to 100%, offset smoothly to 0% so the two-page spread fills the screen.
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
                // 1. LEFT BASE TRAY (Shadow underneath left folio when opened)
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

                // 2. RIGHT BASE PAGE (Stationary, revealed as cover opens)
                Positioned(
                  left: 178,
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildRightBasePage(context, clampedRatio),
                ),

                // 3. CENTER BOOK SPINE HINGE (古籍书脊中缝)
                Positioned(
                  left: 173,
                  top: 4,
                  bottom: 4,
                  width: 10,
                  child: _buildSpineHinge(),
                ),

                // 4. 3D FLIPPING LEAF (FRONT COVER <-> LEFT MOUNTAIN FOLIO)
                // Rotates outward toward viewer with negative perspective
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
                        // --- FRONT FACE: Thread-bound Indigo Silk Cover ---
                        if (coverAngleDeg > -90.0)
                          _buildFrontCover(context, clampedRatio),

                        // --- BACK FACE: Left Folio Mount Hua Painting ---
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

  /// Center Book Spine with Traditional Fishtail Folding Marks (版心黑鱼尾)
  Widget _buildSpineHinge() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1.5),
        gradient: const LinearGradient(
          colors: [Color(0xFF6E5D45), Color(0xFF1E1912), Color(0xFF7A684E)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73000000),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 16),
          // Fishtail mark top
          Container(width: 5, height: 10, color: const Color(0xFF1A1612)),
          Expanded(
            child: Container(
              width: 1.0,
              color: const Color(0x4DD8C8AE),
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          // Fishtail mark bottom
          Container(width: 5, height: 10, color: const Color(0xFF1A1612)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Front Face: Closed Thread-Bound Chinese Book Cover (线装古籍封皮)
  Widget _buildFrontCover(BuildContext context, double openRatio) {
    final elevation = math.sin(openRatio.clamp(0.0, 1.0) * math.pi);

    return GestureDetector(
      onTap: onBookTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF233036),
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
          border: Border.all(color: const Color(0xFF161F24), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.40 + elevation * 0.25),
              blurRadius: 18.0 + elevation * 22.0,
              offset: Offset(6.0 + elevation * 12.0, 10.0 + elevation * 12.0),
            ),
          ],
        ),
      child: Row(
        children: [
          // Spine Binding with White Stitches (线装书脊装订线)
          Container(
            width: 22,
            decoration: const BoxDecoration(
              color: Color(0xFF1B252A),
              border: Border(
                right: BorderSide(color: Color(0xFF3C4B52), width: 1.5),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                5,
                (index) => Container(
                  width: double.infinity,
                  height: 2.0,
                  color: const Color(0xDBE5DEC9),
                ),
              ),
            ),
          ),

          // Cover Surface with Vertical Title Slip (书名签条)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Vertical Title Slip
                  Container(
                    width: 38,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2E9D8),
                      border: Border.all(color: const Color(0xFF8C7B65), width: 1.6),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                          offset: Offset(1, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0x99B83B2E),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '拾\n光\n云\n笺',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1815),
                              height: 1.15,
                              letterSpacing: 2,
                              fontFamily: 'Noto Serif SC',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB83B2E),
                              borderRadius: BorderRadius.circular(1),
                            ),
                            child: const Center(
                              child: Text(
                                '珍\n藏',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 5.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF7F3E8),
                                  height: 1.05,
                                  fontFamily: 'Noto Serif SC',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Swipe Hint Badge at Bottom Right of Cover
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xD9151E22),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF495A63), width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_left_rounded,
                            size: 13,
                            color: Color(0xFFE06D5E),
                          ),
                          SizedBox(width: 2),
                          Text(
                            '向左划翻开',
                            style: TextStyle(
                              fontSize: 8.5,
                              color: Color(0xFFDFD7C8),
                              fontFamily: 'Noto Serif SC',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  /// Back Face of Flipping Leaf: Left Folio Page with Mount Hua Painting
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
          // Inner Double-Line Woodblock Frame with Painting
          Padding(
            padding: const EdgeInsets.all(7),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF241F19), width: 1.8),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xCC241F19),
                    width: 0.8,
                  ),
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

          // Right Spine Crease Shadow
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
                  colors: [
                    Color(0x4D2A2116),
                    Color(0x1A4A3B28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Right Base Page containing the Two Interactive Entry Buttons
  Widget _buildRightBasePage(BuildContext context, double openRatio) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFE6D2),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
        border: Border.all(color: const Color(0xFF8A795D), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D14110C),
            blurRadius: 20,
            offset: Offset(8, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content inside Woodblock Margin Frame
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
                  border: Border.all(
                    color: const Color(0xCC241F19),
                    width: 0.8,
                  ),
                  color: const Color(0xFFF7F3EA),
                ),
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    // Page Header: 云笺日记 · 卷目
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '云笺日记 · 卷目',
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
                            '点选入卷',
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

                    // BUTTON 1: 私人日记 (Personal Diary)
                    Expanded(
                      child: IgnorePointer(
                        ignoring: openRatio < 0.65,
                        child: _buildPersonalDiaryButton(),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // BUTTON 2: 旅行画册 (Travel Keepsake Album)
                    Expanded(
                      child: IgnorePointer(
                        ignoring: openRatio < 0.65,
                        child: _buildTravelAlbumButton(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Left Spine Crease Shadow
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
                  colors: [
                    Color(0x402A2116),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Dynamic Cast Shadow from Opening Front Cover
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

          // Multi-Layer Paper Fore-Edge Stack on Far Right (古籍书口千层纸边)
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

  /// Button 1: 私人日记 Card
  Widget _buildPersonalDiaryButton() {
    final verticalChars = lunarDateText.split('');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPersonalDiaryTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF6ED),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFC5B393), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '私人日记',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1815),
                      fontFamily: 'Noto Serif SC',
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        '进入 →',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB83B2E),
                          fontFamily: 'Noto Serif SC',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Text(
                '今日心绪，静落成笺',
                style: TextStyle(
                  fontSize: 7,
                  color: Color(0xFF5A5347),
                  fontFamily: 'Noto Serif SC',
                ),
              ),

              // Manuscript Grid with Hand-Painted Bamboo and Lunar Date
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3ECE0),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFD6C9B1), width: 0.8),
                  ),
                  child: Stack(
                    children: [
                      // Manuscript Grid Background
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ManuscriptGridPainter(),
                        ),
                      ),

                      // Ink Bamboo Sketch
                      Positioned(
                        left: 4,
                        top: 2,
                        bottom: 2,
                        width: 70,
                        child: CustomPaint(
                          painter: _InkBambooPainter(),
                        ),
                      ),

                      // Right Date & Red Seal Stamp
                      Positioned(
                        right: 6,
                        top: 4,
                        bottom: 4,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Red Seal: 静心
                            Container(
                              width: 10,
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFFB83B2E),
                                borderRadius: BorderRadius.circular(1),
                              ),
                              child: const Center(
                                child: Text(
                                  '静\n心',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 4.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFF7F3E8),
                                    height: 1.05,
                                    fontFamily: 'Noto Serif SC',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),

                            // Vertical Lunar Date
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: verticalChars
                                  .map(
                                    (ch) => Text(
                                      ch,
                                      style: const TextStyle(
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2B2620),
                                        height: 1.05,
                                        fontFamily: 'Noto Serif SC',
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Poetic Footer
              const Text(
                '雨窗独坐，记一段清宁时光。',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 7,
                  color: Color(0xFF3A352D),
                  fontFamily: 'Noto Serif SC',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Button 2: 旅行画册 Card
  Widget _buildTravelAlbumButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTravelAlbumTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF6ED),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFC5B393), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '旅行画册',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1815),
                      fontFamily: 'Noto Serif SC',
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        '进入 →',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3B5249),
                          fontFamily: 'Noto Serif SC',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Text(
                '山河沿路，笔底留痕',
                style: TextStyle(
                  fontSize: 7,
                  color: Color(0xFF5A5347),
                  fontFamily: 'Noto Serif SC',
                ),
              ),

              // Water-Ink Jiangnan Sailboat & Route Artwork
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFE9DC),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFD6C9B1), width: 0.8),
                  ),
                  child: Stack(
                    children: [
                      // Jiangnan Landscape & Sailboat Painter
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _JiangnanLandscapePainter(),
                        ),
                      ),

                      // Top-Right Destination Pill
                      Positioned(
                        top: 3,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xE6FAF6ED),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: const Color(0xFFB8A686), width: 0.6),
                          ),
                          child: Text(
                            travelDestinationTag,
                            style: const TextStyle(
                              fontSize: 6,
                              color: Color(0xFF4A4236),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Noto Serif SC',
                            ),
                          ),
                        ),
                      ),

                      // Bottom-Right Cinnabar Seal Stamp: 江南
                      Positioned(
                        bottom: 3,
                        right: 4,
                        child: Container(
                          width: 12,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB83B2E),
                            borderRadius: BorderRadius.circular(1),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '江\n南',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 4.8,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF7F3E8),
                                height: 1.05,
                                fontFamily: 'Noto Serif SC',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Route Summary Footer
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC49A62),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '●',
                        style: TextStyle(
                          fontSize: 4,
                          color: Color(0xFFFAF6ED),
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      travelRouteSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2B2620),
                        fontFamily: 'Noto Serif SC',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper Painter for Chinese Manuscript Grid (九宫方格)
class _ManuscriptGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFC5B69C).withValues(alpha: 0.35)
      ..strokeWidth = 0.6;

    const gridSize = 12.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Helper Painter for Hand-Painted Ink Bamboo on Manuscript Card
class _InkBambooPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFF1E1D1A)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final leafPaint = Paint()..color = const Color(0xFF1C1B18);

    // Stems
    final s1 = Path()
      ..moveTo(size.width * 0.15, size.height)
      ..quadraticBezierTo(size.width * 0.30, size.height * 0.5, size.width * 0.50, size.height * 0.1);
    canvas.drawPath(s1, stemPaint);

    final s2 = Path()
      ..moveTo(size.width * 0.30, size.height)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.6, size.width * 0.65, size.height * 0.3);
    canvas.drawPath(s2, stemPaint..strokeWidth = 1.3);

    // Bamboo Nodes
    canvas.drawLine(
      Offset(size.width * 0.23, size.height * 0.68),
      Offset(size.width * 0.28, size.height * 0.69),
      stemPaint..strokeWidth = 2.2,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.40),
      Offset(size.width * 0.41, size.height * 0.41),
      stemPaint..strokeWidth = 2.0,
    );

    // Leaves
    _drawLeaf(canvas, Offset(size.width * 0.38, size.height * 0.40), 22, -0.2, leafPaint);
    _drawLeaf(canvas, Offset(size.width * 0.40, size.height * 0.40), 18, 0.3, leafPaint);
    _drawLeaf(canvas, Offset(size.width * 0.48, size.height * 0.20), 20, -0.4, leafPaint);
    _drawLeaf(canvas, Offset(size.width * 0.54, size.height * 0.50), 22, 0.2, leafPaint);
  }

  void _drawLeaf(Canvas canvas, Offset origin, double length, double angle, Paint paint) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);
    final p = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.5, -3, length, 0)
      ..quadraticBezierTo(length * 0.5, 3, 0, 0)
      ..close();
    canvas.drawPath(p, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Helper Painter for Jiangnan Water-Ink Landscape & Sailboat on Travel Card
class _JiangnanLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Distant Misty Hills
    final hill1 = Path()
      ..moveTo(0, h * 0.55)
      ..quadraticBezierTo(w * 0.20, h * 0.20, w * 0.40, h * 0.42)
      ..quadraticBezierTo(w * 0.65, h * 0.30, w, h * 0.45)
      ..lineTo(w, h * 0.70)
      ..lineTo(0, h * 0.70)
      ..close();
    canvas.drawPath(hill1, Paint()..color = const Color(0xFF8A968E).withValues(alpha: 0.45));

    final hill2 = Path()
      ..moveTo(0, h * 0.60)
      ..quadraticBezierTo(w * 0.18, h * 0.35, w * 0.35, h * 0.50)
      ..quadraticBezierTo(w * 0.60, h * 0.45, w, h * 0.58)
      ..lineTo(w, h * 0.75)
      ..lineTo(0, h * 0.75)
      ..close();
    canvas.drawPath(hill2, Paint()..color = const Color(0xFF52645B).withValues(alpha: 0.55));

    // Water Surface
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.60, w, h * 0.40),
      Paint()..color = const Color(0xFFF4EFE4).withValues(alpha: 0.85),
    );

    // Foreground Ink Promontory
    final prom = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.15, h * 0.65, w * 0.28, h * 0.80)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(prom, Paint()..color = const Color(0xFF2B3530).withValues(alpha: 0.80));

    // Dashed Route Curve
    final routePaint = Paint()
      ..color = const Color(0xFF9E7B56)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    _drawDashedCurve(canvas, Offset(w * 0.25, h * 0.85), Offset(w * 0.60, h * 0.65), routePaint);

    // Traditional Sailboat
    _drawSailboat(canvas, Offset(w * 0.60, h * 0.38));
  }

  void _drawDashedCurve(Canvas canvas, Offset p0, Offset p2, Paint paint) {
    final p1 = Offset((p0.dx + p2.dx) / 2, p0.dy - 10);
    const int segments = 10;
    for (int i = 0; i < segments; i += 2) {
      final t1 = i / segments;
      final t2 = (i + 1) / segments;
      final start = _evalBezier(p0, p1, p2, t1);
      final end = _evalBezier(p0, p1, p2, t2);
      canvas.drawLine(start, end, paint);
    }
  }

  Offset _evalBezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  void _drawSailboat(Canvas canvas, Offset origin) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    final sail1 = Path()
      ..moveTo(8, 2)
      ..lineTo(8, 22)
      ..lineTo(0, 20)
      ..lineTo(2, 5)
      ..close();
    canvas.drawPath(sail1, Paint()..color = const Color(0xFFEAE0CE));
    canvas.drawPath(
      sail1,
      Paint()
        ..color = const Color(0xFF3A3228)
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke,
    );

    final sail2 = Path()
      ..moveTo(10, 0)
      ..lineTo(10, 22)
      ..lineTo(18, 19)
      ..lineTo(16, 3)
      ..close();
    canvas.drawPath(sail2, Paint()..color = const Color(0xFFDFD2BC));
    canvas.drawPath(
      sail2,
      Paint()
        ..color = const Color(0xFF3A3228)
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke,
    );

    // Boat Hull
    final hull = Path()
      ..moveTo(-3, 21)
      ..quadraticBezierTo(9, 26, 23, 20)
      ..lineTo(19, 24)
      ..lineTo(1, 24)
      ..close();
    canvas.drawPath(hull, Paint()..color = const Color(0xFF3D3124));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
