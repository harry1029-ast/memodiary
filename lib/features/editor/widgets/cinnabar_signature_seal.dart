import 'package:flutter/material.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../settings/services/signature_seal_service.dart';
import '../../templates/models/template_style.dart';

/// Renders the diarist's persistent colophon Cinnabar Signature Seal (落款朱砂印)
/// in 2×2 seal-carving calligraphy layout governed by the active template's [SealCarvingStyle].
class CinnabarSignatureSeal extends StatelessWidget {
  final SealCarvingStyle sealStyle;
  final String? overrideText;
  final SignatureSealService? sealService;
  final double size;

  const CinnabarSignatureSeal({
    super.key,
    this.sealStyle = SealCarvingStyle.zhuwen,
    this.overrideText,
    this.sealService,
    this.size = 48.0,
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
    final text = rawText.trim().isEmpty ? SignatureSealService.defaultSealText : rawText.trim();
    final cinnabar = tokens.cinnabar;
    final isBaiwen = sealStyle == SealCarvingStyle.baiwen;

    // Split text into 2 columns for traditional right-to-left seal carving
    final (colRight, colLeft) = _partitionSealText(text);

    final sealWidget = Container(
      key: const Key('cinnabar_signature_seal'),
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: isBaiwen ? cinnabar : Colors.transparent,
        border: Border.all(
          color: cinnabar,
          width: size * 0.05,
        ),
        borderRadius: BorderRadius.circular(size * 0.08),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left column (read second in traditional R-to-L seal order)
          _buildColumn(colLeft, isBaiwen, tokens),
          // Right column (read first in traditional R-to-L seal order)
          _buildColumn(colRight, isBaiwen, tokens),
        ],
      ),
    );

    return Semantics(
      label: '落款朱砂印: $text',
      container: true,
      excludeSemantics: true,
      child: sealWidget,
    );
  }

  Widget _buildColumn(List<String> chars, bool isBaiwen, InkDiaryTokens tokens) {
    final textColor = isBaiwen ? tokens.xuanGround : tokens.cinnabar;
    final fontSize = size * 0.32;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: chars.map((ch) {
        return Text(
          ch,
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontNotoSerif,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: textColor,
            height: 1.0,
          ),
        );
      }).toList(),
    );
  }

  /// Partitions 2 to 4 characters into traditional Right and Left seal columns.
  /// Standard 4-char seal:
  ///   ColRight (Top to bottom): char 0, char 1
  ///   ColLeft  (Top to bottom): char 2, char 3
  (List<String>, List<String>) _partitionSealText(String text) {
    final chars = text.characters.take(4).toList();
    if (chars.length == 4) {
      return ([chars[0], chars[1]], [chars[2], chars[3]]);
    } else if (chars.length == 3) {
      return ([chars[0], chars[1]], [chars[2]]);
    } else if (chars.length == 2) {
      return ([chars[0]], [chars[1]]);
    } else if (chars.length == 1) {
      return ([chars[0]], []);
    }
    return (['心', '迹'], ['安', '放']);
  }
}
