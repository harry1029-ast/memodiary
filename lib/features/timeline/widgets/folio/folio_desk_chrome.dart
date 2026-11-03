import 'package:flutter/material.dart';
import '../../../editor/services/audio_sanctum_service.dart';
import '../../../editor/widgets/soundscape_modal.dart';
import 'folio_actions.dart';
import 'folio_reading_perspective.dart';

/// Top floating desk chrome bar with back breadcrumb, title, ambient soundscape,
/// and consolidated More menu.
class FolioTopChrome extends StatelessWidget {
  final String dateBreadcrumb;
  final String displayTitle;
  final bool isEntryLocked;
  final AudioSanctumService? audioSanctumService;
  final FolioActions actions;
  final VoidCallback onBack;

  const FolioTopChrome({
    super.key,
    required this.dateBreadcrumb,
    required this.displayTitle,
    required this.isEntryLocked,
    required this.actions,
    required this.onBack,
    this.audioSanctumService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 6,
        bottom: 8,
        left: 12,
        right: 12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xCC0A0908),
            Color(0x660A0908),
            Colors.transparent,
          ],
        ),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Row(
          children: [
            IconButton(
              key: const Key('folio_back_btn'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFFE6E1D8)),
              tooltip: '返回 · $dateBreadcrumb',
              onPressed: onBack,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                displayTitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFBF8F1),
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (audioSanctumService != null)
              ListenableBuilder(
                listenable: audioSanctumService!,
                builder: (context, _) {
                  final isPlaying = audioSanctumService!.isPlaying;
                  return IconButton(
                    key: const Key('folio_soundscape_btn'),
                    icon: Icon(
                      isPlaying ? Icons.headphones_rounded : Icons.headphones_outlined,
                      size: 20,
                      color: isPlaying ? const Color(0xFFB83B2E) : const Color(0xFFB3ADA3),
                    ),
                    tooltip: '砚边琴韵',
                    onPressed: () {
                      SoundscapeModal.show(
                        context: context,
                        sanctumService: audioSanctumService!,
                      );
                    },
                  );
                },
              ),
            PopupMenuButton<String>(
              key: const Key('folio_more_menu_btn'),
              icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFFE6E1D8)),
              color: const Color(0xFF1E1D1B),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0x33D4AF37), width: 0.8),
              ),
              onSelected: (action) {
                switch (action) {
                  case 'lock':
                    actions.onToggleLock?.call();
                    break;
                  case 'pdf':
                    actions.onExportPdf?.call();
                    break;
                  case 'text':
                    actions.onExportText?.call();
                    break;
                  case 'delete':
                    actions.onSoftDelete?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  key: const Key('folio_menu_lock_entry'),
                  value: 'lock',
                  child: Row(
                    children: [
                      Icon(
                        isEntryLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                        size: 18,
                        color: const Color(0xFFE6E1D8),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEntryLocked ? '解除私密封缄' : '私密封存',
                        style: const TextStyle(color: Color(0xFFE6E1D8)),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  key: Key('folio_menu_export_pdf'),
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf_outlined, size: 18, color: Color(0xFFE6E1D8)),
                      SizedBox(width: 10),
                      Text('导出宣纸 PDF', style: TextStyle(color: Color(0xFFE6E1D8))),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  key: Key('folio_menu_export_text'),
                  value: 'text',
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined, size: 18, color: Color(0xFFE6E1D8)),
                      SizedBox(width: 10),
                      Text('纯文归档', style: TextStyle(color: Color(0xFFE6E1D8))),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                PopupMenuItem(
                  key: const Key('folio_menu_delete_entry'),
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400),
                      const SizedBox(width: 10),
                      Text('移入岁暮拾遗', style: TextStyle(color: Colors.red.shade400)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom floating action dock with perspective switcher, interactive page indicator,
/// and share/edit action buttons.
class FolioBottomDock extends StatelessWidget {
  final ReadingPerspective perspective;
  final VoidCallback onOpenPerspective;
  final int currentPageIndex;
  final int totalPages;
  final VoidCallback onOpenPageJump;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;
  final VoidCallback onShare;
  final VoidCallback? onEditEntry;

  const FolioBottomDock({
    super.key,
    required this.perspective,
    required this.onOpenPerspective,
    required this.currentPageIndex,
    required this.totalPages,
    required this.onOpenPageJump,
    required this.onShare,
    this.onPrevPage,
    this.onNextPage,
    this.onEditEntry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.paddingOf(context).bottom + 8,
        left: 10,
        right: 10,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xE60A0908),
            Color(0x990A0908),
            Colors.transparent,
          ],
        ),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            return SizedBox(
              width: availableWidth,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: availableWidth,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        key: const Key('folio_reading_perspective_btn'),
                        onPressed: onOpenPerspective,
                        icon: const Icon(Icons.auto_stories_outlined, size: 14, color: Color(0xFFD4AF37)),
                        label: Text(
                          perspective.label,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFE6E1D8)),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0x1AD4AF37),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: const Key('folio_prev_page_btn'),
                            icon: const Icon(Icons.chevron_left_rounded, size: 18, color: Color(0xFFE6E1D8)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 28),
                            visualDensity: VisualDensity.compact,
                            tooltip: '上一页',
                            onPressed: onPrevPage,
                          ),
                          InkWell(
                            key: const Key('folio_page_indicator'),
                            borderRadius: BorderRadius.circular(12),
                            onTap: onOpenPageJump,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0x1AFFFFFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '第 ${currentPageIndex + 1} / $totalPages 页',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFFB3ADA3),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('folio_next_page_btn'),
                            icon: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFE6E1D8)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 28),
                            visualDensity: VisualDensity.compact,
                            tooltip: '下一页',
                            onPressed: onNextPage,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: const Key('folio_share_btn'),
                            icon: const Icon(Icons.share_outlined, size: 17, color: Color(0xFFE6E1D8)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            visualDensity: VisualDensity.compact,
                            tooltip: '分享',
                            onPressed: onShare,
                          ),
                          const SizedBox(width: 4),
                          FilledButton.icon(
                            key: const Key('folio_edit_entry_btn'),
                            onPressed: onEditEntry,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFB83B2E),
                              foregroundColor: const Color(0xFFFAF7F0),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 13),
                            label: const Text('落墨修改', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

