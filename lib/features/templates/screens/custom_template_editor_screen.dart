import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../editor/models/typography_settings.dart';
import '../models/template_style.dart';
import '../widgets/template_canvas_container.dart';

/// Preset diary background color swatch.
class ColorSwatchOption {
  final String name;
  final String hex;
  final Color color;

  const ColorSwatchOption({
    required this.name,
    required this.hex,
    required this.color,
  });
}

/// Interactive screen allowing users to build or edit custom visual diary templates
/// with a real-time procedural canvas preview.
class CustomTemplateEditorScreen extends StatefulWidget {
  final AppDatabase database;
  final Template? existingTemplate;

  const CustomTemplateEditorScreen({
    super.key,
    required this.database,
    this.existingTemplate,
  });

  static const List<ColorSwatchOption> presetSwatches = [
    ColorSwatchOption(name: 'Pure White', hex: '#FFFFFF', color: Color(0xFFFFFFFF)),
    ColorSwatchOption(name: 'Warm Ivory', hex: '#FDFBF7', color: Color(0xFFFDFBF7)),
    ColorSwatchOption(name: 'Soft Cream', hex: '#FDF6E2', color: Color(0xFFFDF6E2)),
    ColorSwatchOption(name: 'Retro Kraft', hex: '#EFE6D5', color: Color(0xFFEFE6D5)),
    ColorSwatchOption(name: 'Mint Whisper', hex: '#E8F5E9', color: Color(0xFFE8F5E9)),
    ColorSwatchOption(name: 'Sky Mist', hex: '#E3F2FD', color: Color(0xFFE3F2FD)),
    ColorSwatchOption(name: 'Rose Blush', hex: '#FCE4EC', color: Color(0xFFFCE4EC)),
    ColorSwatchOption(name: 'Lavender Haze', hex: '#F3E5F5', color: Color(0xFFF3E5F5)),
    ColorSwatchOption(name: 'Cool Slate', hex: '#F4F5F7', color: Color(0xFFF4F5F7)),
  ];

  @override
  State<CustomTemplateEditorScreen> createState() =>
      _CustomTemplateEditorScreenState();
}

