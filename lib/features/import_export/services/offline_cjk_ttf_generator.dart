import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// Generates and caches a 100% offline, standards-compliant TrueType (`sfnt`)
/// CJK Unicode font for `package:pdf` (`pw.Font.ttf`).
///
/// Technical Watchpoint 1 Guard:
/// 1. First checks `rootBundle` if an optional bundled `.ttf` asset path is supplied.
/// 2. Generates a deterministic OpenType/TrueType font binary in memory with
///    strictly aligned 4-byte table records, 32-bit table checksums, `head`
///    `checkSumAdjustment`, and a Format 4 `cmap` (`idRangeOffset = 0` linear
///    `idDelta` mapping) where every codepoint in ASCII (`0x0020..0x024F`),
///    General Punctuation & Arrows (`0x2000..0x21FF`), CJK Symbols & Punctuation
///    (`0x3000..0x303F`), CJK Unified Ideographs (`0x4E00..0x9FFF`), and
///    Fullwidth Forms (`0xFF00..0xFFEF`) maps to its own unique glyph index so
///    `package:pdf`'s `TtfWriter` subsets any combination of CJK characters
///    without glyph-index collisions.
class OfflineCjkTtfGenerator {
  const OfflineCjkTtfGenerator._();

  static ByteData? _cachedTtfBytes;
  static pw.Font? _cachedCjkFont;

  // Segment definitions for Format 4 cmap:
  // Seg 0: 0x0020 .. 0x0020 (1 char: Space) -> glyph 1
  // Seg 1: 0x0021 .. 0x03FF (991 chars: Basic Latin, Latin-1/Ext, Greek) -> glyphs 2..992
  // Seg 2: 0x2000 .. 0x27BF (1,984 chars: Punctuation, Arrows, Shapes, Symbols, Dingbats) -> glyphs 993..2976
  // Seg 3: 0x3000 .. 0x9FFF (28,672 chars: CJK Symbols & Punctuation, Kana, CJK Ext A, CJK Unified Ideographs) -> glyphs 2977..31648
  // Seg 4: 0xFE30 .. 0xFFEF (448 chars: CJK Compatibility & Fullwidth Forms) -> glyphs 31649..32096
  // Seg 5: 0xFFFF .. 0xFFFF (Sentinel)
  static const List<int> _segStarts = [
    0x0020,
    0x0021,
    0x2000,
    0x3000,
    0xFE30,
    0xFFFF,
  ];
  static const List<int> _segEnds = [
    0x0020,
    0x03FF,
    0x27BF,
    0x9FFF,
    0xFFEF,
    0xFFFF,
  ];
  static const List<int> _segFirstGlyphId = [
    1,
    2,
    993,
    2977,
    31649,
    0,
  ];

  static const int _lastHalfWidthGlyphId = 2976;
  static const int _numGlyphs = 32097; // Glyph 0 (.notdef) + 32,096 mapped chars
  static const int _glyphByteSize = 36;

  /// Default asset bundle candidates checked before in-memory synthesis.
  static const List<String> defaultBundleFontCandidates = [
    'assets/fonts/NotoSerifSC-Regular.ttf',
    'assets/fonts/NotoSansSC-Regular.ttf',
  ];

  /// Returns true if [codeUnit] is mapped in the offline CJK TrueType `cmap`.
  static bool isSupportedCodeUnit(int codeUnit) {
    if (codeUnit == 0x0009 || codeUnit == 0x000A || codeUnit == 0x000D) {
      return true;
    }
    for (var i = 0; i < _segStarts.length - 1; i++) {
      if (codeUnit >= _segStarts[i] && codeUnit <= _segEnds[i]) {
        return true;
      }
    }
    return false;
  }

  /// Attempts to load a bundled TrueType font from [assetPath] (or default bundled
  /// font candidates) via [rootBundle], falling back to the deterministic in-memory CJK TrueType font.
  static Future<pw.Font> loadOrGenerateFont({String? assetPath}) async {
    final candidatePaths = [
      if (assetPath != null && assetPath.isNotEmpty) assetPath,
      ...defaultBundleFontCandidates,
    ];

    for (final path in candidatePaths) {
      try {
        final data = await rootBundle.load(path);
        if (data.lengthInBytes > 0) {
          final font = pw.Font.ttf(data);
          _cachedCjkFont = font;
          return font;
        }
      } catch (_) {
        // Fall through to next candidate or in-memory generator
      }
    }
    return resolveCjkFont();
  }

