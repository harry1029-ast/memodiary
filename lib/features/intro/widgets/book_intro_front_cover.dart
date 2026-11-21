import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:memodiary/core/theme/widgets/cloud_moon_emblem_painter.dart';

/// Closed thread-bound front cover face for `Book3DStage` featuring directional
/// moonlight/sunlight rim sheen, vertical Xuan paper title slip («云皓日记»),
/// embossed Cloud-Moon emblem, and bottom-right swipe hint.
class BookIntroFrontCover extends StatelessWidget {
  final double openRatio;
  final bool isNight;
  final double lightAngleDeg;
  final VoidCallback? onBookTap;

  const BookIntroFrontCover({
    super.key,
    required this.openRatio,
    required this.isNight,
    required this.lightAngleDeg,
    this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final elevation = math.sin(openRatio.clamp(0.0, 1.0) * math.pi);
    final rad = lightAngleDeg * math.pi / 180.0;
    final dirX = math.sin(rad);
    final dirY = -math.cos(rad);

    return GestureDetector(
      onTap: onBookTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF273642), Color(0xFF1B2730), Color(0xFF131C24)],
            stops: [0.0, 0.58, 1.0],
          ),
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
          border: Border.all(
            color: isNight ? const Color(0x6BBCD2F0) : const Color(0x994A3E2F),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(
                isNight ? 0 : 20,
                isNight ? 0 : 26,
                isNight ? 0 : 36,
                (isNight ? 0.50 : 0.36) + elevation * 0.22,
              ),
              blurRadius: 20.0 + elevation * 22.0,
              offset: Offset(8.0 + elevation * 12.0, 14.0 + elevation * 12.0),
            ),
            if (isNight)
              const BoxShadow(color: Color(0x29AFCAF5), blurRadius: 22.0),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-dirX, -dirY),
                        end: Alignment(dirX, dirY),
                        colors: [
                          isNight ? const Color(0x38D7E6FF) : const Color(0x29FFF8E1),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.52],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                left: 22,
                child: IgnorePointer(
                  child: Center(
                    child: CustomPaint(
                      size: const Size(88, 88),
                      // Subtle silver-gold emboss of the Cloud-Moon emblem.
                      painter: const CloudMoonEmblemPainter(
                        primaryColor: Color(0x33E6D5B8),
                        accentColor: Color(0x33E6D5B8),
                        strokeWeight: 0.22,
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 22,
                    decoration: const BoxDecoration(
                      color: Color(0x73121A21),
                      border: Border(
                        right: BorderSide(color: Color(0x408FA4B8), width: 1.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        5,
                        (index) => Container(
                          width: double.infinity,
                          height: 1.8,
                          color: const Color(0xD9E8E2D5),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTitleSlip(),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xCC162029),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: const Color(0x737A8E9E), width: 0.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.chevron_left_rounded,
                                    size: 13,
                                    color: Color(0xFFD45B4B),
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    '左滑翻开',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      color: Color(0xFFE6E1D6),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSlip() {
    return Container(
      width: 38,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F2E9),
        border: Border.all(color: const Color(0xFFC9B694), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(1, 3)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0x8CB84A39), width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '云\n皓\n日\n记',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1A17),
                height: 1.18,
                letterSpacing: 2,
                fontFamily: 'Noto Serif SC',
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: const Color(0xFFB83B2E),
                borderRadius: BorderRadius.circular(1.5),
              ),
              child: const Center(
                child: Text(
                  '珍\n藏',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 5.8,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFAF6EE),
                    height: 1.05,
                    fontFamily: 'Noto Serif SC',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
