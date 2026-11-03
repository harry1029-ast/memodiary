import 'package:flutter/material.dart';
import '../../../scenery/models/shanshui_atmosphere.dart';

/// Paints procedural Chinese ink and watercolor landscape artwork on the
/// Thread-Bound Folio Frontispiece Cover mount.
///
/// Features authentic procedural brushwork for the 3 Scenery Realms:
/// - Nature (`林泉`): misty mountains, distant pavilion, raining bamboo & solitary boat.
/// - Indoor (`雅室`): scholar tea hall, circular moon window lattice, mud stove & bamboo curtain.
/// - Outdoor (`市井`): ancient arched stone bridge, weeping willow stream & lantern ferry.
///
/// Adapts ink palettes dynamically for light paper and dark obsidian substrates.
class FolioShanshuiArtPainter extends CustomPainter {
  final ShanshuiRealm realm;
  final bool isDark;
  final ShanshuiAtmosphereState? atmosphere;

  const FolioShanshuiArtPainter({
    required this.realm,
    this.isDark = false,
    this.atmosphere,
  });

  factory FolioShanshuiArtPainter.fromAtmosphere({
    required ShanshuiAtmosphereState atmosphere,
    bool isDark = false,
  }) {
    return FolioShanshuiArtPainter(
      realm: atmosphere.realm,
      isDark: isDark,
      atmosphere: atmosphere,
    );
  }

  factory FolioShanshuiArtPainter.fromIndex(
    int index, {
    bool isDark = false,
    ShanshuiAtmosphereState? atmosphere,
  }) {
    final resolved = switch (index % 3) {
      0 => ShanshuiRealm.nature,
      1 => ShanshuiRealm.indoor,
      _ => ShanshuiRealm.outdoor,
    };
    return FolioShanshuiArtPainter(
      realm: resolved,
      isDark: isDark,
      atmosphere: atmosphere,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (realm) {
      case ShanshuiRealm.nature:
        _paintNatureRealm(canvas, size);
      case ShanshuiRealm.indoor:
        _paintIndoorRealm(canvas, size);
      case ShanshuiRealm.outdoor:
        _paintOutdoorRealm(canvas, size);
    }
  }

  void _paintGradientBg(Canvas canvas, Size size, Color top, Color bottom) {
    final gradient = LinearGradient(
      colors: [top, bottom],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = gradient);
  }

  void _paintNatureRealm(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _paintGradientBg(canvas, size,
      isDark ? const Color(0xFF1E2125) : const Color(0xFFEFECE4),
      isDark ? const Color(0xFF141618) : const Color(0xFFDAD2C2),
    );

    // Amber Sun / Moon
    canvas.drawCircle(Offset(w * 0.76, h * 0.22), 18,
      Paint()..color = isDark ? const Color(0x60D4AF37) : const Color(0x40C86446));

    // Far Misty Mountains
    final farMtn = Path()
      ..moveTo(0, h * 0.70)
      ..quadraticBezierTo(w * 0.28, h * 0.36, w * 0.55, h * 0.60)
      ..quadraticBezierTo(w * 0.78, h * 0.28, w, h * 0.52)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(farMtn, Paint()..color = isDark ? const Color(0x35D4AF37) : const Color(0x555A6560));

    // Near Ridge & Valley
    final nearMtn = Path()
      ..moveTo(0, h * 0.84)
      ..quadraticBezierTo(w * 0.36, h * 0.52, w * 0.70, h * 0.76)
      ..quadraticBezierTo(w * 0.88, h * 0.62, w, h * 0.74)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(nearMtn, Paint()..color = isDark ? const Color(0x65E6E1D8) : const Color(0x9E2F3835));

    // Bamboo Stalks
    final bambooPaint = Paint()
      ..color = isDark ? const Color(0xFFD4AF37) : const Color(0xFF232B28)
      ..strokeWidth = 2.0..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.14, h), Offset(w * 0.20, h * 0.16), bambooPaint);
    canvas.drawLine(Offset(w * 0.20, h), Offset(w * 0.28, h * 0.26), bambooPaint);

    // Solitary Skiff
    final boatPath = Path()
      ..moveTo(w * 0.52, h * 0.82)
      ..quadraticBezierTo(w * 0.62, h * 0.88, w * 0.72, h * 0.82);
    canvas.drawPath(boatPath, Paint()
      ..color = isDark ? const Color(0xFFEDE4CE) : const Color(0xFF22262C)
      ..strokeWidth = 2.2..style = PaintingStyle.stroke);

    // Distant Pavilion
    final pavilion = Path()
      ..moveTo(w * 0.80, h * 0.56)
      ..lineTo(w * 0.86, h * 0.52)
      ..lineTo(w * 0.92, h * 0.56)..close();
    canvas.drawPath(pavilion, Paint()
      ..color = isDark ? const Color(0x80D4AF37) : const Color(0x882F3835)
      ..style = PaintingStyle.fill);