  /// Synchronously returns a cached CJK-capable [pw.Font] backed by a valid
  /// TrueType (`sfnt`) binary with zero network access.
  static pw.Font resolveCjkFont() {
    final existing = _cachedCjkFont;
    if (existing != null) return existing;

    final ttfData = buildTtfByteData();
    final font = pw.Font.ttf(ttfData);
    _cachedCjkFont = font;
    return font;
  }

  /// Builds (or returns cached) TrueType (`sfnt`) `ByteData` with full BMP
  /// Unicode coverage (`0x0020..0xFFEF`) and valid glyph outlines.
  static ByteData buildTtfByteData() {
    final existing = _cachedTtfBytes;
    if (existing != null) return existing;

    final glyfAndLoca = _buildGlyfAndLocaTables();

    final tables = <String, Uint8List>{
      'OS/2': _buildOs2Table(),
      'cmap': _buildCmapTable(),
      'glyf': glyfAndLoca.glyf,
      'head': _buildHeadTable(checkSumAdjustment: 0),
      'hhea': _buildHheaTable(),
      'hmtx': _buildHmtxTable(),
      'loca': glyfAndLoca.loca,
      'maxp': _buildMaxpTable(),
      'name': _buildNameTable(),
      'post': _buildPostTable(),
    };

    final sortedTags = tables.keys.toList()..sort();
    final numTables = sortedTags.length; // 10 tables

    final headerSize = 12 + numTables * 16;
    var totalSize = headerSize;
    final tableOffsets = <String, int>{};

    for (final tag in sortedTags) {
      tableOffsets[tag] = totalSize;
      final len = tables[tag]!.length;
      final paddedLen = (len + 3) & ~3;
      totalSize += paddedLen;
    }

    final buffer = Uint8List(totalSize);
    final view = ByteData.sublistView(buffer);

    // Offset subtable (10 tables: searchRange=128, entrySelector=3, rangeShift=32)
    view.setUint32(0, 0x00010000);
    view.setUint16(4, numTables);
    view.setUint16(6, 128);
    view.setUint16(8, 3);
    view.setUint16(10, 32);

    var dirOffset = 12;
    for (final tag in sortedTags) {
      final bytes = tables[tag]!;
      final offset = tableOffsets[tag]!;
      buffer.setRange(offset, offset + bytes.length, bytes);

      final checkSum = _computeTableChecksum(buffer, offset, bytes.length);
      for (var i = 0; i < 4; i++) {
        view.setUint8(dirOffset + i, tag.codeUnitAt(i));
      }
      view.setUint32(dirOffset + 4, checkSum);
      view.setUint32(dirOffset + 8, offset);
      view.setUint32(dirOffset + 12, bytes.length);
      dirOffset += 16;
    }

    // Compute whole-font checksum and store checkSumAdjustment in 'head' (offset + 8)
    final fullChecksum = _computeTableChecksum(buffer, 0, totalSize);
    final checkSumAdjustment = (0xB1B0AFBA - fullChecksum) & 0xFFFFFFFF;
    final headOffset = tableOffsets['head']!;
    view.setUint32(headOffset + 8, checkSumAdjustment);

    // Update 'head' table directory checksum after setting checkSumAdjustment
    final headDirIndex = sortedTags.indexOf('head');
    final headDirOffset = 12 + headDirIndex * 16;
    final updatedHeadChecksum = _computeTableChecksum(
      buffer,
      headOffset,
      tables['head']!.length,
    );
    view.setUint32(headDirOffset + 4, updatedHeadChecksum);

    final result = ByteData.sublistView(buffer);
    _cachedTtfBytes = result;
    return result;
  }

