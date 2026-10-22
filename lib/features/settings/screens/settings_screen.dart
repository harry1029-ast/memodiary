import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/cinnabar_seal_badge.dart';
import '../../../core/theme/widgets/xuan_paper_card.dart';
import '../../analytics/screens/analytics_dashboard_screen.dart';
import '../../recycle_bin/screens/recycle_bin_screen.dart';
import '../../import_export/screens/import_staging_screen.dart';
import '../../import_export/services/backup_crypto.dart';
import '../../import_export/services/backup_restore_service.dart';
import '../../import_export/services/date_parser_engine.dart';
import '../../import_export/services/file_selector_service.dart';
import '../../import_export/widgets/backup_dialogs.dart';
import '../../import_export/widgets/export_dialog.dart';
import '../services/storage_optimizer_service.dart';
import '../widgets/notification_settings_card.dart';

/// Settings, Permissions Status, Storage Optimizer, and Offline Privacy screen
/// elevated into classical Ink & Paper literati aesthetic.
class SettingsScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final FileSelectorService fileSelector;
  final BackupRestoreService? backupService;
  final int backupPbkdf2Iterations;
  final Future<Map<String, PermissionStatus>> Function()? permissionChecker;
  final StorageStats? initialStats;

  const SettingsScreen({
    super.key,
    required this.database,
    required this.mediaService,
    this.fileSelector = const NativeFileSelectorService(),
    this.backupService,
    this.backupPbkdf2Iterations = BackupCrypto.defaultIterations,
    this.permissionChecker,
    this.initialStats,
  });

  static Future<Map<String, PermissionStatus>> defaultPermissionChecker() async {
    try {
      final cam = await Permission.camera.status.timeout(
        const Duration(milliseconds: 150),
        onTimeout: () => PermissionStatus.denied,
      );
      final mic = await Permission.microphone.status.timeout(
        const Duration(milliseconds: 150),
        onTimeout: () => PermissionStatus.denied,
      );
      final photos = await Permission.photos.status.timeout(
        const Duration(milliseconds: 150),
        onTimeout: () => PermissionStatus.denied,
      );
      return {
        'camera': cam,
        'microphone': mic,
        'photos': photos,
      };
    } catch (_) {
      return {
        'camera': PermissionStatus.denied,
        'microphone': PermissionStatus.denied,
        'photos': PermissionStatus.denied,
      };
    }
  }

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  StorageStats? _stats;
  bool _isLoadingStats = true;
  bool _isCleaningOrphans = false;
  DateTime? _lastBackupAt;

  PermissionStatus? _cameraStatus;
  PermissionStatus? _micStatus;
  PermissionStatus? _storageStatus;

  @override
  void initState() {
    super.initState();
    if (widget.initialStats != null) {
      _stats = widget.initialStats;
      _isLoadingStats = false;
      _checkPermissions();
      _loadLastBackupTimestamp();
    } else {
      _loadAll();
    }
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadStorageStats(),
      _checkPermissions(),
      _loadLastBackupTimestamp(),
    ]);
  }

  Future<void> _loadLastBackupTimestamp() async {
    try {
      final ts = await _effectiveBackupService.getLastBackupTimestamp();
      if (mounted) {
        setState(() => _lastBackupAt = ts);
      }
    } catch (_) {}
  }

  Future<void> _loadStorageStats() async {
    final stats = await StorageOptimizerService.analyzeStorage(
      database: widget.database,
      mediaService: widget.mediaService,
    );
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final checker = widget.permissionChecker ?? SettingsScreen.defaultPermissionChecker;
      final results = await checker();
      if (mounted) {
        setState(() {
          _cameraStatus = results['camera'] ?? PermissionStatus.denied;
          _micStatus = results['microphone'] ?? PermissionStatus.denied;
          _storageStatus = results['photos'] ?? PermissionStatus.denied;
        });
      }
    } catch (_) {
      // In headless testing or environments without native permissions, fall back cleanly
    }
  }

  Future<void> _handleCleanOrphans() async {
    setState(() => _isCleaningOrphans = true);
    final purged = await StorageOptimizerService.purgeOrphanMedia(
      database: widget.database,
      mediaService: widget.mediaService,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已释清 $purged 份孤立残卷')),
    );
    await _loadStorageStats();
    if (mounted) {
      setState(() => _isCleaningOrphans = false);
    }
  }

  Future<void> _handleImportFile() async {
    try {
      final file = await widget.fileSelector.pickTextOrMarkdownFile();
      if (file == null || !mounted) return;

      final text = file.readAsStringSync();
      if (!mounted) return;

      final candidates = await DateParserEngine.parseDocumentInIsolate(
        text: text,
      );

      if (!mounted) return;

      if (candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('所选文件无有效字句')),
        );
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

      await _loadStorageStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    }
  }

  BackupRestoreService get _effectiveBackupService =>
      widget.backupService ??
      BackupRestoreService(
        database: widget.database,
        mediaService: widget.mediaService,
      );

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
      backupService: _effectiveBackupService,
      fileSelector: widget.fileSelector,
      pbkdf2Iterations: widget.backupPbkdf2Iterations,
    );
    if (result != null && mounted) {
      await _loadLastBackupTimestamp();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已成全量加密备份：${result.entriesCount} 篇墨卷，${result.mediaFilesCount} 份画卷附件',
          ),
        ),
      );
    }
  }

  Future<void> _handleRestoreBackup() async {
    try {
      final file = await widget.fileSelector.pickBackupFile();
      if (file == null || !mounted) return;

      final inspection = await _effectiveBackupService.inspectBackup(file);
      if (!mounted) return;

      final result = await RestoreBackupDialog.show(
        context: context,
        sourceFile: file,
        inspection: inspection,
        backupService: _effectiveBackupService,
      );

      if (result != null && mounted) {
        await _loadStorageStats();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已完好还原：${result.entriesRestored} 篇墨卷与 ${result.mediaFilesRestored} 份画卷',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('备份解析无效: $e')),
      );
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
              '设置与守拙',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
                letterSpacing: 2.0,
              ),
            ),
            Text(
              'Settings & Privacy',
              style: TextStyle(
                fontSize: 9,
                color: tokens.danmo,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // Studio Motto Banner
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: tokens.cinnabar),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '墨室守拙 · 恪纯无垢',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: tokens.nongmo,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Text(
                  '立约 · 独处',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontKaiti,
                    fontSize: 11,
                    color: tokens.danmo,
                  ),
                ),
              ],
            ),
          ),

          // 1. Storage & Optimizer Section
          _buildSectionHeader('纸墨存蓄 · 存储与空间', 'Storage & Optimization', tokens),
          _buildStorageCard(tokens),
          const SizedBox(height: 20),

          // 2. Writing Reminders Section
          _buildSectionHeader('砚边晨昏 · 鸣钟提醒', 'REMINDERS', tokens),
          const NotificationSettingsCard(),
          const SizedBox(height: 20),

          // 3. Data Portability Section
          _buildSectionHeader('文墨迁徙 · 数据流转', 'Data Portability', tokens),
          _buildDataPortabilityCard(tokens),
          const SizedBox(height: 20),

          // 4. Permissions Dashboard
          _buildSectionHeader('权限看板 · 硬件调用', 'Permissions Dashboard', tokens),
          _buildPermissionsCard(tokens),
          const SizedBox(height: 20),

          // 5. Zero-Cloud Privacy Declaration
          _buildPrivacyCard(tokens),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String tag, InkDiaryTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: tokens.jiaomo,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            tag,
            style: TextStyle(fontSize: 10, color: tokens.danmo, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard(InkDiaryTokens tokens) {
    if (_isLoadingStats || _stats == null) {
      return XuanPaperCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: tokens.cinnabar)),
      );
    }

    final stats = _stats!;
    return XuanPaperCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('现存墨卷', '${stats.activeEntriesCount}', tokens),
              _buildStatColumn('画影附件', '${stats.totalMediaFiles} (${stats.totalMediaFormatted})', tokens),
              _buildStatColumn('纸篓残卷', '${stats.deletedEntriesCount}', tokens),
            ],
          ),
          Divider(height: 24, color: tokens.agedFiber),
          Row(
            children: [
              Icon(
                stats.orphanMediaFiles > 0
                    ? Icons.cleaning_services_outlined
                    : Icons.verified_user_outlined,
                color: stats.orphanMediaFiles > 0 ? tokens.cinnabar : Colors.green.shade700,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.orphanMediaFiles > 0
                          ? '${stats.orphanMediaFiles} 份孤立残卷可释清'
                          : '沙盒纯净 · 无遗留废墨',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: tokens.jiaomo,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stats.orphanMediaFiles > 0
                          ? '可安全释清 ${stats.orphanMediaFormatted} 存储空间。'
                          : '所有影音图卷均与在册日记相契，未检得孤立残片。',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontKaiti,
                        fontSize: 11.5,
                        color: tokens.danmo,
                      ),
                    ),
                  ],
                ),
              ),
              if (stats.orphanMediaFiles > 0)
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.cinnabarWash,
                    foregroundColor: tokens.cinnabar,
                  ),
                  onPressed: _isCleaningOrphans ? null : _handleCleanOrphans,
                  child: _isCleaningOrphans
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: tokens.cinnabar),
                        )
                      : const Text('清理'),
                ),
            ],
          ),
          Divider(height: 24, color: tokens.agedFiber),
          ListTile(
            key: const Key('settings_recycle_bin_tile'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline_rounded, color: tokens.cinnabar),
            title: Row(
              children: [
                Text(
                  '纸篓残卷',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: tokens.jiaomo,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Recycle Bin (${stats.deletedEntriesCount})',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 12,
                    color: tokens.danmo,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              '查看并恢复或彻底销毁三十日内的已废墨卷',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 11.5,
                color: tokens.danmo,
              ),
            ),
            trailing: Icon(Icons.chevron_right, size: 18, color: tokens.danmo),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecycleBinScreen(
                    database: widget.database,
                    mediaService: widget.mediaService,
                  ),
                ),
              ).then((_) {
                _loadStorageStats();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, InkDiaryTokens tokens) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontNotoSerif,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: tokens.jiaomo,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontKaiti,
            fontSize: 11,
            color: tokens.danmo,
          ),
        ),
      ],
    );
  }

  Widget _buildDataPortabilityCard(InkDiaryTokens tokens) {
    return XuanPaperCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            key: const Key('settings_analytics_tile'),
            leading: Icon(Icons.insights_rounded, color: tokens.nongmo),
            title: Text(
              '研墨统计与岁时墨痕',
              style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 14, color: tokens.jiaomo),
            ),
            subtitle: Text(
              '浏览五十二周墨痕长卷、持砚连贯与心境印迹',
              style: TextStyle(fontFamily: InkDiaryTheme.fontKaiti, fontSize: 11, color: tokens.danmo),
            ),
            trailing: Icon(Icons.chevron_right, size: 18, color: tokens.danmo),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnalyticsDashboardScreen(
                    database: widget.database,
                  ),
                ),
              );
            },
          ),
          Divider(height: 1, color: tokens.agedFiber),
          ListTile(
            leading: Icon(Icons.file_upload_outlined, color: tokens.nongmo),
            title: Row(
              children: [
                Text(
                  '文本汇入',
                  style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 14, color: tokens.jiaomo),
                ),
                const SizedBox(width: 6),
                Text(
                  'Import from .txt / .md',
                  style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 12, color: tokens.danmo),
                ),
              ],
            ),
            subtitle: Text(
              '批量识别解析旧日卷宗，智能萃取日期时间',
              style: TextStyle(fontFamily: InkDiaryTheme.fontKaiti, fontSize: 11, color: tokens.danmo),
            ),
            trailing: Icon(Icons.chevron_right, size: 18, color: tokens.danmo),
            onTap: _handleImportFile,
          ),
          Divider(height: 1, color: tokens.agedFiber),
          ListTile(
            leading: Icon(Icons.file_download_outlined, color: tokens.nongmo),
            title: Row(
              children: [
                Text(
                  '导出全册墨卷',
                  style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 14, color: tokens.jiaomo),
                ),
                const SizedBox(width: 6),
                Text(
                  'Export All Diaries',
                  style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 12, color: tokens.danmo),
                ),
              ],
            ),
            subtitle: Text(
              '存为 Markdown (带元数据标签) 或纯文本',
              style: TextStyle(fontFamily: InkDiaryTheme.fontKaiti, fontSize: 11, color: tokens.danmo),
            ),
            trailing: Icon(Icons.chevron_right, size: 18, color: tokens.danmo),
            onTap: _handleExportAll,
          ),
          Divider(height: 1, color: tokens.agedFiber),
          ListTile(
            key: const Key('settings_last_backup_tile'),
            leading: Icon(Icons.history_edu_outlined, size: 20, color: tokens.danmo),
            title: Text(
              '最后全量刻印时间',
              style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 13, color: tokens.jiaomo),
            ),
            subtitle: Text(
              _lastBackupAt != null
                  ? DateFormat('yyyy-MM-dd HH:mm').format(_lastBackupAt!.toLocal())
                  : 'No backup created yet',
              style: TextStyle(fontFamily: InkDiaryTheme.fontKaiti, fontSize: 11, color: tokens.danmo),
            ),
            dense: true,
          ),
          Divider(height: 1, color: tokens.agedFiber),
          ListTile(
            key: const Key('settings_create_backup_tile'),
            leading: Icon(Icons.enhanced_encryption_outlined, color: tokens.cinnabar),
            title: Text(
              '创制加密全量卷宗 (.mdbak)',
              style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 14, color: tokens.jiaomo),
            ),
            subtitle: Text(
              '打包全量 SQLite 数据库与沙盒影音，采用 AES-256 加密封装',
              style: TextStyle(fontFamily: InkDiaryTheme.fontKaiti, fontSize: 11, color: tokens.danmo),
            ),
            trailing: Icon(Icons.chevron_right, size: 18, color: tokens.danmo),
            onTap: _handleCreateBackup,
          ),
          Divider(height: 1, color: tokens.agedFiber),
          ListTile(
            key: const Key('settings_restore_backup_tile'),
            leading: Icon(Icons.restore_page_outlined, color: tokens.nongmo),
            title: Text(
              '自加密卷宗还原备份',
              style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 14, color: tokens.jiaomo),
            ),
            subtitle: Text(
              '原子化验证并完好复苏 .mdbak 全档案',
              style: TextStyle(fontFamily: InkDiaryTheme.fontKaiti, fontSize: 11, color: tokens.danmo),
            ),
            trailing: Icon(Icons.chevron_right, size: 18, color: tokens.danmo),
            onTap: _handleRestoreBackup,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard(InkDiaryTokens tokens) {
    return XuanPaperCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildPermissionTile(
            icon: Icons.camera_alt_outlined,
            title: '即时拓影',
            englishTitle: 'Camera',
            description: '仅用于拍摄日记配图，且悉数隔离存入私密沙盒目录。',
            status: _cameraStatus,
            tokens: tokens,
          ),
          Divider(height: 1, color: tokens.agedFiber),
          _buildPermissionTile(
            icon: Icons.mic_none_outlined,
            title: '原声听写',
            englishTitle: 'Microphone & Speech',
            description: '仅用于触发系统内置端侧原声听写，零费用且永不上送音频。',
            status: _micStatus,
            tokens: tokens,
          ),
          Divider(height: 1, color: tokens.agedFiber),
          _buildPermissionTile(
            icon: Icons.photo_library_outlined,
            title: '画影选撷',
            englishTitle: 'Photos & Files',
            description: '用于导入画卷及归档导出备份至本地文件存储。',
            status: _storageStatus,
            tokens: tokens,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String englishTitle,
    required String description,
    required PermissionStatus? status,
    required InkDiaryTokens tokens,
  }) {
    final isGranted = status == PermissionStatus.granted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: tokens.nongmo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: tokens.jiaomo,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      englishTitle,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 11,
                        color: tokens.danmo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontKaiti,
                    fontSize: 11,
                    color: tokens.danmo,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isGranted ? Colors.green.shade50 : tokens.ricePaper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isGranted ? Colors.green.shade600 : tokens.agedFiber,
                width: 0.8,
              ),
            ),
            child: Text(
              isGranted ? '已获准' : '未授权',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isGranted ? Colors.green.shade800 : tokens.danmo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard(InkDiaryTokens tokens) {
    return XuanPaperCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      backgroundColor: tokens.ricePaper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CinnabarSealBadge(text: '零云上送', isRound: true),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '守拙清规',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: tokens.jiaomo,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '100% Offline & Private',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.cinnabar,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '拾光日记 (MemoDiary) 秉持 100% 离线优先架构 (MemoDiary operates with zero cloud servers)。所有日记文字、Delta JSON 排版与沙盒影音仅驻留于您手中这方屏幕，无任何后台上送、无第三方追踪。配合 SQLCipher AES-256 全库加密，守护案头字句的安宁幽独。',
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontKaiti,
              fontSize: 12,
              height: 1.5,
              color: tokens.nongmo,
            ),
          ),
        ],
      ),
    );
  }
}