    _paintSealStamp(canvas, Offset(w * 0.84, h * 0.72));
  }

  void _paintIndoorRealm(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _paintGradientBg(canvas, size,
      isDark ? const Color(0xFF1F2124) : const Color(0xFFF3ECE0),
      isDark ? const Color(0xFF141619) : const Color(0xFFDED3BF),
    );

    // Moon Window Lattice
    final center = Offset(w * 0.50, h * 0.40);
    final radius = w * 0.32;
    canvas.drawCircle(center, radius, Paint()
      ..color = isDark ? const Color(0x65D4AF37) : const Color(0x458C7355)
      ..style = PaintingStyle.stroke..strokeWidth = 3.0);
    final latticePaint = Paint()
      ..color = isDark ? const Color(0x35D4AF37) : const Color(0x288C7355)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), latticePaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), latticePaint);

    // Bamboo Curtain Slats
    final curtainPaint = Paint()
      ..color = isDark ? const Color(0x55C8A055) : const Color(0x505A4A38)
      ..strokeWidth = 1.2;
    for (int row = 0; row < 6; row++) {
      final y = h * 0.06 + row * 8.0;
      canvas.drawLine(Offset(w * 0.15, y), Offset(w * 0.85, y), curtainPaint);
    }

    // Mud Stove & Kettle
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.40, h * 0.78), width: 36, height: 18), const Radius.circular(3)),
      Paint()..color = isDark ? const Color(0xFFD4AF37) : const Color(0xFF4A3B32)..style = PaintingStyle.fill,
    );
    canvas.drawCircle(Offset(w * 0.40, h * 0.70), 8,
      Paint()..color = isDark ? const Color(0xFFD4AF37) : const Color(0xFF4A3B32)..style = PaintingStyle.fill);

    // Steam
    final steam = Path()
      ..moveTo(w * 0.40, h * 0.64)
      ..quadraticBezierTo(w * 0.38, h * 0.58, w * 0.42, h * 0.52)
      ..quadraticBezierTo(w * 0.46, h * 0.46, w * 0.43, h * 0.40);
    canvas.drawPath(steam, Paint()
      ..color = isDark ? const Color(0x60EDE4CE) : const Color(0x607D6E63)
      ..strokeWidth = 1.2..style = PaintingStyle.stroke);

    _paintSealStamp(canvas, Offset(w * 0.14, h * 0.16));
  }

  void _paintOutdoorRealm(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _paintGradientBg(canvas, size,
      isDark ? const Color(0xFF1E2220) : const Color(0xFFEBECE7),
      isDark ? const Color(0xFF131715) : const Color(0xFFCBD2CC),
    );

    // Arched Stone Bridge
    final bridgePath = Path()
      ..moveTo(w * 0.10, h * 0.70)
      ..quadraticBezierTo(w * 0.50, h * 0.45, w * 0.90, h * 0.70);
    canvas.drawPath(bridgePath, Paint()
      ..color = isDark ? const Color(0x70C2B280) : const Color(0x803E5E54)
      ..style = PaintingStyle.stroke..strokeWidth = 3.5);

    final archPath = Path()
      ..moveTo(w * 0.35, h * 0.70)
      ..quadraticBezierTo(w * 0.50, h * 0.54, w * 0.65, h * 0.70)..close();
    canvas.drawPath(archPath, Paint()..color = isDark ? const Color(0x40131715) : const Color(0x35233B34));

    // Willow Branches
    final willowPaint = Paint()
      ..color = isDark ? const Color(0x85D4AF37) : const Color(0x902E483F)
      ..strokeWidth = 1.4..style = PaintingStyle.stroke;
    final willow = Path()
      ..moveTo(w * 0.85, 0)..quadraticBezierTo(w * 0.78, h * 0.22, w * 0.82, h * 0.44)
      ..moveTo(w * 0.92, 0)..quadraticBezierTo(w * 0.88, h * 0.28, w * 0.90, h * 0.50);
    canvas.drawPath(willow, willowPaint);

    // Lantern Ferry
    final ferry = Path()
      ..moveTo(w * 0.42, h * 0.82)
      ..quadraticBezierTo(w * 0.52, h * 0.86, w * 0.62, h * 0.82);
    canvas.drawPath(ferry, Paint()
      ..color = isDark ? const Color(0xFFE6E1D8) : const Color(0xFF233B34)
      ..strokeWidth = 2.0..style = PaintingStyle.stroke);
    canvas.drawCircle(Offset(w * 0.52, h * 0.77), 3.2, Paint()..color = const Color(0xFFE67E22));

    _paintSealStamp(canvas, Offset(w * 0.82, h * 0.76));
  }

  void _paintSealStamp(Canvas canvas, Offset offset) {
    final stampColor = isDark ? const Color(0xFFD95B4B) : const Color(0xFFB83B2E);
    canvas.drawRect(
      Rect.fromLTWH(offset.dx, offset.dy, 12, 16),
      Paint()..color = stampColor.withValues(alpha: 0.88),
    );
  }

  @override
  bool shouldRepaint(covariant FolioShanshuiArtPainter oldDelegate) {
    return oldDelegate.realm != realm ||
        oldDelegate.isDark != isDark ||
        oldDelegate.atmosphere != atmosphere;
  }
}
