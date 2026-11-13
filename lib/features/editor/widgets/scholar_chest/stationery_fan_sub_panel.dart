import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../../templates/models/template_constants.dart';
import '../../../templates/models/template_style.dart';
import '../../../templates/screens/custom_template_editor_screen.dart';
import '../../../templates/widgets/template_canvas_container.dart';
import '../../../templates/widgets/template_delete_dialog.dart';

/// In-chest sub-panel for the Fanned Stationery artifact featuring the template card carousel.
class StationeryFanSubPanel extends StatefulWidget {
  final AppDatabase database;
  final String activeTemplateId;
  final ValueChanged<Template> onSelectTemplate;
  final VoidCallback? onCustomTemplateCreated;
  final VoidCallback? onClose;

  const StationeryFanSubPanel({
    super.key,
    required this.database,
    required this.activeTemplateId,
    required this.onSelectTemplate,
    this.onCustomTemplateCreated,
    this.onClose,
  });

  @override
  State<StationeryFanSubPanel> createState() => _StationeryFanSubPanelState();
}

class _StationeryFanSubPanelState extends State<StationeryFanSubPanel> {
  late Future<List<Template>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  void _loadTemplates() {
    _templatesFuture = widget.database.templatesDao.getAllTemplates();
  }

  Future<void> _handleCreateCustom() async {
    final createdTemplate = await Navigator.push<Template>(
      context,
      MaterialPageRoute(
        builder: (navContext) =>
            CustomTemplateEditorScreen(database: widget.database),
      ),
    );
    if (createdTemplate != null) {
      setState(_loadTemplates);
      widget.onSelectTemplate(createdTemplate);
      widget.onCustomTemplateCreated?.call();
    }
  }

  Future<void> _handleEditCustom(Template templateItem) async {
    final updatedTemplate = await Navigator.push<Template>(
      context,
      MaterialPageRoute(
        builder: (navContext) => CustomTemplateEditorScreen(
          database: widget.database,
          existingTemplate: templateItem,
        ),
      ),
    );
    if (updatedTemplate != null && mounted) {
      setState(_loadTemplates);
      if (widget.activeTemplateId == templateItem.id) {
        widget.onSelectTemplate(updatedTemplate);
      }
    }
  }

  Future<void> _handleDeleteCustom(Template templateItem) async {
    if (!isTemplateDeletable(templateItem)) return;

    final confirmed = await showTemplateDeleteDialog(context, templateItem);
    if (confirmed == true && mounted) {
      await widget.database.templatesDao.deleteCustomTemplate(templateItem.id);
      setState(_loadTemplates);
      if (widget.activeTemplateId == templateItem.id) {
        final remainingTemplates =
            await widget.database.templatesDao.getAllTemplates();
        final fallbackTemplate = remainingTemplates.firstWhere(
          (fallbackCandidate) => fallbackCandidate.id == 'template_minimalist_white',
          orElse: () => remainingTemplates.first,
        );
        widget.onSelectTemplate(fallbackTemplate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sub-panel Header with Title, Poetic Subtitle & Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Row(
                children: [
                  Icon(Icons.auto_stories, size: 16, color: Color(0xFFFFDF85)),
                  SizedBox(width: 6),
                  Text(
                    '文房雅笺 · 素笺谱系',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF3D99B),
                    ),
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '“笺换风骨，意蕴随迁”',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontKaiti,
                        fontSize: 11,
                        color: Color(0xFFD4C5B0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  key: const Key('chest_create_template_button'),
                  onTap: _handleCreateCustom,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF381F1D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFD25447).withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 12, color: Color(0xFFFFDF85)),
                        SizedBox(width: 3),
                        Text(
                          '定制雅笺',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF5E6C8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.onClose != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    key: const Key('chest_subpanel_close_button'),
                    onTap: widget.onClose,
                    child: Semantics(
                      button: true,
                      label: '收拢面板',
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        color: Colors.transparent,
                        child: const Icon(Icons.close, size: 16, color: Color(0xFFD4C5B0)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Horizontal Card Carousel with delete & edit buttons for custom templates
        SizedBox(
          height: 164,
          child: FutureBuilder<List<Template>>(
            future: _templatesFuture,
            builder: (context, snapshot) {
              final templates = snapshot.data ?? [];
              if (templates.isEmpty) {
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)),
                  ),
                );
              }
              final displayTemplates = templates
                  .where((templateItem) => !templateItem.id.startsWith('suite_'))
                  .toList();

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: displayTemplates.length,
                separatorBuilder: (sepContext, sepIndex) => const SizedBox(width: 10),
                itemBuilder: (itemContext, itemIndex) {
                  final templateItem = displayTemplates[itemIndex];
                  final isSelected = templateItem.id == widget.activeTemplateId;
                  final templateStyle = TemplateStyle.fromTemplate(templateItem);
                  final isDeletable = isTemplateDeletable(templateItem);

                  return GestureDetector(
                    key: Key('chest_template_chip_${templateItem.id}'),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onSelectTemplate(templateItem);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 86,
                          height: 116,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFFDF85)
                                  : const Color(0xFFD4AF37).withValues(alpha: 0.35),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFFDF85).withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: TemplateCanvasContainer(
                              style: templateStyle,
                              isThumbnail: true,
                              customPadding: const EdgeInsets.all(6),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      'Aa',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? const Color(0xFFB83B2E)
                                            : const Color(0xFF2C1E0A),
                                        fontFamily: templateStyle.fontFamily,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: Container(
                                        width: 15,
                                        height: 15,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFB83B2E),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        templateItem.backgroundType,
                                        style: const TextStyle(
                                          fontSize: 8,
                                          color: Color(0xFF68645E),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: 86,
                          child: Text(
                            templateItem.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontNotoSerif,
                              fontSize: 11,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFFFFDF85)
                                  : const Color(0xFFF5E6C8),
                            ),
                          ),
                        ),
                        if (isDeletable)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  key: Key('edit_template_${templateItem.id}'),
                                  onTap: () => _handleEditCustom(templateItem),
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2.5),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 13,
                                      color: Color(0xFFD4C5B0),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  key: Key('delete_template_${templateItem.id}'),
                                  onTap: () => _handleDeleteCustom(templateItem),
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2.5),
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 13,
                                      color: Color(0xFFE57373),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox(height: 18),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
