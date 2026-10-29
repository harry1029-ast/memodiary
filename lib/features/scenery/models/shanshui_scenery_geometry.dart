import 'package:flutter/material.dart';

class ShanshuiRipple {
  double x;
  double y;
  double radius;
  final double maxRadius;
  double alpha;

  ShanshuiRipple({
    required this.x,
    required this.y,
    required this.radius,
    required this.maxRadius,
    required this.alpha,
  });
}

class ShanshuiParticle {
  double x;
  double y;
  final double vx;
  final double vy;
  final double size;
  double angle;
  final double vAngle;
  final double phase;
  final bool colorToggle;

  ShanshuiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.angle,
    required this.vAngle,
    required this.phase,
    required this.colorToggle,
  });
}

class ShanshuiCrane {
  double x;
  double y;
  final double scale;
  final double speed;
  final double phase;
  final double yAmp;
  final bool isHero;

  ShanshuiCrane({
    required this.x,
    required this.y,
    required this.scale,
    required this.speed,
    required this.phase,
    required this.yAmp,
    required this.isHero,
  });
}

class ShanshuiWeatherDrop {
  double x;
  double y;
  final double len;
  final double speed;
  final double size;
  final double phase;

  ShanshuiWeatherDrop({
    required this.x,
    required this.y,
    required this.len,
    required this.speed,
    required this.size,
    required this.phase,
  });
}

enum FoliageLayer { back, island, foreground, front }

enum FoliageRole { primary, secondary, accent }

class FoliageClusterDescriptor {
  final double x;
  final double y;
  final double r;
  final FoliageLayer layer;
  final FoliageRole role;

  const FoliageClusterDescriptor({
    required this.x,
    required this.y,
    required this.r,
    required this.layer,
    required this.role,
  });
}

/// Fixed mathematical geometry polygons ported from the master 1500x1000 Shanshui canvas.
class ShanshuiGeometry {
  const ShanshuiGeometry._();

  static const List<Offset> farMountain1 = [
    Offset(0, 560), Offset(70, 420), Offset(140, 360), Offset(210, 410), Offset(310, 260), Offset(390, 195),
    Offset(460, 240), Offset(550, 160), Offset(630, 220), Offset(720, 290), Offset(820, 210), Offset(900, 265),
    Offset(990, 185), Offset(1080, 250), Offset(1170, 310), Offset(1280, 225), Offset(1370, 280), Offset(1450, 350), Offset(1500, 400), Offset(1500, 650), Offset(0, 650),
  ];

  static const List<Offset> farMountain2 = [
    Offset(0, 580), Offset(90, 470), Offset(190, 380), Offset(270, 430), Offset(360, 320), Offset(450, 370),
    Offset(540, 270), Offset(640, 190), Offset(715, 250), Offset(790, 330), Offset(880, 280), Offset(960, 350),
    Offset(1060, 240), Offset(1140, 195), Offset(1230, 290), Offset(1330, 340), Offset(1420, 270), Offset(1500, 330), Offset(1500, 660), Offset(0, 660),
  ];

  static const List<Offset> leftKarstBack = [
    Offset(-20, 620), Offset(25, 310), Offset(68, 175), Offset(105, 190), Offset(155, 82), Offset(195, 68),
    Offset(230, 125), Offset(265, 195), Offset(305, 140), Offset(342, 165), Offset(395, 290), Offset(445, 420),
    Offset(510, 495), Offset(560, 590), Offset(-20, 620),
  ];

  static const List<Offset> leftKarstFront = [
    Offset(-10, 640), Offset(45, 390), Offset(95, 290), Offset(140, 315), Offset(215, 190), Offset(265, 145),
    Offset(310, 160), Offset(368, 285), Offset(415, 395), Offset(465, 345), Offset(505, 390), Offset(555, 515),
    Offset(600, 610), Offset(-10, 640),
  ];

  static const List<Offset> rightKarstPeaks = [
    Offset(840, 610), Offset(895, 445), Offset(935, 375), Offset(985, 225), Offset(1015, 210), Offset(1065, 310),
    Offset(1105, 375), Offset(1155, 285), Offset(1190, 260), Offset(1245, 370), Offset(1295, 315), Offset(1345, 235),
    Offset(1385, 290), Offset(1445, 420), Offset(1520, 580), Offset(840, 610),
  ];

  static const List<Offset> centerIslandHill = [
    Offset(590, 645), Offset(625, 585), Offset(665, 545), Offset(720, 520), Offset(785, 510), Offset(855, 515),
    Offset(915, 540), Offset(955, 585), Offset(985, 645), Offset(590, 645),
  ];

  static const List<FoliageClusterDescriptor> foliageClusters = [
    FoliageClusterDescriptor(x: 65, y: 515, r: 46, layer: FoliageLayer.back, role: FoliageRole.accent),
    FoliageClusterDescriptor(x: 120, y: 495, r: 52, layer: FoliageLayer.back, role: FoliageRole.secondary),
    FoliageClusterDescriptor(x: 185, y: 510, r: 44, layer: FoliageLayer.back, role: FoliageRole.primary),
    FoliageClusterDescriptor(x: 350, y: 545, r: 38, layer: FoliageLayer.front, role: FoliageRole.accent),
    FoliageClusterDescriptor(x: 395, y: 525, r: 48, layer: FoliageLayer.front, role: FoliageRole.primary),
    FoliageClusterDescriptor(x: 438, y: 555, r: 36, layer: FoliageLayer.front, role: FoliageRole.secondary),
    FoliageClusterDescriptor(x: 675, y: 530, r: 32, layer: FoliageLayer.island, role: FoliageRole.primary),
    FoliageClusterDescriptor(x: 710, y: 515, r: 28, layer: FoliageLayer.island, role: FoliageRole.secondary),
    FoliageClusterDescriptor(x: 880, y: 520, r: 34, layer: FoliageLayer.island, role: FoliageRole.primary),
    FoliageClusterDescriptor(x: 918, y: 540, r: 28, layer: FoliageLayer.island, role: FoliageRole.accent),
    FoliageClusterDescriptor(x: 1185, y: 785, r: 44, layer: FoliageLayer.foreground, role: FoliageRole.primary),
    FoliageClusterDescriptor(x: 1235, y: 745, r: 54, layer: FoliageLayer.foreground, role: FoliageRole.secondary),
    FoliageClusterDescriptor(x: 1290, y: 720, r: 58, layer: FoliageLayer.foreground, role: FoliageRole.primary),
    FoliageClusterDescriptor(x: 1345, y: 755, r: 50, layer: FoliageLayer.foreground, role: FoliageRole.secondary),
    FoliageClusterDescriptor(x: 1255, y: 805, r: 46, layer: FoliageLayer.foreground, role: FoliageRole.accent),
    FoliageClusterDescriptor(x: 1315, y: 815, r: 48, layer: FoliageLayer.foreground, role: FoliageRole.primary),
    FoliageClusterDescriptor(x: 45, y: 865, r: 45, layer: FoliageLayer.foreground, role: FoliageRole.primary),
    FoliageClusterDescriptor(x: 95, y: 895, r: 50, layer: FoliageLayer.foreground, role: FoliageRole.secondary),
    FoliageClusterDescriptor(x: 155, y: 925, r: 40, layer: FoliageLayer.foreground, role: FoliageRole.accent),
  ];
}