class _CustomTemplateEditorScreenState
    extends State<CustomTemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _hexController;

  late TemplateBackgroundType _backgroundType;
  late String _backgroundHex;
  late double _lineSpacing;
  late double _marginHorizontal;
  late String _selectedFontFamily;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTemplate;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _backgroundType = existing != null
        ? TemplateBackgroundType.fromString(existing.backgroundType)
        : TemplateBackgroundType.lined;
    _backgroundHex = existing?.backgroundValue ?? '#FDFBF7';
    _hexController = TextEditingController(text: _backgroundHex);
    _lineSpacing = (existing?.lineSpacing ?? 1.6).clamp(1.0, 2.5);
    _marginHorizontal = (existing?.marginHorizontal ?? 20.0).clamp(12.0, 48.0);
    _selectedFontFamily = existing?.fontFamily ?? 'System';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  TemplateStyle get _currentPreviewStyle {
    return TemplateStyle(
      type: _backgroundType,
      backgroundColor: TemplateStyle.parseHexColor(_backgroundHex),
      lineSpacing: _lineSpacing,
      marginHorizontal: _marginHorizontal,
      fontFamily: _selectedFontFamily == 'System' ? null : _selectedFontFamily,
    );
  }

  void _onHexChanged(String value) {
    final cleaned = value.trim();
    final regex = RegExp(r'^#?[0-9A-Fa-f]{6}$');
    if (regex.hasMatch(cleaned)) {
      final normalized =
          cleaned.startsWith('#') ? cleaned.toUpperCase() : '#${cleaned.toUpperCase()}';
      setState(() {
        _backgroundHex = normalized;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final trimmedName = _nameController.text.trim();
      Template savedTemplate;

      if (widget.existingTemplate != null) {
        await widget.database.updateCustomTemplate(
          widget.existingTemplate!.id,
          name: trimmedName,
          backgroundType: _backgroundType.toDbValue,
          backgroundValue: _backgroundHex,
          fontFamily: _selectedFontFamily,
          lineSpacing: _lineSpacing,
          marginHorizontal: _marginHorizontal,
        );
        final updated =
            await widget.database.getTemplateById(widget.existingTemplate!.id);
        savedTemplate = updated!;
      } else {
        savedTemplate = await widget.database.createCustomTemplate(
          name: trimmedName,
          backgroundType: _backgroundType.toDbValue,
          backgroundValue: _backgroundHex,
          fontFamily: _selectedFontFamily,
          lineSpacing: _lineSpacing,
          marginHorizontal: _marginHorizontal,
        );
      }

      if (mounted) {
        Navigator.pop(context, savedTemplate);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save template: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingTemplate != null;
    final previewStyle = _currentPreviewStyle;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Custom Template' : 'New Custom Template'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              key: const Key('save_custom_template_button'),
              onPressed: _isSaving ? null : _handleSave,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Live Interactive Preview Card
              Text(
              'LIVE CANVAS PREVIEW',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              key: const Key('template_live_preview_card'),
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: TemplateCanvasContainer(
                  style: previewStyle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saturday, Oct 17 · ☀️ Sunny',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontFamily: previewStyle.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _nameController.text.trim().isEmpty
                            ? 'Autumn Morning Reflections'
                            : _nameController.text.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: previewStyle.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          'Sunlight filtered softly through the golden leaves, casting warm patterns across the desk.\n拾光日记 · 记录每一个值得珍藏的瞬间。',
                          style: TextStyle(
                            fontSize: 14,
                            height: _lineSpacing,
                            color: Colors.black87,
                            fontFamily: previewStyle.fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Template Name Field
            TextFormField(
              key: const Key('template_name_input'),
              controller: _nameController,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                hintText: 'e.g., Lavender Lined, Cozy Grid',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.drive_file_rename_outline),
              ),
              onChanged: (_) => setState(() {}),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a template name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 3. Background Type Selector
            Text(
              'Paper Pattern',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TemplateBackgroundType.values.map((type) {
                final isSelected = _backgroundType == type;
                return ChoiceChip(
                  key: Key('bg_type_${type.toDbValue}'),
                  label: Text(type.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _backgroundType = type);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 4. Background Color Swatches & Hex Picker
            Text(
              'Paper Color',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: CustomTemplateEditorScreen.presetSwatches.map((swatch) {
                final isSelected =
                    _backgroundHex.toUpperCase() == swatch.hex.toUpperCase();
                return GestureDetector(
                  key: Key('color_swatch_${swatch.hex}'),
                  onTap: () {
                    setState(() {
                      _backgroundHex = swatch.hex;
                      _hexController.text = swatch.hex;
                    });
                  },
                  child: Tooltip(
                    message: swatch.name,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: swatch.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey.shade400,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 18,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('template_hex_input'),
              controller: _hexController,
              decoration: const InputDecoration(
                labelText: 'Custom Hex Color (#RRGGBB)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.palette_outlined),
                isDense: true,
              ),
              onChanged: _onHexChanged,
              validator: (val) {
                final regex = RegExp(r'^#?[0-9A-Fa-f]{6}$');
                if (val == null || !regex.hasMatch(val.trim())) {
                  return 'Enter a valid 6-digit hex color (e.g., #FDFBF7)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // 5. Line Spacing Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Line Spacing',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_lineSpacing.toStringAsFixed(1)}x',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            Slider(
              key: const Key('line_spacing_slider'),
              value: _lineSpacing,
              min: 1.0,
              max: 2.5,
              divisions: 15,
              label: '${_lineSpacing.toStringAsFixed(1)}x',
              onChanged: (val) {
                setState(() {
                  _lineSpacing = double.parse(val.toStringAsFixed(1));
                });
              },
            ),
            const SizedBox(height: 12),

            // 6. Horizontal Margin Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Horizontal Margin',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_marginHorizontal.round()} px',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            Slider(
              key: const Key('margin_horizontal_slider'),
              value: _marginHorizontal,
              min: 12.0,
              max: 48.0,
              divisions: 18,
              label: '${_marginHorizontal.round()} px',
              onChanged: (val) {
                setState(() {
                  _marginHorizontal = val.roundToDouble();
                });
              },
            ),
            const SizedBox(height: 16),

            // 7. Font Family Selector
            Text(
              'Default Font Family',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const Key('font_family_dropdown'),
              isExpanded: true,
              initialValue: _selectedFontFamily,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.font_download_outlined),
              ),
              items: TypographyCatalog.options.map((opt) {
                final val = opt.fontFamily ?? 'System';
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    '${opt.name} (${opt.description})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedFontFamily = val);
                }
              },
            ),
            const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
