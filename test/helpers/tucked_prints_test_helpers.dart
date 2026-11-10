import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/features/editor/widgets/editor_paper_canvas.dart';

/// The resting fan of Tucked Prints above the active Stationery Sheet (one target).
final Finder tuckedPrintsFan = find.byKey(const Key('tucked_prints'));

/// One Tucked Print of the active sheet, by attachment id.
Finder tuckedPrint(String mediaId) => find.byKey(Key('tucked_print_$mediaId'));

/// Unmounts [mediaId] from its sheet back into the Staging Handscroll through
/// the desk's unmount action, as the fanned overlay's ↩ 揭回 does (the overlay
/// lands in SPEC-011 ticket 07; switch this to tapping its ↩ then). Does not pump.
void unmountTuckedPrint(WidgetTester tester, String mediaId) {
  tester.widget<EditorPaperCanvas>(find.byType(EditorPaperCanvas)).deskMedia.onUnmount!(mediaId);
}
