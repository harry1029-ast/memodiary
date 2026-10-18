import 'package:flutter/material.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/analytics/services/analytics_service.dart';
import 'package:memodiary/features/analytics/widgets/yearly_contribution_heatmap.dart';
import 'package:memodiary/features/timeline/widgets/entry_summary_card.dart';

/// Writing Analytics & Yearly Contribution Heatmap Dashboard Screen.
class AnalyticsDashboardScreen extends StatefulWidget {
  final AppDatabase database;
  final DateTime? referenceDate;

  const AnalyticsDashboardScreen({
    super.key,
    required this.database,
    this.referenceDate,
  });

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  WritingStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await AnalyticsService.computeStats(
      widget.database,
      referenceToday: widget.referenceDate,
    );
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Writing Analytics'),
      ),
      body: _isLoading || _stats == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Summary Metric Cards (2x2 Grid)
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          theme: theme,
                          icon: Icons.book_outlined,
                          label: 'Total Entries',
                          value: '${_stats!.totalEntries}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          theme: theme,
                          icon: Icons.text_snippet_outlined,
                          label: 'Words / Chars',
                          value: '${_stats!.totalWords}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          theme: theme,
                          icon: Icons.local_fire_department_outlined,
                          label: 'Current Streak',
                          value: '${_stats!.currentStreakDays} days',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          theme: theme,
                          icon: Icons.emoji_events_outlined,
                          label: 'Longest Streak',
                          value: '${_stats!.longestStreakDays} days',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. 52-Week Contribution Heatmap
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withAlpha(100),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yearly Writing Heatmap (52 Weeks)',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          YearlyContributionHeatmap(
                            dailyActivityMap: _stats!.dailyActivityMap,
                            referenceDate: widget.referenceDate,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Mood Distribution Breakdown
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withAlpha(100),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mood Distribution',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildMoodBreakdown(theme, _stats!.moodCounts),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatTile({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBreakdown(ThemeData theme, Map<int, int> moodCounts) {
    final totalMoods = moodCounts.values.fold<int>(0, (sum, c) => sum + c);

    return Column(
      children: [
        for (int mood = 5; mood >= 1; mood--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Text(
                  EntrySummaryCard.moodEmojis[mood] ?? '',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: totalMoods > 0
                          ? (moodCounts[mood] ?? 0) / totalMoods
                          : 0.0,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${moodCounts[mood] ?? 0}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
