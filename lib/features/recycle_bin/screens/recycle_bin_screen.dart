import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/services/recycle_bin_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/cinnabar_seal_badge.dart';
import '../../../core/theme/widgets/xuan_paper_card.dart';

/// Screen displaying soft-deleted entries with 30-day countdowns,
/// restore capability, and permanent purge actions in literati aesthetic.
class RecycleBinScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;

  const RecycleBinScreen({
    super.key,
    required this.database,
    required this.mediaService,
  });

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  List<Entry> _deletedEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedEntries();
  }

  Future<void> _loadDeletedEntries() async {
    setState(() => _isLoading = true);
    try {
      final entries = await widget.database.entriesDao.getDeletedEntries();
      if (mounted) {
        setState(() {
          _deletedEntries = entries;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrint('Error loading deleted entries: $e\n$st');
      if (mounted) {
        setState(() {
          _deletedEntries = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRestore(Entry entry) async {
    HapticFeedback.lightImpact();
    await widget.database.entriesDao.restoreEntry(entry.id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '已恢复：${(entry.title?.trim().isNotEmpty ?? false) ? entry.title!.trim() : "无题"}',
        ),
      ),
    );
    await _loadDeletedEntries();
  }

  Future<void> _handlePermanentDelete(Entry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('彻底删除日记？'),
        content: const Text(
          '将彻底删除这篇日记及其关联的照片和视频，删除后无法恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('彻底删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.lightImpact();
      await RecycleBinService.permanentDeleteEntry(
        entryId: entry.id,
        database: widget.database,
        mediaService: widget.mediaService,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('已彻底删除')),
      );
      await _loadDeletedEntries();
    }
  }

  Future<void> _handleEmptyBin() async {
    if (_deletedEntries.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空回收站？'),
        content: Text(
          '确定彻底删除全部 ${_deletedEntries.length} 篇日记？删除后无法恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('清空回收站'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.lightImpact();
      await RecycleBinService.emptyRecycleBin(
        database: widget.database,
        mediaService: widget.mediaService,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('已清空回收站')),
      );
      await _loadDeletedEntries();
    }
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
        title: Text(
          '回收站',
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontNotoSerif,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: tokens.jiaomo,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_deletedEntries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: tokens.cinnabar),
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('清空回收站'),
                onPressed: _handleEmptyBin,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: tokens.cinnabar))
          : RefreshIndicator(
              color: tokens.cinnabar,
              onRefresh: _loadDeletedEntries,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // Top Context Banner
                  XuanPaperCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(16),
                    backgroundColor: tokens.ricePaper,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: 22,
                          color: tokens.cinnabar,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '30 天保留期',
                                style: TextStyle(
                                  fontFamily: InkDiaryTheme.fontNotoSerif,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: tokens.jiaomo,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '已删除的日记将保留 30 天，到期后自动彻底清除。',
                                style: TextStyle(
                                  fontFamily: InkDiaryTheme.fontKaiti,
                                  fontSize: 12,
                                  color: tokens.danmo,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        CinnabarSealBadge(
                          text: '共 ${_deletedEntries.length} 篇',
                          isRound: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_deletedEntries.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Icon(
                              Icons.auto_delete_outlined,
                              size: 48,
                              color: tokens.danmo.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '回收站为空',
                              style: TextStyle(
                                fontFamily: InkDiaryTheme.fontNotoSerif,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: tokens.jiaomo,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._deletedEntries.map((entry) {
                      final daysRemaining =
                          RecycleBinService.getDaysUntilPermanentDelete(entry);
                      final title = (entry.title?.trim().isNotEmpty ?? false)
                          ? entry.title!.trim()
                          : '无题';
                      final updatedStr =
                          DateFormat('yyyy年M月d日 · HH:mm').format(entry.updatedAt);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: XuanPaperCard(
                          margin: EdgeInsets.zero,
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: InkDiaryTheme.fontNotoSerif,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: tokens.jiaomo,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: tokens.cinnabarWash,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: tokens.cinnabar.withValues(alpha: 0.3),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            '$daysRemaining 天后自动清除',
                                            style: TextStyle(
                                              fontFamily: InkDiaryTheme.fontKaiti,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: tokens.cinnabar,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '删除于 $updatedStr',
                                      style: TextStyle(
                                        fontFamily: InkDiaryTheme.fontKaiti,
                                        fontSize: 11,
                                        color: tokens.danmo,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.history, size: 20, color: tokens.nongmo),
                                    tooltip: '恢复',
                                    onPressed: () => _handleRestore(entry),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_forever, size: 20, color: tokens.cinnabar),
                                    tooltip: '彻底删除',
                                    onPressed: () => _handlePermanentDelete(entry),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
