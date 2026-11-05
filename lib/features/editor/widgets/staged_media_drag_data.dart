/// Payload of a Staging Handscroll print lifted by long-press. A dedicated type
/// (not a bare id) so the sheet only accepts handscroll drags.
class StagedMediaDragData {
  final String mediaId;

  const StagedMediaDragData(this.mediaId);
}
