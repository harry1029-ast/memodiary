import 'package:flutter/material.dart';
import 'book_intro_portal_painters.dart';

/// Portal card 1 on the right folio page of the Book Intro: opens Personal Diary (`TimelineScreen`).
class BookIntroPersonalDiaryCard extends StatelessWidget {
  final String lunarDateText;
  final VoidCallback onTap;

  const BookIntroPersonalDiaryCard({
    super.key,
    required this.lunarDateText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final verticalChars = lunarDateText.split('');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '私人日记',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1815),
                      fontFamily: 'Noto Serif SC',
                    ),
                  ),
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
              const Text(
                '记录日常心情与生活',
                style: TextStyle(
                  fontSize: 7,
                  color: Color(0xFF5A5347),
                  fontFamily: 'Noto Serif SC',
                ),
              ),
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
                      const Positioned.fill(
                        child: CustomPaint(painter: ManuscriptGridPainter()),
                      ),
                      const Positioned(
                        left: 4,
                        top: 2,
                        bottom: 2,
                        width: 70,
                        child: CustomPaint(painter: InkBambooPainter()),
                      ),
                      Positioned(
                        right: 6,
                        top: 4,
                        bottom: 4,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
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
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: verticalChars
                                  .map(
                                    (character) => Text(
                                      character,
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
              const Text(
                '随时随地写下你的故事',
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
}

/// Portal card 2 on the right folio page of the Book Intro: opens Travel Albums (`AlbumCollectionsScreen`).
class BookIntroTravelAlbumCard extends StatelessWidget {
  final String travelDestinationTag;
  final String travelRouteSummary;
  final VoidCallback onTap;

  const BookIntroTravelAlbumCard({
    super.key,
    required this.travelDestinationTag,
    required this.travelRouteSummary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '旅行相册',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1815),
                      fontFamily: 'Noto Serif SC',
                    ),
                  ),
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
              const Text(
                '整理旅途照片与足迹',
                style: TextStyle(
                  fontSize: 7,
                  color: Color(0xFF5A5347),
                  fontFamily: 'Noto Serif SC',
                ),
              ),
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
                      const Positioned.fill(
                        child: CustomPaint(painter: JiangnanLandscapePainter()),
                      ),
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
                              BoxShadow(color: Color(0x33000000), blurRadius: 2),
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
                        style: TextStyle(fontSize: 4, color: Color(0xFFFAF6ED), height: 1),
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
