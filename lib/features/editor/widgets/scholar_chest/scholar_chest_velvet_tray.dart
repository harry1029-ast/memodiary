import 'package:flutter/material.dart';

import '../../ink_choreography/ink_choreography_config.dart';
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

/// The recessed crimson velvet tray docked at the bottom of the Scholar's
/// Stationery Chest: the Twin Bamboo Brushes groove above an asymmetrical
/// curio compartment (stationery fan, guqin, brush mountain, fish lock).
class ScholarChestVelvetTray extends StatelessWidget {
  final ScholarArtifactType? activeArtifact;

  /// The live Ink Choreography mode shown on the Twin Bamboo Brushes badge.
  final InkDeliveryMode inkDeliveryMode;
  final bool isSoundscapePlaying;
  final bool isLocked;
  final void Function(ScholarArtifactType type, ScholarTactileChime chime) onSelectArtifact;

  const ScholarChestVelvetTray({
    super.key,
    required this.activeArtifact,
    required this.inkDeliveryMode,
    required this.isSoundscapePlaying,
    required this.isLocked,
    required this.onSelectArtifact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                activeMode: inkDeliveryMode,
                isSelected: activeArtifact == ScholarArtifactType.twinBrushes,
                onTap: () => onSelectArtifact(
                  ScholarArtifactType.twinBrushes,
                  ScholarTactileChime.ceramicBrushTap,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(height: 206, child: _buildCurioCompartment()),
            ],
          ),
        ),
      ),
    );
  }

  /// Classical asymmetrical curio compartment: fan-spread stationery on the
  /// left (flex 38), guqin over brush rest and fish lock on the right (62).
  Widget _buildCurioCompartment() {
    return Row(
      children: [
        Expanded(
          flex: 38,
          child: ArtifactStationeryFan(
            isSelected: activeArtifact == ScholarArtifactType.stationeryFan,
            onTap: () => onSelectArtifact(
              ScholarArtifactType.stationeryFan,
              ScholarTactileChime.paperRustle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 62,
          child: Column(
            children: [
              SizedBox(
                height: 92,
                child: ArtifactGuqinZither(
                  isSelected: activeArtifact == ScholarArtifactType.guqinZither,
                  isPlaying: isSoundscapePlaying,
                  onTap: () => onSelectArtifact(
                    ScholarArtifactType.guqinZither,
                    ScholarTactileChime.guqinPluck,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 56,
                      child: ArtifactBrushMountain(
                        isSelected: activeArtifact == ScholarArtifactType.brushMountain,
                        onTap: () => onSelectArtifact(
                          ScholarArtifactType.brushMountain,
                          ScholarTactileChime.ceramicBrushTap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 44,
                      child: ArtifactFishLock(
                        isSelected: activeArtifact == ScholarArtifactType.fishLock,
                        isLocked: isLocked,
                        onTap: () => onSelectArtifact(
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
    );
  }
}
