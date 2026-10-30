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

        return Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 14, left: 4, right: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // In-line watermark prompt text directly on paper rules
              Text(
                '“${spark.localizedPrompt}”',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontKaiti,
                  fontSize: 15.0,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                  color: tokens.danmo.withValues(alpha: 0.75),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              // 1-Tap "由此题落墨 · Adopt Prompt" action
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onAdoptPrompt();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
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
            ],
          ),
        );
      },
    );
  }
}
