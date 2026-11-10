import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/stationery_sheet_descriptor.dart';

/// Lifts the desk (sheet, header band and chrome) while the software keyboard
/// is open, by one decision:
///
/// - **Whole sheet:** whenever the whole Stationery Sheet fits on the desk
///   left visible above the keyboard and accessory row, the desk lifts just
///   far enough that all of it shows, wherever the caret is.
/// - **Caret (fallback):** otherwise it lifts typewriter-style, far enough
///   that the caret of the active sheet stays [kClearanceRows] rows above the
///   accessory row, but never further than brings the sheet's bottom edge
///   into view.
///
/// The sheet itself never moves or reflows when the keyboard opens: its
/// geometry is resolved against the resting desk height, and this widget only
/// translates the whole desk upward, so ruling and text move together and stay
/// in line. With the keyboard closed, or (in the fallback) the caret outside
/// the active sheet (e.g. the title field), the lift returns to zero.
class KeyboardDeskLift extends StatefulWidget {
  /// Whether the software keyboard covers part of the desk.
  final bool isKeyboardVisible;

  /// Height of the desk left visible above the keyboard and accessory row.
  final double visibleHeight;

  /// The active sheet's top and bottom edges on the resting desk.
  final double sheetTop;
  final double sheetBottom;

  /// The sheet's row stride, by which the caret's clearance is measured.
  final double rowHeight;

  /// The sheet the diarist is writing on, or null for a non-text sheet.
  final TextStationerySheet? activeSheet;
  final Widget child;

  /// Rows kept clear between the caret and the bottom of the visible desk.
  static const int kClearanceRows = 2;

  /// Breathing room kept between the caret and the top of the visible desk,
  /// and below the sheet's bottom edge when it is lifted into view.
  static const double kCaretMargin = 12.0;
  static const Duration kLiftDuration = Duration(milliseconds: 180);

  const KeyboardDeskLift({
    super.key,
    required this.isKeyboardVisible,
    required this.visibleHeight,
    required this.sheetTop,
    required this.sheetBottom,
    required this.rowHeight,
    required this.activeSheet,
    required this.child,
  });

  /// How far the desk around [context] is lifted this frame (0 outside a
  /// lift), for desk elements that must stay on the visible desk.
  static double liftOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DeskLiftScope>()?.lift ?? 0.0;

  @override
  State<KeyboardDeskLift> createState() => _KeyboardDeskLiftState();
}

class _DeskLiftScope extends InheritedWidget {
  final double lift;

  const _DeskLiftScope({required this.lift, required super.child});

  @override
  bool updateShouldNotify(_DeskLiftScope oldWidget) => lift != oldWidget.lift;
}

class _KeyboardDeskLiftState extends State<KeyboardDeskLift> {
  final GlobalKey _deskKey = GlobalKey();
  double _lift = 0.0;
  double _measuredVisibleHeight = 0.0;
  bool _isMeasureScheduled = false;

  @override
  void initState() {
    super.initState();
    _listenTo(widget.activeSheet);
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(KeyboardDeskLift oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.activeSheet, widget.activeSheet)) {
      _stopListening(oldWidget.activeSheet);
      _listenTo(widget.activeSheet);
    }
    _scheduleMeasure();
  }

  @override
  void dispose() {
    _stopListening(widget.activeSheet);
    super.dispose();
  }

  void _listenTo(TextStationerySheet? sheet) {
    sheet?.controller.addListener(_scheduleMeasure);
    sheet?.focusNode.addListener(_scheduleMeasure);
  }

  void _stopListening(TextStationerySheet? sheet) {
    sheet?.controller.removeListener(_scheduleMeasure);
    sheet?.focusNode.removeListener(_scheduleMeasure);
  }

  void _scheduleMeasure() {
    if (_isMeasureScheduled) return;
    _isMeasureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isMeasureScheduled = false;
      if (!mounted) return;
      final target = _resolveLift();
      if ((target - _lift).abs() > 0.5) setState(() => _lift = target);
    });
  }

  double _resolveLift() {
    if (!widget.isKeyboardVisible) return 0.0;
    // The furthest lift brings the sheet's bottom edge into view. When that
    // leaves its top edge on the desk too, the whole sheet fits: lift so it shows.
    final maxLift = math.max(0.0, widget.sheetBottom + KeyboardDeskLift.kCaretMargin - widget.visibleHeight);
    if (widget.sheetTop >= maxLift) return maxLift;

    final sheet = widget.activeSheet;
    if (sheet == null || !sheet.focusNode.hasFocus) return 0.0;
    final caret = _caretRectOnDesk(sheet);
    if (caret == null) return _lift;

    // While the diarist types, the desk holds its lift (typewriter-style), so
    // it only climbs line by line. When the visible desk changes (the keyboard
    // or the chrome around it moving), the lift starts afresh, so a passing
    // state never leaves the desk higher than the caret needs.
    final hasVisibleDeskChanged = (widget.visibleHeight - _measuredVisibleHeight).abs() > 0.5;
    _measuredVisibleHeight = widget.visibleHeight;
    var lift = hasVisibleDeskChanged ? 0.0 : _lift;
    final clearance = KeyboardDeskLift.kClearanceRows * widget.rowHeight;
    if (caret.bottom + clearance - lift > widget.visibleHeight) {
      lift = caret.bottom + clearance - widget.visibleHeight;
    }
    const margin = KeyboardDeskLift.kCaretMargin;
    if (caret.top - margin - lift < 0) {
      lift = caret.top - margin;
    }
    return lift.clamp(0.0, maxLift).toDouble();
  }

  /// The caret's rect in the unlifted desk's coordinates.
  Rect? _caretRectOnDesk(TextStationerySheet sheet) {
    final selection = sheet.controller.selection;
    final editorState = sheet.editorKey.currentState;
    final desk = _deskKey.currentContext?.findRenderObject();
    if (!selection.isValid || editorState == null || !editorState.mounted || desk is! RenderBox) {
      return null;
    }
    final renderEditor = editorState.renderEditor;
    if (!renderEditor.attached || !renderEditor.hasSize) return null;
    final localCaret = renderEditor.getLocalRectForCaret(selection.extent);
    final topLeft = renderEditor.localToGlobal(localCaret.topLeft, ancestor: desk);
    return topLeft & localCaret.size;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _lift),
      duration: KeyboardDeskLift.kLiftDuration,
      curve: Curves.easeOutCubic,
      builder: (liftContext, lift, child) => _DeskLiftScope(
        lift: lift,
        child: Transform.translate(offset: Offset(0.0, -lift), child: child),
      ),
      child: KeyedSubtree(key: _deskKey, child: widget.child),
    );
  }
}
