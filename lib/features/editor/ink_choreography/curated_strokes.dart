/// STUB: minimal curated strokes ported from the studio prototype. The full
/// Latin/digit/punctuation table replaces this file at merge.
///
/// char -> strokes -> points `[x, y]`, ints in `0..100` (cap height 16..84,
/// x-height top about 42, baseline 84, descenders about 96).
const Map<String, List<List<List<int>>>> curatedStrokes = {
  'A': [
    [
      [50, 15],
      [40, 36],
      [18, 85],
    ],
    [
      [50, 15],
      [60, 36],
      [82, 85],
    ],
    [
      [30, 60],
      [50, 58],
      [70, 60],
    ],
  ],
  'E': [
    [
      [28, 16],
      [27, 50],
      [28, 84],
    ],
    [
      [28, 18],
      [52, 16],
      [76, 17],
    ],
    [
      [28, 49],
      [48, 48],
      [68, 49],
    ],
    [
      [28, 82],
      [54, 83],
      [79, 81],
    ],
  ],
  'e': [
    [
      [24, 54],
      [74, 52],
      [72, 36],
      [58, 27],
      [46, 26],
      [26, 36],
      [22, 62],
      [32, 78],
      [48, 82],
      [68, 76],
    ],
  ],
  '。': [
    [
      [46, 66],
      [38, 68],
      [38, 78],
      [46, 82],
      [54, 78],
      [54, 68],
      [46, 66],
    ],
  ],
  '，': [
    [
      [48, 66],
      [51, 76],
      [38, 88],
    ],
  ],
};
