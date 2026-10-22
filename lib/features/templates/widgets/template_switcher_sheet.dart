import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../models/template_style.dart';
import '../screens/custom_template_editor_screen.dart';
import 'template_canvas_container.dart';

/// Modal bottom sheet allowing users to preview, select, create, edit, and delete templates.
/// Swapping or deleting templates strictly alters presentation; entry Delta content remains immutable.
class TemplateSwitcherSheet extends StatefulWidget {
  final List<Template> templates;
  final String currentTemplateId;
  final ValueChanged<Template> onTemplateSelected;
  final AppDatabase? database;

  const TemplateSwitcherSheet({
    super.key,
    required this.templates,
    required this.currentTemplateId,
    required this.onTemplateSelected,
    this.database,
  });

  static Future<void> show({
    required BuildContext context,
    required List<Template> templates,
    required String currentTemplateId,
    required ValueChanged<Template> onTemplateSelected,
    AppDatabase? database,
  }) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tokens.xuanGround,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) => TemplateSwitcherSheet(
        templates: templates,
        currentTemplateId: currentTemplateId,
        onTemplateSelected: onTemplateSelected,
        database: database,
      ),
    );
  }

  @override
  State<TemplateSwitcherSheet> createState() => _TemplateSwitcherSheetState();
}

class _TemplateSwitcherSheetState extends State<TemplateSwitcherSheet> {
  late List<Template> _templates;
  late String _activeTemplateId;

  @override
  void initState() {
    super.initState();
    _templates = List<Template>.from(widget.templates);
    _activeTemplateId = widget.currentTemplateId;
  }

  Future<void> _refreshTemplates() async {
    if (widget.database == null) return;
    final updated = await widget.database!.getAllTemplates();
    if (mounted) {
      setState(() {
        _templates = updated;
      });
    }
  }

  Future<void> _handleCreateCustom() async {
    if (widget.database == null) return;
    final created = await Navigator.push<Template>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomTemplateEditorScreen(database: widget.database!),
      ),
    );

    if (created != null && mounted) {
      await _refreshTemplates();
      setState(() => _activeTemplateId = created.id);
      widget.onTemplateSelected(created);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleEditCustom(Template template) async {
    if (widget.database == null) return;
    final updated = await Navigator.push<Template>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomTemplateEditorScreen(
          database: widget.database!,
          existingTemplate: template,
        ),
      ),
    );

    if (updated != null && mounted) {
      await _refreshTemplates();
      if (_activeTemplateId == updated.id) {
        widget.onTemplateSelected(updated);
      }
    }
  }

  Future<void> _handleDeleteCustom(Template template) async {
    if (widget.database == null || !template.isCustom) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Custom Template?'),
        content: Text(
          '确定删除「${template.name}」？所有使用该信笺的手稿将自动回退为澄心素宣，字句原意毫发无损。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton.tonal(
            key: const Key('confirm_delete_custom_template_button'),
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.database!.deleteCustomTemplate(template.id);
      await _refreshTemplates();
      if (_activeTemplateId == template.id && _templates.isNotEmpty) {
        final fallback = _templates.firstWhere(
          (t) => t.id == 'template_minimalist_white',
          orElse: () => _templates.first,
        );
        setState(() => _activeTemplateId = fallback.id);
        widget.onTemplateSelected(fallback);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Indicator
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.danmo.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 18,
                        decoration: BoxDecoration(
                          color: tokens.cinnabar,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Switch Template',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: tokens.jiaomo,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        ' · ',
                        style: TextStyle(color: tokens.danmo),
                      ),
                      Flexible(
                        child: Text(
                          '素笺信札',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontKaiti,
                            fontSize: 14,
                            color: tokens.nongmo,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.database != null)
                  InkWell(
                    key: const Key('new_custom_template_button'),
                    onTap: _handleCreateCustom,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: tokens.cinnabarWash,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tokens.cinnabar.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 14,
                            color: tokens.cinnabar,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '定制雅笺',
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontNotoSerif,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tokens.cinnabar,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Poetic Subtitle
            Container(
              padding: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: tokens.agedFiber,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '“笺换风骨，意蕴随迁”',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontKaiti,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: tokens.jiaomo,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '随意切换信笺式样，不更动字句分毫',
                    style: TextStyle(
                      fontSize: 11,
                      color: tokens.danmo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Carousel List
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _templates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final template = _templates[index];
                  final isSelected = template.id == _activeTemplateId;
                  final style = TemplateStyle.fromTemplate(template);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onTemplateSelected(template);
                      Navigator.pop(context);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Card Preview
                        Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 144,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? tokens.cinnabar
                                      : tokens.agedFiber,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: tokens.cinnabar.withValues(alpha: 0.18),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: tokens.jiaomo.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: TemplateCanvasContainer(
                                  style: style,
                                  customPadding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Aa',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? tokens.cinnabar : tokens.jiaomo,
                                              fontFamily: style.fontFamily,
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: tokens.cinnabar,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                size: 13,
                                                color: Colors.white,
                                              ),
                                            ),
                                        ],
                                      ),
                                      Center(
                                        child: Text(
                                          template.name.length > 2
                                              ? template.name.substring(0, 2)
                                              : template.name,
                                          style: TextStyle(
                                            fontFamily: InkDiaryTheme.fontNotoSerif,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2.0,
                                            color: tokens.jiaomo.withValues(alpha: 0.85),
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              template.backgroundType,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: tokens.danmo,
                                              ),
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              '使用中',
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w600,
                                                color: tokens.cinnabar,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (template.isCustom)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tokens.cinnabarWash,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: tokens.cinnabar.withValues(alpha: 0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    '定制',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: tokens.cinnabar,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Paper Name Label
                        SizedBox(
                          width: 110,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  template.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: InkDiaryTheme.fontNotoSerif,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? tokens.jiaomo : tokens.nongmo,
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: tokens.cinnabar,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Custom Template Actions
                        if (template.isCustom && widget.database != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  key: Key('edit_template_${template.id}'),
                                  onTap: () => _handleEditCustom(template),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 14,
                                      color: tokens.nongmo,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  key: Key('delete_template_${template.id}'),
                                  onTap: () => _handleDeleteCustom(template),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 14,
                                      color: tokens.cinnabar,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
