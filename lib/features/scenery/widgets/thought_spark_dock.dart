import 'package:flutter/material.dart';
import '../../../core/theme/ink_diary_theme.dart';

/// Frosted semi-transparent glassmorphic Xuan-paper overlay docked at the bottom
/// of the 16:9 [ShanshuiSceneryCard], presenting daily reflective prompts and the
/// "由此题落墨" write shortcut.
class ThoughtSparkDock extends StatelessWidget {
  final String prompt;
  final VoidCallback onRefreshPrompt;
  final ValueChanged<String> onWritePrompt;

  const ThoughtSparkDock({
    super.key,
    required this.prompt,
    required this.onRefreshPrompt,
    required this.onWritePrompt,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<InkDiaryTokens>() ?? InkDiaryTokens.light;

    return Container(
      key: const Key('thought_spark_dock'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xE61E1A17), // Deep ink semi-transparent frost
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.cinnabar,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '灵感火花 · THOUGHT SPARK',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: const Color(0xFFD6CEBE),
                ),
              ),
              const Spacer(),
              Semantics(
                label: '更换灵感题目',
                button: true,
                child: InkWell(
                  key: const Key('thought_spark_refresh_button'),
                  onTap: onRefreshPrompt,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 15,
                      color: Color(0xFFA69F91),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '“$prompt”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontLiterata,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                    color: const Color(0xFFF7F4EB),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: '由此题落墨写日记',
                button: true,
                child: TextButton.icon(
                  key: const Key('thought_spark_write_button'),
                  onPressed: () => onWritePrompt(prompt),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    foregroundColor: tokens.cinnabar,
                    backgroundColor: tokens.cinnabar.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.brush, size: 12),
                  label: const Text(
                    '由此题落墨',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

