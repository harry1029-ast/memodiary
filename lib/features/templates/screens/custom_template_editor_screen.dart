import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../editor/models/typography_settings.dart';
import '../models/template_style.dart';
import '../widgets/template_canvas_container.dart';

/// Preset diary background color swatch with literati naming.
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
/// with a real-time procedural canvas preview in Ink & Paper aesthetic.
class CustomTemplateEditorScreen extends StatefulWidget {
  final AppDatabase database;
  final Template? existingTemplate;

  const CustomTemplateEditorScreen({
    super.key,
    required this.database,
    this.existingTemplate,
  });

  static const List<ColorSwatchOption> presetSwatches = [
    ColorSwatchOption(name: '澄心素白', hex: '#FFFFFF', color: Color(0xFFFFFFFF)),
    ColorSwatchOption(name: '温润象牙', hex: '#FDFBF7', color: Color(0xFFFDFBF7)),
    ColorSwatchOption(name: '暖阳素笺', hex: '#FDF6E2', color: Color(0xFFFDF6E2)),
    ColorSwatchOption(name: '仿古茶皮', hex: '#EFE6D5', color: Color(0xFFEFE6D5)),
    ColorSwatchOption(name: '松烟淡青', hex: '#E8F5E9', color: Color(0xFFE8F5E9)),
    ColorSwatchOption(name: '天青水色', hex: '#E3F2FD', color: Color(0xFFE3F2FD)),
    ColorSwatchOption(name: '绛霞微粉', hex: '#FCE4EC', color: Color(0xFFFCE4EC)),
    ColorSwatchOption(name: '幽兰淡紫', hex: '#F3E5F5', color: Color(0xFFF3E5F5)),
    ColorSwatchOption(name: '黛灰寒砚', hex: '#F4F5F7', color: Color(0xFFF4F5F7)),
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
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    final isEditing = widget.existingTemplate != null;
    final previewStyle = _currentPreviewStyle;

    return Scaffold(
      backgroundColor: tokens.xuanGround,
      appBar: AppBar(
        backgroundColor: tokens.xuanGround,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: tokens.agedFiber,
            width: 1.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tokens.jiaomo),
          tooltip: '返回',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? '订正雅笺 · 笺谱改样' : '创制新笺 · 笺谱定样',
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontNotoSerif,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: tokens.jiaomo,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              key: const Key('save_custom_template_button'),
              style: FilledButton.styleFrom(
                backgroundColor: tokens.cinnabar,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: _isSaving ? null : _handleSave,
              icon: const Icon(Icons.check, size: 16),
              label: Text(
                _isSaving ? '存卷中...' : '定稿归卷',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: tokens.cinnabar,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '案头即时笺样 · LIVE PREVIEW',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: tokens.jiaomo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                key: const Key('template_live_preview_card'),
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tokens.agedFiber),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.jiaomo.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: TemplateCanvasContainer(
                    style: previewStyle,
                    typography: TypographySettings(
                      fontSize: 14,
                      lineSpacing: _lineSpacing,
                      fontFamily: previewStyle.fontFamily,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '丙午岁九月廿一 · ☀️ 晴朗',
                          style: TextStyle(
                            fontFamily: previewStyle.fontFamily ?? InkDiaryTheme.fontKaiti,
                            fontSize: 12,
                            color: tokens.danmo,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _nameController.text.trim().isEmpty
                              ? '秋山晚眺 · 随笔起兴'
                              : _nameController.text.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: previewStyle.fontFamily ?? InkDiaryTheme.fontNotoSerif,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: tokens.jiaomo,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            '秋水初凝，晨光微露，案头烹茶一瓯，静观落叶飘飏。\n拾光日记 · 记录每一个值得珍藏的瞬间。',
                            style: TextStyle(
                              fontFamily: previewStyle.fontFamily ?? InkDiaryTheme.fontKaiti,
                              fontSize: 14,
                              height: _lineSpacing,
                              color: tokens.nongmo,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // 2. Template Name Field
              TextFormField(
                key: const Key('template_name_input'),
                controller: _nameController,
                maxLength: 30,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  color: tokens.jiaomo,
                ),
                decoration: InputDecoration(
                  labelText: '信笺雅称 · Template Name',
                  hintText: '如：澄心朱丝栏、雨过天青笺',
                  filled: true,
                  fillColor: tokens.ricePaper,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: tokens.agedFiber),
                  ),
                  prefixIcon: Icon(Icons.drive_file_rename_outline, color: tokens.danmo),
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

              // 3. Background Pattern Type Selector
              Text(
                '界格规制 · Paper Pattern',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: tokens.jiaomo,
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
                    selectedColor: tokens.jiaomo,
                    backgroundColor: tokens.ricePaper,
                    labelStyle: TextStyle(
                      fontFamily: InkDiaryTheme.fontKaiti,
                      color: isSelected ? tokens.xuanGround : tokens.nongmo,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        HapticFeedback.lightImpact();
                        setState(() => _backgroundType = type);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 4. Background Color Swatches & Hex Picker
              Text(
                '笺纸底色 · Paper Color',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: tokens.jiaomo,
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
                      HapticFeedback.lightImpact();
                      setState(() {
                        _backgroundHex = swatch.hex;
                        _hexController.text = swatch.hex;
                      });
                    },
                    child: Tooltip(
                      message: swatch.name,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: swatch.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? tokens.cinnabar
                                : tokens.agedFiber,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: tokens.cinnabar.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: tokens.cinnabar,
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
                decoration: InputDecoration(
                  labelText: '自定义色值十六进制 (#RRGGBB)',
                  filled: true,
                  fillColor: tokens.ricePaper,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: tokens.agedFiber),
                  ),
                  prefixIcon: Icon(Icons.palette_outlined, color: tokens.danmo),
                  isDense: true,
                ),
                onChanged: _onHexChanged,
                validator: (val) {
                  final regex = RegExp(r'^#?[0-9A-Fa-f]{6}$');
                  if (val == null || !regex.hasMatch(val.trim())) {
                    return '请输入有效 6 位十六进制色值 (例如 #FDFBF7)';
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
                    '行间疏密 · Line Spacing',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: tokens.jiaomo,
                    ),
                  ),
                  Text(
                    '${_lineSpacing.toStringAsFixed(1)}x',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: tokens.cinnabar,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: tokens.cinnabar,
                  inactiveTrackColor: tokens.agedFiber,
                  thumbColor: tokens.cinnabar,
                  trackHeight: 3.5,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
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
              ),
              const SizedBox(height: 12),

              // 6. Horizontal Margin Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '左右留白 · Horizontal Margin',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: tokens.jiaomo,
                    ),
                  ),
                  Text(
                    '${_marginHorizontal.round()} px',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: tokens.cinnabar,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: tokens.cinnabar,
                  inactiveTrackColor: tokens.agedFiber,
                  thumbColor: tokens.cinnabar,
                  trackHeight: 3.5,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
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
              ),
              const SizedBox(height: 16),

              // 7. Font Family Selector
              Text(
                '默认文字体式 · Font Family',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: tokens.jiaomo,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: const Key('font_family_dropdown'),
                isExpanded: true,
                initialValue: _selectedFontFamily,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: tokens.ricePaper,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: tokens.agedFiber),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'System',
                    child: Text('系统默认 · System Default'),
                  ),
                  ...TypographyCatalog.options.map((opt) {
                    return DropdownMenuItem(
                      value: opt.fontFamily ?? opt.id,
                      child: Text(
                        '${opt.name} (${opt.description})',
                        style: TextStyle(fontFamily: opt.fontFamily),
                      ),
                    );
                  }),
                ],
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
