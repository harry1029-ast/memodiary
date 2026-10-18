import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:memodiary/core/database/app_database.dart';

/// Interactive Serendipity Memory Roulette card/dialog that randomly draws
/// an entry written >= 90 days ago for mindful rediscovery.
class SerendipityRouletteCard extends StatefulWidget {
  final AppDatabase database;
  final ValueChanged<Entry> onOpenEntry;
  final int minDaysAgo;

  const SerendipityRouletteCard({
    super.key,
    required this.database,
    required this.onOpenEntry,
    this.minDaysAgo = 90,
  });

  /// Shows the Serendipity Memory Roulette inside a modal dialog.
  static Future<void> show({
    required BuildContext context,
    required AppDatabase database,
    required ValueChanged<Entry> onOpenEntry,
    int minDaysAgo = 90,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SerendipityRouletteCard(
          database: database,
          minDaysAgo: minDaysAgo,
          onOpenEntry: (entry) {
            Navigator.pop(ctx);
            onOpenEntry(entry);
          },
        ),
      ),
    );
  }

  @override
  State<SerendipityRouletteCard> createState() => _SerendipityRouletteCardState();
}

class _SerendipityRouletteCardState extends State<SerendipityRouletteCard> {
  Entry? _drawnEntry;
  bool _isSpinning = true;

  @override
  void initState() {
    super.initState();
    _drawMemory();
  }

  Future<void> _drawMemory() async {
    setState(() => _isSpinning = true);
    HapticFeedback.lightImpact();

    final entry = await widget.database.getRandomOldEntry(
      minDaysAgo: widget.minDaysAgo,
    );

    if (mounted) {
      setState(() {
        _drawnEntry = entry;
        _isSpinning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Serendipity Memory Roulette',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isSpinning)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: CircularProgressIndicator(),
            )
          else if (_drawnEntry == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No unlocked memories older than ${widget.minDaysAgo} days yet. Keep writing to fill your time vault!',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(110),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(120),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(_drawnEntry!.entryDate),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (_drawnEntry!.title?.trim().isNotEmpty ?? false)
                        ? _drawnEntry!.title!.trim()
                        : 'Untitled Memory',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _drawnEntry!.isLocked
                        ? '🔒 This memory is PIN-locked.'
                        : _drawnEntry!.plainText.trim(),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                key: const Key('serendipity_draw_again_btn'),
                onPressed: _drawMemory,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Draw Another'),
              ),
              if (_drawnEntry != null) ...[
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('serendipity_open_entry_btn'),
                  onPressed: () => widget.onOpenEntry(_drawnEntry!),
                  child: const Text('Read Memory'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

