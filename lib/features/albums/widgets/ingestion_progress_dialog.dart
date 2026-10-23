import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../services/album_ingestion_service.dart';

/// Modal progress dialog displayed while [AlbumIngestionService] processes a batch of photos.
class IngestionProgressDialog extends StatelessWidget {
  final ValueListenable<IngestionProgress> progressListenable;
  final VoidCallback onCancel;

  const IngestionProgressDialog({
    super.key,
    required this.progressListenable,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;

    return PopScope(
      canPop: false,
      child: ValueListenableBuilder<IngestionProgress>(
        valueListenable: progressListenable,
        builder: (context, progress, _) {
          final currentStep = progress.total == 0
              ? 0
              : (progress.processed + 1).clamp(1, progress.total);

          return AlertDialog(
            title: const Text('正在导入旅途影像'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: progress.total > 0 ? progress.fraction : null,
                  color: tokens.cinnabar,
                  backgroundColor: tokens.agedFiber,
                ),
                const SizedBox(height: 14),
                Text(
                  progress.isDone
                      ? '正在整理入册（已处理 ${progress.processed} / ${progress.total} 张）…'
                      : '正在导入第 $currentStep / ${progress.total} 张照片…',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 14,
                    color: tokens.nongmo,
                  ),
                ),
                if (progress.failed > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '已跳过 ${progress.failed} 张无法读取的图片',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 12,
                      color: tokens.cinnabar,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                key: const Key('album_ingest_cancel'),
                onPressed: progress.isDone ? null : onCancel,
                child: const Text('停止'),
              ),
            ],
          );
        },
      ),
    );
  }
}