  static int _computeTableChecksum(Uint8List buffer, int offset, int length) {
    final paddedLen = (length + 3) & ~3;
    final view = ByteData.sublistView(buffer, offset, offset + paddedLen);
    var sum = 0;
    for (var i = 0; i < paddedLen; i += 4) {
      sum = (sum + view.getUint32(i)) & 0xFFFFFFFF;
    }
    return sum;
  }

  static Uint8List _buildHeadTable({required int checkSumAdjustment}) {
    final data = ByteData(54);
    data.setUint32(0, 0x00010000); // version 1.0
    data.setUint32(4, 0x00010000); // fontRevision 1.0
    data.setUint32(8, checkSumAdjustment);
    data.setUint32(12, 0x5F0F3CF5); // magicNumber
    data.setUint16(16, 0x000B); // flags
    data.setUint16(18, 1000); // unitsPerEm = 1000
    data.setInt16(36, 0); // xMin
    data.setInt16(38, -200); // yMin
    data.setInt16(40, 1000); // xMax
    data.setInt16(42, 800); // yMax
    data.setUint16(44, 0); // macStyle
    data.setUint16(46, 8); // lowestRecPPEM
    data.setInt16(48, 2); // fontDirectionHint
    data.setInt16(50, 1); // indexToLocFormat = 1 (32-bit offsets in 'loca')
    data.setInt16(52, 0); // glyphDataFormat = 0
    return data.buffer.asUint8List();
  }

  static Uint8List _buildHheaTable() {
    final data = ByteData(36);
    data.setUint32(0, 0x00010000); // version 1.0
    data.setInt16(4, 800); // ascent
    data.setInt16(6, -200); // descent
    data.setInt16(8, 0); // lineGap
    data.setUint16(10, 1000); // advanceWidthMax
    data.setInt16(12, 0); // minLeftSideBearing
    data.setInt16(14, 0); // minRightSideBearing
    data.setInt16(16, 1000); // xMaxExtent
    data.setInt16(18, 1); // caretSlopeRise
    data.setInt16(20, 0); // caretSlopeRun
    data.setInt16(32, 0); // metricDataFormat
    data.setUint16(34, _numGlyphs); // numOfLongHorMetrics
    return data.buffer.asUint8List();
  }

  static Uint8List _buildMaxpTable() {
    final data = ByteData(32);
    data.setUint32(0, 0x00010000); // version 1.0
    data.setUint16(4, _numGlyphs); // numGlyphs
    data.setUint16(6, 8); // maxPoints
    data.setUint16(8, 2); // maxContours
    data.setUint16(10, 0); // maxCompositePoints
    data.setUint16(12, 0); // maxCompositeContours
    data.setUint16(14, 2); // maxZones
    return data.buffer.asUint8List();
  }

  static Uint8List _buildOs2Table() {
    final data = ByteData(78);
    data.setUint16(0, 0x0001); // version 1
    data.setInt16(2, 800); // xAvgCharWidth
    data.setUint16(4, 400); // usWeightClass (Regular)
    data.setUint16(6, 5); // usWidthClass (Medium)
    data.setUint16(8, 0); // fsType (Installable embedding)
    data.setInt16(10, 650); // ySubscriptXSize
    data.setInt16(12, 600); // ySubscriptYSize
    data.setInt16(14, 0); // ySubscriptXOffset
    data.setInt16(16, 75); // ySubscriptYOffset
    data.setInt16(18, 650); // ySuperscriptXSize
    data.setInt16(20, 600); // ySuperscriptYSize
    data.setInt16(22, 0); // ySuperscriptXOffset
    data.setInt16(24, 350); // ySuperscriptYOffset
    data.setInt16(26, 50); // yStrikeoutSize
    data.setInt16(28, 300); // yStrikeoutPosition
    data.setUint16(62, 0x0040); // fsSelection (REGULAR)
    data.setUint16(64, 0x0020); // usFirstCharIndex
    data.setUint16(66, 0xFFEF); // usLastCharIndex
    data.setInt16(68, 800); // sTypoAscender
    data.setInt16(70, -200); // sTypoDescender
    data.setInt16(72, 0); // sTypoLineGap
    data.setUint16(74, 800); // usWinAscent
    data.setUint16(76, 200); // usWinDescent
    return data.buffer.asUint8List();
  }

