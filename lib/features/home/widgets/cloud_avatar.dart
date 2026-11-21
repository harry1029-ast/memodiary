import 'package:flutter/material.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/widgets/cloud_moon_emblem_painter.dart';
import 'package:memodiary/core/theme/widgets/min_tap_target.dart';
import 'package:memodiary/features/home/widgets/diarist_panel_controller.dart';

/// The diarist's drawn round cloud avatar: the Cloud-Moon emblem on a woodwork
/// disc ringed in the active palette's accent. A placeholder until a profile
/// spec gives the diarist their own picture.
class CloudAvatar extends StatelessWidget {
  final double diameter;

  const CloudAvatar({super.key, required this.diameter});

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;
    final inset = diameter * 0.16;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.woodFrameMid, palette.woodFrameDark],
        ),
        border: Border.all(
          color: palette.accentPrimary,
          width: diameter >= 48 ? 2.0 : 1.2,
        ),
      ),
      padding: EdgeInsets.all(inset),
      child: CustomPaint(
        painter: CloudMoonEmblemPainter(
          primaryColor: palette.headerTitleText,
          accentColor: palette.accentPrimary,
          moonFillColor: palette.accentPrimary.withValues(alpha: 0.25),
          strokeWeight: 24 / (diameter - 2 * inset),
        ),
      ),
    );
  }
}

/// The header's top-left `我的` button on both Home Shell tabs: opens the
/// Diarist Panel through the enclosing [DiaristPanelScope].
class DiaristAvatarButton extends StatelessWidget {
  static const double avatarDiameter = 32.0;

  const DiaristAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    // A container, so the header title beside it is not merged into the button.
    return Semantics(
      container: true,
      child: MinTapTarget(
        semanticLabel: '我的',
        enabled: true,
        borderRadius: BorderRadius.circular(22),
        onTap: () => DiaristPanelScope.of(context).open(),
        child: const CloudAvatar(diameter: avatarDiameter),
      ),
    );
  }
}
