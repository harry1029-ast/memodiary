import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../services/event_suggestion_service.dart';

/// Interactive 1-tap "Smart Event Suggestions" association chips displayed in SearchScreen
/// styled with authentic literati slip tags.
class EventSuggestionChips extends StatelessWidget {
  final List<EventSuggestion> suggestions;
  final String? activeTerm;
  final ValueChanged<EventSuggestion> onSuggestionTapped;

  const EventSuggestionChips({
    super.key,
    required this.suggestions,
    this.activeTerm,
    required this.onSuggestionTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final tokens = InkDiaryTheme.tokensOf(context);

    return Container(
      key: const Key('smart_event_suggestions_bar'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: tokens.cinnabar,
              ),
              const SizedBox(width: 6),
              Text(
                '灵犀物候联想',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: tokens.cinnabar,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                ' · 依笔意析出',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontKaiti,
                  fontSize: 11,
                  color: tokens.danmo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions.map((suggestion) {
                final isSelected = activeTerm != null &&
                    activeTerm!.trim().toLowerCase() ==
                        suggestion.term.trim().toLowerCase();

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    key: Key('event_chip_${suggestion.term}'),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onSuggestionTapped(suggestion);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? tokens.cinnabarWash : tokens.ricePaper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? tokens.cinnabar : tokens.agedFiber,
                          width: isSelected ? 1.4 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            suggestion.isCurated ? Icons.bookmark_border_rounded : Icons.tag_rounded,
                            size: 13,
                            color: isSelected ? tokens.cinnabar : tokens.danmo,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${suggestion.label} · ${suggestion.count}',
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontKaiti,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? tokens.cinnabar : tokens.jiaomo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