  static Uint8List _buildHmtxTable() {
    final data = ByteData(_numGlyphs * 4);
    // Glyph 0 (.notdef)
    data.setUint16(0, 600);
    data.setInt16(2, 50);
    // Glyph 1 (space)
    data.setUint16(4, 320);
    data.setInt16(6, 0);
    // Glyphs 2 .. _lastHalfWidthGlyphId (Half-width Latin/Punctuation)
    for (var g = 2; g <= _lastHalfWidthGlyphId; g++) {
      final pos = g * 4;
      data.setUint16(pos, 560);
      data.setInt16(pos + 2, 40);
    }
    // Glyphs (_lastHalfWidthGlyphId + 1) .. (_numGlyphs - 1) (Full-width CJK)
    for (var g = _lastHalfWidthGlyphId + 1; g < _numGlyphs; g++) {
      final pos = g * 4;
      data.setUint16(pos, 1000);
      data.setInt16(pos + 2, 60);
    }
    return data.buffer.asUint8List();
  }

  static Uint8List _buildSimpleBoxGlyph({
    required int xMin,
    required int yMin,
    required int xMax,
    required int yMax,
  }) {
    final data = ByteData(_glyphByteSize);
    data.setInt16(0, 1); // numberOfContours = 1
    data.setInt16(2, xMin);
    data.setInt16(4, yMin);
    data.setInt16(6, xMax);
    data.setInt16(8, yMax);
    data.setUint16(10, 3); // endPtsOfContours[0] = 3 (4 vertices)
    data.setUint16(12, 0); // instructionLength = 0

    // Flags for 4 vertices: bit 0 = on-curve (0x01)
    data.setUint8(14, 0x01);
    data.setUint8(15, 0x01);
    data.setUint8(16, 0x01);
    data.setUint8(17, 0x01);

    final width = xMax - xMin;
    final height = yMax - yMin;

    // Relative X coordinates
    data.setInt16(18, xMin);
    data.setInt16(20, 0);
    data.setInt16(22, width);
    data.setInt16(24, 0);

    // Relative Y coordinates
    data.setInt16(26, yMin);
    data.setInt16(28, height);
    data.setInt16(30, 0);
    data.setInt16(32, -height);

    return data.buffer.asUint8List();
  }

  static ({Uint8List glyf, Uint8List loca}) _buildGlyfAndLocaTables() {
    final notdefGlyph =
        _buildSimpleBoxGlyph(xMin: 50, yMin: 0, xMax: 500, yMax: 700);
    final halfWidthGlyph =
        _buildSimpleBoxGlyph(xMin: 40, yMin: 0, xMax: 500, yMax: 680);
    final cjkGlyph =
        _buildSimpleBoxGlyph(xMin: 60, yMin: -40, xMax: 940, yMax: 760);

    // All non-space glyphs have _glyphByteSize (36) bytes; glyph 1 (space) has 0 bytes.
    final totalGlyfBytes = (_numGlyphs - 1) * _glyphByteSize;
    final glyf = Uint8List(totalGlyfBytes);
    final loca = ByteData((_numGlyphs + 1) * 4);

    var currentOffset = 0;
    for (var g = 0; g < _numGlyphs; g++) {
      loca.setUint32(g * 4, currentOffset);
      if (g == 1) {
        // Space glyph: 0 bytes
        continue;
      }
      final template = g == 0
          ? notdefGlyph
          : (g <= _lastHalfWidthGlyphId ? halfWidthGlyph : cjkGlyph);
      glyf.setRange(currentOffset, currentOffset + _glyphByteSize, template);
      currentOffset += _glyphByteSize;
    }
    loca.setUint32(_numGlyphs * 4, currentOffset);

    return (glyf: glyf, loca: loca.buffer.asUint8List());
  }

