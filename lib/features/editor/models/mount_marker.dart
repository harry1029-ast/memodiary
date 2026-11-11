import 'dart:math' as math;
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

  /// Whether [delta] contains any non-whitespace character or non-marker inline embed.
  static bool hasVisibleContent(Delta delta) {
    for (final operation in delta.operations) {
      if (!operation.isInsert || mediaIdOf(operation) != null) continue;
      final data = operation.data;
      if (data is String) {
        if (data.trim().isNotEmpty) return true;
      } else {
        return true;
      }
    }
    return false;
  }

  /// Whether the character/embed at [offset] in [delta] is a mount marker.
  static bool isMarkerAt(Delta delta, int offset) => consecutiveMarkersAt(delta, offset) > 0;

  /// Counts how many consecutive mount marker embeds begin at [offset] in [delta].
  static int consecutiveMarkersAt(Delta delta, int offset) {
    if (offset < 0) return 0;
    var current = 0;
    var count = 0;
    var counting = false;
    for (final op in delta.operations) {
      if (!op.isInsert) continue;
      final len = op.length ?? 0;
      if (!counting) {
        if (offset >= current && offset < current + len) {
          if (mediaIdOf(op) != null) {
            counting = true;
            count += len;
          } else {
            return 0;
          }
        }
      } else {
        if (mediaIdOf(op) != null) {
          count += len;
        } else {
          break;
        }
      }
      current += len;
    }
    return count;
  }

  /// Finds the offset of the nearest non-marker character strictly before [offset],
  /// or null if no non-marker character precedes [offset].
  static int? prevNonMarkerOffset(Delta delta, int offset) {
    if (offset <= 0) return null;
    int? target;
    var current = 0;
    for (final op in delta.operations) {
      if (!op.isInsert) continue;
      final len = op.length ?? 0;
      if (current >= offset) break;
      if (mediaIdOf(op) == null) {
        final available = math.min(len, offset - current);
        if (available > 0) {
          target = current + available - 1;
        }
      }
      current += len;
    }
    return target;
  }

  /// Finds the offset at which a newly mounted item should be anchored: immediately
  /// after the last non-newline text character or content embed and any attached mount markers,
  /// before any trailing empty newlines. If the Delta contains no text or content (only
  /// newlines and markers), returns immediately after any existing markers at offset 0.
  static int endOfTextOffset(Delta delta) {
    var current = 0;
    int? lastContentEndOffset;

    for (final op in delta.operations) {
      if (!op.isInsert) continue;
      final data = op.data;
      final len = op.length ?? 0;

      if (mediaIdOf(op) == null) {
        if (data is String) {
          final text = data;
          var lastNonNewline = -1;
          for (int i = text.length - 1; i >= 0; i--) {
            if (text[i] != '\n') {
              lastNonNewline = i;
              break;
            }
          }
          if (lastNonNewline != -1) {
            lastContentEndOffset = current + lastNonNewline + 1;
          }
        } else {
          // Content embeds (e.g. inline image, divider) are non-newline content.
          lastContentEndOffset = current + len;
        }
      }
      current += len;
    }

    if (lastContentEndOffset != null) {
      return lastContentEndOffset + consecutiveMarkersAt(delta, lastContentEndOffset);
    }

    return consecutiveMarkersAt(delta, 0);
  }
}
