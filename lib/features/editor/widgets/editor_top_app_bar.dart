import 'package:flutter/material.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../controllers/editor_autosave_manager.dart';
import '../services/audio_sanctum_service.dart';
import 'scholar_chest/scholar_chest_drawer.dart';

/// Classical Ink & Paper stationery top app bar for the diary editor.
///
/// Encapsulates:
/// - Navigation return & auto-commit
/// - Live debounced autosave status indicator
/// - Ambient soundscape pill indicator
/// - Time-capsule lock pill indicator
/// - Keepsake Scroll View trigger
/// - Scholar's Stationery Chest drawer trigger with badge
/// - Cinnabar Seal Done action button
class EditorTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Color paperColor;
  final Color iconColor;
  final ValueNotifier<AutosaveStatus> autosaveStatusNotifier;
  final AudioSanctumService audioSanctumService;
  final DateTime? unlockAt;
  final VoidCallback onSaveAndExit;
  final VoidCallback onOpenKeepsakeScroll;
  final void Function([ScholarArtifactType initialArtifact]) onOpenScholarChest;

  const EditorTopAppBar({
    super.key,
    required this.paperColor,
    required this.iconColor,
    required this.autosaveStatusNotifier,
    required this.audioSanctumService,
    required this.unlockAt,
    required this.onSaveAndExit,
    required this.onOpenKeepsakeScroll,
    required this.onOpenScholarChest,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return AppBar(
      backgroundColor: paperColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: iconColor, size: 22),
        tooltip: '返回 · Back',
        onPressed: onSaveAndExit,
      ),
      title: ValueListenableBuilder<AutosaveStatus>(
        valueListenable: autosaveStatusNotifier,
        builder: (statusContext, status, unusedChild) {
          String label = '已保存';
          Color dotColor = const Color(0xFF059669);
          if (status == AutosaveStatus.saving) {
            label = '存墨中...';
            dotColor = const Color(0xFFD97706);
          } else if (status == AutosaveStatus.unsaved) {
            label = '草稿未存';
            dotColor = tokens.danmo;
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontKaiti,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        // Ambient soundscape pill indicator (when playing)
        ListenableBuilder(
          listenable: audioSanctumService,
          builder: (listenableContext, unusedChild) {
            if (!audioSanctumService.isPlaying) return const SizedBox.shrink();
            return GestureDetector(
              key: const Key('top_bar_soundscape_pill'),
              onTap: () => onOpenScholarChest(ScholarArtifactType.guqinZither),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.cinnabar.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.cinnabar.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.music_note, size: 12, color: tokens.cinnabar),
                    const SizedBox(width: 3),
                    Text(
                      '清音',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontKaiti,
                        fontSize: 10,
                        color: tokens.cinnabar,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Time Capsule lock pill indicator (when locked in the future)
        if (unlockAt != null && unlockAt!.isAfter(DateTime.now()))
          GestureDetector(
            key: const Key('top_bar_lock_pill'),
            onTap: () => onOpenScholarChest(ScholarArtifactType.fishLock),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 11, color: Color(0xFF8A5A2B)),
                  const SizedBox(width: 3),
                  Text(
                    '封缄',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontKaiti,
                      fontSize: 10,
                      color: const Color(0xFF8A5A2B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Keepsake Scroll View Action
        IconButton(
          key: const Key('top_bar_keepsake_scroll_button'),
          icon: Icon(Icons.auto_stories_outlined, color: iconColor, size: 22),
          tooltip: '卷轴赏鉴 · Keepsake Scroll',
          onPressed: onOpenKeepsakeScroll,
        ),

        // Scholar's Stationery Chest Emblem Button with Live Status Badge
        ListenableBuilder(
          listenable: audioSanctumService,
          builder: (listenableContext, unusedChild) {
            final isPlayingSoundscape = audioSanctumService.isPlaying;
            final isCapsuleLocked = unlockAt != null && unlockAt!.isAfter(DateTime.now());
            final hasBadge = isPlayingSoundscape || isCapsuleLocked;

            return Badge(
              isLabelVisible: hasBadge,
              backgroundColor: isPlayingSoundscape ? tokens.cinnabar : const Color(0xFFD4AF37),
              smallSize: 8,
              alignment: const AlignmentDirectional(0.8, -0.8),
              child: IconButton(
                key: const Key('top_bar_scholar_chest_button'),
                icon: Icon(Icons.all_inbox_outlined, color: iconColor, size: 22),
                tooltip: '文房百宝匣 · 锦盒书案',
                onPressed: () => onOpenScholarChest(),
              ),
            );
          },
        ),

        // Cinnabar Seal & Complete Save
        IconButton(
          key: const Key('editor_seal_done_btn'),
          icon: Icon(Icons.check, color: tokens.cinnabar, size: 22),
          tooltip: '完成归卷 · Done',
          onPressed: onSaveAndExit,
        ),
      ],
    );
  }
}
