import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/xuan_paper_card.dart';
import '../services/backup_crypto.dart';
import '../services/backup_restore_service.dart';
import '../services/date_parser_engine.dart';
import '../services/file_selector_service.dart';
import '../widgets/backup_dialogs.dart';
import '../widgets/export_dialog.dart';
import 'import_staging_screen.dart';

/// The Import & Backup screen (导入与备份): the diarist's data-moving tools.
///
/// Imports `.txt` / `.md` diaries into import staging, exports diaries, shows
/// the last-backup time, creates `.mdbak` backups and restores from them.
class ImportBackupScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final FileSelectorService fileSelector;
  final BackupRestoreService? backupService;
  final int backupPbkdf2Iterations;

  const ImportBackupScreen({
    super.key,
    required this.database,
    required this.mediaService,
    this.fileSelector = const NativeFileSelectorService(),
    this.backupService,
    this.backupPbkdf2Iterations = BackupCrypto.defaultIterations,
  });

  @override
  State<ImportBackupScreen> createState() => _ImportBackupScreenState();
}

class _ImportBackupScreenState extends State<ImportBackupScreen> {
  late final BackupRestoreService _backupService;
  DateTime? _lastBackupAt;

  @override
  void initState() {
    super.initState();
    _backupService = widget.backupService ??
        BackupRestoreService(
          database: widget.database,
          mediaService: widget.mediaService,
        );
    _loadLastBackupTimestamp();
  }

  Future<void> _loadLastBackupTimestamp() async {
    try {
      final ts = await _backupService.getLastBackupTimestamp();
      if (mounted) {
        setState(() => _lastBackupAt = ts);
      }
    } catch (_) {}
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleImportFile() async {
    try {
      final file = await widget.fileSelector.pickTextOrMarkdownFile();
      if (file == null || !mounted) return;

      final text = await file.readAsString();
      if (!mounted) return;

      final candidates = await DateParserEngine.parseDocumentInIsolate(
        text: text,
      );

      if (!mounted) return;

      if (candidates.isEmpty) {
        _showSnackBar('所选文件中没有可导入的日记内容');
        return;
      }

      final fileName = p.basename(file.path);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImportStagingScreen(
            initialCandidates: candidates,
            database: widget.database,
            fileName: fileName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('导入失败：$e');
    }
  }

  void _handleExportAll() {
    ExportDialog.show(
      context: context,
      database: widget.database,
      fileSelector: widget.fileSelector,
      mediaService: widget.mediaService,
    );
  }

  Future<void> _handleCreateBackup() async {
    final result = await CreateBackupDialog.show(
      context: context,
      backupService: _backupService,
      fileSelector: widget.fileSelector,
      pbkdf2Iterations: widget.backupPbkdf2Iterations,
    );
    if (result != null && mounted) {
      await _loadLastBackupTimestamp();
      if (!mounted) return;
      _showSnackBar(
        '已导出备份：${result.entriesCount} 篇日记，${result.mediaFilesCount} 个媒体文件',
      );
    }
  }

  Future<void> _handleRestoreBackup() async {
    try {
      final file = await widget.fileSelector.pickBackupFile();
      if (file == null || !mounted) return;

      final inspection = await _backupService.inspectBackup(file);
      if (!mounted) return;

      final result = await RestoreBackupDialog.show(
        context: context,
        sourceFile: file,
        inspection: inspection,
        backupService: _backupService,
      );

      if (result != null && mounted) {
        _showSnackBar(
          '恢复完成：${result.entriesRestored} 篇日记，${result.mediaFilesRestored} 个媒体文件',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('备份文件无效或无法读取：$e');
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
          '导入与备份',
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontNotoSerif,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: tokens.jiaomo,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [_buildToolsCard(tokens)],
      ),
    );
  }

  Widget _buildToolsCard(InkDiaryTokens tokens) {
    return XuanPaperCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildActionTile(
            key: const Key('import_backup_import_text_tile'),
            icon: Icons.file_upload_outlined,
            iconColor: tokens.nongmo,
            title: '导入文本',
            subtitle: '从 .txt 或 .md 文件批量导入日记并自动识别日期',
            onTap: _handleImportFile,
            tokens: tokens,
          ),
          Divider(height: 1, color: tokens.agedFiber),
          _buildActionTile(
            key: const Key('import_backup_export_tile'),
            icon: Icons.file_download_outlined,
            iconColor: tokens.nongmo,
            title: '导出日记',
            subtitle: '导出为 PDF、Markdown 或纯文本文件',
            onTap: _handleExportAll,
            tokens: tokens,
          ),
          Divider(height: 1, color: tokens.agedFiber),
          ListTile(
            key: const Key('import_backup_last_backup_tile'),
            leading: Icon(Icons.history_edu_outlined, size: 20, color: tokens.danmo),
            title: Text(
              '上次备份时间',
              style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 13, color: tokens.jiaomo),
            ),
            subtitle: Text(
              _lastBackupAt != null
                  ? DateFormat('yyyy-MM-dd HH:mm').format(_lastBackupAt!.toLocal())
                  : '尚未创建备份',
              style: TextStyle(fontFamily: InkDiaryTheme.fontKaiti, fontSize: 11, color: tokens.danmo),
            ),
            dense: true,
          ),
          Divider(height: 1, color: tokens.agedFiber),
          _buildActionTile(
            key: const Key('import_backup_create_backup_tile'),
            icon: Icons.enhanced_encryption_outlined,
            iconColor: tokens.cinnabar,
            title: '导出加密备份 (.mdbak)',
            subtitle: '将全部日记、相册、模板及照片视频打包为加密 .mdbak 文件',
            onTap: _handleCreateBackup,
            tokens: tokens,
          ),
          Divider(height: 1, color: tokens.agedFiber),
          _buildActionTile(
            key: const Key('import_backup_restore_backup_tile'),
            icon: Icons.restore_page_outlined,
            iconColor: tokens.nongmo,
            title: '从备份恢复',
            subtitle: '选择 .mdbak 备份文件并完整恢复数据',
            onTap: _handleRestoreBackup,
            tokens: tokens,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required Key key,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required InkDiaryTokens tokens,
  }) {
    return ListTile(
      key: key,
      leading: Icon(icon, size: 20, color: iconColor),
      title: Text(
        title,
        style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 14, color: tokens.jiaomo),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontFamily: InkDiaryTheme.fontKaiti, fontSize: 11, color: tokens.danmo),
      ),
      trailing: Icon(Icons.chevron_right, size: 18, color: tokens.danmo),
      onTap: onTap,
    );
  }
}
