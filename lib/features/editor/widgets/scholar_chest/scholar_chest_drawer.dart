import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../models/typography_settings.dart';
import '../../services/audio_sanctum_service.dart';
import 'artifact_brush_mountain.dart';
import 'artifact_fish_lock.dart';
import 'artifact_guqin_zither.dart';
import 'artifact_stationery_fan.dart';
import 'artifact_twin_brushes.dart';

enum ScholarArtifactType {
  twinBrushes,
  stationeryFan,
  brushMountain,
  guqinZither,
  fishLock,
}

/// The unified Scholar's Stationery Chest (文房百宝匣 · 锦盒书案) modal drawer.
/// Consolidates stationery templates, typography, soundscapes, and time capsules
/// into an antique brocade-rimmed velvet tray with interactive artifacts and tactile chimes.
class ScholarChestDrawer extends StatefulWidget {
  final AppDatabase database;
  final String activeTemplateId;
  final TypographySettings typography;
  final AudioSanctumService audioSanctumService;
  final DateTime? unlockAt;
  final bool isCenterAligned;
  final ScholarArtifactType initialArtifact;
  final ValueChanged<Template> onSelectTemplate;
  final ValueChanged<TypographySettings> onTypographyChanged;
  final ValueChanged<DateTime?> onLockChanged;
  final VoidCallback? onToggleAlignment;

  const ScholarChestDrawer({
    super.key,
    required this.database,
    required this.activeTemplateId,
    required this.typography,
    required this.audioSanctumService,
    this.unlockAt,
    this.isCenterAligned = false,
    this.initialArtifact = ScholarArtifactType.stationeryFan,
    required this.onSelectTemplate,
    required this.onTypographyChanged,
    required this.onLockChanged,
    this.onToggleAlignment,
  });

  /// Opens the Scholar's Stationery Chest modal bottom drawer.
  static Future<void> show({
    required BuildContext context,
    required AppDatabase database,
    required String activeTemplateId,
    required TypographySettings typography,
    required AudioSanctumService audioSanctumService,
    DateTime? unlockAt,
    bool isCenterAligned = false,
    ScholarArtifactType initialArtifact = ScholarArtifactType.stationeryFan,
    required ValueChanged<Template> onSelectTemplate,
    required ValueChanged<TypographySettings> onTypographyChanged,
    required ValueChanged<DateTime?> onLockChanged,
    VoidCallback? onToggleAlignment,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScholarChestDrawer(
        database: database,
        activeTemplateId: activeTemplateId,
        typography: typography,
        audioSanctumService: audioSanctumService,
        unlockAt: unlockAt,
        isCenterAligned: isCenterAligned,
        initialArtifact: initialArtifact,
        onSelectTemplate: onSelectTemplate,
        onTypographyChanged: onTypographyChanged,
        onLockChanged: onLockChanged,
        onToggleAlignment: onToggleAlignment,
      ),
    );
  }

  @override
  State<ScholarChestDrawer> createState() => _ScholarChestDrawerState();
}

class _ScholarChestDrawerState extends State<ScholarChestDrawer> {
  late ScholarArtifactType _activeArtifact;

  @override
  void initState() {
    super.initState();
    _activeArtifact = widget.initialArtifact;
  }

