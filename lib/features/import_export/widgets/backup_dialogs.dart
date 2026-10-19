import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../models/backup_manifest.dart';
import '../services/backup_crypto.dart';
import '../services/backup_restore_service.dart';
import '../services/file_selector_service.dart';

/// Bottom sheet / dialog for creating an encrypted or unencrypted `.mdbak` full-archive backup,
/// supporting both "Save to Device" (`file_picker`) and "Share..." (`share_plus` streaming from disk).
class CreateBackupDialog extends StatefulWidget {
  final BackupRestoreService backupService;
  final FileSelectorService fileSelector;
  final int pbkdf2Iterations;
  final Future<void> Function(File file)? onShareFile;

  const CreateBackupDialog({
    super.key,
    required this.backupService,
    required this.fileSelector,
    this.pbkdf2Iterations = BackupCrypto.defaultIterations,
    this.onShareFile,
  });

  static Future<BackupResult?> show({
    required BuildContext context,
    required BackupRestoreService backupService,
    required FileSelectorService fileSelector,
    int pbkdf2Iterations = BackupCrypto.defaultIterations,
    Future<void> Function(File file)? onShareFile,
  }) {
    return showDialog<BackupResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CreateBackupDialog(
        backupService: backupService,
        fileSelector: fileSelector,
        pbkdf2Iterations: pbkdf2Iterations,
        onShareFile: onShareFile,
      ),
    );
  }

  @override
  State<CreateBackupDialog> createState() => _CreateBackupDialogState();
}

class _CreateBackupDialogState extends State<CreateBackupDialog> {
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _encryptWithPassphrase = true;
  bool _isWorking = false;
  double _progress = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _passphraseController.addListener(_onInputChanged);
    _confirmController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  bool get _isPassphraseValid {
    if (!_encryptWithPassphrase) return true;
    final pass = _passphraseController.text;
    final confirm = _confirmController.text;
    return pass.length >= 8 && pass == confirm;
  }

  String? get _validationHint {
    if (!_encryptWithPassphrase) return null;
    final pass = _passphraseController.text;
    final confirm = _confirmController.text;
    if (pass.isEmpty) {
      return 'Enter at least 8 characters to encrypt your backup.';
    }
    if (pass.length < 8) {
      return 'Passphrase must be at least 8 characters (${pass.length}/8).';
    }
    if (confirm.isNotEmpty && pass != confirm) {
      return 'Passphrases do not match.';
    }
    if (confirm.isEmpty) {
      return 'Please confirm your passphrase.';
    }
    return null;
  }

  Future<void> _executeBackup({required bool shareAfterCreate}) async {
    if (!_isPassphraseValid || _isWorking) return;

    setState(() {
      _isWorking = true;
      _progress = 0.05;
      _errorMessage = null;
    });

    Directory? tempStagingDir;
    try {
      tempStagingDir =
          await Directory.systemTemp.createTemp('memodiary_export_mdbak_');
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'memodiary_backup_$timestamp.mdbak';
      final tempFile = File(p.join(tempStagingDir.path, fileName));

      final result = await widget.backupService.createBackup(
        destination: tempFile,
        passphrase:
            _encryptWithPassphrase ? _passphraseController.text : null,
        pbkdf2Iterations: widget.pbkdf2Iterations,
        onProgress: (p) {
          if (mounted) {
            setState(() => _progress = p);
          }
        },
      );

      if (shareAfterCreate) {
        if (widget.onShareFile != null) {
          await widget.onShareFile!(result.file);
        } else {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(result.file.path)],
              subject: 'MemoDiary Full Archive Backup ($fileName)',
            ),
          );
        }
        if (!mounted) return;
        Navigator.pop(context, result);
      } else {
        final savedPath = await widget.fileSelector.saveBackupFile(
          fileName: fileName,
          sourceFile: result.file,
        );
        if (!mounted) return;
        if (savedPath != null) {
          Navigator.pop(context, result);
        } else {
          setState(() => _isWorking = false);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isWorking = false;
        _errorMessage = 'Backup failed: $e';
      });
    } finally {
      if (tempStagingDir != null && await tempStagingDir.exists()) {
        try {
          await tempStagingDir.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = _validationHint;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.enhanced_encryption_outlined, size: 22),
          SizedBox(width: 8),
          Expanded(child: Text('Create Full-Archive Backup')),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bundles all diaries, notebooks, custom templates, and sandboxed photos/videos into a single portable .mdbak archive.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                key: const Key('backup_encrypt_switch'),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Encrypt with Passphrase (AES-256-GCM)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                value: _encryptWithPassphrase,
                onChanged: _isWorking
                    ? null
                    : (val) => setState(() => _encryptWithPassphrase = val),
              ),
              if (_encryptWithPassphrase) ...[
                const SizedBox(height: 8),
                TextField(
                  key: const Key('backup_passphrase_field'),
                  controller: _passphraseController,
                  enabled: !_isWorking,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Passphrase (min 8 chars)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('backup_confirm_passphrase_field'),
                  controller: _confirmController,
                  enabled: !_isWorking,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Passphrase',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    hint,
                    key: const Key('backup_validation_hint'),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Keep this passphrase safe. Encrypted archives are protected with PBKDF2 + AES-256-GCM and cannot be recovered if forgotten.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ] else ...[
                Container(
                  key: const Key('backup_unencrypted_warning'),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Warning: Unencrypted backup stores your diary text and media in plaintext without passphrase protection.',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              if (_isWorking) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _progress),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isWorking ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        OutlinedButton.icon(
          key: const Key('backup_share_button'),
          onPressed: (!_isPassphraseValid || _isWorking)
              ? null
              : () => _executeBackup(shareAfterCreate: true),
          icon: const Icon(Icons.share_outlined, size: 18),
          label: const Text('Share...'),
        ),
        FilledButton.icon(
          key: const Key('backup_save_button'),
          onPressed: (!_isPassphraseValid || _isWorking)
              ? null
              : () => _executeBackup(shareAfterCreate: false),
          icon: const Icon(Icons.save_alt_rounded, size: 18),
          label: const Text('Save to Device'),
        ),
      ],
    );
  }
}

