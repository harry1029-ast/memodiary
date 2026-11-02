import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../../templates/models/template_style.dart';
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
                  builder: (context, fanProgress, _) {
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

/// Renders 3 authentic fan-spread classical stationery sheets (松烟夜墨, 冷金洒金, 朱丝栏宣纸).
class FanSpreadStationeryPainter extends CustomPainter {
  final double fanProgress;

  FanSpreadStationeryPainter({required this.fanProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.5;
    final bottomY = size.height * 0.90;
    final sheetWidth = size.width * 0.64;
    final sheetHeight = size.height * 0.72;

    // Sheet 3 (Back): Night Ink Sheet (松烟夜墨)
    canvas.save();
    canvas.translate(centerX, bottomY);
    canvas.rotate((-10 - 12 * fanProgress) * math.pi / 180);
    canvas.translate(-centerX - 5 * fanProgress, -bottomY - 4 * fanProgress);
    final backRect = Rect.fromCenter(
      center: Offset(centerX, size.height * 0.48),
      width: sheetWidth,
      height: sheetHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(backRect, const Radius.circular(5)),
      Paint()..color = const Color(0xFF23272B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(backRect, const Radius.circular(5)),
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.restore();

    // Sheet 2 (Middle): Cold Gold-Flecked Parchment (冷金宣笺)
    canvas.save();
    canvas.translate(centerX, bottomY);
    canvas.rotate((-2 - 2 * fanProgress) * math.pi / 180);
    canvas.translate(-centerX, -bottomY - 6 * fanProgress);
    final midRect = Rect.fromCenter(
      center: Offset(centerX, size.height * 0.48),
      width: sheetWidth,
      height: sheetHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(midRect, const Radius.circular(5)),
      Paint()..color = const Color(0xFFF3E6CE),
    );
    // Gold specks
    final speckPaint = Paint()..color = const Color(0xFFC89D32);
    canvas.drawCircle(
      Offset(midRect.left + 10, midRect.top + 16),
      1.6,
      speckPaint,
    );
    canvas.drawCircle(
      Offset(midRect.right - 12, midRect.top + 28),
      1.4,
      speckPaint,
    );
    canvas.drawCircle(
      Offset(midRect.left + 20, midRect.bottom - 24),
      1.8,
      speckPaint,
    );
    canvas.restore();

    // Sheet 1 (Front): Cinnabar Vermilion-Ruled Xuan Paper (朱丝栏宣纸)
    canvas.save();
    canvas.translate(centerX, bottomY);
    canvas.rotate((8 + 12 * fanProgress) * math.pi / 180);
    canvas.translate(-centerX + 5 * fanProgress, -bottomY - 5 * fanProgress);
    final frontRect = Rect.fromCenter(
      center: Offset(centerX, size.height * 0.50),
      width: sheetWidth,
      height: sheetHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frontRect, const Radius.circular(5)),
      Paint()..color = const Color(0xFFFAF7F2),
    );
    // Cinnabar outer border & vertical columns
    final vermilionPaint = Paint()
      ..color = const Color(0xFFB83B2E).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final innerRect = frontRect.deflate(5);
    canvas.drawRect(innerRect, vermilionPaint);
    for (int colIndex = 1; colIndex <= 3; colIndex++) {
      final lineX = innerRect.left + (innerRect.width / 4) * colIndex;
      canvas.drawLine(
        Offset(lineX, innerRect.top),
        Offset(lineX, innerRect.bottom),
        vermilionPaint,
      );
    }
    // Red seal stamp on front sheet
    canvas.drawRect(
      Rect.fromLTWH(innerRect.right - 10, innerRect.bottom - 12, 7, 7),
      Paint()..color = const Color(0xFFB83B2E),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FanSpreadStationeryPainter oldDelegate) =>
      oldDelegate.fanProgress != fanProgress;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Curated suites header
        Row(
          children: [
            Icon(Icons.auto_stories, size: 16, color: const Color(0xFFC04851)),
            const SizedBox(width: 6),
            Text(
              '典藏雅笺 · 四时风致',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C1E0A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSuiteChip(
              context: context,
              key: const Key('chest_suite_chip_wenfang'),
              suite: StationerySuites.wenfang,
            ),
            _buildSuiteChip(
              context: context,
              key: const Key('chest_suite_chip_lengjin'),
              suite: StationerySuites.lengjin,
            ),
            _buildSuiteChip(
              context: context,
              key: const Key('chest_suite_chip_zhuqing'),
              suite: StationerySuites.zhuqing,
            ),
            _buildSuiteChip(
              context: context,
              key: const Key('chest_suite_chip_moye'),
              suite: StationerySuites.songyan,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '文房雅笺 · 笺纸谱系',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C1E0A),
              ),
            ),
            TextButton.icon(
              key: const Key('chest_create_template_button'),
              icon: const Icon(Icons.palette_outlined, size: 14),
              label: const Text('创制新笺', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC04851),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (navContext) =>
                        CustomTemplateEditorScreen(database: database),
                  ),
                );
                if (created == true) {
                  onCustomTemplateCreated?.call();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        FutureBuilder<List<Template>>(
          future: database.getAllTemplates(),
          builder: (context, snapshot) {
            final templates = snapshot.data ?? [];
            if (templates.isEmpty) {
              return const SizedBox.shrink();
            }
            final libraryTemplates = templates
                .where((templateItem) => !templateItem.id.startsWith('suite_'))
                .toList();
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: libraryTemplates.map((templateItem) {
                final isSelected = templateItem.id == activeTemplateId;
                return ChoiceChip(
                  key: Key('chest_template_chip_${templateItem.id}'),
                  label: Text(
                    templateItem.name,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF2C1E0A),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFFC04851),
                  backgroundColor: const Color(0xFFF7F3E8),
                  onSelected: (selected) {
                    if (selected) {
                      onSelectTemplate(templateItem);
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

  Widget _buildSuiteChip({
    required BuildContext context,
    required Key key,
    required StationerySuite suite,
  }) {
    final suiteTemplate = suite.toTemplate();
    final isSelected = activeTemplateId == suiteTemplate.id;
    return ChoiceChip(
      key: key,
      label: Text(
        suite.name,
        style: TextStyle(
          fontFamily: InkDiaryTheme.fontNotoSerif,
          fontSize: 11.5,
          color: isSelected ? Colors.white : const Color(0xFF2C1E0A),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFFC04851),
      backgroundColor: const Color(0xFFF7F3E8),
      onSelected: (_) => onSelectTemplate(suiteTemplate),
    );
  }
}
