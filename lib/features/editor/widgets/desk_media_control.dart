import 'package:flutter/material.dart';

/// Light/dark paper tones shared by the Staging Handscroll and the Sheet Mount
/// Strip, so their prints and controls read as one set of stationery.
class DeskMediaPalette {
  final bool isPaperDark;

  const DeskMediaPalette({required this.isPaperDark});

  /// Ink tone of neutral controls (📌, ↩).
  Color get ink => isPaperDark ? const Color(0xFFD6D1C7) : const Color(0xFF3C3836);

  /// Cinnabar tone of erase controls and the video play seal.
  Color get cinnabar => isPaperDark ? const Color(0xFFE57373) : const Color(0xFFB83B2E);

  /// Paper-toned matte framing a mounted print.
  Color get matte => isPaperDark ? const Color(0xFF1E1D1B) : const Color(0xFFFBF8F1);

  /// Hairline border around the matte.
  Color get matteBorder => isPaperDark ? const Color(0x33FFFFFF) : const Color(0x1F000000);
}

/// Which palette tone a [DeskMediaControl] is drawn in.
enum DeskMediaControlTone { ink, cinnabar }

/// A 44×44 action on a handscroll slot or a mounted print whose semantics name
/// only that action.
class DeskMediaControl extends StatelessWidget {
  final IconData icon;
  final DeskMediaControlTone tone;
  final bool isPaperDark;
  final String semanticLabel;
  final VoidCallback? onPressed;

  /// Edge of the square touch target.
  static const double kExtent = 44.0;

  const DeskMediaControl({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.isPaperDark,
    this.tone = DeskMediaControlTone.ink,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DeskMediaPalette(isPaperDark: isPaperDark);
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: tone == DeskMediaControlTone.cinnabar ? palette.cinnabar : palette.ink,
        constraints: const BoxConstraints.tightFor(width: kExtent, height: kExtent),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        onPressed: onPressed,
      ),
    );
  }
}
