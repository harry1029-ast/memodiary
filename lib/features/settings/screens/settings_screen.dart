import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/services/ocr/ocr_queue_manager.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/theme_settings_service.dart';
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
import '../widgets/appearance_theme_card.dart';
import '../widgets/notification_settings_card.dart';
import '../widgets/ocr_backfill_dialog.dart';
import '../../intro/screens/book_intro_screen.dart';
import '../../intro/services/book_intro_settings_service.dart';
import '../../scenery/models/shanshui_atmosphere.dart';
import '../../scenery/services/scenery_settings_service.dart';
import '../../editor/widgets/cinnabar_signature_seal.dart';
import '../services/signature_seal_service.dart';

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
  final ThemeSettingsService? themeSettings;
  final ScenerySettingsService? scenerySettingsService;
  final OcrQueueManager? ocrQueueManager;
  final SignatureSealService? signatureSealService;

  const SettingsScreen({
    super.key,
    required this.database,
    required this.mediaService,
    this.fileSelector = const NativeFileSelectorService(),
    this.backupService,
    this.backupPbkdf2Iterations = BackupCrypto.defaultIterations,
    this.permissionChecker,
    this.initialStats,
    this.themeSettings,
    this.scenerySettingsService,
    this.ocrQueueManager,
    this.signatureSealService,
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

  final _introSettings = BookIntroSettingsService();
  bool _showBookIntroOnLaunch = true;
  late final ScenerySettingsService _scenerySettings;
  bool _isSceneryCollapsed = false;
  ShanshuiAtmosphereState? _pinnedAtmosphere;
  SceneryRealmPreference _realmPreference = SceneryRealmPreference.auto;

  late final ThemeSettingsService _themeSettings;
  late final SignatureSealService _signatureSealService;
  String _signatureSealText = SignatureSealService.defaultSealText;
  int _unindexedPhotoCount = 0;

  @override
  void initState() {
    super.initState();
    _scenerySettings = widget.scenerySettingsService ?? ScenerySettingsService();
    _themeSettings = widget.themeSettings ?? ThemeSettingsService.instance;
    _signatureSealService = widget.signatureSealService ?? SignatureSealService();
    _loadScenerySettings();
    _loadBookIntroPreference();
    _loadOcrStatus();
    _loadSignatureSealText();
    if (widget.initialStats != null) {
      _stats = widget.initialStats;
      _isLoadingStats = false;
      _checkPermissions();
      _loadLastBackupTimestamp();
    } else {
      _loadAll();
    }
  }

  Future<void> _loadSignatureSealText() async {
    final text = await _signatureSealService.getSealText();
    if (mounted) {
      setState(() => _signatureSealText = text);
    }
  }

  Future<void> _loadOcrStatus() async {
    if (widget.ocrQueueManager == null) return;
    try {
      final count = await widget.ocrQueueManager!.pendingBackfillCount();
      if (mounted) {
        setState(() {
          _unindexedPhotoCount = count;
        });
      }
    } catch (error) {
      debugPrint('Error loading OCR backfill count in settings: $error');
    }
  }

  Future<void> _loadScenerySettings() async {
    final isSceneryCollapsed = await _scenerySettings.getIsCollapsed();
    final pinned = await _scenerySettings.getPinnedAtmosphere();
    final realmPref = await _scenerySettings.getRealmPreference();
    if (mounted) {
      setState(() {
        _isSceneryCollapsed = isSceneryCollapsed;
        _pinnedAtmosphere = pinned;
        _realmPreference = realmPref;
      });
    }
  }

  Future<void> _loadBookIntroPreference() async {
    final show = await _introSettings.getShouldShowOnLaunch();
    if (mounted) {
      setState(() {
        _showBookIntroOnLaunch = show;
      });
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text('已清理 $purged 个冗余文件')),
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
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(content: Text('所选文件中没有可导入的日记内容')),
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
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('导入失败：$e')),
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
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '已导出备份：${result.entriesCount} 篇日记，${result.mediaFilesCount} 个媒体文件',
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
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '恢复完成：${result.entriesRestored} 篇日记，${result.mediaFilesRestored} 个媒体文件',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('备份文件无效或无法读取：$e')),
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
        title: Text(
          '设置',
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
        children: [
          // 0. Book Cover & Experience Section
          _buildSectionHeader('开卷动画', tokens),
          _buildBookIntroCard(tokens),
          const SizedBox(height: 20),

          // 0.5. Appearance & Theme Section
          _buildSectionHeader('外观主题', tokens),
          AppearanceThemeCard(themeSettings: _themeSettings),
          const SizedBox(height: 20),

          // 0.6. Signature Seal Section
          _buildSectionHeader('签名印章', tokens),
          _buildSignatureSealCard(tokens),
          const SizedBox(height: 20),

          // 1. Storage & Optimizer Section
          _buildSectionHeader('存储与清理', tokens),
          _buildStorageCard(tokens),
          const SizedBox(height: 20),

          // 2. Writing Reminders Section
          _buildSectionHeader('写作提醒', tokens),
          const NotificationSettingsCard(),
          const SizedBox(height: 20),

          // 3. Data Portability Section
          _buildSectionHeader('导入与导出', tokens),
          _buildDataPortabilityCard(tokens),
          const SizedBox(height: 20),

          // 4. Permissions Dashboard
          _buildSectionHeader('权限管理', tokens),
          _buildPermissionsCard(tokens),
          const SizedBox(height: 20),

          // 5. Zero-Cloud Privacy Declaration
          _buildSectionHeader('隐私保护', tokens),
          _buildPrivacyCard(tokens),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, InkDiaryTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: InkDiaryTheme.fontNotoSerif,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: tokens.jiaomo,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBookIntroCard(InkDiaryTokens tokens) {
    return XuanPaperCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '启动时显示开卷动画',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tokens.jiaomo,
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '开启后打开应用时显示封面翻页动画',
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.danmo,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                key: const Key('settings_book_intro_switch'),
                value: _showBookIntroOnLaunch,
                activeThumbColor: tokens.cinnabar,
                onChanged: (val) async {
                  await _introSettings.setShouldShowOnLaunch(val);
                  if (mounted) {
                    setState(() => _showBookIntroOnLaunch = val);
                  }
                },
              ),
            ],
          ),
          const Divider(height: 20),
          ListTile(
            key: const Key('settings_book_intro_tile'),
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tokens.agedFiber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.menu_book_rounded, color: tokens.cinnabar, size: 20),
            ),
            title: Text(
              '预览开卷动画',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tokens.jiaomo,
                fontFamily: InkDiaryTheme.fontNotoSerif,
              ),
            ),
            subtitle: Text(
              '立即查看 3D 封面翻页效果',
              style: TextStyle(fontSize: 10.5, color: tokens.danmo),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 14, color: tokens.danmo),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookIntroScreen(
                    database: widget.database,
                    mediaService: widget.mediaService,
                    startOpened: false,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '默认收起顶部画卷',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tokens.jiaomo,
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '在日记主页默认将顶部风景画卷收起为状态条',
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.danmo,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                key: const Key('settings_scenery_collapsed_switch'),
                value: _isSceneryCollapsed,
                activeThumbColor: tokens.cinnabar,
                onChanged: (val) async {
                  await _scenerySettings.setIsCollapsed(val);
                  if (mounted) {
                    setState(() => _isSceneryCollapsed = val);
                  }
                },
              ),
            ],
          ),
          const Divider(height: 20),
          ListTile(
            key: const Key('settings_scenery_realm_tile'),
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tokens.agedFiber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.art_track_rounded, color: tokens.cinnabar, size: 20),
            ),
            title: Text(
              '画卷场景',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tokens.jiaomo,
                fontFamily: InkDiaryTheme.fontNotoSerif,
              ),
            ),
            subtitle: Text(
              _realmPreference == SceneryRealmPreference.auto
                  ? '自动（根据近期日记切换）'
                  : _realmPreference.nameZh,
              style: TextStyle(fontSize: 10.5, color: tokens.danmo),
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: tokens.danmo),
            onTap: () => _showRealmPreferenceDialog(tokens),
          ),
          const Divider(height: 20),
          ListTile(
            key: const Key('settings_scenery_pin_atmosphere_tile'),
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tokens.agedFiber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.landscape_outlined, color: tokens.cinnabar, size: 20),
            ),
            title: Text(
              '固定画卷氛围',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tokens.jiaomo,
                fontFamily: InkDiaryTheme.fontNotoSerif,
              ),
            ),
            subtitle: Text(
              _pinnedAtmosphere != null
                  ? '${_pinnedAtmosphere!.season.nameZh} · ${_pinnedAtmosphere!.timeOfDay.nameZh} · ${_pinnedAtmosphere!.weather.nameZh}'
                  : '随本地时间和近期日记自动变化',
              style: TextStyle(fontSize: 10.5, color: tokens.danmo),
            ),
            trailing: Icon(Icons.tune_rounded, size: 16, color: tokens.danmo),
            onTap: () => _showPinAtmosphereDialog(tokens),
          ),
          const Divider(height: 20),
          ListTile(
            key: const Key('settings_scenery_reset_atmosphere_tile'),
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tokens.agedFiber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.wb_sunny_outlined, color: tokens.cinnabar, size: 20),
            ),
            title: Text(
              '重置画卷氛围',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tokens.jiaomo,
                fontFamily: InkDiaryTheme.fontNotoSerif,
              ),
            ),
            subtitle: Text(
              '清除固定设置，恢复随本地时间和近期日记自动变化',
              style: TextStyle(fontSize: 10.5, color: tokens.danmo),
            ),
            trailing: Icon(Icons.refresh_rounded, size: 16, color: tokens.danmo),
            onTap: () async {
              await _scenerySettings.setPinnedAtmosphere(null);
              if (!mounted) return;
              setState(() {
                _pinnedAtmosphere = null;
                _realmPreference = SceneryRealmPreference.auto;
              });
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已恢复自动同步')),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showRealmPreferenceDialog(InkDiaryTokens tokens) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: tokens.xuanGround,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '画卷场景',
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: tokens.jiaomo,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRealmDialogOption(
                  dialogContext: dialogContext,
                  tokens: tokens,
                  key: const Key('settings_realm_option_auto'),
                  preference: SceneryRealmPreference.auto,
                  title: '自动',
                  subtitle: '根据最近 24 小时日记内容自动切换',
                ),
                _buildRealmDialogOption(
                  dialogContext: dialogContext,
                  tokens: tokens,
                  key: const Key('settings_realm_option_nature'),
                  preference: SceneryRealmPreference.nature,
                  title: '山水',
                  subtitle: '水墨山水风景',
                ),
                _buildRealmDialogOption(
                  dialogContext: dialogContext,
                  tokens: tokens,
                  key: const Key('settings_realm_option_indoor'),
                  preference: SceneryRealmPreference.indoor,
                  title: '室内',
                  subtitle: '室内书房茶室',
                ),
                _buildRealmDialogOption(
                  dialogContext: dialogContext,
                  tokens: tokens,
                  key: const Key('settings_realm_option_outdoor'),
                  preference: SceneryRealmPreference.outdoor,
                  title: '街市',
                  subtitle: '街头市集风光',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('取消', style: TextStyle(color: tokens.danmo)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRealmDialogOption({
    required BuildContext dialogContext,
    required InkDiaryTokens tokens,
    required Key key,
    required SceneryRealmPreference preference,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _realmPreference == preference;
    return Semantics(
      button: true,
      label: '设置画卷场景为 $title',
      child: ListTile(
        key: key,
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tokens.agedFiber,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            preference.icon,
            color: isSelected ? tokens.cinnabar : tokens.danmo,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? tokens.cinnabar : tokens.jiaomo,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 10.5, color: tokens.danmo),
        ),
        trailing: isSelected
            ? Icon(Icons.check_rounded, color: tokens.cinnabar, size: 20)
            : null,
        onTap: () async {
          await _scenerySettings.setRealmPreference(preference);
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);
          }
          if (mounted) {
            setState(() => _realmPreference = preference);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已设置画卷场景为：$title')),
            );
          }
        },
      ),
    );
  }

  Future<void> _showPinAtmosphereDialog(InkDiaryTokens tokens) async {
    ShanshuiSeason selectedSeason = _pinnedAtmosphere?.season ?? ShanshuiSeason.spring;
    ShanshuiTimeOfDay selectedTime = _pinnedAtmosphere?.timeOfDay ?? ShanshuiTimeOfDay.day;
    ShanshuiWeather selectedWeather = _pinnedAtmosphere?.weather ?? ShanshuiWeather.sunny;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: tokens.xuanGround,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                '固定画卷氛围',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: tokens.jiaomo,
                ),
              ),
              content: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('季节', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tokens.danmo)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: ShanshuiSeason.values.map((season) {
                          final isSel = selectedSeason == season;
                          return ChoiceChip(
                            key: Key('settings_pin_season_chip_${season.id}'),
                            label: Text(season.nameZh),
                            selected: isSel,
                            onSelected: (_) => setDialogState(() => selectedSeason = season),
                            selectedColor: tokens.cinnabar,
                            labelStyle: TextStyle(
                              color: isSel ? tokens.onAccentPrimary : tokens.jiaomo,
                              fontSize: 11,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text('时段', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tokens.danmo)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: ShanshuiTimeOfDay.values.map((timeOfDay) {
                          final isSel = selectedTime == timeOfDay;
                          return ChoiceChip(
                            key: Key('settings_pin_time_chip_${timeOfDay.id}'),
                            label: Text(timeOfDay.nameZh),
                            selected: isSel,
                            onSelected: (_) => setDialogState(() => selectedTime = timeOfDay),
                            selectedColor: tokens.cinnabar,
                            labelStyle: TextStyle(
                              color: isSel ? tokens.onAccentPrimary : tokens.jiaomo,
                              fontSize: 11,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text('天气', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tokens.danmo)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: ShanshuiWeather.values.map((weather) {
                          final isSel = selectedWeather == weather;
                          return ChoiceChip(
                            key: Key('settings_pin_weather_chip_${weather.id}'),
                            label: Text(weather.nameZh),
                            selected: isSel,
                            onSelected: (_) => setDialogState(() => selectedWeather = weather),
                            selectedColor: tokens.cinnabar,
                            labelStyle: TextStyle(
                              color: isSel ? tokens.onAccentPrimary : tokens.jiaomo,
                              fontSize: 11,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('取消', style: TextStyle(color: tokens.danmo)),
                ),
                FilledButton(
                  key: const Key('settings_pin_save_button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.cinnabar,
                    foregroundColor: tokens.onAccentPrimary,
                  ),
                  onPressed: () async {
                    final newState = ShanshuiAtmosphereState(
                      season: selectedSeason,
                      timeOfDay: selectedTime,
                      weather: selectedWeather,
                    );
                    await _scenerySettings.setPinnedAtmosphere(newState);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    if (mounted) {
                      setState(() => _pinnedAtmosphere = newState);
                      ScaffoldMessenger.of(this.context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text('已固定画卷氛围：${newState.season.nameZh} · ${newState.timeOfDay.nameZh} · ${newState.weather.nameZh}')),
                      );
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSignatureSealCard(InkDiaryTokens tokens) {
    return XuanPaperCard(
      key: const Key('settings_signature_seal_card'),
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tokens.agedFiber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.draw_outlined,
              color: tokens.cinnabar,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '签名印章文字',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.jiaomo,
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '当前印章文字：$_signatureSealText',
                  style: TextStyle(
                    fontSize: 11,
                    color: tokens.danmo,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.0,
            child: CinnabarSignatureSeal(
              overrideText: _signatureSealText,
              size: 36,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            key: const Key('settings_edit_signature_seal_button'),
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.cinnabar,
              side: BorderSide(color: tokens.cinnabar.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () => _showSignatureSealDialog(tokens),
            child: const Text('修改'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSignatureSealDialog(InkDiaryTokens tokens) async {
    final controller = TextEditingController(text: _signatureSealText);
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentText = controller.text.trim();
            final isValid = currentText.length >= 2 && currentText.length <= 4;

            return AlertDialog(
              backgroundColor: tokens.ricePaper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: tokens.agedFiber),
              ),
              title: Text(
                '修改签名印章（2至4字）',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: tokens.jiaomo,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '印章文字将显示在日记结尾处。',
                    style: TextStyle(fontSize: 12, color: tokens.danmo),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: CinnabarSignatureSeal(
                      overrideText: currentText.isEmpty
                          ? SignatureSealService.defaultSealText
                          : currentText,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('settings_signature_seal_input'),
                    controller: controller,
                    maxLength: 4,
                    decoration: InputDecoration(
                      hintText: '如：心迹安放、随记',
                      filled: true,
                      fillColor: tokens.xuanGround,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: tokens.agedFiber),
                      ),
                      counterText: '${controller.text.characters.length}/4',
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  key: const Key('settings_signature_seal_reset_button'),
                  onPressed: () async {
                    await _signatureSealService.setSealText(SignatureSealService.defaultSealText);
                    if (mounted) {
                      setState(() => _signatureSealText = SignatureSealService.defaultSealText);
                    }
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                  },
                  child: Text('恢复默认', style: TextStyle(color: tokens.danmo)),
                ),
                FilledButton(
                  key: const Key('settings_signature_seal_save_button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.cinnabar,
                    foregroundColor: tokens.onAccentPrimary,
                  ),
                  onPressed: isValid
                      ? () async {
                          await _signatureSealService.setSealText(currentText);
                          if (mounted) {
                            setState(() => _signatureSealText = currentText);
                          }
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }
                        }
                      : null,
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
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
              _buildStatColumn('日记篇数', '${stats.activeEntriesCount}', tokens),
              _buildStatColumn('媒体文件', '${stats.totalMediaFiles} (${stats.totalMediaFormatted})', tokens),
              _buildStatColumn('回收站', '${stats.deletedEntriesCount}', tokens),
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
                          ? '发现 ${stats.orphanMediaFiles} 个未关联的冗余文件'
                          : '存储状态正常，无冗余文件',
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
                          ? '清理后可释放 ${stats.orphanMediaFormatted} 空间。'
                          : '所有照片和视频均已被日记或相册正常引用。',
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
            leading:
                Icon(Icons.delete_outline_rounded, size: 20, color: tokens.cinnabar),
            title: Text(
              '回收站 (${stats.deletedEntriesCount})',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
              ),
            ),
            subtitle: Text(
              '查看、恢复或彻底删除 30 天内删除的日记',
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
          if (widget.ocrQueueManager != null) ...[
            Divider(height: 24, color: tokens.agedFiber),
            ListTile(
              key: const Key('settings_ocr_backfill_tile'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.document_scanner_outlined,
                size: 20,
                color: tokens.cinnabar,
              ),
              title: Text(
                '离线文字识别索引',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: tokens.jiaomo,
                ),
              ),
              subtitle: Text(
                _unindexedPhotoCount == 0
                    ? '已建立全部文字索引'
                    : '发现 $_unindexedPhotoCount 张照片尚未建立索引',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontKaiti,
                  fontSize: 11.5,
                  color: tokens.danmo,
                ),
              ),
              trailing: Icon(Icons.chevron_right, size: 18, color: tokens.danmo),
              onTap: () async {
                await showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => OcrBackfillDialog(
                    ocrQueueManager: widget.ocrQueueManager!,
                  ),
                );
                if (mounted) {
                  _loadOcrStatus();
                }
              },
            ),
          ],
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
              '写作统计',
              style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 14, color: tokens.jiaomo),
            ),
            subtitle: Text(
              '查看总篇数、总字数、年度写作热力图与心情分布',
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
            title: Text(
              '导入文本',
              style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 14, color: tokens.jiaomo),
            ),
            subtitle: Text(
              '从 .txt 或 .md 文件批量导入日记并自动识别日期',
              style: TextStyle(fontFamily: InkDiaryTheme.fontKaiti, fontSize: 11, color: tokens.danmo),
            ),
            trailing: Icon(Icons.chevron_right, size: 18, color: tokens.danmo),
            onTap: _handleImportFile,
          ),
          Divider(height: 1, color: tokens.agedFiber),
          ListTile(
            leading: Icon(Icons.file_download_outlined, color: tokens.nongmo),
            title: Text(
              '导出日记',
              style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 14, color: tokens.jiaomo),
            ),
            subtitle: Text(
              '导出为 PDF、Markdown 或纯文本文件',
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
          ListTile(
            key: const Key('settings_create_backup_tile'),
            leading: Icon(Icons.enhanced_encryption_outlined, color: tokens.cinnabar),
            title: Text(
              '导出加密备份 (.mdbak)',
              style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 14, color: tokens.jiaomo),
            ),
            subtitle: Text(
              '将全部日记、相册、模板及照片视频打包为加密 .mdbak 文件',
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
              '从备份恢复',
              style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 14, color: tokens.jiaomo),
            ),
            subtitle: Text(
              '选择 .mdbak 备份文件并完整恢复数据',
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
            title: '相机',
            description: '仅用于拍摄日记配图，照片会直接保存在应用私密目录中。',
            status: _cameraStatus,
            tokens: tokens,
          ),
          Divider(height: 1, color: tokens.agedFiber),
          _buildPermissionTile(
            icon: Icons.mic_none_outlined,
            title: '语音听写',
            description: '仅用于调用系统语音识别输入文字，不会向外部上传音频。',
            status: _micStatus,
            tokens: tokens,
          ),
          Divider(height: 1, color: tokens.agedFiber),
          _buildPermissionTile(
            icon: Icons.photo_library_outlined,
            title: '相册与文件',
            description: '用于从相册导入照片，以及导出日记和备份文件到本地。',
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
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: tokens.jiaomo,
                  ),
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
              isGranted ? '已授权' : '未授权',
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
              const CinnabarSealBadge(text: '纯本地', isRound: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '完全离线 · 本地隐私保护',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: tokens.jiaomo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '云皓日记全程离线运行，没有任何云端服务器。所有日记内容、排版格式与照片视频均仅保存在您的设备本地，无后台上传或第三方追踪，并通过 SQLCipher AES-256 全库加密保护您的数据安全。',
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
