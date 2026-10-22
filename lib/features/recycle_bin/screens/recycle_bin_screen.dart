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
      final entries = await widget.database.getDeletedEntries();
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
    await widget.database.restoreEntry(entry.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '已复墨还案：${(entry.title?.trim().isNotEmpty ?? false) ? entry.title!.trim() : "无题"}',
        ),
      ),
    );
    await _loadDeletedEntries();
  }

  Future<void> _handlePermanentDelete(Entry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('焚稿归尘 · 彻底抹去？'),
        content: const Text(
          '此操作将彻底焚化本篇日记及一切附载画卷，墨迹成灰，永不可溯。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('留存残卷'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('焚为灰烬'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已彻底焚化抹去')),
      );
      await _loadDeletedEntries();
    }
  }

  Future<void> _handleEmptyBin() async {
    if (_deletedEntries.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('焚稿净匣 · 清空纸篓？'),
        content: Text(
          '确定焚化全部 ${_deletedEntries.length} 篇残章？磁盘空间将被彻底释清，此去无从追寻。',
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
            child: const Text('悉数焚净'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('纸篓已焚稿净匣')),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '岁暮拾遗',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
                letterSpacing: 2.0,
              ),
            ),
            Text(
              'RECYCLE BIN',
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
          if (_deletedEntries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: tokens.cinnabar),
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('焚稿净匣'),
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
                                '卷底残章 · 尘匣安歇',
                                style: TextStyle(
                                  fontFamily: InkDiaryTheme.fontNotoSerif,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: tokens.jiaomo,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '移入纸篓之文稿，存席三十日后墨迹自散归虚。',
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
                          text: '存留 ${_deletedEntries.length} 卷',
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
                              '尘匣空明 · 暂无残卷',
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
                          : '无题 · 虚白初草';
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
                                            '$daysRemaining 日后化散',
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
                                      '抹于 $updatedStr',
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
                                    tooltip: '复墨还案',
                                    onPressed: () => _handleRestore(entry),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_forever, size: 20, color: tokens.cinnabar),
                                    tooltip: '焚稿归尘',
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
