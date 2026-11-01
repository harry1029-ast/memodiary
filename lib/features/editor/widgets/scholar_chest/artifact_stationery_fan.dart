import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../../templates/screens/custom_template_editor_screen.dart';

/// Stationery artifact representing the fanned paper tray (叠印花笺).
/// Allows diarists to switch curated stationery suites and custom templates.
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
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6B1A1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF8B262A),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? 0.35 : 0.2),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Fanned sheets graphic
              SizedBox(
                height: 42,
                width: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Sheet 3 (left rotated)
                    Transform.rotate(
                      angle: isSelected ? -0.22 : -0.14,
                      child: _buildSheet(const Color(0xFFE8DFCC)),
                    ),
                    // Sheet 2 (right rotated)
                    Transform.rotate(
                      angle: isSelected ? 0.22 : 0.14,
                      child: _buildSheet(const Color(0xFFF7F3E8)),
                    ),
                    // Sheet 1 (center)
                    _buildSheet(const Color(0xFFFBF8F1), isFront: true),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Plaque
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1A17),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheet(Color color, {bool isFront = false}) {
    return Container(
      width: 44,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0x334E342E), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: isFront
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(margin: const EdgeInsets.symmetric(horizontal: 4), height: 1, color: const Color(0x33C04851)),
                Container(margin: const EdgeInsets.symmetric(horizontal: 4), height: 1, color: const Color(0x33C04851)),
                Container(margin: const EdgeInsets.symmetric(horizontal: 4), height: 1, color: const Color(0x33C04851)),
              ],
            )
          : null,
    );
  }
}

/// In-chest sub-panel for the Fanned Stationery artifact
class StationeryFanSubPanel extends StatelessWidget {
  final AppDatabase database;
  final String activeTemplateId;
  final ValueChanged<Template> onSelectTemplate;
  final VoidCallback? onCustomTemplateCreated;

  const StationeryFanSubPanel({
    super.key,
    required this.database,
    required this.activeTemplateId,
    required this.onSelectTemplate,
    this.onCustomTemplateCreated,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '文房雅笺 · 笺纸谱系',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
              ),
            ),
            TextButton.icon(
              key: const Key('chest_open_custom_template_button'),
              style: TextButton.styleFrom(
                foregroundColor: tokens.cinnabar,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              icon: const Icon(Icons.palette_outlined, size: 14),
              label: const Text('创制新笺', style: TextStyle(fontSize: 12)),
              onPressed: () async {
                final created = await Navigator.push<Template>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomTemplateEditorScreen(database: database),
                  ),
                );
                if (created != null) {
                  onSelectTemplate(created);
                  onCustomTemplateCreated?.call();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Stream/Future of templates from DB
        FutureBuilder<List<Template>>(
          future: database.getAllTemplates(),
          builder: (context, snapshot) {
            final templates = snapshot.data ?? [];
            if (templates.isEmpty) {
              return const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: templates.map((tmpl) {
                final isSelected = tmpl.id == activeTemplateId;
                return ChoiceChip(
                  key: Key('chest_template_chip_${tmpl.id}'),
                  label: Text(tmpl.name),
                  selected: isSelected,
                  selectedColor: tokens.cinnabar,
                  backgroundColor: tokens.ricePaper,
                  labelStyle: TextStyle(
                    fontFamily: InkDiaryTheme.fontKaiti,
                    fontSize: 12,
                    color: isSelected ? Colors.white : tokens.jiaomo,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      onSelectTemplate(tmpl);
                    }
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
