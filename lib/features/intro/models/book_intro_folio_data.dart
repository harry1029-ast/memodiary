/// Immutable contextual metadata rendered on the right folio of the
/// classical thread-bound book spread.
class BookIntroFolioData {
  final String lunarDateText;
  final String travelTripTitle;
  final String travelRouteSummary;
  final String travelDestinationTag;

  const BookIntroFolioData({
    this.lunarDateText = '十月廿八',
    this.travelTripTitle = '江南烟雨行',
    this.travelRouteSummary = '杭州 → 乌镇 → 苏州',
    this.travelDestinationTag = '江南',
  });

  BookIntroFolioData copyWith({
    String? lunarDateText,
    String? travelTripTitle,
    String? travelRouteSummary,
    String? travelDestinationTag,
  }) {
    return BookIntroFolioData(
      lunarDateText: lunarDateText ?? this.lunarDateText,
      travelTripTitle: travelTripTitle ?? this.travelTripTitle,
      travelRouteSummary: travelRouteSummary ?? this.travelRouteSummary,
      travelDestinationTag: travelDestinationTag ?? this.travelDestinationTag,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookIntroFolioData &&
          runtimeType == other.runtimeType &&
          lunarDateText == other.lunarDateText &&
          travelTripTitle == other.travelTripTitle &&
          travelRouteSummary == other.travelRouteSummary &&
          travelDestinationTag == other.travelDestinationTag;

  @override
  int get hashCode => Object.hash(
        lunarDateText,
        travelTripTitle,
        travelRouteSummary,
        travelDestinationTag,
      );
}

