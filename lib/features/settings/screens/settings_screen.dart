import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/analytics/screens/analytics_dashboard_screen.dart';
import 'package:memodiary/features/import_export/screens/import_staging_screen.dart';
import 'package:memodiary/features/import_export/services/date_parser_engine.dart';
import 'package:memodiary/features/import_export/services/file_selector_service.dart';
import 'package:memodiary/features/import_export/widgets/export_dialog.dart';
import '../services/storage_optimizer_service.dart';
import '../widgets/notification_settings_card.dart';

/// Settings, Permissions Status, Storage Optimizer, and Offline Privacy screen.
class SettingsScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final FileSelectorService fileSelector;
  final Future<Map<String, PermissionStatus>> Function()? permissionChecker;
  final StorageStats? initialStats;

  const SettingsScreen({
    super.key,
    required this.database,
    required this.mediaService,
    this.fileSelector = const NativeFileSelectorService(),
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
    } else {
      _loadAll();
    }
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadStorageStats(),
      _checkPermissions(),
    ]);
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
      SnackBar(content: Text('Cleaned up $purged orphan media files')),
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

      // Parse in background Isolate worker to maintain 60 FPS
      final candidates = await DateParserEngine.parseDocumentInIsolate(
        text: text,
      );

      if (!mounted) return;

      if (candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected file contains no readable text.')),
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
        SnackBar(content: Text('Failed to import file: $e')),
      );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Privacy'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Storage & Optimizer Section
          _buildSectionHeader('Storage & Optimization', theme),
          _buildStorageCard(theme),
          const SizedBox(height: 20),

          // 2. Writing Reminders Section
          _buildSectionHeader('Writing Reminders', theme),
          const NotificationSettingsCard(),
          const SizedBox(height: 20),

          // 3. Data Portability Section
          _buildSectionHeader('Data Portability', theme),
          _buildDataPortabilityCard(theme),
          const SizedBox(height: 20),

          // 4. Permissions Dashboard
          _buildSectionHeader('Permissions Dashboard', theme),
          _buildPermissionsCard(theme),
          const SizedBox(height: 20),

          // 5. Zero-Cloud Privacy Declaration
          _buildPrivacyCard(theme),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildStorageCard(ThemeData theme) {
    if (_isLoadingStats || _stats == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final stats = _stats!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Active Entries', '${stats.activeEntriesCount}', theme),
                _buildStatColumn('Media Files', '${stats.totalMediaFiles} (${stats.totalMediaFormatted})', theme),
                _buildStatColumn('In Bin', '${stats.deletedEntriesCount}', theme),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  stats.orphanMediaFiles > 0
                      ? Icons.cleaning_services_outlined
                      : Icons.verified_outlined,
                  color: stats.orphanMediaFiles > 0 ? Colors.amber.shade800 : Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.orphanMediaFiles > 0
                            ? '${stats.orphanMediaFiles} Orphan Media Files'
                            : 'Media Sandbox Clean',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        stats.orphanMediaFiles > 0
                            ? '${stats.orphanMediaFormatted} can be safely reclaimed.'
                            : 'All files correspond to active diary entries.',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (stats.orphanMediaFiles > 0)
                  FilledButton.tonal(
                    onPressed: _isCleaningOrphans ? null : _handleCleanOrphans,
                    child: _isCleaningOrphans
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Clean'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildDataPortabilityCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: Column(
        children: [
          ListTile(
            key: const Key('settings_analytics_tile'),
            leading: const Icon(Icons.insights_rounded),
            title: const Text('Writing Analytics & Heatmap'),
            subtitle: const Text('View 52-week contribution grid, streaks, and word counts.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Import from .txt / .md'),
            subtitle: const Text('Batch parse diary archives with intelligent date detection.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: _handleImportFile,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export All Diaries'),
            subtitle: const Text('Save to Markdown (with YAML frontmatter) or plain text.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: _handleExportAll,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: Column(
        children: [
          _buildPermissionTile(
            icon: Icons.camera_alt_outlined,
            title: 'Camera',
            description: 'Used strictly to capture diary photos stored in the sandboxed directory.',
            status: _cameraStatus,
          ),
          const Divider(height: 1),
          _buildPermissionTile(
            icon: Icons.mic_none_outlined,
            title: 'Microphone & Speech',
            description: 'Used strictly for zero-cost on-device speech-to-text dictation.',
            status: _micStatus,
          ),
          const Divider(height: 1),
          _buildPermissionTile(
            icon: Icons.photo_library_outlined,
            title: 'Photos & Files',
            description: 'Used to import images and save backup export files to local storage.',
            status: _storageStatus,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: const Text('Open System App Settings'),
            ),
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
  }) {
    final isGranted = status?.isGranted ?? false;
    return ListTile(
      leading: Icon(icon),
      title: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isGranted ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isGranted ? 'Allowed' : 'Not Granted',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isGranted ? Colors.green.shade800 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildPrivacyCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                '100% Offline & Private',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'MemoDiary operates with zero cloud servers, zero external tracking SDKs, and zero telemetry. '
            'All diary entries are protected at rest with SQLCipher AES-256 encryption using hardware-backed '
            'keys, and all photos remain isolated in the app sandbox on your device.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
