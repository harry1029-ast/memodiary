import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/ocr/ocr_queue_manager.dart';
import '../../../core/theme/ink_diary_theme.dart';

/// Modal progress dialog driving [OcrQueueManager.runBackfill] in literati Ink & Paper aesthetic.
///
/// Features:
/// - Real-time progress updates showing "正在索引: $current/$total 张照片".
/// - Responsive [LinearProgressIndicator] styled with cinnabar vermilion.
/// - Clean cancellation via "取消" button that halts scanning without corrupting the database.
/// - Completion state displaying "识图索引已完成" with a confirmation button.
class OcrBackfillDialog extends StatefulWidget {
  final OcrQueueManager ocrQueueManager;

  const OcrBackfillDialog({
    super.key,
    required this.ocrQueueManager,
  });

  /// Displays the modal progress dialog.
  static Future<void> show(
    BuildContext context, {
    required OcrQueueManager ocrQueueManager,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => OcrBackfillDialog(
        ocrQueueManager: ocrQueueManager,
      ),
    );
  }

  @override
  State<OcrBackfillDialog> createState() => _OcrBackfillDialogState();
}

class _OcrBackfillDialogState extends State<OcrBackfillDialog> {
  bool _isCancelled = false;
  bool _isPaused = false;
  bool _isComplete = false;
  int _current = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _startBackfill();
  }

  Future<void> _startBackfill() async {
    try {
      final pendingCount = await widget.ocrQueueManager.pendingBackfillCount();
      if (!mounted || _isCancelled) {
        return;
      }

      if (pendingCount == 0) {
        setState(() {
          _isComplete = true;
          _current = 0;
          _total = 0;
        });
        return;
      }

      setState(() {
        _total = pendingCount;
        _current = 0;
      });

      await widget.ocrQueueManager.runBackfill(
        onProgress: (progressCurrent, progressTotal) {
          if (mounted && !_isCancelled) {
            setState(() {
              _current = progressCurrent;
              _total = progressTotal;
            });
          }
        },
        isCancelled: () => _isCancelled,
        isPaused: () => _isPaused,
      );

      if (mounted && !_isCancelled) {
        setState(() {
          _isComplete = true;
        });
      }
    } catch (error) {
      debugPrint('OCR backfill execution error: $error');
      if (mounted && !_isCancelled) {
        setState(() {
          _isComplete = true;
        });
      }
    }
  }

  void _handleCancel() {
    _isCancelled = true;
    Navigator.of(context).pop();
  }

  void _handleDone() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    final double? progressValue = _total > 0
        ? (_current / _total).clamp(0.0, 1.0)
        : (_isComplete ? 1.0 : null);

    final String statusText;
    if (_isComplete) {
      statusText = '识图索引已完成';
    } else if (_isPaused) {
      statusText = '已暂停: $_current/$_total 张照片';
    } else {
      statusText = '正在索引: $_current/$_total 张照片';
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _isCancelled = true;
        }
      },
      child: AlertDialog(
        key: const Key('settings_ocr_backfill_dialog'),
        backgroundColor: tokens.ricePaper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tokens.agedFiber),
        ),
        title: Row(
          children: [
            Icon(
              _isComplete
                  ? Icons.check_circle_outline_rounded
                  : Icons.document_scanner_outlined,
              size: 22,
              color: tokens.cinnabar,
            ),
            const SizedBox(width: 8),
            Text(
              '离线识图索引',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              statusText,
              key: const Key('settings_ocr_backfill_progress_text'),
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 13.5,
                color: tokens.jiaomo,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                key: const Key('settings_ocr_backfill_progress_bar'),
                value: progressValue,
                backgroundColor: tokens.agedFiber,
                valueColor: AlwaysStoppedAnimation<Color>(tokens.cinnabar),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isComplete
                  ? '所有画卷与照片文字均已加入本地离线全文索引。'
                  : '正在由端侧视觉引擎于后台建立全文字词索引，可随时取消并保留已完成进度。',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 11,
                color: tokens.danmo,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isComplete) ...[
            TextButton(
              key: const Key('settings_ocr_backfill_pause_button'),
              style: TextButton.styleFrom(
                foregroundColor: tokens.jiaomo,
              ),
              onPressed: () {
                setState(() {
                  _isPaused = !_isPaused;
                });
              },
              child: Text(_isPaused ? '继续' : '暂停'),
            ),
            TextButton(
              key: const Key('settings_ocr_backfill_cancel_button'),
              style: TextButton.styleFrom(
                foregroundColor: tokens.danmo,
              ),
              onPressed: _handleCancel,
              child: const Text('取消'),
            ),
          ] else
            FilledButton.tonal(
              key: const Key('settings_ocr_backfill_done_button'),
              style: FilledButton.styleFrom(
                backgroundColor: tokens.cinnabarWash,
                foregroundColor: tokens.cinnabar,
              ),
              onPressed: _handleDone,
              child: const Text('完成'),
            ),
        ],
      ),
    );
  }
}
