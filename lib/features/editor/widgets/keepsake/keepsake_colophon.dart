import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../../templates/models/template_style.dart';
import '../../../templates/services/stationery_geometry.dart';
import '../../../templates/widgets/template_canvas_painter.dart';
import '../cinnabar_signature_seal.dart';

/// Renders the terminal colophon (题跋落款) with date, mood/weather, and Cinnabar Signature Seal.
class KeepsakeColophon extends StatelessWidget {
  final Entry entry;
  final TemplateStyle style;
  final Color inkColor;
  final double columnWidth;

  const KeepsakeColophon({
    super.key,
    required this.entry,
    required this.style,
    required this.inkColor,
    this.columnWidth = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    final colophon = StationeryGeometry.buildColophon(entry);

    return Container(
      width: TemplateCanvasPainter.kVerticalColumnStride * 2,
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Vertical Colophon Metadata aligned in the guaranteed-unruled leftmost lane
          Flexible(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: TemplateCanvasPainter.kVerticalColumnStride,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: Semantics(
                    container: true,
                    label: colophon.fullLabel,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildVerticalRun(colophon.dateLine),
                        if (colophon.detailParts.isNotEmpty) ...[
                          const SizedBox(height: 10.0),
                          _buildVerticalRun(colophon.detailLine),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8.0),

          // User's Cinnabar Signature Seal
          CinnabarSignatureSeal(
            key: const Key('keepsake_signature_seal'),
            sealStyle: style.tokens.sealStyle,
            size: 44.0,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalRun(String text) {
    final chars = text.split('');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: chars.map((ch) {
        if (ch == ' ') return const SizedBox(height: 6.0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.5),
          child: Text(
            ch,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontKaiti,
              fontSize: 11.0,
              color: inkColor.withValues(alpha: 0.65),
              height: 1.0,
            ),
          ),
        );
      }).toList(),
    );
  }
}
