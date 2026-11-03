import 'dart:io';
import 'package:flutter/material.dart';
import 'folio_leaf_model.dart';
import 'folio_reading_perspective.dart';
import 'folio_shanshui_art_painter.dart';

/// Page 0: Ceremonial Frontispiece Cover of the Thread-Bound Folio.
class FolioFrontispiecePage extends StatelessWidget {
  final FolioFrontispieceCoverLeaf leaf;
  final FolioSubstrateTheme theme;
  final VoidCallback? onTurnForward;

  const FolioFrontispiecePage({
    super.key,
    required this.leaf,
    required this.theme,
    this.onTurnForward,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = theme.isDark ? const Color(0xFFE07A6B) : const Color(0xFFB83B2E);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopMetadata(accentColor),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                border: Border.all(color: accentColor.withValues(alpha: 0.42), width: 1.4),
                color: theme.isDark ? Colors.white.withValues(alpha: 0.015) : Colors.white.withValues(alpha: 0.25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTitleBanner(accentColor),
                  const SizedBox(height: 14),
                  Expanded(child: _buildArtworkMount(accentColor)),
                  const SizedBox(height: 12),
                  _buildReflectionOrPlaceholder(accentColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildBottomFooter(accentColor),
        ],
      ),
    );
  }

  Widget _buildTopMetadata(Color accentColor) {
    const moodLabels = ['低落', '平淡', '平静', '愉快', '欣喜'];
    final moodText = leaf.mood != null ? moodLabels[(leaf.mood! - 1).clamp(0, 4)] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              border: Border.all(color: accentColor.withValues(alpha: 0.45)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              leaf.lunarDate,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: accentColor, letterSpacing: 1.0, fontFamily: theme.fontFamily),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leaf.weather != null && leaf.weather!.isNotEmpty)
              Text(leaf.weather!, style: TextStyle(fontSize: 10.5, color: theme.inkSecondary)),
            if (moodText != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.inkSecondary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(moodText, style: TextStyle(fontSize: 9.5, color: theme.inkPrimary)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTitleBanner(Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leaf.gregorianDate.isNotEmpty
                    ? leaf.gregorianDate
                    : '拾光日记 · 岁时扉页',
                style: TextStyle(fontSize: 10.0, letterSpacing: 1.2, color: theme.inkSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                leaf.entryTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                  fontFamily: theme.fontFamily,
                  color: theme.inkPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                border: Border.all(color: accentColor.withValues(alpha: 0.40)),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text('扉页 · 封面', style: TextStyle(fontSize: 10.0, color: accentColor, fontWeight: FontWeight.w500)),
            ),
            if (leaf.isWeeklyReview) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFFD4AF37)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  leaf.weekNumber != null ? '周报 · 第${leaf.weekNumber}周' : '周回顾',
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF9E7812)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildArtworkMount(Color accentColor) {
    final silkColor = theme.isDark ? const Color(0xD0C8A055) : const Color(0xC0DFC898);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.isDark ? const Color(0xFF141619) : const Color(0xFFFDFBF7),
            border: Border.all(color: const Color(0xFF8C7355).withValues(alpha: 0.35)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: (leaf.heroPhotoPath != null && leaf.heroPhotoPath!.isNotEmpty)
                    ? Image.file(
                        File(leaf.heroPhotoPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => CustomPaint(
                          painter: FolioShanshuiArtPainter(
                            realm: leaf.sceneryAtmosphere.realm,
                            isDark: theme.isDark,
                            atmosphere: leaf.sceneryAtmosphere,
                          ),
                        ),
                      )
                    : CustomPaint(
                        painter: FolioShanshuiArtPainter(
                          realm: leaf.sceneryAtmosphere.realm,
                          isDark: theme.isDark,
                          atmosphere: leaf.sceneryAtmosphere,
                        ),
                      ),
              ),
              Positioned.fill(child: CustomPaint(painter: _SilkCornerMountsPainter(silkColor: silkColor))),
            ],
          ),
        ),
        Positioned(
          top: -8,
          child: Transform.rotate(
            angle: -0.04,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xB8DEC183), Color(0xCCD2AD64), Color(0xADC8A055)]),
                border: Border.symmetric(vertical: BorderSide(color: const Color(0xFFAA823C).withValues(alpha: 0.45))),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: const Text(
                '泥金和纸胶带 · 拾光·珍藏拓影',
                style: TextStyle(fontSize: 8.5, letterSpacing: 1.0, fontWeight: FontWeight.w600, color: Color(0xFF5A4418)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReflectionOrPlaceholder(Color accentColor) {
    if (leaf.isZeroWordDraft) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.06),
          border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '「此卷留白，静待泼墨」',
            style: TextStyle(
              fontSize: 13.0,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w500,
              fontFamily: theme.fontFamily,
              color: accentColor,
            ),
          ),
        ),
      );
    }

    if (leaf.openingReflection != null && leaf.openingReflection!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.06),
          border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 0.8),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          leaf.openingReflection!,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.45,
            fontFamily: theme.fontFamily,
            color: theme.inkPrimary.withValues(alpha: 0.9),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBottomFooter(Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '扉页 · 第 1 / ${leaf.totalLeaves} 页',
          style: TextStyle(fontSize: 10.0, letterSpacing: 1.1, color: theme.inkSecondary),
        ),
        if (onTurnForward != null && !leaf.isZeroWordDraft)
          Semantics(
            button: true,
            label: '轻翻展读正文',
            child: GestureDetector(
              onTap: onTurnForward,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Text(
                  '轻翻展读正文 ⇢',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: accentColor),
                ),
              ),
            ),
          )
        else
          Text(leaf.isZeroWordDraft ? '卷末 · 静候落笔' : '', style: TextStyle(fontSize: 10.0, color: theme.inkSecondary)),
      ],
    );
  }
}

/// Paints the 4 classical silk mounting corners (`四角绫绢护角`) holding the artwork.
class _SilkCornerMountsPainter extends CustomPainter {
  final Color silkColor;
  const _SilkCornerMountsPainter({required this.silkColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = silkColor..style = PaintingStyle.fill;
    final linePaint = Paint()..color = const Color(0xFFAA823C).withValues(alpha: 0.6)..strokeWidth = 1.0;
    const s = 14.0;
    for (int cornerIndex = 0; cornerIndex < 4; cornerIndex++) {
      final path = Path();
      switch (cornerIndex) {
        case 0: // TL
          path..moveTo(0, 0)..lineTo(s, 0)..lineTo(0, s)..close();
          canvas.drawLine(const Offset(s, 0), const Offset(0, s), linePaint);
        case 1: // TR
          path..moveTo(size.width, 0)..lineTo(size.width - s, 0)..lineTo(size.width, s)..close();
          canvas.drawLine(Offset(size.width - s, 0), Offset(size.width, s), linePaint);
        case 2: // BL
          path..moveTo(0, size.height)..lineTo(s, size.height)..lineTo(0, size.height - s)..close();
          canvas.drawLine(Offset(s, size.height), Offset(0, size.height - s), linePaint);
        case 3: // BR
          path..moveTo(size.width, size.height)..lineTo(size.width - s, size.height)..lineTo(size.width, size.height - s)..close();
          canvas.drawLine(Offset(size.width - s, size.height), Offset(size.width, size.height - s), linePaint);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SilkCornerMountsPainter oldDelegate) => oldDelegate.silkColor != silkColor;
}
