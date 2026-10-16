import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/recycle_bin_service.dart';

/// Screen displaying soft-deleted entries with 30-day countdowns,
/// restore capability, and permanent purge actions.
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
    final entries = await widget.database.getDeletedEntries();
    if (mounted) {
      setState(() {
        _deletedEntries = entries;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRestore(Entry entry) async {
    await widget.database.restoreEntry(entry.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Restored "${(entry.title?.trim().isNotEmpty ?? false) ? entry.title!.trim() : "Untitled"}"',
        ),
      ),
    );
    await _loadDeletedEntries();
  }

  Future<void> _handlePermanentDelete(Entry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: const Text(
          'This will permanently delete this diary entry and its photos. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await RecycleBinService.permanentDeleteEntry(
        entryId: entry.id,
        database: widget.database,
        mediaService: widget.mediaService,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry permanently deleted')),
      );
      await _loadDeletedEntries();
    }
  }

  Future<void> _handleEmptyBin() async {
    if (_deletedEntries.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Recycle Bin?'),
        content: Text(
          'Permanently remove all ${_deletedEntries.length} items and reclaim device storage? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Empty All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await RecycleBinService.emptyRecycleBin(
        database: widget.database,
        mediaService: widget.mediaService,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recycle bin emptied')),
      );
      await _loadDeletedEntries();
    }
  }

  int _calculateDaysRemaining(DateTime updatedAt) {
    final elapsedDays = DateTime.now().difference(updatedAt).inDays;
    final remaining = 30 - elapsedDays;
    return remaining.clamp(0, 30);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        actions: [
          if (_deletedEntries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Empty Bin',
              onPressed: _handleEmptyBin,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deletedEntries.isEmpty
              ? _buildEmptyState(theme)
              : _buildList(theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: 64,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Recycle Bin is Empty',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Entries moved to the trash are stored here for 30 days before being permanently purged.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _deletedEntries.length,
      itemBuilder: (context, index) {
        final entry = _deletedEntries[index];
        final daysLeft = _calculateDaysRemaining(entry.updatedAt);
        final titleText =
            (entry.title?.trim().isNotEmpty ?? false) ? entry.title!.trim() : 'Untitled';
        final deletedDateStr =
            DateFormat('MMM d, y · h:mm a').format(entry.updatedAt);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withAlpha(100),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              titleText,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: daysLeft <= 3
                                  ? Colors.red.shade50
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              daysLeft == 0 ? 'Purges soon' : '$daysLeft days left',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: daysLeft <= 3
                                    ? Colors.red.shade700
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Deleted $deletedDateStr',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.restore_rounded),
                  tooltip: 'Restore',
                  onPressed: () => _handleRestore(entry),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red.shade600,
                  ),
                  tooltip: 'Delete Forever',
                  onPressed: () => _handlePermanentDelete(entry),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
