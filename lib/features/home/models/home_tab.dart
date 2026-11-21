import 'package:flutter/material.dart' show IconData, Icons, State, StatefulWidget;

/// The two peer tabs held by the Home Shell.
enum HomeTab {
  /// 日记: the timeline.
  diary(
    label: '日记',
    primaryActionLabel: '写日记',
    primaryActionIcon: Icons.brush_rounded,
  ),

  /// 相册: the album collections.
  albums(
    label: '相册',
    primaryActionLabel: '新建相册',
    primaryActionIcon: Icons.add_photo_alternate_outlined,
  );

  const HomeTab({
    required this.label,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
  });

  /// Tab Rail label.
  final String label;

  /// Scroll Roller Button label while this tab is active.
  final String primaryActionLabel;

  /// Scroll Roller Button icon while this tab is active.
  final IconData primaryActionIcon;
}

/// The seam through which a Home Shell tab exposes its primary create flow
/// (写日记, 新建相册) to the Scroll Roller Button.
///
/// The tab attaches its own handler, which runs the create flow and refreshes
/// the tab's list, so the shell never needs to know about entries or albums.
class HomeTabPrimaryAction {
  Future<void> Function()? _handler;

  /// Whether a tab has attached a handler.
  bool get isAttached => _handler != null;

  void attach(Future<void> Function() handler) => _handler = handler;

  /// Detaches [handler] if it is still the attached one.
  void detach(Future<void> Function() handler) {
    if (_handler == handler) _handler = null;
  }

  /// Runs the attached tab's primary action, if any.
  Future<void> run() async {
    final handler = _handler;
    if (handler != null) await handler();
  }
}

/// Binds a Home Shell tab's [runPrimaryAction] to the [HomeTabPrimaryAction]
/// its widget carries, for the State's lifetime: attached in `initState`,
/// moved when the widget is rebuilt with another action, detached on dispose.
mixin HomeTabPrimaryActionBinding<T extends StatefulWidget> on State<T> {
  /// The action seam [widget] carries (null outside the Home Shell).
  HomeTabPrimaryAction? primaryActionOf(T widget);

  /// The tab's create flow, run by the Scroll Roller Button.
  Future<void> runPrimaryAction();

  @override
  void initState() {
    super.initState();
    primaryActionOf(widget)?.attach(runPrimaryAction);
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldAction = primaryActionOf(oldWidget);
    final newAction = primaryActionOf(widget);
    if (oldAction != newAction) {
      oldAction?.detach(runPrimaryAction);
      newAction?.attach(runPrimaryAction);
    }
  }

  @override
  void dispose() {
    primaryActionOf(widget)?.detach(runPrimaryAction);
    super.dispose();
  }
}
