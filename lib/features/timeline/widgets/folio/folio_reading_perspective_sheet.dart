import 'package:flutter/material.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import 'folio_reading_perspective.dart';

/// Minimalist bottom sheet for non-destructively switching the Thread-Bound Folio
/// [ReadingPerspective] without modifying SQLite entries or templates.
class FolioReadingPerspectiveSheet extends StatelessWidget {
  final ReadingPerspective currentPerspective;
  final ValueChanged<ReadingPerspective> onPerspectiveSelected;

  const FolioReadingPerspectiveSheet({
    super.key,
    required this.currentPerspective,
    required this.onPerspectiveSelected,
  });

  /// Displays the reading perspective bottom sheet.
  static Future<ReadingPerspective?> show({
    required BuildContext context,
    required ReadingPerspective currentPerspective,
    required ValueChanged<ReadingPerspective> onPerspectiveSelected,
  }) {
    return showModalBottomSheet<ReadingPerspective>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => FolioReadingPerspectiveSheet(
        currentPerspective: currentPerspective,
        onPerspectiveSelected: onPerspectiveSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141312),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: const Color(0x33D4AF37), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag bar & header
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_stories_outlined, size: 20, color: tokens.cinnabar),
                      const SizedBox(width: 8),
                      const Text(
                        '展阅视角',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE6E1D8),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Perspective Options
              ...ReadingPerspective.values.map((perspective) {
                final isSelected = perspective == currentPerspective;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    key: Key('folio_perspective_option_${perspective.name}'),
                    onTap: () {
                      onPerspectiveSelected(perspective);
                      Navigator.pop(context, perspective);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0x1AD4AF37) : const Color(0x0DFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0x99D4AF37) : const Color(0x1AFFFFFF),
                          width: isSelected ? 1.2 : 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            size: 18,
                            color: isSelected ? const Color(0xFFD4AF37) : Colors.white38,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  perspective.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected ? const Color(0xFFFBF8F1) : const Color(0xFFB3ADA3),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  perspective.subtitle,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0x33D4AF37),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '当前',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
