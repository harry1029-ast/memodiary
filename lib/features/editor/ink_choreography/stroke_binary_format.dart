import 'dart:convert';
import 'dart:typed_data';

/// Strokes of one character: strokes -> points -> `[x, y]` in the `0..100` box.
typedef StrokeSet = List<List<List<int>>>;

const int _headerBytes = 8;
const int _indexEntryBytes = 8;
const int _formatVersion = 1;
const List<int> _magic = [0x4D, 0x44, 0x53, 0x54]; // ASCII "MDST"

/// Serializes [entries] (code point -> strokes, any order) into the `MDST`
/// version 1 little-endian format. Output is deterministic.
///
/// Format: 8-byte header (`MDST`, uint16 version, uint16 count), then
/// `count * 8` index bytes (uint32 code point ascending, uint32 payload
/// offset), then the payload (uint8 strokeCount, per stroke uint8 pointCount
/// and `pointCount * (uint8 x, uint8 y)`).
Uint8List encodeStrokeTable(Map<int, StrokeSet> entries) {
  final codePoints = entries.keys.toList()..sort();
  final payload = BytesBuilder(copy: false);
  final offsets = <int>[];
  for (final codePoint in codePoints) {
    offsets.add(payload.length);
    final strokes = entries[codePoint]!;
    payload.addByte(strokes.length);
    for (final stroke in strokes) {
      payload.addByte(stroke.length);
      for (final point in stroke) {
        payload.addByte(point[0]);
        payload.addByte(point[1]);
      }
    }
  }

  final payloadBytes = payload.toBytes();
  final total =
      _headerBytes + codePoints.length * _indexEntryBytes + payloadBytes.length;
  final out = Uint8List(total);
  final view = ByteData.sublistView(out);
  out.setRange(0, 4, _magic);
  view.setUint16(4, _formatVersion, Endian.little);
  view.setUint16(6, codePoints.length, Endian.little);
  for (var slot = 0; slot < codePoints.length; slot++) {
    final at = _headerBytes + slot * _indexEntryBytes;
    view.setUint32(at, codePoints[slot], Endian.little);
    view.setUint32(at + 4, offsets[slot], Endian.little);
  }
  out.setRange(
    _headerBytes + codePoints.length * _indexEntryBytes,
    total,
    payloadBytes,
  );
  return out;
}

/// Validated, read-only view over an `MDST` buffer with `O(log N)` lookup.
class HanziStrokeBinary {
  HanziStrokeBinary._(this._data, this.count, this._payloadStart);

  final ByteData _data;
  final int _payloadStart;

  /// Number of indexed characters.
  final int count;

  /// Validates magic, version, size and strictly ascending index, or throws a
  /// [FormatException].
  factory HanziStrokeBinary.parse(ByteData data) {
    if (data.lengthInBytes < _headerBytes) {
      throw const FormatException('Stroke table is truncated');
    }
    for (var at = 0; at < _magic.length; at++) {
      if (data.getUint8(at) != _magic[at]) {
        throw const FormatException('Stroke table has bad magic');
      }
    }
    final version = data.getUint16(4, Endian.little);
    if (version != _formatVersion) {
      throw FormatException('Unsupported stroke table version $version');
    }
    final count = data.getUint16(6, Endian.little);
    final payloadStart = _headerBytes + count * _indexEntryBytes;
    if (data.lengthInBytes < payloadStart) {
      throw const FormatException('Stroke table index is truncated');
    }
    var previous = -1;
    for (var slot = 0; slot < count; slot++) {
      final at = _headerBytes + slot * _indexEntryBytes;
      final codePoint = data.getUint32(at, Endian.little);
      final offset = data.getUint32(at + 4, Endian.little);
      if (codePoint <= previous) {
        throw const FormatException('Stroke table index is not ascending');
      }
      if (payloadStart + offset >= data.lengthInBytes) {
        throw const FormatException('Stroke table offset is out of range');
      }
      previous = codePoint;
    }
    return HanziStrokeBinary._(data, count, payloadStart);
  }

  /// Strokes for [codePoint], or null when it is not indexed.
  StrokeSet? lookup(int codePoint) {
    var low = 0;
    var high = count - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final at = _headerBytes + mid * _indexEntryBytes;
      final candidate = _data.getUint32(at, Endian.little);
      if (candidate == codePoint) {
        return _decode(_payloadStart + _data.getUint32(at + 4, Endian.little));
      }
      if (candidate < codePoint) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return null;
  }

  StrokeSet _decode(int start) {
    var cursor = start;
    final strokeCount = _data.getUint8(cursor++);
    final strokes = <List<List<int>>>[];
    for (var strokeIndex = 0; strokeIndex < strokeCount; strokeIndex++) {
      final pointCount = _data.getUint8(cursor++);
      final points = <List<int>>[];
      for (var pointIndex = 0; pointIndex < pointCount; pointIndex++) {
        points.add([_data.getUint8(cursor), _data.getUint8(cursor + 1)]);
        cursor += 2;
      }
      strokes.add(points);
    }
    return strokes;
  }
}

/// Parses one `graphics.txt` JSON line into (character, raw medians), or null
/// when the line is blank.
({String character, List<List<List<num>>> medians})? parseGraphicsLine(
  String line,
) {
  if (line.trim().isEmpty) return null;
  final json = jsonDecode(line) as Map<String, dynamic>;
  final medians = [
    for (final stroke in json['medians'] as List<dynamic>)
      [
        for (final point in stroke as List<dynamic>)
          [for (final value in point as List<dynamic>) value as num],
      ],
  ];
  return (character: json['character'] as String, medians: medians);
}
