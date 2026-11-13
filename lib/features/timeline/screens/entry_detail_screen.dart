import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/xuan_paper_card.dart';
import '../../editor/screens/entry_editor_screen.dart';
import '../../editor/services/audio_sanctum_service.dart';
import '../../import_export/widgets/export_dialog.dart';
import '../../import_export/widgets/pdf_preview_screen.dart';
import '../../templates/models/template_style.dart';
import '../widgets/folio/thread_bound_folio_screen.dart';

/// Full-screen entry detail viewer rendering the entry inside the Mobile
/// Single-Page Thread-Bound Folio with PIN protection, ambient soundscapes,
/// and consolidated minimalist desk chrome.
class EntryDetailScreen extends StatefulWidget {
  final Entry? entry;
  final String? entryId;
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final AuthService? authService;
  final AudioSanctumService? audioSanctumService;
  final Future<void> Function(String text, {String? subject})? shareHandler;

  const EntryDetailScreen({
    super.key,
    this.entry,
    this.entryId,
    required this.database,
    required this.mediaService,
    this.authService,
    this.audioSanctumService,
    this.shareHandler,
  }) : assert(entry != null || entryId != null, 'Either entry or entryId must be provided');

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  Entry? _entry;
  AppDatabase get _db => widget.database;
  MediaSandboxService get _media => widget.mediaService;

  late final AuthService _authService;
  late final AudioSanctumService _audioSanctumService;
  Template? _template;
  List<MediaAttachment> _attachments = const [];
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = true;
  bool _isSessionUnlocked = false;
  String? _pinError;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _authService = widget.authService ?? AuthService();
    _audioSanctumService = widget.audioSanctumService ?? AudioSanctumService();
    _loadData();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final targetId = _entry?.id ?? widget.entryId!;
      final freshEntry = await _db.entriesDao.getEntryById(targetId);
      if (freshEntry != null) {
        _entry = freshEntry;
      }

      final entry = _entry;
      if (entry == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      _template = await _db.templatesDao.getTemplateById(entry.templateId);
      if (_template == null) {
        final allTemplates = await _db.templatesDao.getAllTemplates();
        if (allTemplates.isNotEmpty) {
          _template = allTemplates.first;
        }
      }

      _attachments = await _db.mediaOcrDao.getMediaForEntry(entry.id);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (error, stackTrace) {
      debugPrint('Error loading entry detail: $error\n$stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _isCurrentlyBlocked => _entry != null && _entry!.isLocked && !_isSessionUnlocked;

  Future<void> _handleUnlockWithPin() async {
    final entry = _entry;
    if (entry == null) return;

    final enteredPin = _pinController.text.trim();
    if (enteredPin.isEmpty) {
      setState(() => _pinError = '请输入印匣密码');
      return;
    }

    bool verified = false;
    if (entry.entryPinHash != null && entry.entryPinHash!.isNotEmpty) {
      verified = _authService.verifyEntryPin(enteredPin, entry.entryPinHash!);
    } else {
      verified = await _authService.verifyPin(enteredPin);
    }

    if (verified) {
      HapticFeedback.lightImpact();
      setState(() {
        _isSessionUnlocked = true;
        _pinError = null;
        _pinController.clear();
      });
    } else {
      setState(() => _pinError = 'Incorrect PIN');
    }
  }

  Future<void> _handleUnlockWithBiometrics() async {
    final authenticated = await _authService.authenticateBiometric(
      localizedReason: '解锁私密手稿',
    );
    if (authenticated && mounted) {
      HapticFeedback.lightImpact();
      setState(() {
        _isSessionUnlocked = true;
        _pinError = null;
      });
    }
  }

  Future<void> _handleToggleLock() async {
    final entry = _entry;
    if (entry == null) return;

    if (entry.isLocked) {
      await _db.entriesDao.unlockEntryPermanently(entry.id);
      HapticFeedback.lightImpact();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已解除私密封缄')),
        );
      }
      return;
    }

    final pinInputController = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('私密封缄 · Lock Entry'),
        content: TextField(
          key: const Key('lock_entry_pin_input'),
          controller: pinInputController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(labelText: '设定 4-6 位密码', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
          FilledButton(
            key: const Key('confirm_lock_entry_btn'),
            onPressed: () {
              final text = pinInputController.text.trim();
              if (text.length >= 4) Navigator.pop(dialogContext, text);
            },
            child: const Text('落锁封存'),
          ),
        ],
      ),
    );

    if (pin != null && pin.length >= 4) {
      final pinHash = _authService.hashEntryPin(pin);
      await _db.entriesDao.lockEntry(entry.id, pinHash: pinHash);
      HapticFeedback.lightImpact();
      setState(() => _isSessionUnlocked = false);
      await _loadData();
    }
  }

