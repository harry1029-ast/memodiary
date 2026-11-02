import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/database/app_database.dart';
import '../../models/typography_settings.dart';
import '../../services/audio_sanctum_service.dart';
import 'artifact_brush_mountain.dart';
import 'artifact_fish_lock.dart';
import 'artifact_guqin_zither.dart';
import 'artifact_stationery_fan.dart';
import 'artifact_twin_brushes.dart';
import 'crimson_velvet_bed_painter.dart';

enum ScholarArtifactType {
  twinBrushes,
  stationeryFan,
  brushMountain,
  guqinZither,
  fishLock,
}

/// The unified Scholar's Stationery Chest (文房百宝匣 · 锦盒书案) modal drawer.
/// Consolidates stationery templates, typography, soundscapes, and time capsules
/// into an antique walnut-gold framed tray with interactive curio artifacts.
class ScholarChestDrawer extends StatefulWidget {
  final AppDatabase database;
  final String activeTemplateId;
  final TypographySettings typography;
  final AudioSanctumService audioSanctumService;
  final DateTime? unlockAt;
  final bool isCenterAligned;
  final ScholarArtifactType? initialArtifact;
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
    ScholarArtifactType? initialArtifact = ScholarArtifactType.stationeryFan,
    required ValueChanged<Template> onSelectTemplate,
    required ValueChanged<TypographySettings> onTypographyChanged,
    required ValueChanged<DateTime?> onLockChanged,
    VoidCallback? onToggleAlignment,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => ScholarChestDrawer(
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
  ScholarArtifactType? _activeArtifact;

  @override
  void initState() {
    super.initState();
    _activeArtifact = widget.initialArtifact;
  }

  void _selectArtifact(ScholarArtifactType type, ScholarTactileChime chime) {
    HapticFeedback.lightImpact();
    widget.audioSanctumService.playChime(chime);
    setState(() {
      if (_activeArtifact == type) {
        _activeArtifact = null; // Toggle collapse
      } else {
        _activeArtifact = type;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        key: const Key('scholar_chest_drawer'),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF34281E), // Rich antique mahogany/walnut ground
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: Color(0xFF6B5335), width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 18,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Protruding Top Clasp Handle (▼ 文房百宝匣 · 锦盒书案)
            GestureDetector(
              key: const Key('chest_dismiss_handle'),
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3E3027), Color(0xFF281E18)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF8C7148),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('▼', style: TextStyle(fontSize: 11, color: Color(0xFFE5C384))),
                    SizedBox(width: 8),
                    Text(
                      '文房百宝匣 · 锦盒书案',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF2E5CE),
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(width: 8),
                    CircleAvatar(radius: 3.5, backgroundColor: Color(0xFFD93829)),
                    SizedBox(width: 6),
                    Text(
                      '下拉收拢 / 点器物设雅',
                      style: TextStyle(fontSize: 11, color: Color(0xFFD4C5B0)),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Contextual Sub-Panel Floating Above the Chest (Top)
            if (_activeArtifact != null)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                  child: Container(
                    key: const Key('chest_sub_panel_container'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E130F).withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black87,
                          blurRadius: 16,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: _buildActiveSubPanel(),
                  ),
                ),
              ),

            // 3. Recessed Crimson Velvet Tray Housing Artifacts (Bottom, docked)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.28),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomPaint(
                  painter: const CrimsonVelvetBedPainter(),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Groove: Twin Bamboo Brushes
                        ArtifactTwinBrushes(
                          isSelected: _activeArtifact ==
                              ScholarArtifactType.twinBrushes,
                          onTap: () => _selectArtifact(
                            ScholarArtifactType.twinBrushes,
                            ScholarTactileChime.ceramicBrushTap,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Classical Asymmetrical Curio Compartment
                        SizedBox(
                          height: 206,
                          child: Row(
                            children: [
                              // Left Column (flex 38): Fan-Spread Stationery Sheets
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
                              const SizedBox(width: 8),

                              // Right Column (flex 62): Guqin + Brush Rest & Fish Lock
                              Expanded(
                                flex: 62,
                                child: Column(
                                  children: [
                                    // Upper Groove: 7-String Guqin Zither
                                    SizedBox(
                                      height: 92,
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
                                    const SizedBox(height: 8),

                                    // Lower Row: Brush Rest (56%) + Fish Lock (44%)
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSubPanel() {
    switch (_activeArtifact) {
      case null:
        return const SizedBox.shrink();

      case ScholarArtifactType.twinBrushes:
        return Container(
          key: const Key('chest_subpanel_twin_brushes'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  const Icon(Icons.brush_outlined, size: 24, color: Color(0xFFFFDF85)),
                  GestureDetector(
                    onTap: () => setState(() => _activeArtifact = null),
                    child: const Icon(Icons.close, size: 16, color: Color(0xFFD4C5B0)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '笔锋运墨动效 · 敬请期待',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF3D99B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '双管并提，疾涩相参，运笔入微之境将随墨潮而至。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFFD4C5B0),
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
          onClose: () => setState(() => _activeArtifact = null),
        );

      case ScholarArtifactType.brushMountain:
        return BrushMountainSubPanel(
          typography: widget.typography,
          onTypographyChanged: widget.onTypographyChanged,
          isCenterAligned: widget.isCenterAligned,
          onToggleAlignment: widget.onToggleAlignment,
          onClose: () => setState(() => _activeArtifact = null),
        );

      case ScholarArtifactType.guqinZither:
        return GuqinZitherSubPanel(
          audioSanctumService: widget.audioSanctumService,
          onClose: () => setState(() => _activeArtifact = null),
        );

      case ScholarArtifactType.fishLock:
        return FishLockSubPanel(
          unlockAt: widget.unlockAt,
          onLockChanged: widget.onLockChanged,
          onClose: () => setState(() => _activeArtifact = null),
        );
    }
  }
}
