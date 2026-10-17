import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../editor/screens/entry_editor_screen.dart';
import '../../timeline/models/timeline_entry_item.dart';
import '../../timeline/screens/entry_detail_screen.dart';
import '../../timeline/widgets/entry_summary_card.dart';
import '../services/calendar_week_utils.dart';

/// Dedicated Weekly Review aggregation dashboard displaying Monday-to-Sunday daily cards
/// (supporting multiple entries per day), mood summaries, and weekly debrief drafting.
class WeeklyReviewScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final int? initialYear;
  final int? initialWeekNumber;

  const WeeklyReviewScreen({
    super.key,
    required this.database,
    required this.mediaService,
    this.initialYear,
    this.initialWeekNumber,
  });

  @override
  State<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends State<WeeklyReviewScreen> {
  late int _year;
  late int _weekNumber;

  List<Entry> _weekEntries = [];
  Entry? _weeklyDebrief;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final nowInfo = CalendarWeekUtils.getIsoWeekAndYear(DateTime.now());
    _year = widget.initialYear ?? nowInfo.year;
    _weekNumber = widget.initialWeekNumber ?? nowInfo.weekNumber;
    _loadWeekData();
  }

  Future<void> _loadWeekData() async {
    setState(() => _isLoading = true);

    try {
      final entries =
          await widget.database.getEntriesForCalendarWeek(_year, _weekNumber);
      final debrief =
          await widget.database.getWeeklyReviewEntry(_year, _weekNumber);

      if (mounted) {
        setState(() {
          _weekEntries = entries;
          _weeklyDebrief = debrief;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrint('Error loading weekly review data: $e\n$st');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _stepWeek(int delta) {
    final next = CalendarWeekUtils.getAdjacentWeek(_year, _weekNumber, delta);
    setState(() {
      _year = next.year;
      _weekNumber = next.weekNumber;
    });
    _loadWeekData();
  }

  void _jumpToCurrentWeek() {
    final nowInfo = CalendarWeekUtils.getIsoWeekAndYear(DateTime.now());
    setState(() {
      _year = nowInfo.year;
      _weekNumber = nowInfo.weekNumber;
    });
    _loadWeekData();
  }

  Future<void> _handleStartOrOpenDebrief() async {
    if (_weeklyDebrief != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EntryDetailScreen(
            entry: _weeklyDebrief!,
            database: widget.database,
            mediaService: widget.mediaService,
          ),
        ),
      );
      if (mounted) {
        await _loadWeekData();
      }
      return;
    }

    final newId = const Uuid().v4();
    final notebooks = await widget.database.getAllNotebooks();
    final notebookId =
        notebooks.isNotEmpty ? notebooks.first.id : 'notebook_default';
    final range = CalendarWeekUtils.getIsoWeekRange(_year, _weekNumber);
    final debriefDate = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      20,
      0,
    );

    await widget.database.createEntry(
      EntriesCompanion.insert(
        id: newId,
        notebookId: notebookId,
        templateId: 'template_weekly_review',
        title: Value('Week $_weekNumber Review'),
        contentDelta: jsonEncode([
          {'insert': '\n'}
        ]),
        plainText: '',
        entryDate: debriefDate,
        isWeeklyReview: const Value(true),
        weekNumber: Value(_weekNumber),
      ),
    );

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EntryEditorScreen(
          database: widget.database,
          mediaSandboxService: widget.mediaService,
          entryId: newId,
        ),
      ),
    );

    if (mounted) {
      await _loadWeekData();
    }
  }

  Future<void> _handleAddEntryForDate(DateTime day) async {
    final newId = const Uuid().v4();
    final notebooks = await widget.database.getAllNotebooks();
    final notebookId =
        notebooks.isNotEmpty ? notebooks.first.id : 'notebook_default';
    final defaultTemplateId = notebooks.isNotEmpty
        ? notebooks.first.defaultTemplateId
        : 'template_minimalist_white';

    final entryDateTime = DateTime(day.year, day.month, day.day, 12, 0);

    await widget.database.createEntry(
      EntriesCompanion.insert(
        id: newId,
        notebookId: notebookId,
        templateId: defaultTemplateId,
        title: const Value(''),
        contentDelta: jsonEncode([
          {'insert': '\n'}
        ]),
        plainText: '',
        entryDate: entryDateTime,
      ),
    );

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EntryEditorScreen(
          database: widget.database,
          mediaSandboxService: widget.mediaService,
          entryId: newId,
        ),
      ),
    );

    if (mounted) {
      await _loadWeekData();
    }
  }

  void _navigateToDetail(Entry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EntryDetailScreen(
          entry: entry,
          database: widget.database,
          mediaService: widget.mediaService,
        ),
      ),
    ).then((_) {
      if (mounted) _loadWeekData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupedByDay = CalendarWeekUtils.groupEntriesByWeekday(
      _weekEntries,
      _year,
      _weekNumber,
    );
    final dailyEntriesCount =
        groupedByDay.values.fold<int>(0, (sum, list) => sum + list.length);

    // Aggregate mood counts across daily entries
    final moodCounts = <int, int>{};
    for (final list in groupedByDay.values) {
      for (final e in list) {
        if (e.mood != null) {
          moodCounts[e.mood!] = (moodCounts[e.mood!] ?? 0) + 1;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weekly Review',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            key: const Key('jump_current_week_button'),
            onPressed: _jumpToCurrentWeek,
            icon: const Icon(Icons.today, size: 18),
            label: const Text('This Week'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Week Stepper Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  key: const Key('prev_week_button'),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous Week',
                  onPressed: () => _stepWeek(-1),
                ),
                Column(
                  children: [
                    Text(
                      'Week $_weekNumber, $_year',
                      key: const Key('week_header_title'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CalendarWeekUtils.formatWeekRange(_year, _weekNumber),
                      key: const Key('week_header_range'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  key: const Key('next_week_button'),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next Week',
                  onPressed: () => _stepWeek(1),
                ),
              ],
            ),
          ),

          // 2. Main Scrollable Dashboard
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadWeekData,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Weekly Highlights Bar
                        _buildSummaryBanner(
                          theme,
                          dailyEntriesCount,
                          moodCounts,
                        ),
                        const SizedBox(height: 16),

                        // Weekly Debrief Card
                        _buildWeeklyDebriefSection(theme),
                        const SizedBox(height: 20),

                        Text(
                          'MONDAY – SUNDAY DAILY LOGS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 7-Day Aggregated Cards (Multi-Entry per Day Safe)
                        ...groupedByDay.entries.map(
                          (entry) => _buildDaySection(
                            theme,
                            entry.key,
                            entry.value,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBanner(
    ThemeData theme,
    int dailyEntriesCount,
    Map<int, int> moodCounts,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(90),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insights_rounded,
            color: theme.colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            '$dailyEntriesCount ${dailyEntriesCount == 1 ? 'Entry' : 'Entries'}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (moodCounts.isNotEmpty)
            Wrap(
              spacing: 8,
              children: moodCounts.entries.map((m) {
                final emoji = EntrySummaryCard.moodEmojis[m.key] ?? '🙂';
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$emoji ${m.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Text(
              'No moods logged yet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyDebriefSection(ThemeData theme) {
    final hasDebrief = _weeklyDebrief != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: hasDebrief
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: hasDebrief ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasDebrief
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hasDebrief
                        ? 'W$_weekNumber Debrief Completed'
                        : 'W$_weekNumber Debrief Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: hasDebrief
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  key: const Key('weekly_debrief_action_button'),
                  onPressed: _handleStartOrOpenDebrief,
                  icon: Icon(
                    hasDebrief
                        ? Icons.menu_book_outlined
                        : Icons.rate_review_outlined,
                    size: 16,
                  ),
                  label: Text(hasDebrief ? 'Open Debrief' : 'Start Review'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (hasDebrief) ...[
              Text(
                (_weeklyDebrief!.title?.trim().isNotEmpty ?? false)
                    ? _weeklyDebrief!.title!.trim()
                    : 'Week $_weekNumber Review',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_weeklyDebrief!.plainText.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _weeklyDebrief!.plainText.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ] else
              Text(
                'Synthesize this week\'s key moments, lessons, and gratitude in a dedicated weekly review entry.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySection(
    ThemeData theme,
    DateTime day,
    List<Entry> dayEntries,
  ) {
    final dayLabel = DateFormat('EEEE, MMM d').format(day);

    return Container(
      key: Key('weekday_card_${day.weekday}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dayLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              if (dayEntries.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${dayEntries.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                key: Key('add_entry_day_${day.weekday}'),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                tooltip: 'Add entry for $dayLabel',
                visualDensity: VisualDensity.compact,
                onPressed: () => _handleAddEntryForDate(day),
              ),
            ],
          ),
          if (dayEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'No entry recorded',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            // Watchpoint 1: Render stacked cards for all entries logged on this day
            Column(
              children: dayEntries.map((entry) {
                final item = TimelineEntryItem(entry: entry);
                final isSealed = item.isSealedTimeCapsule;
                final moodEmoji = entry.mood != null
                    ? EntrySummaryCard.moodEmojis[entry.mood!]
                    : null;
                final weatherIcon = entry.weather != null
                    ? EntrySummaryCard.weatherIcons[entry.weather!]
                    : null;
                final timeLabel = DateFormat('h:mm a').format(entry.entryDate);

                return InkWell(
                  key: Key('weekly_entry_item_${entry.id}'),
                  onTap: isSealed ? null : () => _navigateToDetail(entry),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(120),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    timeLabel,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (isSealed) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.lock_outline, size: 14),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Sealed Time Capsule',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (!isSealed) ...[
                                if (entry.title?.trim().isNotEmpty ?? false) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.title!.trim(),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                                if (entry.plainText.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    entry.plainText.trim(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        if (moodEmoji != null || weatherIcon != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (moodEmoji != null)
                                Text(
                                  moodEmoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              if (weatherIcon != null) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  weatherIcon,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
