import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../models/thought_spark.dart';
import '../services/thought_spark_service.dart';

/// Dismissible micro-prompt card providing inspirational reflection cues
/// styled as a warm handmade parchment card with classical amber deckle edging.
class ThoughtSparkBanner extends StatefulWidget {
  final ThoughtSparkService sparkService;
  final ValueChanged<String> onInsertPrompt;
  final VoidCallback onDismiss;

  const ThoughtSparkBanner({
    super.key,
    required this.sparkService,
    required this.onInsertPrompt,
    required this.onDismiss,
  });

  @override
  State<ThoughtSparkBanner> createState() => _ThoughtSparkBannerState();
}

class _ThoughtSparkBannerState extends State<ThoughtSparkBanner> {
  late ThoughtSpark _spark;

  @override
  void initState() {
    super.initState();
    _spark = widget.sparkService.getRandomSpark();
  }

  void _shuffle() {
    HapticFeedback.lightImpact();
    setState(() {
      _spark = widget.sparkService.nextSpark();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF6E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x73DEB366),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.jiaomo.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Top Bar
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 17,
                color: Color(0xFF99601D),
              ),
              const SizedBox(width: 7),
              Text(
                'Thought Spark',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7D4915),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                ' · ',
                style: TextStyle(
                  color: const Color(0xFF99601D).withValues(alpha: 0.8),
                ),
              ),
              Text(
                '灵感火花',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontKaiti,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7D4915),
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              // Shuffle button
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(Icons.refresh, color: Color(0xFF99601D)),
                tooltip: '换一则灵感',
                onPressed: _shuffle,
              ),
              const SizedBox(width: 4),
              // Dismiss button
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(Icons.close, color: Color(0xFF99601D)),
                tooltip: '隐去灵感',
                onPressed: widget.onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Prompt Body Text
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              '“${_spark.localizedPrompt}”',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 14.5,
                height: 1.45,
                color: tokens.jiaomo,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Action Button
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onInsertPrompt(_spark.localizedPrompt);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.post_add,
                      size: 15,
                      color: Color(0xFF7D4915),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '由此落墨 · ',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontKaiti,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7D4915),
                      ),
                    ),
                    Text(
                      'Use Prompt',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7D4915),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
