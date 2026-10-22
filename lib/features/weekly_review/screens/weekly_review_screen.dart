import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/cinnabar_seal_badge.dart';
import '../../../core/theme/widgets/xuan_paper_card.dart';
import '../../editor/screens/entry_editor_screen.dart';
import '../../timeline/models/timeline_entry_item.dart';
import '../../timeline/screens/entry_detail_screen.dart';
import '../../timeline/widgets/entry_summary_card.dart';
import '../services/calendar_week_utils.dart';
import 'weekly_debrief_detail_screen.dart';

/// Dedicated Weekly Review aggregation dashboard displaying Monday-to-Sunday daily cards,
/// mood summaries, and weekly debrief drafting in classical Ink & Paper literati aesthetic.
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
    HapticFeedback.lightImpact();
    final next = CalendarWeekUtils.getAdjacentWeek(_year, _weekNumber, delta);
    setState(() {
      _year = next.year;
      _weekNumber = next.weekNumber;
    });
    _loadWeekData();
  }

  void _jumpToCurrentWeek() {
    HapticFeedback.lightImpact();
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
          builder: (_) => WeeklyDebriefDetailScreen(
            debriefEntry: _weeklyDebrief!,
            weekEntries: _weekEntries,
            year: _year,
            weekNumber: _weekNumber,
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
        title: Value('第$_weekNumber周 · 周志复盘'),
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
    final tokens = InkDiaryTheme.tokensOf(context);

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
      backgroundColor: tokens.xuanGround,
      appBar: AppBar(
        backgroundColor: tokens.xuanGround,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: tokens.agedFiber, width: 1.0),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tokens.jiaomo),
          tooltip: '返回',
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '周志复盘',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: tokens.jiaomo,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Weekly Review',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 12,
                    color: tokens.danmo,
                  ),
                ),
              ],
            ),
            Text(
              'WEEKLY RETROSPECTIVE',
              style: TextStyle(
                fontSize: 9,
                color: tokens.danmo,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              key: const Key('jump_current_week_button'),
              onTap: _jumpToCurrentWeek,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.ricePaper,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tokens.agedFiber),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 13, color: tokens.cinnabar),
                    const SizedBox(width: 4),
                    Text(
                      '本周',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontKaiti,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: tokens.jiaomo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Week Horizon Navigator Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: XuanPaperCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: const Key('prev_week_button'),
                    icon: Icon(Icons.chevron_left, color: tokens.jiaomo),
                    tooltip: '上一周',
                    onPressed: () => _stepWeek(-1),
                  ),
                  Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Week $_weekNumber, $_year',
                            key: const Key('week_header_title'),
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontNotoSerif,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: tokens.jiaomo,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(第$_weekNumber周)',
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontKaiti,
                              fontSize: 12,
                              color: tokens.danmo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CalendarWeekUtils.formatWeekRange(_year, _weekNumber),
                        key: const Key('week_header_range'),
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontKaiti,
                          fontSize: 11,
                          color: tokens.danmo,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    key: const Key('next_week_button'),
                    icon: Icon(Icons.chevron_right, color: tokens.jiaomo),
                    tooltip: '下一周',
                    onPressed: () => _stepWeek(1),
                  ),
                ],
              ),
            ),
          ),

          // 2. Main Scrollable Dashboard
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: tokens.cinnabar))
                : RefreshIndicator(
                    color: tokens.cinnabar,
                    onRefresh: _loadWeekData,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      children: [
                        // Weekly Inscription & Mood Status Bar
                        _buildStatusRibbon(tokens, dailyEntriesCount, moodCounts),
                        const SizedBox(height: 14),

                        // Weekly Debrief Feature Card
                        _buildWeeklyDebriefSection(tokens, dailyEntriesCount),
                        const SizedBox(height: 20),

                        // Section Title: Daily Logs Flow
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 3.5,
                                  height: 15,
                                  decoration: BoxDecoration(
                                    color: tokens.cinnabar,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  '一候七日 · 每日随笔',
                                  style: TextStyle(
                                    fontFamily: InkDiaryTheme.fontNotoSerif,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: tokens.jiaomo,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'MONDAY – SUNDAY',
                              style: TextStyle(
                                fontSize: 10,
                                color: tokens.danmo,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // 7-Day Aggregated Cards
                        ...groupedByDay.entries.map(
                          (entry) => _buildDaySection(tokens, entry.key, entry.value),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRibbon(
    InkDiaryTokens tokens,
    int dailyEntriesCount,
    Map<int, int> moodCounts,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.ricePaper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.agedFiber),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note, color: tokens.cinnabar, size: 20),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$dailyEntriesCount 卷墨稿',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: tokens.jiaomo,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$dailyEntriesCount ${dailyEntriesCount == 1 ? "Entry" : "Entries"}',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 11,
                  color: tokens.danmo,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            dailyEntriesCount > 0 ? '· 秋思已成章' : '· 暂无录存',
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontKaiti,
              fontSize: 12,
              color: tokens.danmo,
            ),
          ),
          const Spacer(),
          if (moodCounts.isNotEmpty)
            Wrap(
              spacing: 6,
              children: moodCounts.entries.map((m) {
                final emoji = EntrySummaryCard.moodEmojis[m.key] ?? '🙂';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tokens.xuanGround,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.agedFiber),
                  ),
                  child: Text(
                    '$emoji ${m.value}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyDebriefSection(InkDiaryTokens tokens, int dailyEntriesCount) {
    final hasDebrief = _weeklyDebrief != null;
    final progress = (dailyEntriesCount / 7.0).clamp(0.0, 1.0);

    return XuanPaperCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CinnabarSealBadge(
                    text: hasDebrief ? 'W$_weekNumber 复盘已毕' : 'W$_weekNumber 待复盘',
                    isRound: false,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasDebrief ? 'W$_weekNumber Debrief Completed' : 'W$_weekNumber Debrief Pending',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tokens.danmo,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                key: const Key('weekly_debrief_action_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.jiaomo,
                  foregroundColor: tokens.xuanGround,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _handleStartOrOpenDebrief,
                icon: Icon(
                  hasDebrief ? Icons.auto_stories : Icons.rate_review_outlined,
                  size: 15,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasDebrief ? '阅览周述' : '落墨启撰',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasDebrief ? 'View Review' : 'Start Review',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasDebrief && (_weeklyDebrief!.title?.trim().isNotEmpty ?? false)
                ? _weeklyDebrief!.title!.trim()
                : '第$_weekNumber周 · 凝思复盘录',
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: tokens.jiaomo,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasDebrief && _weeklyDebrief!.plainText.trim().isNotEmpty
                ? _weeklyDebrief!.plainText.trim()
                : '草木渐深，砚池微凉。提炼本周要事、心境起伏与所获体悟，以墨凝思。',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontKaiti,
              fontSize: 12.5,
              height: 1.45,
              color: tokens.danmo,
            ),
          ),
          const SizedBox(height: 12),

          // Metaphor gauge progress
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: tokens.agedFiber,
                    valueColor: AlwaysStoppedAnimation<Color>(tokens.cinnabar),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '节候律动 $dailyEntriesCount/7',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontKaiti,
                  fontSize: 11,
                  color: tokens.danmo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(InkDiaryTokens tokens, DateTime day, List<Entry> dayEntries) {
    final dayLabel = DateFormat('M月d日 · EEEE').format(day);

    return Container(
      key: Key('weekday_card_${day.weekday}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.ricePaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.agedFiber),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    dayLabel,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: tokens.jiaomo,
                    ),
                  ),
                  if (dayEntries.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: tokens.cinnabarWash,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${dayEntries.length} 篇',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: tokens.cinnabar,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              IconButton(
                key: Key('add_entry_day_${day.weekday}'),
                icon: Icon(Icons.add_circle_outline, size: 18, color: tokens.danmo),
                tooltip: '添笔本日日志',
                visualDensity: VisualDensity.compact,
                onPressed: () => _handleAddEntryForDate(day),
              ),
            ],
          ),
          if (dayEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '今日虚白，未有染毫',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontKaiti,
                  fontSize: 12,
                  color: tokens.danmo.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              children: dayEntries.map((entry) {
                final item = TimelineEntryItem(entry: entry);
                final isSealed = item.isSealedTimeCapsule;
                final moodEmoji = entry.mood != null ? EntrySummaryCard.moodEmojis[entry.mood!] : null;
                final timeLabel = DateFormat('HH:mm').format(entry.entryDate);

                return InkWell(
                  key: Key('weekly_entry_item_${entry.id}'),
                  onTap: isSealed ? null : () => _navigateToDetail(entry),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tokens.xuanGround,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: tokens.agedFiber),
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
                                    style: TextStyle(
                                      fontFamily: InkDiaryTheme.fontKaiti,
                                      fontSize: 11,
                                      color: tokens.danmo,
                                    ),
                                  ),
                                  if (moodEmoji != null) ...[
                                    const SizedBox(width: 6),
                                    Text(moodEmoji, style: const TextStyle(fontSize: 13)),
                                  ],
                                  if (isSealed) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.lock_clock, size: 12, color: tokens.cinnabar),
                                    const SizedBox(width: 4),
                                    Text(
                                      '封缄胶囊',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: tokens.cinnabar,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (!isSealed) ...[
                                if (entry.title?.trim().isNotEmpty ?? false) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    entry.title!.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: InkDiaryTheme.fontNotoSerif,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: tokens.jiaomo,
                                    ),
                                  ),
                                ],
                                if (entry.plainText.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    entry.plainText.trim(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: InkDiaryTheme.fontKaiti,
                                      fontSize: 11.5,
                                      color: tokens.nongmo,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Right Seal Stamp "印"
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: tokens.cinnabar,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Center(
                            child: Text(
                              '印',
                              style: TextStyle(
                                fontFamily: InkDiaryTheme.fontNotoSerif,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: tokens.xuanGround,
                              ),
                            ),
                          ),
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
