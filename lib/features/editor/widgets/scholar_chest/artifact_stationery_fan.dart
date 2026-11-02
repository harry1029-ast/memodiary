import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../../templates/models/template_style.dart';
import '../../../templates/screens/custom_template_editor_screen.dart';
import '../../../templates/widgets/template_canvas_container.dart';
import 'fan_spread_stationery_painter.dart';

/// Stationery artifact representing the fanned paper tray (叠印花笺).
/// Allows diarists to preview and switch stationery templates.
class ArtifactStationeryFan extends StatelessWidget {
  final bool isSelected;
  final VoidCallback? onTap;

  const ArtifactStationeryFan({
    super.key,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '叠印花笺: 切换笺纸底色与界格',
      selected: isSelected,
      child: GestureDetector(
        key: const Key('chest_artifact_stationery_fan'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF6B1A1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFD4AF37)
                  : const Color(0xFF8B262A),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isSelected ? 0.35 : 0.2,
                ),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                bottom: 24,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, fanProgress, child) {
                    return CustomPaint(
                      painter: FanSpreadStationeryPainter(
                        fanProgress: fanProgress,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 4,
                right: 4,
                bottom: 2,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1A17),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFF8C7148),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '叠印花笺',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontKaiti,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE6C875),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// In-chest sub-panel for the Fanned Stationery artifact featuring Image 2's card carousel.
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
    _templatesFuture = widget.database.getAllTemplates();
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
            Row(
              children: [
                const Icon(Icons.auto_stories, size: 16, color: Color(0xFFFFDF85)),
                const SizedBox(width: 6),
                const Text(
                  '文房雅笺 · 素笺谱系',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D99B),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '“笺换风骨，意蕴随迁”',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontKaiti,
                    fontSize: 11,
                    color: Color(0xFFD4C5B0),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                GestureDetector(
                  key: const Key('chest_create_template_button'),
                  onTap: () async {
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
                  },
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

        // Horizontal Card Carousel (Restored from Image 2)
        SizedBox(
          height: 154,
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
