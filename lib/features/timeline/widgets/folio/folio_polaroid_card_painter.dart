import 'package:flutter/material.dart';

/// Gold washi tape strip (泥金和纸胶带) pinned at the card corner.
class GoldWashiTapeWidget extends StatelessWidget {
  final double width;
  final double height;
  final double rotationAngle;

  const GoldWashiTapeWidget({
    super.key,
    this.width = 38.0,
    this.height = 10.0,
    this.rotationAngle = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationAngle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1.5),
          gradient: const LinearGradient(
            colors: [
              Color(0xB3D4AF37),
              Color(0xCCE6CA65),
              Color(0x99B8860B),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
          border: Border.all(
            color: const Color(0x66FDE68A),
            width: 0.5,
          ),
        ),
      ),
    );
  }
}

