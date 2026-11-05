import 'package:flutter/material.dart';

/// What the diarist chose when leaving the editor with items still staged.
enum StagedExitChoice {
  /// 留在画卷: leave, keeping the items staged for next time (the default).
  keep,

  /// 舍弃待贴: erase the staged items, then leave.
  discard,

  /// 继续装裱: dismiss the reminder and stay in the editor.
  continueMounting,
}

/// Self-contained exit reminder shown when the Staging Handscroll still holds
/// items. Holds no mutable state: each button pops the route with its choice.
class StagedExitReminderDialog extends StatelessWidget {
  final int stagedCount;

  const StagedExitReminderDialog({super.key, required this.stagedCount});

  /// Shows the reminder and returns the choice; dismissing it by tapping
  /// outside counts as [StagedExitChoice.continueMounting].
  static Future<StagedExitChoice> show(BuildContext context, {required int stagedCount}) async {
    final choice = await showDialog<StagedExitChoice>(
      context: context,
      builder: (_) => StagedExitReminderDialog(stagedCount: stagedCount),
    );
    return choice ?? StagedExitChoice.continueMounting;
  }

  /// Runs the exit reminder for [stagedCount] staged items and returns whether
  /// the editor should be left. [discardStaged] runs first on 舍弃待贴.
  static Future<bool> confirmLeave(
    BuildContext context, {
    required int stagedCount,
    required Future<void> Function() discardStaged,
  }) async {
    if (stagedCount == 0) return true;
    final choice = await show(context, stagedCount: stagedCount);
    if (choice == StagedExitChoice.continueMounting) return false;
    if (choice == StagedExitChoice.discard) await discardStaged();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    const minTapSize = Size(44, 44);
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      key: const Key('staged_exit_reminder'),
      title: const Text('画卷中尚有待贴之物'),
      content: Text(
        '待贴画卷里还有 $stagedCount 件影札未装裱。离开后可留在画卷，下次继续；亦可舍弃。',
        style: textTheme.bodyMedium,
      ),
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        FilledButton(
          key: const Key('staged_exit_keep_button'),
          style: FilledButton.styleFrom(minimumSize: minTapSize),
          onPressed: () => Navigator.pop(context, StagedExitChoice.keep),
          child: const Text('留在画卷'),
        ),
        TextButton(
          key: const Key('staged_exit_discard_button'),
          style: TextButton.styleFrom(minimumSize: minTapSize),
          onPressed: () => Navigator.pop(context, StagedExitChoice.discard),
          child: const Text('舍弃待贴'),
        ),
        TextButton(
          key: const Key('staged_exit_continue_button'),
          style: TextButton.styleFrom(minimumSize: minTapSize),
          onPressed: () => Navigator.pop(context, StagedExitChoice.continueMounting),
          child: const Text('继续装裱'),
        ),
      ],
    );
  }
}
