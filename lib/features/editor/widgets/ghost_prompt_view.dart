import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../models/thought_spark.dart';

/// In-line reflection cue rendered gently inside the empty Journal Sheet.
/// Automatically hides when the entry contains user text, and provides
/// a 1-tap "由此题落墨" action to adopt the spark as an opening quote.
class GhostPromptView extends StatelessWidget {
  final QuillController controller;
  final ThoughtSpark spark;
  final VoidCallback onAdoptPrompt;
  final VoidCallback? onShuffle;

  const GhostPromptView({
    super.key,
    required this.controller,
    required this.spark,
    required this.onAdoptPrompt,
    this.onShuffle,
  });

  bool get _isDocumentEmpty {
    final plainText = controller.document.toPlainText().trim();
    return plainText.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!_isDocumentEmpty) {
          return const SizedBox.shrink();
        }

        final tokens = InkDiaryTheme.tokensOf(context);

        return Container(
          margin: const EdgeInsets.only(top: 8, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: tokens.agedFiber.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: tokens.deckleBorder.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 15,
                color: tokens.cinnabar.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '“${spark.localizedPrompt}”',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontKaiti,
                        fontSize: 14.5,
                        fontStyle: FontStyle.italic,
                        height: 1.45,
                        color: tokens.danmo,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onAdoptPrompt();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_note,
                                  size: 16,
                                  color: tokens.cinnabar,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '由此题落墨 · Adopt Prompt',
                                  style: TextStyle(
                                    fontFamily: InkDiaryTheme.fontKaiti,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: tokens.cinnabar,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (onShuffle != null) ...[
                          const SizedBox(width: 12),
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onShuffle!();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    size: 13,
                                    color: tokens.danmo,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '换一则',
                                    style: TextStyle(
                                      fontFamily: InkDiaryTheme.fontKaiti,
                                      fontSize: 11.5,
                                      color: tokens.danmo,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
