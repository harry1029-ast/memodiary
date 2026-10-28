import 'package:flutter/material.dart';

/// Interactive bottom slider with a circular cinnabar seal stamp handle
/// for opening or closing the 3D Chinese thread-bound diary book.
class BottomSealSlider extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final ValueChanged<double> onProgressChanged;
  final VoidCallback onToggle;

  const BottomSealSlider({
    super.key,
    required this.progress,
    required this.onProgressChanged,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const handleSize = 42.0;
        final maxTravel = totalWidth - handleSize - 8.0;
        final handleOffset = ((1.0 - progress) * maxTravel).clamp(0.0, maxTravel);

        void handleDragUpdate(DragUpdateDetails details) {
          if (maxTravel <= 0) return;
          // Dragging left increases progress (swiping left to open)
          final deltaRatio = -details.delta.dx / maxTravel;
          final newProgress = (progress + deltaRatio).clamp(0.0, 1.0);
          onProgressChanged(newProgress);
        }

        void handleDragEnd(DragEndDetails details) {
          final velocity = details.primaryVelocity ?? 0.0;
          if (velocity < -80.0) {
            onProgressChanged(1.0);
          } else if (velocity > 80.0) {
            onProgressChanged(0.0);
          } else if (progress >= 0.12 && progress < 0.5) {
            onProgressChanged(1.0);
          } else if (progress <= 0.88 && progress >= 0.5) {
            onProgressChanged(0.0);
          } else if (progress >= 0.5) {
            onProgressChanged(1.0);
          } else {
            onProgressChanged(0.0);
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggle,
          onHorizontalDragUpdate: handleDragUpdate,
          onHorizontalDragEnd: handleDragEnd,
          child: Container(
            width: totalWidth,
            height: 52,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F2E9).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFC9BDA6), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F1C1914),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                // Progress Fill Gradient (fills from right towards left)
                FractionallySizedBox(
                  alignment: Alignment.centerRight,
                  widthFactor: progress.clamp(0.12, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Color(0x333B5249),
                          Color(0x4DB83B2E),
                          Color(0x8CB83B2E),
                        ],
                      ),
                    ),
                  ),
                ),

                // Center Instructions Text Label
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: progress < 0.5 ? 16 : 48,
                      right: progress < 0.5 ? 48 : 16,
                    ),
                    child: Center(
                      child: Text(
                        progress < 0.70
                            ? '向左滑动掀开古籍封皮 · Swipe Left to Open'
                            : '点选书页「私人日记」或「旅行画册」入卷',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: Color(0xFF2B2620),
                          fontFamily: 'Noto Serif SC',
                        ),
                      ),
                    ),
                  ),
                ),

                // Draggable & Clickable Red Cinnabar Seal Handle
                Positioned(
                  left: handleOffset,
                  child: Container(
                    width: handleSize,
                    height: handleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFD24E40), Color(0xFF982B1F)],
                        center: Alignment(-0.2, -0.2),
                        radius: 0.85,
                      ),
                      border: Border.all(
                        color: const Color(0xFFF7D9CE).withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66B83B2E),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        progress < 0.5
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        color: const Color(0xFFFAF6ED),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

