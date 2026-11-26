import 'package:flutter/material.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../settings/services/signature_seal_service.dart';
import '../../templates/models/template_style.dart';
import '../../templates/services/stationery_geometry.dart';

/// Renders the diarist's persistent colophon Cinnabar Signature Seal (落款朱砂印)
/// in 2×2 seal-carving calligraphy layout governed by the active template's [SealCarvingStyle].
class CinnabarSignatureSeal extends StatelessWidget {
  final SealCarvingStyle sealStyle;
  final String? overrideText;
  final SignatureSealService? sealService;
  final double size;
  final Color? sealColor;
  final Color? intaglioTextColor;
  final Color? zhuwenBackgroundColor;
  final String? fontFamily;
  final double? fontSize;
  final FontWeight fontWeight;
  final double? borderWidth;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;
  final bool includeSemantics;

  const CinnabarSignatureSeal({
    super.key,
    this.sealStyle = SealCarvingStyle.zhuwen,
    this.overrideText,
    this.sealService,
    this.size = 48.0,
    this.sealColor,
    this.intaglioTextColor,
    this.zhuwenBackgroundColor,
    this.fontFamily,
    this.fontSize,
    this.fontWeight = FontWeight.w900,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.boxShadow,
    this.includeSemantics = true,
  });

  @override
  Widget build(BuildContext context) {
    if (sealStyle == SealCarvingStyle.hidden) {
      return const SizedBox.shrink();
    }

    if (overrideText != null && overrideText!.trim().isNotEmpty) {
      return _buildSeal(context, overrideText!.trim());
    }

    final service = sealService ?? SignatureSealService();
    return FutureBuilder<String>(
      future: service.getSealText(),
      builder: (context, snapshot) {
        final text = snapshot.data ?? SignatureSealService.defaultSealText;
        return _buildSeal(context, text);
      },
    );
  }

  Widget _buildSeal(BuildContext context, String rawText) {
    final tokens = InkDiaryTheme.tokensOf(context);
    final layout = StationeryGeometry.buildSealLayout(
      text: rawText,
      sealStyle: sealStyle,
    );
    if (!layout.isVisible) {
      return const SizedBox.shrink();
    }

    final cinnabar = sealColor ?? tokens.sealCinnabar;
    final groundColor = intaglioTextColor ?? tokens.xuanGround;

    final sealWidget = Container(
      key: const Key('cinnabar_signature_seal'),
      width: size,
      height: size,
      padding: padding ?? EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: layout.isBaiwen
            ? cinnabar
            : (zhuwenBackgroundColor ?? Colors.transparent),
        border: Border.all(
          color: cinnabar,
          width: borderWidth ?? size * 0.05,
        ),
        borderRadius: BorderRadius.circular(borderRadius ?? size * 0.08),
        boxShadow: boxShadow,
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left column (read second in traditional R-to-L seal order)
          _buildColumn(layout.colLeft, layout.isBaiwen, cinnabar, groundColor),
          // Right column (read first in traditional R-to-L seal order)
          _buildColumn(layout.colRight, layout.isBaiwen, cinnabar, groundColor),
        ],
      ),
    );

    if (!includeSemantics) {
      return sealWidget;
    }

    return Semantics(
      label: '签名印章：${layout.semanticText}',
      container: true,
      excludeSemantics: true,
      child: sealWidget,
    );
  }

  Widget _buildColumn(
    List<String> chars,
    bool isBaiwen,
    Color cinnabar,
    Color groundColor,
  ) {
    final textColor = isBaiwen ? groundColor : cinnabar;
    final resolvedFontSize = fontSize ?? size * 0.32;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: chars.map((character) {
        return Text(
          character,
          style: TextStyle(
            fontFamily: fontFamily ?? InkDiaryTheme.fontNotoSerif,
            fontSize: resolvedFontSize,
            fontWeight: fontWeight,
            color: textColor,
            height: 1.0,
          ),
        );
      }).toList(),
    );
  }
}
