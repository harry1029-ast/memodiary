import 'package:flutter/material.dart';

import '../../../../core/services/media_sandbox_service.dart';
import '../../domain/stationery_sheet_descriptor.dart';
import '../staging_handscroll.dart';
import 'closed_brocade_scroll.dart';
import 'walnut_desk_painter.dart';

/// The Desk Workstation (案头画案): the dark walnut desk and bamboo mat on which
/// the Staging Handscroll rests. The rest of the editor keeps its light paper
/// look. An empty handscroll lies closed as a brocade scroll that starts
/// collecting when tapped. Pure presentation: actions bubble through callbacks.
class DeskWorkstation extends StatefulWidget {
  final List<SheetMediaItem> stagedItems;
  final MediaSandboxService mediaSandboxService;

  /// 1-based number of the active Stationery Sheet that 📌 mounts onto.
  final int activeSheetNumber;
  final VoidCallback? onCollect;
  final ValueChanged<SheetMediaItem>? onTapItem;
  final ValueChanged<SheetMediaItem>? onMountItem;
  final ValueChanged<SheetMediaItem>? onEraseItem;

  static const double kHeaderHeight = 26.0;
  static const EdgeInsets kMatInsets = EdgeInsets.fromLTRB(10.0, kHeaderHeight, 10.0, 8.0);

  const DeskWorkstation({
    super.key,
    required this.stagedItems,
    required this.mediaSandboxService,
    required this.activeSheetNumber,
    this.onCollect,
    this.onTapItem,
    this.onMountItem,
    this.onEraseItem,
  });

  @override
  State<DeskWorkstation> createState() => _DeskWorkstationState();
}

class _DeskWorkstationState extends State<DeskWorkstation> {
  final _deskPainter = WalnutDeskPainter(matInsets: DeskWorkstation.kMatInsets);

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
                          onTap: widget.onCollect,
                        )
                      : StagingHandscroll(
                          items: widget.stagedItems,
                          mediaSandboxService: widget.mediaSandboxService,
                          activeSheetNumber: widget.activeSheetNumber,
                          isPaperDark: false,
                          onTapItem: widget.onTapItem,
                          onMountItem: widget.onMountItem,
                          onEraseItem: widget.onEraseItem,
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