/// Dialog for confirming and executing an atomic Replace-mode restore from a `.mdbak` file.
class RestoreBackupDialog extends StatefulWidget {
  final File sourceFile;
  final BackupInspection inspection;
  final BackupRestoreService backupService;

  const RestoreBackupDialog({
    super.key,
    required this.sourceFile,
    required this.inspection,
    required this.backupService,
  });

  static Future<RestoreResult?> show({
    required BuildContext context,
    required File sourceFile,
    required BackupInspection inspection,
    required BackupRestoreService backupService,
  }) {
    return showDialog<RestoreResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RestoreBackupDialog(
        sourceFile: sourceFile,
        inspection: inspection,
        backupService: backupService,
      ),
    );
  }

  @override
  State<RestoreBackupDialog> createState() => _RestoreBackupDialogState();
}

class _RestoreBackupDialogState extends State<RestoreBackupDialog> {
  final TextEditingController _passphraseController = TextEditingController();
  bool _confirmedReplace = false;
  bool _isRestoring = false;
  double _progress = 0.0;
  String? _errorMessage;

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_isRestoring || !_confirmedReplace) return false;
    if (widget.inspection.isEncrypted &&
        _passphraseController.text.isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _handleRestore() async {
    if (!_canSubmit) return;

    setState(() {
      _isRestoring = true;
      _progress = 0.05;
      _errorMessage = null;
    });

    try {
      final result = await widget.backupService.restoreBackup(
        source: widget.sourceFile,
        passphrase: widget.inspection.isEncrypted
            ? _passphraseController.text
            : null,
        onProgress: (p) {
          if (mounted) {
            setState(() => _progress = p);
          }
        },
      );

      if (!mounted) return;
      Navigator.pop(context, result);
    } on WrongPassphraseException catch (e) {
      if (!mounted) return;
      setState(() {
        _isRestoring = false;
        _errorMessage = e.message;
      });
    } on BackupException catch (e) {
      if (!mounted) return;
      setState(() {
        _isRestoring = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRestoring = false;
        _errorMessage = 'Restore failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileName = p.basename(widget.sourceFile.path);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.restore_page_outlined, size: 22),
          SizedBox(width: 8),
          Expanded(child: Text('Restore from Backup')),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Selected archive: $fileName',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                key: const Key('restore_replace_warning'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Replace Mode Warning: Restoring this backup will replace all current diaries, notebooks, templates, and media on this device. If the archive is corrupted or the passphrase is wrong, your current data will remain untouched.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.inspection.isEncrypted) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const Key('restore_passphrase_field'),
                  controller: _passphraseController,
                  enabled: !_isRestoring,
                  obscureText: true,
                  onChanged: (_) => setState(() => _errorMessage = null),
                  decoration: const InputDecoration(
                    labelText: 'Backup Passphrase',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              CheckboxListTile(
                key: const Key('restore_confirm_checkbox'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'I understand this will replace all current diary records.',
                  style: TextStyle(fontSize: 13),
                ),
                value: _confirmedReplace,
                onChanged: _isRestoring
                    ? null
                    : (val) => setState(() => _confirmedReplace = val ?? false),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  key: const Key('restore_error_text'),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (_isRestoring) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _progress),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isRestoring ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('restore_confirm_button'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: _canSubmit ? _handleRestore : null,
          child: const Text('Replace & Restore'),
        ),
      ],
    );
  }
}
