import 'package:flutter/material.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../models/letterhead_data.dart';

/// Date line 1 (`yyyy年M月d日 周X`) over the muted date line 2
/// (`<lunar day> · <solar term>`) of the Journal Letterhead.
///
/// Neither line is ever truncated with an ellipsis. When line 2 does not fit,
/// the solar term is dropped first; a line that still does not fit scales down
/// so the solar date is never cut.
class LetterheadDateBlock extends StatelessWidget {
  const LetterheadDateBlock({super.key, required this.data});

  static const double fontSize = 13;

  final LetterheadData data;

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    final solarStyle = TextStyle(
      fontFamily: InkDiaryTheme.fontKaiti,
      fontSize: fontSize,
      height: 1.25,
      fontWeight: FontWeight.w600,
      color: tokens.nongmo,
    );
    final lunarStyle = solarStyle.copyWith(
      fontWeight: FontWeight.w400,
      color: tokens.danmo,
    );

    return Semantics(
      label: data.dateSemanticsLabel,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final lunarText = _lunarTextThatFits(context, constraints.maxWidth, lunarStyle);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScaleDownLine(
                child: Text(
                  data.solarDateLine,
                  key: const Key('letterhead_solar_line'),
                  softWrap: false,
                  style: solarStyle,
                ),
              ),
              if (lunarText != null)
                _ScaleDownLine(
                  child: Text(
                    lunarText,
                    key: const Key('letterhead_lunar_line'),
                    softWrap: false,
                    style: lunarStyle,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// The lunar line with the solar term when it fits [maxWidth], else without.
  String? _lunarTextThatFits(BuildContext context, double maxWidth, TextStyle style) {
    final withTerm = data.lunarLineWithTerm;
    if (withTerm == null) return null;

    final painter = TextPainter(
      text: TextSpan(text: withTerm, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final fits = painter.width <= maxWidth;
    painter.dispose();
    return fits ? withTerm : data.lunarDayLine;
  }
}

class _ScaleDownLine extends StatelessWidget {
  const _ScaleDownLine({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}
