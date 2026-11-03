import 'package:flutter/foundation.dart';

/// Bundles user action callbacks for the Thread-Bound Folio desk chrome.
class FolioActions {
  final VoidCallback? onEditEntry;
  final VoidCallback? onSoftDelete;
  final VoidCallback? onToggleLock;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportText;
  final Future<void> Function(String text, {String? subject})? shareHandler;

  const FolioActions({
    this.onEditEntry,
    this.onSoftDelete,
    this.onToggleLock,
    this.onExportPdf,
    this.onExportText,
    this.shareHandler,
  });
}
