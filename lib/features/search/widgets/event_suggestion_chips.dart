import 'package:flutter/material.dart';
import '../services/event_suggestion_service.dart';

/// Interactive 1-tap "Smart Event Suggestions" association chips displayed in SearchScreen.
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

    final theme = Theme.of(context);

    return Container(
      key: const Key('smart_event_suggestions_bar'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Smart Event Suggestions',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions.map((s) {
                final isSelected = activeTerm != null &&
                    activeTerm!.trim().toLowerCase() ==
                        s.term.trim().toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    key: Key('event_chip_${s.term}'),
                    avatar: Icon(
                      s.isCurated
                          ? Icons.bookmark_border_rounded
                          : Icons.tag_rounded,
                      size: 15,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    backgroundColor: isSelected
                        ? theme.colorScheme.primaryContainer
                        : null,
                    label: Text(
                      '${s.label} · ${s.count}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                    onPressed: () => onSuggestionTapped(s),
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

