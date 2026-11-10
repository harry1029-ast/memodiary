import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controllers/editor_autosave_manager.dart';
import 'autosave_status_dot.dart';
import 'keyboard_desk_lift.dart';
import 'stationery_page_indicator.dart';

/// The left of the Scholar's Desk header band: the page indicator and, while
/// the app bar is away (keyboard open), the save-state dot beside it.
///
/// The band rides the [KeyboardDeskLift] with the sheet, but the dot stands
/// in for the app bar, so once the lift would carry the band off the top of
/// the visible desk the dot stays at the top instead.
class DeskHeaderBandLead extends StatelessWidget {
  final int currentSheetIndex;
  final int totalSheets;

  /// The autosave status to mirror, or null while the app bar shows it.
  final ValueListenable<AutosaveStatus>? saveStatus;

  /// Distance from the top of the desk to the band.
  final double bandTop;

  const DeskHeaderBandLead({
    super.key,
    required this.currentSheetIndex,
    required this.totalSheets,
    this.saveStatus,
    this.bandTop = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final status = saveStatus;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IgnorePointer(
          child: StationeryPageIndicator(currentSheetIndex: currentSheetIndex, totalSheets: totalSheets),
        ),
        if (status != null) ...[
          const SizedBox(width: 8.0),
          Builder(
            builder: (liftContext) => Transform.translate(
              offset: Offset(0.0, math.max(0.0, KeyboardDeskLift.liftOf(liftContext) - bandTop)),
              child: AutosaveStatusDot(key: const Key('editor_save_state_dot'), status: status),
            ),
          ),
        ],
      ],
    );
  }
}
