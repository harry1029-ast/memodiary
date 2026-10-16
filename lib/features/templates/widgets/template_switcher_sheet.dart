import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../models/template_style.dart';
import 'template_canvas_container.dart';

/// Modal bottom sheet allowing users to preview and select templates.
/// Swapping templates ONLY alters presentation; entry Delta content remains immutable.
class TemplateSwitcherSheet extends StatelessWidget {
  final List<Template> templates;
  final String currentTemplateId;
  final ValueChanged<Template> onTemplateSelected;

  const TemplateSwitcherSheet({
    super.key,
    required this.templates,
    required this.currentTemplateId,
    required this.onTemplateSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required List<Template> templates,
    required String currentTemplateId,
    required ValueChanged<Template> onTemplateSelected,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 16),
            const Text(
              'Switch Template',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Change visual styling without altering your written content.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final template = templates[index];
                  final isSelected = template.id == currentTemplateId;
                  final style = TemplateStyle.fromTemplate(template);

                  return GestureDetector(
                    onTap: () {
                      onTemplateSelected(template);
                      Navigator.pop(context);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 95,
                          height: 115,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(isSelected ? 25 : 10),
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
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 95,
                          child: Text(
                            template.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.black87,
                            ),
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

