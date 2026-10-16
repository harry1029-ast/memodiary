import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/timeline/widgets/entry_summary_card.dart';
import '../models/import_candidate_entry.dart';

/// Interactive review and fallback staging screen for parsed diary import candidates.
/// Allows date corrections, entry toggling, and atomic SQLite transaction commit.
class ImportStagingScreen extends StatefulWidget {
  final List<ImportCandidateEntry> initialCandidates;
  final AppDatabase database;
  final String fileName;

  const ImportStagingScreen({
    super.key,
    required this.initialCandidates,
    required this.database,
    required this.fileName,
  });

  @override
  State<ImportStagingScreen> createState() => _ImportStagingScreenState();
}

class _ImportStagingScreenState extends State<ImportStagingScreen> {
  late List<ImportCandidateEntry> _candidates;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _candidates = List.from(widget.initialCandidates);
  }

  int get _selectedCount => _candidates.where((c) => c.isSelected).length;

  int get _needsReviewCount => _candidates
      .where((c) =>
          c.confidence == DateParseConfidence.none ||
          c.confidence == DateParseConfidence.low)
      .length;

  void _toggleSelectAll(bool select) {
    setState(() {
      for (final c in _candidates) {
        c.isSelected = select;
      }
    });
  }

  Future<void> _pickDateForCandidate(ImportCandidateEntry candidate) async {
    final current = candidate.parsedDate ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );

    final finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime?.hour ?? current.hour,
      pickedTime?.minute ?? current.minute,
    );

    setState(() {
      candidate.parsedDate = finalDateTime;
      candidate.confidence = DateParseConfidence.high;
    });
  }

  Future<void> _executeBatchImport() async {
    final selected = _candidates.where((c) => c.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() => _isImporting = true);

    try {
      final notebooks = await widget.database.getAllNotebooks();
      final notebookId =
          notebooks.isNotEmpty ? notebooks.first.id : 'notebook_default';
      final templateId = notebooks.isNotEmpty
          ? notebooks.first.defaultTemplateId
          : 'template_minimalist_white';

      final companions = selected
          .map((c) => c.toCompanion(
                notebookId: notebookId,
                templateId: templateId,
              ))
          .toList();

      // Atomic Drift transaction
      final count = await widget.database.batchImportEntries(companions);

      if (!mounted) return;

      setState(() => _isImporting = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
          title: const Text('Import Complete'),
          content: Text(
            'Successfully imported $count diary entries from "${widget.fileName}".',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context, true); // Pop staging screen
              },
              child: const Text('View Timeline'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
          title: const Text('Import Failed'),
          content: Text(
            'Database transaction rolled back with no changes written:\n$e',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allSelected = _selectedCount == _candidates.length && _candidates.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Staging'),
        actions: [
          TextButton(
            onPressed: () => _toggleSelectAll(!allSelected),
            child: Text(allSelected ? 'Deselect All' : 'Select All'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header summary statistics
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Found ${_candidates.length} candidate entries',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _needsReviewCount > 0
                            ? '$_needsReviewCount entries need date review'
                            : 'All entries have detected dates',
                        style: TextStyle(
                          fontSize: 12,
                          color: _needsReviewCount > 0
                              ? Colors.amber.shade900
                              : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$_selectedCount / ${_candidates.length} selected',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Candidate Entries List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _candidates.length,
              itemBuilder: (context, index) {
                final candidate = _candidates[index];
                return _buildCandidateCard(candidate, theme);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _selectedCount > 0 && !_isImporting
                ? _executeBatchImport
                : null,
            icon: _isImporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_done_rounded),
            label: Text(_isImporting
                ? 'Importing...'
                : 'Import Selected ($_selectedCount)'),
          ),
        ),
      ),
    );
  }

  Widget _buildCandidateCard(ImportCandidateEntry candidate, ThemeData theme) {
    final dateStr = candidate.parsedDate != null
        ? DateFormat('yyyy-MM-dd · EEE').format(candidate.parsedDate!)
        : 'Missing Date';

    final isLowConfidence =
        candidate.confidence == DateParseConfidence.none ||
        candidate.confidence == DateParseConfidence.low;

    final moodEmoji = candidate.mood != null
        ? EntrySummaryCard.moodEmojis[candidate.mood!]
        : null;
    final weatherIcon = candidate.weather != null
        ? EntrySummaryCard.weatherIcons[candidate.weather!]
        : null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isLowConfidence
              ? Colors.amber.shade300
              : theme.colorScheme.outlineVariant.withAlpha(100),
          width: isLowConfidence ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: candidate.isSelected,
              onChanged: (val) {
                setState(() => candidate.isSelected = val ?? false);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row with confidence & interactive date picker button
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _pickDateForCandidate(candidate),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isLowConfidence
                                ? Colors.amber.shade100
                                : theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLowConfidence
                                    ? Icons.warning_amber_rounded
                                    : Icons.calendar_today_outlined,
                                size: 14,
                                color: isLowConfidence
                                    ? Colors.amber.shade900
                                    : theme.colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isLowConfidence
                                      ? Colors.amber.shade900
                                      : theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 16,
                                color: isLowConfidence
                                    ? Colors.amber.shade900
                                    : theme.colorScheme.onPrimaryContainer,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (moodEmoji != null) ...[
                        Text(moodEmoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                      ],
                      if (weatherIcon != null) ...[
                        Icon(
                          weatherIcon,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    candidate.title.isNotEmpty ? candidate.title : 'Untitled',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Snippet
                  Text(
                    candidate.plainText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