  void _selectArtifact(ScholarArtifactType type, ScholarTactileChime chime) {
    HapticFeedback.lightImpact();
    widget.audioSanctumService.playChime(chime);
    setState(() => _activeArtifact = type);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        key: const Key('scholar_chest_drawer'),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF4A3428), // Woven brocade rim
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Lacquer dismissal handle
            GestureDetector(
              key: const Key('chest_dismiss_handle'),
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Brocade header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD4AF37),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '文房百宝匣 · 锦盒书案',
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontNotoSerif,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF3EADB),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFD4AF37), size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Recessed crimson velvet tray housing the artifacts
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Velvet tray wrapper
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF8B262A),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CustomPaint(
                        painter: const CrimsonVelvetBedPainter(),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Top Groove: Twin Bamboo Brushes
                              ArtifactTwinBrushes(
                                isSelected: _activeArtifact ==
                                    ScholarArtifactType.twinBrushes,
                                onTap: () => _selectArtifact(
                                  ScholarArtifactType.twinBrushes,
                                  ScholarTactileChime.ceramicBrushTap,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // 2. Classical Asymmetrical Curio Compartment
                              SizedBox(
                                height: 216,
                                child: Row(
                                  children: [
                                    // Left Tall Velvet Well (flex 38): Fan-Spread Stationery Sheets
                                    Expanded(
                                      flex: 38,
                                      child: ArtifactStationeryFan(
                                        isSelected: _activeArtifact ==
                                            ScholarArtifactType.stationeryFan,
                                        onTap: () => _selectArtifact(
                                          ScholarArtifactType.stationeryFan,
                                          ScholarTactileChime.paperRustle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Right 62% Column: Upper Guqin Zither + Lower Brush Rest & Fish Lock
                                    Expanded(
                                      flex: 62,
                                      child: Column(
                                        children: [
                                          // Top Horizontal Groove: 7-String Guqin Zither
                                          SizedBox(
                                            height: 96,
                                            child: ArtifactGuqinZither(
                                              isSelected: _activeArtifact ==
                                                  ScholarArtifactType.guqinZither,
                                              isPlaying: widget.audioSanctumService.isPlaying,
                                              onTap: () => _selectArtifact(
                                                ScholarArtifactType.guqinZither,
                                                ScholarTactileChime.guqinPluck,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),

                                          // Bottom Row: Porcelain Brush Rest (56%) + Brass Fish Lock (44%)
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 56,
                                                  child: ArtifactBrushMountain(
                                                    isSelected: _activeArtifact ==
                                                        ScholarArtifactType.brushMountain,
                                                    onTap: () => _selectArtifact(
                                                      ScholarArtifactType.brushMountain,
                                                      ScholarTactileChime.ceramicBrushTap,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  flex: 44,
                                                  child: ArtifactFishLock(
                                                    isSelected: _activeArtifact ==
                                                        ScholarArtifactType.fishLock,
                                                    isLocked: widget.unlockAt != null &&
                                                        widget.unlockAt!.isAfter(DateTime.now()),
                                                    onTap: () => _selectArtifact(
                                                      ScholarArtifactType.fishLock,
                                                      ScholarTactileChime.brassLockClick,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // In-chest Dynamic Sub-panel
                    Container(
                      key: const Key('chest_sub_panel_container'),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tokens.xuanGround,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: tokens.agedFiber),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildActiveSubPanel(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSubPanel() {
    switch (_activeArtifact) {
      case ScholarArtifactType.twinBrushes:
        return Container(
          key: const Key('chest_subpanel_twin_brushes'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.brush_outlined, size: 28, color: const Color(0xFFC04851)),
              const SizedBox(height: 6),
              Text(
                '笔锋运墨动效 · 敬请期待',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C1E0A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '双管并提，疾涩相参，运笔入微之境将随墨潮而至。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontKaiti,
                  fontSize: 12,
                  color: const Color(0xFF7A6B5D),
                ),
              ),
            ],
          ),
        );

      case ScholarArtifactType.stationeryFan:
        return StationeryFanSubPanel(
          database: widget.database,
          activeTemplateId: widget.activeTemplateId,
          onSelectTemplate: widget.onSelectTemplate,
        );

      case ScholarArtifactType.brushMountain:
        return BrushMountainSubPanel(
          typography: widget.typography,
          onTypographyChanged: widget.onTypographyChanged,
          isCenterAligned: widget.isCenterAligned,
          onToggleAlignment: widget.onToggleAlignment,
        );

      case ScholarArtifactType.guqinZither:
        return GuqinZitherSubPanel(
          audioSanctumService: widget.audioSanctumService,
        );

      case ScholarArtifactType.fishLock:
        return FishLockSubPanel(
          unlockAt: widget.unlockAt,
          onLockChanged: widget.onLockChanged,
        );
    }
  }
}

/// Renders the diagonal-ribbed crimson silk velvet bed inside the Scholar's Chest.
class CrimsonVelvetBedPainter extends CustomPainter {
  const CrimsonVelvetBedPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, -0.3),
        radius: 1.1,
        colors: [
          Color(0xFFA81C22),
          Color(0xFF7C1016),
          Color(0xFF4F070B),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final ribPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..strokeWidth = 4.5;
    for (double xOffset = -size.height;
        xOffset < size.width + size.height;
        xOffset += 14) {
      canvas.drawLine(
        Offset(xOffset, 0),
        Offset(xOffset + size.height * 0.7, size.height),
        ribPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


