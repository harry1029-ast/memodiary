import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/database/app_database.dart';
import '../../../templates/models/template_style.dart';
import '../../models/stationery_sheet_configs.dart';
import '../../models/typography_settings.dart';
import '../../services/audio_sanctum_service.dart';
import '../../ink_choreography/ink_choreography_controller.dart';
import 'artifact_brush_mountain.dart';
import 'artifact_fish_lock.dart';
import 'artifact_guqin_zither.dart';
import 'artifact_stationery_fan.dart';
import 'scholar_chest_velvet_tray.dart';
import 'twin_brushes_sub_panel.dart';

export 'scholar_chest_velvet_tray.dart' show ScholarArtifactType;

/// The unified Scholar's Stationery Chest (文房百宝匣 · 锦盒书案) modal drawer.
/// Consolidates stationery templates, typography, soundscapes, and time capsules
/// into an antique walnut-gold framed tray with interactive curio artifacts.
class ScholarChestDrawer extends StatefulWidget {
  final AppDatabase database;
  final String activeTemplateId;
  final TypographySettings typography;
  final AudioSanctumService audioSanctumService;

  /// The editor's live Ink Choreography preferences; the drawer rebuilds
  /// from it directly (Modal Route State Encapsulation).
  final InkChoreographyController inkChoreography;

  /// The active template's ink and paper, for the Trial Rice-Grid.
  final Color inkColor;
  final Color paperColor;
  final DateTime? unlockAt;
  final bool isCenterAligned;

  /// Whether the active Stationery Sheet is an ephemera sheet, which has no
  /// characters for 全页挥毫 to replay.
  final bool isEphemeraSheetActive;
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
    required this.inkChoreography,
    this.inkColor = defaultInkColor,
    this.paperColor = defaultPaperColor,
    this.unlockAt,
    this.isCenterAligned = false,
    this.isEphemeraSheetActive = false,
    this.initialArtifact = ScholarArtifactType.stationeryFan,
    required this.onSelectTemplate,
    required this.onTypographyChanged,
    required this.onLockChanged,
    this.onToggleAlignment,
  });

  static const Color defaultInkColor = Color(0xFF212121);
  static const Color defaultPaperColor = Color(0xFFFBF8F1);

  /// Opens the Scholar's Stationery Chest modal bottom drawer.
  static Future<void> show({
    required BuildContext context,
    required AppDatabase database,
    required String activeTemplateId,
    required TypographySettings typography,
    required AudioSanctumService audioSanctumService,
    required InkChoreographyController inkChoreography,
    Color inkColor = defaultInkColor,
    Color paperColor = defaultPaperColor,
    DateTime? unlockAt,
    bool isCenterAligned = false,
    bool isEphemeraSheetActive = false,
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
        inkChoreography: inkChoreography,
        inkColor: inkColor,
        paperColor: paperColor,
        unlockAt: unlockAt,
        isCenterAligned: isCenterAligned,
        isEphemeraSheetActive: isEphemeraSheetActive,
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
  late String _activeTemplateId;
  late TypographySettings _currentTypography;
  late Color _inkColor;
  late Color _paperColor;
  DateTime? _unlockAt;
  late bool _isCenterAligned;

  @override
  void initState() {
    super.initState();
    _activeArtifact = widget.initialArtifact;
    _activeTemplateId = widget.activeTemplateId;
    _currentTypography = widget.typography;
    _inkColor = widget.inkColor;
    _paperColor = widget.paperColor;
    _unlockAt = widget.unlockAt;
    _isCenterAligned = widget.isCenterAligned;
  }

  @override
  void didUpdateWidget(covariant ScholarChestDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeTemplateId != widget.activeTemplateId) {
      _activeTemplateId = widget.activeTemplateId;
    }
    if (oldWidget.typography != widget.typography) {
      _currentTypography = widget.typography;
    }
    if (oldWidget.unlockAt != widget.unlockAt) {
      _unlockAt = widget.unlockAt;
    }
    if (oldWidget.isCenterAligned != widget.isCenterAligned) {
      _isCenterAligned = widget.isCenterAligned;
    }
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
                    Flexible(
                      flex: 3,
                      child: Text(
                        '文房百宝匣 · 锦盒书案',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF2E5CE),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    CircleAvatar(radius: 3.5, backgroundColor: Color(0xFFD93829)),
                    SizedBox(width: 6),
                    Flexible(
                      flex: 2,
                      child: Text(
                        '下拉收拢 / 点器物设雅',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Color(0xFFD4C5B0)),
                      ),
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
              child: ListenableBuilder(
                listenable: widget.inkChoreography,
                builder: (context, _) => ScholarChestVelvetTray(
                  activeArtifact: _activeArtifact,
                  inkDeliveryMode: widget.inkChoreography.config.deliveryMode,
                  isSoundscapePlaying: widget.audioSanctumService.isPlaying,
                  isLocked: _unlockAt != null && _unlockAt!.isAfter(DateTime.now()),
                  onSelectArtifact: _selectArtifact,
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
        return TwinBrushesSubPanel(
          controller: widget.inkChoreography,
          audioSanctumService: widget.audioSanctumService,
          inkColor: _inkColor,
          paperColor: _paperColor,
          fontFamily: _currentTypography.fontFamily,
          isSheetReplayAvailable: !widget.isEphemeraSheetActive,
          onSheetReplayRequested: () => Navigator.pop(context),
          onClose: () => setState(() => _activeArtifact = null),
        );

      case ScholarArtifactType.stationeryFan:
        return StationeryFanSubPanel(
          database: widget.database,
          activeTemplateId: _activeTemplateId,
          onSelectTemplate: (selectedTemplate) {
            final sheetTheme = StationerySheetThemeConfig.fromTemplateStyle(
              templateStyle: TemplateStyle.fromTemplate(selectedTemplate),
              typography: TypographySettings.fromTemplate(selectedTemplate),
            );
            setState(() {
              _activeTemplateId = selectedTemplate.id;
              _currentTypography = sheetTheme.typography;
              _inkColor = sheetTheme.inkColor;
              _paperColor = sheetTheme.templateStyle.backgroundColor;
            });
            widget.onSelectTemplate(selectedTemplate);
          },
          onClose: () => setState(() => _activeArtifact = null),
        );

      case ScholarArtifactType.brushMountain:
        return BrushMountainSubPanel(
          typography: _currentTypography,
          onTypographyChanged: (updatedTypography) {
            setState(() {
              _currentTypography = updatedTypography;
            });
            widget.onTypographyChanged(updatedTypography);
          },
          isCenterAligned: _isCenterAligned,
          onToggleAlignment: () {
            setState(() {
              _isCenterAligned = !_isCenterAligned;
            });
            widget.onToggleAlignment?.call();
          },
          onClose: () => setState(() => _activeArtifact = null),
        );

      case ScholarArtifactType.guqinZither:
        return GuqinZitherSubPanel(
          audioSanctumService: widget.audioSanctumService,
          onClose: () => setState(() => _activeArtifact = null),
        );

      case ScholarArtifactType.fishLock:
        return FishLockSubPanel(
          unlockAt: _unlockAt,
          onLockChanged: (updatedUnlockAt) {
            setState(() {
              _unlockAt = updatedUnlockAt;
            });
            widget.onLockChanged(updatedUnlockAt);
          },
          onClose: () => setState(() => _activeArtifact = null),
        );
    }
  }
}
