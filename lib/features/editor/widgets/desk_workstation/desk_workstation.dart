import 'package:flutter/material.dart';

import '../../../../core/services/media_sandbox_service.dart';
import '../../domain/stationery_sheet_descriptor.dart';
import '../../models/desk_media_handlers.dart';
import '../staging_handscroll.dart';
import 'closed_brocade_scroll.dart';
import 'walnut_desk_painter.dart';

/// The Desk Workstation (案头画案): the bamboo mat on the walnut desk on which
/// the Staging Handscroll rests. The editor canvas paints the walnut desk
/// beneath it, so the workstation adds only its mat. An empty handscroll lies closed as a brocade scroll that starts
/// collecting when tapped. Pure presentation: actions bubble through callbacks.
class DeskWorkstation extends StatefulWidget {
  final List<SheetMediaItem> stagedItems;
  final MediaSandboxService mediaSandboxService;

  /// 1-based number of the active Stationery Sheet that 📌 mounts onto.
  final int activeSheetNumber;
  final ValueChanged<SheetMediaItem>? onTapItem;

  /// Collect, mount, erase and Brush Reveal plumbing.
  final DeskMediaHandlers handlers;

  static const double kHeaderHeight = 26.0;
  static const EdgeInsets kMatInsets = EdgeInsets.fromLTRB(10.0, kHeaderHeight, 10.0, 8.0);

  const DeskWorkstation({
    super.key,
    required this.stagedItems,
    required this.mediaSandboxService,
    required this.activeSheetNumber,
    this.onTapItem,
    this.handlers = const DeskMediaHandlers(),
  });

  @override
  State<DeskWorkstation> createState() => _DeskWorkstationState();
}

class _DeskWorkstationState extends State<DeskWorkstation> {
  final _deskPainter = WalnutDeskPainter(
    matInsets: DeskWorkstation.kMatInsets,
    paintsDesk: false,
  );

  /// Whether the open handscroll got there by opening from closed, so it
  /// unrolls. A workstation built with items that are all awaiting their
  /// reveal was closed before that collect (e.g. it was collapsed and the
  /// collect expanded it); otherwise it was already open (reopen, re-expand).
  late bool _opensFromClosed = _allAwaitingReveal(widget.stagedItems);

  bool _allAwaitingReveal(List<SheetMediaItem> items) {
    final queue = widget.handlers.brushReveals;
    return items.isNotEmpty && queue != null && items.every((item) => queue.isPending(item.id));
  }

  bool _anyAwaitingReveal(List<SheetMediaItem> items) {
    final queue = widget.handlers.brushReveals;
    return queue != null && items.any((item) => queue.isPending(item.id));
  }

  @override
  void didUpdateWidget(covariant DeskWorkstation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only a Collect (new items awaiting their reveal) unrolls the scroll;
    // unmounting, undoing an erase or reflow opens it in place.
    if (oldWidget.stagedItems.isEmpty && widget.stagedItems.isNotEmpty) {
      _opensFromClosed = _anyAwaitingReveal(widget.stagedItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = widget.stagedItems.isEmpty;
    final headerLabel = isClosed
        ? '待贴画卷 · 锦袱束绦'
        : '待贴画卷 · ${widget.stagedItems.length} 影';

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: ClipRect(
        child: CustomPaint(
          key: const Key('desk_workstation'),
          painter: _deskPainter,
          child: Stack(
            children: [
              Positioned(
                left: 16.0,
                top: 0.0,
                height: DeskWorkstation.kHeaderHeight,
                right: 16.0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ExcludeSemantics(
                    child: Text(
                      headerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.0,
                        letterSpacing: 1.5,
                        color: Color(0xE6FDE68A),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: DeskWorkstation.kMatInsets.add(const EdgeInsets.all(6.0)),
                  child: isClosed
                      ? ClosedBrocadeScroll(
                          key: const Key('closed_brocade_scroll'),
                          onTap: widget.handlers.onCollect,
                        )
                      : StagingHandscroll(
                          items: widget.stagedItems,
                          mediaSandboxService: widget.mediaSandboxService,
                          activeSheetNumber: widget.activeSheetNumber,
                          isPaperDark: false,
                          onTapItem: widget.onTapItem,
                          handlers: widget.handlers,
                          unrollOnOpen: _opensFromClosed,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