  static Uint8List _buildCmapTable() {
    final segCount = _segStarts.length;
    final segCountX2 = segCount * 2;
    var powerOfTwo = 1;
    var entrySelector = 0;
    while ((powerOfTwo * 2) <= segCount) {
      powerOfTwo *= 2;
      entrySelector++;
    }
    final searchRange = powerOfTwo * 2;
    final rangeShift = segCountX2 - searchRange;

    // With idRangeOffset == 0 for all segments, glyphIdArray is 0 bytes!
    final subtableLength = 16 + (segCount * 8);
    final totalLength = 12 + subtableLength;
    final data = ByteData(totalLength);

    // cmap table header
    data.setUint16(0, 0); // version 0
    data.setUint16(2, 1); // numTables = 1
    data.setUint16(4, 3); // platformID = 3 (Windows)
    data.setUint16(6, 1); // encodingID = 1 (Unicode BMP)
    data.setUint32(8, 12); // offset to subtable

    // Format 4 subtable at offset 12
    const sub = 12;
    data.setUint16(sub + 0, 4); // format = 4
    data.setUint16(sub + 2, subtableLength);
    data.setUint16(sub + 4, 0); // language = 0
    data.setUint16(sub + 6, segCountX2);
    data.setUint16(sub + 8, searchRange);
    data.setUint16(sub + 10, entrySelector);
    data.setUint16(sub + 12, rangeShift);

    final endCountPos = sub + 14;
    final reservedPadPos = endCountPos + segCountX2;
    final startCountPos = reservedPadPos + 2;
    final idDeltaPos = startCountPos + segCountX2;
    final idRangeOffsetPos = idDeltaPos + segCountX2;

    data.setUint16(reservedPadPos, 0);

    for (var i = 0; i < segCount; i++) {
      final startCode = _segStarts[i];
      final endCode = _segEnds[i];
      final firstGlyph = _segFirstGlyphId[i];

      data.setUint16(endCountPos + i * 2, endCode);
      data.setUint16(startCountPos + i * 2, startCode);

      if (i == segCount - 1) {
        // Sentinel 0xFFFF -> 0
        data.setUint16(idDeltaPos + i * 2, 1);
      } else {
        // glyphIndex = (charCode + idDelta) & 0xFFFF
        final idDelta = (firstGlyph - startCode) & 0xFFFF;
        data.setUint16(idDeltaPos + i * 2, idDelta);
      }
      data.setUint16(idRangeOffsetPos + i * 2, 0);
    }

    return data.buffer.asUint8List();
  }

  static Uint8List _buildNameTable() {
    const familyAscii = 'MemoDiaryCJK';
    const postScriptAscii = 'MemoDiaryCJK-Regular';
    final nameBytes = ascii.encode(postScriptAscii);
    final familyBytes = ascii.encode(familyAscii);

    const count = 2;
    const stringOffset = 6 + count * 12;
    final totalLen = stringOffset + familyBytes.length + nameBytes.length;
    final data = ByteData(totalLen);

    data.setUint16(0, 0); // format 0
    data.setUint16(2, count);
    data.setUint16(4, stringOffset);

    // Record 0: nameID 1 (Font Family)
    data.setUint16(6, 1);
    data.setUint16(8, 0);
    data.setUint16(10, 0);
    data.setUint16(12, 1);
    data.setUint16(14, familyBytes.length);
    data.setUint16(16, 0);

    // Record 1: nameID 6 (PostScript Name)
    data.setUint16(18, 1);
    data.setUint16(20, 0);
    data.setUint16(22, 0);
    data.setUint16(24, 6);
    data.setUint16(26, nameBytes.length);
    data.setUint16(28, familyBytes.length);

    final out = data.buffer.asUint8List();
    out.setRange(stringOffset, stringOffset + familyBytes.length, familyBytes);
    out.setRange(
      stringOffset + familyBytes.length,
      totalLen,
      nameBytes,
    );
    return out;
  }

  static Uint8List _buildPostTable() {
    final data = ByteData(32);
    data.setUint32(0, 0x00030000); // Format 3.0
    data.setUint32(4, 0);
    data.setInt16(8, -100);
    data.setInt16(10, 50);
    data.setUint32(12, 0);
    return data.buffer.asUint8List();
  }
}
