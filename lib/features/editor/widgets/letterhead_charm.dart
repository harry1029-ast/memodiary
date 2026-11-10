import 'package:flutter/material.dart';

import '../../../core/theme/ink_diary_theme.dart';

/// A vertical calligraphy tag (Weather Charm / Mood Charm) hanging at the right
/// of the Journal Letterhead: an emoji above a two-character label set
/// vertically. Tapping it opens its picker.
///
/// The visible tag carries `Key(keyPrefix)`; its 44x44 touch target carries
/// `Key('${keyPrefix}_target')`.
class LetterheadCharm extends StatelessWidget {
  const LetterheadCharm({
    super.key,
    required this.keyPrefix,
    required this.emoji,
    required this.label,
    required this.semanticsLabel,
    required this.onTap,
  });

  static const double targetSize = 44;

  final String keyPrefix;
  final String emoji;
  final String label;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: InkWell(
        key: Key('${keyPrefix}_target'),
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: targetSize, minHeight: targetSize),
          child: Center(
            child: Container(
              key: Key(keyPrefix),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
              decoration: BoxDecoration(
                color: tokens.ricePaper.withValues(alpha: 0.9),
                border: Border.all(color: tokens.cinnabar.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), offset: Offset(1, 2), blurRadius: 4),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14, height: 1.2)),
                  const SizedBox(height: 2),
                  for (final character in label.split(''))
                    Text(
                      character,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontKaiti,
                        fontSize: 12,
                        height: 1.2,
                        color: tokens.danmo,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
