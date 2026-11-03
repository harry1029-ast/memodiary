/// Models and definitions for the Paper Heart Framing visual prototype.
///
/// Explores three structural solutions to eliminate the small floating box
/// and dead whitespace void in EntryEditorScreen when the keyboard is dismissed.
enum PaperFramingVariant {
  /// Option A: Tactile Stationery Card (信笺台面卡片)
  /// Physical writing desk metaphor with a distinct elevated paper sheet,
  /// soft drop shadows, and top-anchored 14-row stationery card.
  variantA,

  /// Option B: Dynamic Breathing Stride (自适应呼吸行距)
  /// Maintains 1:1 Folio parity with fixed 14 rows, but dynamically expands
  /// the line stride (24px -> 38-42px) to elegantly frame the full screen
  /// when the keyboard is dismissed.
  variantB,

  /// Option C: Screen-Adaptive Row Capacity (屏幕全高满版)
  /// Expands innerFrameRect vertically to fill the entire device viewport
  /// (26-28 rows), maximizing writing space with scrollable viewport.
  variantC,
}

extension PaperFramingVariantExtension on PaperFramingVariant {
  String get keyName {
    switch (this) {
      case PaperFramingVariant.variantA:
        return 'A';
      case PaperFramingVariant.variantB:
        return 'B';
      case PaperFramingVariant.variantC:
        return 'C';
    }
  }

  String get title {
    switch (this) {
      case PaperFramingVariant.variantA:
        return '触感信笺 (Desk Card)';
      case PaperFramingVariant.variantB:
        return '呼吸行高 (Breathing Stride)';
      case PaperFramingVariant.variantC:
        return '全高满版 (Full Height)';
    }
  }

  String get shortSummary {
    switch (this) {
      case PaperFramingVariant.variantA:
        return '书案台面与微立体物理信笺卡片，维持14行版心，温润真实';
      case PaperFramingVariant.variantB:
        return '行距随视口弹性呼吸(24~40px)，收起键盘铺满屏幕，保持14行对齐';
      case PaperFramingVariant.variantC:
        return '纵向完全铺满屏幕(~26-28行)，输入区域最大化，视口平滑跟随';
    }
  }

  PaperFramingVariant get previous {
    switch (this) {
      case PaperFramingVariant.variantA:
        return PaperFramingVariant.variantC;
      case PaperFramingVariant.variantB:
        return PaperFramingVariant.variantA;
      case PaperFramingVariant.variantC:
        return PaperFramingVariant.variantB;
    }
  }

  PaperFramingVariant get next {
    switch (this) {
      case PaperFramingVariant.variantA:
        return PaperFramingVariant.variantB;
      case PaperFramingVariant.variantB:
        return PaperFramingVariant.variantC;
      case PaperFramingVariant.variantC:
        return PaperFramingVariant.variantA;
    }
  }
}
