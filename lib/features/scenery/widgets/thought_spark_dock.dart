import 'package:flutter/material.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/shapes/classical_chinese_borders.dart';

/// Frosted semi-transparent glassmorphic Xuan-paper overlay docked at the bottom
/// of the 16:9 [ShanshuiSceneryCard], presenting daily reflective prompts,
/// the "由此题落墨" write shortcut, and a retractable toggle to reveal the full painting.
class ThoughtSparkDock extends StatelessWidget {
  final String prompt;
  final VoidCallback onRefreshPrompt;
  final ValueChanged<String> onWritePrompt;
  final VoidCallback? onHideDock;

  const ThoughtSparkDock({
    super.key,
    required this.prompt,
    required this.onRefreshPrompt,
    required this.onWritePrompt,
    this.onHideDock,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<InkDiaryTokens>() ?? InkDiaryTokens.light;

    return Container(
      key: const Key('thought_spark_dock'),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xE81C1916), // Deep ink semi-transparent frost
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
              const Text(
                '灵感火花 · THOUGHT SPARK',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Color(0xFFD6CEBE),
                ),
              ),
              if (onHideDock != null) ...[
                const SizedBox(width: 6),
                Semantics(
                  label: '隐藏灵感火花，尽赏完整山水',
                  button: true,
                  child: InkWell(
                    key: const Key('thought_spark_hide_button'),
                    onTap: onHideDock,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Color(0xFFE8E0D2),
                      ),
                    ),
                  ),
                ),
              ],
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                    color: Color(0xFFF7F4EB),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: '由此题落墨写日记',
                button: true,
                child: Container(
                  decoration: ShapeDecoration(
                    shape: const BegoniaPlaqueBorder(
                      cutSize: 4.0,
                      borderColor: Color(0xFFB83B2E),
                      borderWidth: 0.8,
                    ),
                    color: tokens.cinnabar.withValues(alpha: 0.18),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      key: const Key('thought_spark_write_button'),
                      onTap: () => onWritePrompt(prompt),
                      customBorder: const BegoniaPlaqueBorder(cutSize: 4.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.brush, size: 12, color: tokens.cinnabar),
                            const SizedBox(width: 4),
                            Text(
                              '由此题落墨',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: tokens.cinnabar,
                              ),
                            ),
                          ],
                        ),
                      ),
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
