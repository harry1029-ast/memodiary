import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/xuan_paper_card.dart';
import '../../timeline/widgets/entry_summary_card.dart';
import '../services/analytics_service.dart';
import '../widgets/yearly_contribution_heatmap.dart';

/// Writing Analytics & Yearly Contribution Heatmap Dashboard Screen in literati aesthetic.
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

  Future<void> _handleShareStats() async {
    if (_stats == null) return;
    final text = '【墨记 · 研墨统计】\n'
        '累积心迹：${_stats!.totalEntries} 篇\n'
        '挥毫字数：${_stats!.totalWords} 言\n'
        '当下持砚：${_stats!.currentStreakDays} 天\n'
        '最长连墨：${_stats!.longestStreakDays} 天\n'
        '—— 拾光日记 · 墨染素笺';

    await SharePlus.instance.share(
      ShareParams(text: text, subject: '墨记 · 研墨统计'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

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
                  '研墨统计',
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
                  'Writing Analytics',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 12,
                    color: tokens.danmo,
                  ),
                ),
              ],
            ),
            Text(
              'INK ANALYTICS',
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
              onTap: _handleShareStats,
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
                    Icon(Icons.share, size: 13, color: tokens.cinnabar),
                    const SizedBox(width: 4),
                    Text(
                      '印迹',
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
      body: _isLoading || _stats == null
          ? Center(child: CircularProgressIndicator(color: tokens.cinnabar))
          : RefreshIndicator(
              color: tokens.cinnabar,
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // 1. Primary 4-Metric Grid (Tactile Xuan Paper Tiles)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          tokens: tokens,
                          icon: Icons.collections_bookmark_outlined,
                          title: '册卷总数',
                          englishTitle: 'Total Entries',
                          value: '${_stats!.totalEntries}',
                          unit: '篇',
                          caption: '累积心迹笔墨',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          tokens: tokens,
                          icon: Icons.edit_note,
                          title: '挥毫字数',
                          englishTitle: 'Words / Chars',
                          value: '${_stats!.totalWords}',
                          unit: '言',
                          caption: '平仄字句成篇',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          tokens: tokens,
                          icon: Icons.local_fire_department_outlined,
                          title: '当下连墨',
                          value: '${_stats!.currentStreakDays}',
                          unit: '天',
                          englishUnit: 'days',
                          caption: _stats!.currentStreakDays > 0 ? '笔耕不辍' : '今日未润砚墨',
                          accentColor: tokens.cinnabar,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          tokens: tokens,
                          icon: Icons.workspace_premium_outlined,
                          title: '最长持砚',
                          value: '${_stats!.longestStreakDays}',
                          unit: '天',
                          englishUnit: 'days',
                          caption: '心静则笔耕连绵',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. 52-Week Contribution Heatmap (岁时墨痕)
                  XuanPaperCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                  '岁时墨痕',
                                  style: TextStyle(
                                    fontFamily: InkDiaryTheme.fontNotoSerif,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: tokens.jiaomo,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Yearly Writing Heatmap (52 Weeks)',
                                  style: TextStyle(fontSize: 10, color: tokens.danmo),
                                ),
                              ],
                            ),
                            Text(
                              '年景心流',
                              style: TextStyle(
                                fontFamily: InkDiaryTheme.fontKaiti,
                                fontSize: 11,
                                color: tokens.danmo,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '字句如溪，随四时清泉细水长流。',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontKaiti,
                            fontSize: 12,
                            color: tokens.danmo,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Heatmap Widget
                        YearlyContributionHeatmap(
                          dailyActivityMap: _stats!.dailyActivityMap,
                          referenceDate: widget.referenceDate,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Mood Distribution (心境气象)
                  XuanPaperCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                              '心境气象',
                              style: TextStyle(
                                fontFamily: InkDiaryTheme.fontNotoSerif,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: tokens.jiaomo,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Mood Distribution',
                              style: TextStyle(
                                fontSize: 11,
                                color: tokens.danmo,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_stats!.moodCounts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '尚未记录心境感怀',
                              style: TextStyle(
                                fontFamily: InkDiaryTheme.fontKaiti,
                                fontSize: 12,
                                color: tokens.danmo,
                              ),
                            ),
                          )
                        else
                          Column(
                            children: _stats!.moodCounts.entries.map((entry) {
                              final emoji = EntrySummaryCard.moodEmojis[entry.key] ?? '🙂';
                              final count = entry.value;
                              final ratio = _stats!.totalEntries > 0
                                  ? (count / _stats!.totalEntries).clamp(0.0, 1.0)
                                  : 0.0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Text(emoji, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: ratio,
                                          minHeight: 6,
                                          backgroundColor: tokens.agedFiber,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            tokens.cinnabar,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '$count 篇',
                                      style: TextStyle(
                                        fontFamily: InkDiaryTheme.fontKaiti,
                                        fontSize: 12,
                                        color: tokens.danmo,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricTile({
    required InkDiaryTokens tokens,
    required IconData icon,
    required String title,
    String? englishTitle,
    required String value,
    required String unit,
    String? englishUnit,
    required String caption,
    Color? accentColor,
  }) {
    return XuanPaperCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: tokens.nongmo,
                    ),
                  ),
                  if (englishTitle != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      englishTitle,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 10,
                        color: tokens.danmo,
                      ),
                    ),
                  ],
                ],
              ),
              Icon(icon, size: 17, color: accentColor ?? tokens.danmo),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: accentColor ?? tokens.jiaomo,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontKaiti,
                  fontSize: 12,
                  color: tokens.danmo,
                ),
              ),
              if (englishUnit != null) ...[
                const SizedBox(width: 4),
                Text(
                  '$value $englishUnit',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 11,
                    color: tokens.danmo,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontKaiti,
              fontSize: 11,
              color: tokens.danmo,
            ),
          ),
        ],
      ),
    );
  }
}
