import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/app_database.dart';
import '../models/template_style.dart';
import '../screens/custom_template_editor_screen.dart';
import 'template_canvas_container.dart';

/// Modal bottom sheet allowing users to preview, select, create, edit, and delete templates.
/// Swapping or deleting templates ONLY alters presentation; entry Delta content remains immutable.
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
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => TemplateSwitcherSheet(
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
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Custom Template?'),
        content: Text(
          'Delete "${template.name}"? Any entries using this template will safely fall back to Minimalist White without losing content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            key: const Key('confirm_delete_custom_template_button'),
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
            child: const Text('Delete'),
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
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Switch Template',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.database != null)
                  TextButton.icon(
                    key: const Key('new_custom_template_button'),
                    onPressed: _handleCreateCustom,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('New Custom'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Change visual styling without altering your written content.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 182,
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
                        Stack(
                          children: [
                            Container(
                              width: 95,
                              height: 115,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.primaryColor
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2.5 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withAlpha(isSelected ? 25 : 10),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: TemplateCanvasContainer(
                                  style: style,
                                  customPadding: const EdgeInsets.all(8),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      'Aa',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                        fontFamily: style.fontFamily,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (template.isCustom)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Custom',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 95,
                          child: Text(
                            template.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? theme.primaryColor
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (template.isCustom && widget.database != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                key: Key('edit_template_${template.id}'),
                                onTap: () => _handleEditCustom(template),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 15,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                key: Key('delete_template_${template.id}'),
                                onTap: () => _handleDeleteCustom(template),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 15,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ),
                            ],
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
