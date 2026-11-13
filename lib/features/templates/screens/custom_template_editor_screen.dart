import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../models/template_style.dart';
import '../widgets/custom_template_color_typography_section.dart';
import '../widgets/custom_template_preview_card.dart';
import '../widgets/custom_template_style_selectors.dart';

export '../widgets/custom_template_color_typography_section.dart'
    show ColorSwatchOption;

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
  late PaperSubstrate _selectedSubstrate;
  late RuleInkTint _selectedRuleTint;
  late SealCarvingStyle _selectedSealStyle;
  late String _backgroundHex;
  late double _lineSpacing;
  late double _marginHorizontal;
  late String _selectedFontFamily;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTemplate;
    final initialTokens = existing != null
        ? StationeryVisualTokens.fromBackgroundValue(existing.backgroundValue)
        : const StationeryVisualTokens();
    _selectedSubstrate = initialTokens.substrate;
    _selectedRuleTint = initialTokens.ruleTint;
    _selectedSealStyle = initialTokens.sealStyle;

    _nameController = TextEditingController(text: existing?.name ?? '');
    _backgroundType = existing != null
        ? TemplateBackgroundType.fromString(existing.backgroundType)
        : TemplateBackgroundType.lined;
    _backgroundHex = initialTokens.customBgColor != null
        ? TemplateStyle.toHexString(initialTokens.customBgColor!)
        : (existing != null && existing.backgroundValue.startsWith('#')
            ? existing.backgroundValue
            : TemplateStyle.toHexString(_selectedSubstrate.defaultColor));
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
    final tokens = StationeryVisualTokens(
      substrate: _selectedSubstrate,
      ruleTint: _selectedRuleTint,
      sealStyle: _selectedSealStyle,
      customBgColor: TemplateStyle.parseHexColor(_backgroundHex),
    );
    return TemplateStyle(
      type: _backgroundType,
      backgroundColor: TemplateStyle.parseHexColor(_backgroundHex),
      lineSpacing: _lineSpacing,
      marginHorizontal: _marginHorizontal,
      fontFamily: _selectedFontFamily == 'System' ? null : _selectedFontFamily,
      tokens: tokens,
    );
  }

  void _onHexChanged(String value) {
    final cleaned = value.trim();
    final regex = RegExp(r'^#?[0-9A-Fa-f]{6}$');
    if (regex.hasMatch(cleaned)) {
      final normalized = cleaned.startsWith('#')
          ? cleaned.toUpperCase()
          : '#${cleaned.toUpperCase()}';
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
      final tokens = StationeryVisualTokens(
        substrate: _selectedSubstrate,
        ruleTint: _selectedRuleTint,
        sealStyle: _selectedSealStyle,
        customBgColor: TemplateStyle.parseHexColor(_backgroundHex),
      );
      final bgValue = (_selectedSubstrate == PaperSubstrate.xuan &&
              _selectedRuleTint == RuleInkTint.slate &&
              _selectedSealStyle == SealCarvingStyle.zhuwen)
          ? _backgroundHex
          : tokens.toBackgroundValue();

      final templatesDao = widget.database.templatesDao;
      Template savedTemplate;

      if (widget.existingTemplate != null) {
        await templatesDao.updateCustomTemplate(
          widget.existingTemplate!.id,
          name: trimmedName,
          backgroundType: _backgroundType.toDbValue,
          backgroundValue: bgValue,
          fontFamily: _selectedFontFamily,
          lineSpacing: _lineSpacing,
          marginHorizontal: _marginHorizontal,
        );
        final updated =
            await templatesDao.getTemplateById(widget.existingTemplate!.id);
        savedTemplate = updated!;
      } else {
        savedTemplate = await templatesDao.createCustomTemplate(
          name: trimmedName,
          backgroundType: _backgroundType.toDbValue,
          backgroundValue: bgValue,
          fontFamily: _selectedFontFamily,
          lineSpacing: _lineSpacing,
          marginHorizontal: _marginHorizontal,
        );
      }

      if (mounted) {
        Navigator.pop(context, savedTemplate);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $error')),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
              CustomTemplatePreviewCard(
                previewStyle: previewStyle,
                lineSpacing: _lineSpacing,
                marginHorizontal: _marginHorizontal,
                templateTitle: _nameController.text,
                sealStyle: _selectedSealStyle,
              ),
              const SizedBox(height: 22),
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
                  prefixIcon: Icon(
                    Icons.drive_file_rename_outline,
                    color: tokens.danmo,
                  ),
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
              CustomTemplateStyleSelectors(
                backgroundType: _backgroundType,
                selectedSubstrate: _selectedSubstrate,
                selectedRuleTint: _selectedRuleTint,
                selectedSealStyle: _selectedSealStyle,
                onBackgroundTypeChanged: (type) =>
                    setState(() => _backgroundType = type),
                onSubstrateChanged: (sub) {
                  setState(() {
                    _selectedSubstrate = sub;
                    _backgroundHex = TemplateStyle.toHexString(sub.defaultColor);
                    _hexController.text = _backgroundHex;
                  });
                },
                onRuleTintChanged: (tint) =>
                    setState(() => _selectedRuleTint = tint),
                onSealStyleChanged: (style) =>
                    setState(() => _selectedSealStyle = style),
              ),
              const SizedBox(height: 20),
              CustomTemplateColorTypographySection(
                presetSwatches: CustomTemplateEditorScreen.presetSwatches,
                backgroundHex: _backgroundHex,
                hexController: _hexController,
                lineSpacing: _lineSpacing,
                marginHorizontal: _marginHorizontal,
                selectedFontFamily: _selectedFontFamily,
                onSelectSwatchHex: (hex) {
                  setState(() {
                    _backgroundHex = hex;
                    _hexController.text = hex;
                  });
                },
                onHexChanged: _onHexChanged,
                onLineSpacingChanged: (val) {
                  setState(() {
                    _lineSpacing = double.parse(val.toStringAsFixed(1));
                  });
                },
                onMarginHorizontalChanged: (val) {
                  setState(() {
                    _marginHorizontal = val.roundToDouble();
                  });
                },
                onFontFamilyChanged: (val) {
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
