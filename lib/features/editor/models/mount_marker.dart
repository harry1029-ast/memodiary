import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

/// The invisible, zero-height inline embed (`{"mount": "<attachmentId>"}`) that
/// anchors a mounted photo or video to the passage of text it was mounted beside
/// (ADR-0009). The Delta is the single source of truth for mounting: an
/// attachment is mounted if and only if a marker references it.
class MountMarker {
  const MountMarker._();

  /// Delta embed key for mount markers.
  static const String embedType = 'mount';

  /// Quill embeddable inserting a marker that references [mediaId].
  static Embeddable embeddable(String mediaId) => Embeddable(embedType, mediaId);

  /// The referenced attachment id when [operation] is a mount marker insert, else null.
  static String? mediaIdOf(Operation operation) {
    if (!operation.isInsert) return null;
    final data = operation.data;
    if (data is Map && data.containsKey(embedType)) {
      return data[embedType]?.toString();
    }
    return null;
  }

  /// Referenced attachment ids in document order.
  static List<String> mediaIdsIn(Delta delta) {
    final ids = <String>[];
    for (final operation in delta.operations) {
      final mediaId = mediaIdOf(operation);
      if (mediaId != null) ids.add(mediaId);
    }
    return ids;
  }

  /// A copy of [delta] with every mount marker removed.
  static Delta strip(Delta delta) {
    final stripped = Delta();
    for (final operation in delta.operations) {
      if (mediaIdOf(operation) == null) stripped.push(operation);
    }
    return stripped;
  }
}
