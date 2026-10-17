import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/dictation_service.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../templates/models/template_style.dart';
import '../../templates/widgets/template_canvas_container.dart';
import '../../templates/widgets/template_switcher_sheet.dart';
import '../controllers/editor_autosave_manager.dart';
import '../models/typography_settings.dart';
import '../services/thought_spark_service.dart';
import '../widgets/dictation_bar.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/entry_metadata_bar.dart';
import '../widgets/sandboxed_image_embed_builder.dart';
import '../widgets/thought_spark_banner.dart';
import '../widgets/typography_sheet.dart';

/// Full rich-text multimodal diary editor screen.
/// Decouples content (Quill Delta JSON) from presentation (Procedural Templates & Typography).
class EntryEditorScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaSandboxService;
  final String entryId;
  final DictationService? dictationService;
  final ThoughtSparkService? thoughtSparkService;
  final ImagePicker? imagePicker;

  const EntryEditorScreen({
    super.key,
    required this.database,
    required this.mediaSandboxService,
    required this.entryId,
    this.dictationService,
    this.thoughtSparkService,
    this.imagePicker,
  });

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  late final DictationService _dictationService;
  late final ThoughtSparkService _thoughtSparkService;
  late final ImagePicker _imagePicker;

  QuillController? _controller;
  EditorAutosaveManager? _autosaveManager;

  Template? _currentTemplate;
  List<Template> _allTemplates = [];
  TypographySettings _typography = const TypographySettings();

  bool _isLoading = true;
  bool _showThoughtSpark = true;
  bool _isDictating = false;

  DateTime _entryDate = DateTime.now();
  int? _mood;
  String? _weather;
  DateTime? _unlockAt;

  @override
  void initState() {
    super.initState();
    _dictationService = widget.dictationService ?? DictationService();
    _thoughtSparkService = widget.thoughtSparkService ?? ThoughtSparkService();
    _imagePicker = widget.imagePicker ?? ImagePicker();
    _loadEntryData();
  }

  @override
  void dispose() {
    _autosaveManager?.dispose();
    _controller?.dispose();
    _dictationService.dispose();
    super.dispose();
  }

  Future<void> _loadEntryData() async {
    try {
      final entry = await widget.database.getEntryById(widget.entryId);
      if (entry == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final templates = await widget.database.select(widget.database.templates).get();
      final template = templates.firstWhere(
        (t) => t.id == entry.templateId,
        orElse: () => templates.first,
      );

      // Parse Quill Delta
      Document document;
      try {
        if (entry.contentDelta.trim().isEmpty) {
          document = Document();
        } else {
          final decoded = jsonDecode(entry.contentDelta);
          if (decoded is List) {
            document = Document.fromJson(decoded);
          } else {
            document = Document();
          }
        }
      } catch (_) {
        document = Document();
      }

      final controller = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );

      final autosave = EditorAutosaveManager(
        database: widget.database,
        entryId: widget.entryId,
        controller: controller,
      );

      if (mounted) {
        setState(() {
          _currentTemplate = template;
          _allTemplates = templates;
          _controller = controller;
          _autosaveManager = autosave;
          _entryDate = entry.entryDate;
          _mood = entry.mood;
          _weather = entry.weather;
          _unlockAt = entry.unlockAt;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrint('Error loading entry editor data: $e\n$st');
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleTemplateSwitch() async {
    if (_currentTemplate == null) return;
    final freshTemplates = await widget.database.getAllTemplates();
    if (!mounted) return;
    setState(() {
      _allTemplates = freshTemplates;
    });

    await TemplateSwitcherSheet.show(
      context: context,
      templates: _allTemplates,
      currentTemplateId: _currentTemplate!.id,
      database: widget.database,
      onTemplateSelected: (newTemplate) async {
        setState(() {
          _currentTemplate = newTemplate;
        });
        // Preserves contentDelta completely untouched!
        await widget.database.updateEntryTemplate(widget.entryId, newTemplate.id);
      },
    );
  }

  Future<void> _handleTypographySettings() async {
    await TypographySheet.show(
      context: context,
      settings: _typography,
      onChanged: (newSettings) {
        setState(() {
          _typography = newSettings;
        });
      },
    );
  }

  Future<void> _handleImagePick() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo with Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Photo Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picked = await _imagePicker.pickImage(source: source);
      if (picked == null || _controller == null) return;

      // Sandbox isolation: Compress to WebP and get relative path
      final relativePath = await widget.mediaSandboxService.copyAndCompressImage(
        File(picked.path),
      );

      // Insert into Quill Delta
      final index = _controller!.selection.baseOffset.clamp(
        0,
        _controller!.document.length - 1,
      );
      _controller!.document.insert(index, BlockEmbed.image(relativePath));

      // Record in media_attachments table
      await widget.database.attachMediaToEntry(
        id: const Uuid().v4(),
        entryId: widget.entryId,
        relativePath: relativePath,
        mediaType: 'image',
      );

      _autosaveManager?.saveDraft();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to insert photo: $e')),
        );
      }
    }
  }

  void _handleInsertPrompt(String prompt) {
    if (_controller == null) return;
    final index = _controller!.selection.baseOffset.clamp(
      0,
      _controller!.document.length - 1,
    );
    _controller!.document.insert(index, '$prompt\n');
    _controller!.formatText(index, prompt.length, Attribute.blockQuote);
    setState(() {
      _showThoughtSpark = false;
    });
    _autosaveManager?.saveDraft(force: true);
  }

  Future<void> _handleSaveAndExit() async {
    await _autosaveManager?.saveDraft(force: true);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _controller == null || _currentTemplate == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final templateStyle = TemplateStyle.fromTemplate(_currentTemplate!);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _handleSaveAndExit,
        ),
        title: ValueListenableBuilder<AutosaveStatus>(
          valueListenable: _autosaveManager!.statusNotifier,
          builder: (context, status, _) {
            String label = 'Saved';
            Color color = Colors.green;
            if (status == AutosaveStatus.saving) {
              label = 'Saving...';
              color = Colors.orange;
            } else if (status == AutosaveStatus.unsaved) {
              label = 'Unsaved';
              color = Colors.grey;
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            );
          },
        ),
        actions: [
          // Template switcher
          IconButton(
            icon: const Icon(Icons.style_outlined, color: Colors.black87),
            tooltip: 'Switch Template',
            onPressed: _handleTemplateSwitch,
          ),
          // Typography
          IconButton(
            icon: const Icon(Icons.font_download_outlined, color: Colors.black87),
            tooltip: 'Typography',
            onPressed: _handleTypographySettings,
          ),
          // Save and Done
          IconButton(
            icon: const Icon(Icons.check, color: Colors.deepPurple),
            tooltip: 'Done',
            onPressed: _handleSaveAndExit,
          ),
        ],
      ),
      body: Column(
        children: [
          // Metadata bar (Date, Mood, Weather, Time Capsule)
          Container(
            color: Colors.white,
            child: EntryMetadataBar(
              entryDate: _entryDate,
              mood: _mood,
              weather: _weather,
              unlockAt: _unlockAt,
              onDateChanged: (val) {
                setState(() => _entryDate = val);
                widget.database.updateEntryMetadata(widget.entryId, entryDate: val);
              },
              onMoodChanged: (val) {
                setState(() => _mood = val);
                widget.database.updateEntryMetadata(widget.entryId, mood: val);
              },
              onWeatherChanged: (val) {
                setState(() => _weather = val);
                widget.database.updateEntryMetadata(widget.entryId, weather: val);
              },
              onUnlockAtChanged: (val) {
                setState(() => _unlockAt = val);
                widget.database.updateEntryMetadata(widget.entryId, unlockAt: val);
              },
            ),
          ),

          // Thought Spark Banner
          if (_showThoughtSpark)
            ThoughtSparkBanner(
              sparkService: _thoughtSparkService,
              onInsertPrompt: _handleInsertPrompt,
              onDismiss: () => setState(() => _showThoughtSpark = false),
            ),

          // Procedural Canvas Container wrapping Quill Editor
          Expanded(
            child: TemplateCanvasContainer(
              style: templateStyle,
              child: QuillEditor(
                controller: _controller!,
                focusNode: FocusNode(),
                scrollController: ScrollController(),
                config: QuillEditorConfig(
                  placeholder: 'Write your heart out today...',
                  embedBuilders: [
                    SandboxedImageEmbedBuilder(
                      mediaSandboxService: widget.mediaSandboxService,
                      onImageRemoved: () => _autosaveManager?.saveDraft(),
                    ),
                  ],
                  customStyles: DefaultStyles(
                    paragraph: DefaultTextBlockStyle(
                      _typography.toTextStyle(),
                      const HorizontalSpacing(0, 0),
                      const VerticalSpacing(0, 0),
                      const VerticalSpacing(0, 0),
                      null,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating Dictation Bar when active
          if (_isDictating)
            DictationBar(
              controller: _controller!,
              dictationService: _dictationService,
              onClose: () => setState(() => _isDictating = false),
            ),

          // Fixed Bottom Formatting Toolbar
          EditorToolbar(
            controller: _controller!,
            isDictating: _isDictating,
            onPickImage: _handleImagePick,
            onToggleDictation: () => setState(() => _isDictating = !_isDictating),
            onOpenTypography: _handleTypographySettings,
            onOpenTemplates: _handleTemplateSwitch,
          ),
        ],
      ),
    );
  }
}
