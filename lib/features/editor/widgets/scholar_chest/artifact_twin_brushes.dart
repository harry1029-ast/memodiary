import 'package:flutter/material.dart';
import '../../../../core/theme/ink_diary_theme.dart';

/// Top horizontal groove placeholder artifact representing the twin calligraphy brushes (双管毛笔).
/// Animates a gentle brush lift on tap and displays a poetic placeholder in the drawer sub-panel.
class ArtifactTwinBrushes extends StatefulWidget {
  final bool isSelected;
  final VoidCallback? onTap;

  const ArtifactTwinBrushes({
    super.key,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<ArtifactTwinBrushes> createState() => _ArtifactTwinBrushesState();
}

class _ArtifactTwinBrushesState extends State<ArtifactTwinBrushes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _liftAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _liftAnimation = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    if (widget.isSelected) {
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant ArtifactTwinBrushes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '双管毛笔: 笔锋运墨动效 (敬请期待)',
      selected: widget.isSelected,
      child: GestureDetector(
        key: const Key('chest_artifact_twin_brushes'),
        onTap: () {
          widget.onTap?.call();
        },
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return Transform.translate(
              offset: Offset(0, _liftAnimation.value),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B1A1E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.isSelected
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFF8B262A),
                    width: widget.isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Brush shaft 1 & 2 vector graphic representation
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildBrushShaft(const Color(0xFFC29B38), const Color(0xFFE8DFCC)),
                          _buildBrushShaft(const Color(0xFF8A5A2B), const Color(0xFF2B2B2B)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Brass plaque label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1A17),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                      ),
                      child: Text(
                        '双管笔槽',
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontKaiti,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE6C875),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrushShaft(Color shaftColor, Color tipColor) {
    return Row(
      children: [
        // Brush Tip (hair)
        Container(
          width: 14,
          height: 6.5,
          decoration: BoxDecoration(
            color: tipColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              bottomLeft: Radius.circular(5),
            ),
          ),
        ),
        // Brass ferrule wrap
        Container(
          width: 5,
          height: 7,
          color: const Color(0xFFD4AF37),
        ),
        // Bamboo shaft
        Expanded(
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: shaftColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(2),
                bottomRight: Radius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