  Future<void> _handleEdit() async {
    final entry = _entry;
    if (entry == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EntryEditorScreen(
          database: _db,
          mediaSandboxService: _media,
          entryId: entry.id,
        ),
      ),
    );

    if (result == true || mounted) {
      await _loadData();
    }
  }

  Future<void> _handleShare(String fullShareText, {String? subject}) async {
    final entry = _entry;
    if (entry == null) return;

    if (widget.shareHandler != null) {
      await widget.shareHandler!(fullShareText, subject: subject ?? entry.title);
    } else {
      await SharePlus.instance.share(
        ShareParams(
          text: fullShareText,
          subject: subject ?? entry.title,
        ),
      );
    }
  }

  Future<void> _handleExportPdf() async {
    final entry = _entry;
    if (entry == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          singleEntry: entry,
          database: _db,
          mediaService: _media,
        ),
      ),
    );
  }

  Future<void> _handleExportText() async {
    final entry = _entry;
    if (entry == null) return;

    ExportDialog.show(
      context: context,
      database: _db,
      singleEntry: entry,
      mediaService: _media,
    );
  }

  Future<void> _handleSoftDelete() async {
    final entry = _entry;
    if (entry == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Move to Recycle Bin?'),
        content: const Text('此手稿将移入回收站，30 天内仍可完好还原，逾期将彻底化作飞灰。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('保留手稿')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Move to Bin'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.entriesDao.softDeleteEntry(entry.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Widget _buildLockBarrier(InkDiaryTokens tokens) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: XuanPaperCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: tokens.cinnabarWash,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.cinnabar.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.lock_outline_rounded, size: 32, color: tokens.cinnabar),
              ),
              const SizedBox(height: 18),
              Text(
                'This Diary Entry is Locked',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tokens.jiaomo,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '此卷已落锁封存。请输入印匣密码或验证指纹，方可展卷阅览。',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: InkDiaryTheme.fontKaiti, fontSize: 13, color: tokens.danmo),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 200,
                child: TextField(
                  key: const Key('entry_unlock_pin_field'),
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  onSubmitted: (_) => _handleUnlockWithPin(),
                  decoration: InputDecoration(
                    hintText: '输入印匣密码',
                    errorText: _pinError,
                    counterText: '',
                    filled: true,
                    fillColor: tokens.ricePaper,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: tokens.agedFiber),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('entry_unlock_submit_btn'),
                onPressed: _handleUnlockWithPin,
                style: FilledButton.styleFrom(backgroundColor: tokens.jiaomo, foregroundColor: tokens.xuanGround),
                icon: const Icon(Icons.key_rounded, size: 16),
                label: const Text('启封展卷'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('entry_unlock_biometric_btn'),
                onPressed: _handleUnlockWithBiometrics,
                icon: Icon(Icons.fingerprint_rounded, color: tokens.cinnabar),
                label: Text('生物指纹解印', style: TextStyle(color: tokens.cinnabar)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0908),
        body: Center(child: CircularProgressIndicator(color: tokens.cinnabar)),
      );
    }

    final entry = _entry;
    if (entry == null || _template == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0908),
        appBar: AppBar(backgroundColor: const Color(0xFF0A0908), leading: const BackButton(color: Color(0xFFE6E1D8))),
        body: Center(
          child: Text('未找到对应日记手稿', style: TextStyle(fontFamily: InkDiaryTheme.fontKaiti, color: tokens.danmo, fontSize: 15)),
        ),
      );
    }

    if (_isCurrentlyBlocked) {
      return Scaffold(
        backgroundColor: tokens.xuanGround,
        appBar: AppBar(
          backgroundColor: tokens.xuanGround,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: tokens.jiaomo),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            DateFormat('yyyy年M月d日').format(entry.entryDate),
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 16,
              color: tokens.jiaomo,
            ),
          ),
        ),
        body: _buildLockBarrier(tokens),
      );
    }

    final templateStyle = TemplateStyle.fromTemplate(_template!);

    return ThreadBoundFolioScreen(
      entry: entry,
      templateStyle: templateStyle,
      attachments: _attachments,
      mediaService: _media,
      audioSanctumService: _audioSanctumService,
      actions: FolioActions(
        shareHandler: _handleShare,
        onEditEntry: _handleEdit,
        onSoftDelete: _handleSoftDelete,
        onToggleLock: _handleToggleLock,
        onExportPdf: _handleExportPdf,
        onExportText: _handleExportText,
      ),
      onOverlayPositionChanged: (photoId, xRatio, yRatio) =>
          _db.mediaOcrDao.updateMediaAttachmentOverlayPosition(
        photoId,
        xRatio: xRatio,
        yRatio: yRatio,
      ),
    );
  }
}
