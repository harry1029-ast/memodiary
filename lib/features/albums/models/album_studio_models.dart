import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Supported types of interactive scrapbook overlay elements on a page canvas.
enum OverlayElementType {
  sticker,
  text,
  datePill,
  sealStamp;

  String toJson() => name;

  static OverlayElementType fromJson(String? raw) {
    for (final candidate in OverlayElementType.values) {
      if (candidate.name == raw) {
        return candidate;
      }
    }
    return OverlayElementType.sticker;
  }
}

/// Assignment of a sandboxed [AlbumPhoto] to a specific geometric slot on a page,
/// including non-destructive pan and zoom crop adjustments.
@immutable
class PhotoSlotAssignment {
  final int slotIndex;
  final String photoId;
  final double panOffsetX;
  final double panOffsetY;
  final double zoomScale;

  const PhotoSlotAssignment({
    required this.slotIndex,
    required this.photoId,
    this.panOffsetX = 0.0,
    this.panOffsetY = 0.0,
    this.zoomScale = 1.0,
  });

  PhotoSlotAssignment copyWith({
    int? slotIndex,
    String? photoId,
    double? panOffsetX,
    double? panOffsetY,
    double? zoomScale,
  }) {
    return PhotoSlotAssignment(
      slotIndex: slotIndex ?? this.slotIndex,
      photoId: photoId ?? this.photoId,
      panOffsetX: panOffsetX ?? this.panOffsetX,
      panOffsetY: panOffsetY ?? this.panOffsetY,
      zoomScale: zoomScale ?? this.zoomScale,
    );
  }

  Map<String, dynamic> toJson() => {
        'slotIndex': slotIndex,
        'photoId': photoId,
        'panOffsetX': panOffsetX,
        'panOffsetY': panOffsetY,
        'zoomScale': zoomScale,
      };

  factory PhotoSlotAssignment.fromJson(Map<String, dynamic> json) {
    return PhotoSlotAssignment(
      slotIndex: (json['slotIndex'] as num?)?.toInt() ?? 0,
      photoId: json['photoId'] as String? ?? '',
      panOffsetX: (json['panOffsetX'] as num?)?.toDouble() ?? 0.0,
      panOffsetY: (json['panOffsetY'] as num?)?.toDouble() ?? 0.0,
      zoomScale: (json['zoomScale'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoSlotAssignment &&
          other.slotIndex == slotIndex &&
          other.photoId == photoId &&
          other.panOffsetX == panOffsetX &&
          other.panOffsetY == panOffsetY &&
          other.zoomScale == zoomScale);

  @override
  int get hashCode => Object.hash(
        slotIndex,
        photoId,
        panOffsetX,
        panOffsetY,
        zoomScale,
      );
}

/// Visual background configuration for an individual scrapbook page.
@immutable
class PageBackgroundConfig {
  final int backgroundColorArgb;
  final int textColorArgb;
  final String? graphicPatternId;

  const PageBackgroundConfig({
    this.backgroundColorArgb = 0xFFFCF9F2,
    this.textColorArgb = 0xFF1E1E1E,
    this.graphicPatternId,
  });

  PageBackgroundConfig copyWith({
    int? backgroundColorArgb,
    int? textColorArgb,
    String? graphicPatternId,
    bool clearGraphicPattern = false,
  }) {
    return PageBackgroundConfig(
      backgroundColorArgb: backgroundColorArgb ?? this.backgroundColorArgb,
      textColorArgb: textColorArgb ?? this.textColorArgb,
      graphicPatternId: clearGraphicPattern
          ? null
          : (graphicPatternId ?? this.graphicPatternId),
    );
  }

  Map<String, dynamic> toJson() => {
        'backgroundColorArgb': backgroundColorArgb,
        'textColorArgb': textColorArgb,
        'graphicPatternId': graphicPatternId,
      };

  factory PageBackgroundConfig.fromJson(Map<String, dynamic> json) {
    return PageBackgroundConfig(
      backgroundColorArgb:
          (json['backgroundColorArgb'] as num?)?.toInt() ?? 0xFFFCF9F2,
      textColorArgb: (json['textColorArgb'] as num?)?.toInt() ?? 0xFF1E1E1E,
      graphicPatternId: json['graphicPatternId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageBackgroundConfig &&
          other.backgroundColorArgb == backgroundColorArgb &&
          other.textColorArgb == textColorArgb &&
          other.graphicPatternId == graphicPatternId);

  @override
  int get hashCode => Object.hash(
        backgroundColorArgb,
        textColorArgb,
        graphicPatternId,
      );
}

/// Freely positionable scrapbook element (sticker, text label, date pill, or cinnabar seal)
/// rendered on top of the page layout.
@immutable
class PageOverlayElement {
  final String id;
  final OverlayElementType type;
  final String content;

  /// Normalized horizontal center coordinate (`0.0..1.0`).
  final double dx;

  /// Normalized vertical center coordinate (`0.0..1.0`).
  final double dy;

  /// Relative scale multiplier (default `1.0`).
  final double scale;

  /// Clockwise rotation in radians (default `0.0`).
  final double rotation;

  /// Explicit stacking order on the page canvas.
  final int zIndex;

  /// Optional ARGB tint or text color override.
  final int? colorArgb;

  const PageOverlayElement({
    required this.id,
    required this.type,
    required this.content,
    this.dx = 0.5,
    this.dy = 0.5,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.zIndex = 0,
    this.colorArgb,
  });

  PageOverlayElement copyWith({
    String? id,
    OverlayElementType? type,
    String? content,
    double? dx,
    double? dy,
    double? scale,
    double? rotation,
    int? zIndex,
    int? colorArgb,
    bool clearColor = false,
  }) {
    return PageOverlayElement(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      colorArgb: clearColor ? null : (colorArgb ?? this.colorArgb),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toJson(),
        'content': content,
        'dx': dx,
        'dy': dy,
        'scale': scale,
        'rotation': rotation,
        'zIndex': zIndex,
        'colorArgb': colorArgb,
      };

  factory PageOverlayElement.fromJson(Map<String, dynamic> json) {
    return PageOverlayElement(
      id: json['id'] as String? ?? '',
      type: OverlayElementType.fromJson(json['type'] as String?),
      content: json['content'] as String? ?? '',
      dx: (json['dx'] as num?)?.toDouble() ?? 0.5,
      dy: (json['dy'] as num?)?.toDouble() ?? 0.5,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      colorArgb: (json['colorArgb'] as num?)?.toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageOverlayElement &&
          other.id == id &&
          other.type == type &&
          other.content == content &&
          other.dx == dx &&
          other.dy == dy &&
          other.scale == scale &&
          other.rotation == rotation &&
          other.zIndex == zIndex &&
          other.colorArgb == colorArgb);

  @override
  int get hashCode => Object.hash(
        id,
        type,
        content,
        dx,
        dy,
        scale,
        rotation,
        zIndex,
        colorArgb,
      );
}

/// Complete state of a single page inside a DIY photobook studio document.
@immutable
class AlbumPageModel {
  final String id;
  final int pageNumber;
  final String layoutTemplateId;
  final List<PhotoSlotAssignment> photoSlots;
  final PageBackgroundConfig backgroundConfig;
  final List<PageOverlayElement> overlays;
  final String? dateHeaderText;

  AlbumPageModel({
    required this.id,
    required this.pageNumber,
    required this.layoutTemplateId,
    List<PhotoSlotAssignment> photoSlots = const [],
    this.backgroundConfig = const PageBackgroundConfig(),
    List<PageOverlayElement> overlays = const [],
    this.dateHeaderText,
  })  : photoSlots = List<PhotoSlotAssignment>.unmodifiable(photoSlots),
        overlays = List<PageOverlayElement>.unmodifiable(overlays);

  AlbumPageModel copyWith({
    String? id,
    int? pageNumber,
    String? layoutTemplateId,
    List<PhotoSlotAssignment>? photoSlots,
    PageBackgroundConfig? backgroundConfig,
    List<PageOverlayElement>? overlays,
    String? dateHeaderText,
    bool clearDateHeader = false,
  }) {
    return AlbumPageModel(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      layoutTemplateId: layoutTemplateId ?? this.layoutTemplateId,
      photoSlots: photoSlots ?? this.photoSlots,
      backgroundConfig: backgroundConfig ?? this.backgroundConfig,
      overlays: overlays ?? this.overlays,
      dateHeaderText:
          clearDateHeader ? null : (dateHeaderText ?? this.dateHeaderText),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pageNumber': pageNumber,
        'layoutTemplateId': layoutTemplateId,
        'photoSlots': photoSlots.map((slot) => slot.toJson()).toList(),
        'backgroundConfig': backgroundConfig.toJson(),
        'overlays': overlays.map((overlay) => overlay.toJson()).toList(),
        'dateHeaderText': dateHeaderText,
      };

  factory AlbumPageModel.fromJson(Map<String, dynamic> json) {
    final rawSlots = (json['photoSlots'] as List<dynamic>? ?? [])
        .map((item) =>
            PhotoSlotAssignment.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    final rawOverlays = (json['overlays'] as List<dynamic>? ?? [])
        .map((item) =>
            PageOverlayElement.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    final bgRaw = json['backgroundConfig'];
    final bgConfig = bgRaw is Map
        ? PageBackgroundConfig.fromJson(Map<String, dynamic>.from(bgRaw))
        : const PageBackgroundConfig();

    return AlbumPageModel(
      id: json['id'] as String? ?? '',
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      layoutTemplateId:
          json['layoutTemplateId'] as String? ?? 'solo_full_bleed',
      photoSlots: rawSlots,
      backgroundConfig: bgConfig,
      overlays: rawOverlays,
      dateHeaderText: json['dateHeaderText'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlbumPageModel &&
          other.id == id &&
          other.pageNumber == pageNumber &&
          other.layoutTemplateId == layoutTemplateId &&
          listEquals(other.photoSlots, photoSlots) &&
          other.backgroundConfig == backgroundConfig &&
          listEquals(other.overlays, overlays) &&
          other.dateHeaderText == dateHeaderText);

  @override
  int get hashCode => Object.hash(
        id,
        pageNumber,
        layoutTemplateId,
        Object.hashAll(photoSlots),
        backgroundConfig,
        Object.hashAll(overlays),
        dateHeaderText,
      );
}

/// Root document persisted as `studio_layout_json` inside `album_collections`.
@immutable
class AlbumStudioDocument {
  final List<AlbumPageModel> pages;

  /// Photo IDs temporarily removed from pages and held in the "Removed" holding tray.
  final List<String> removedPhotoIds;

  /// Most-recently-used background colors (ARGB ints, capped at 8).
  final List<int> recentBackgroundColors;

  /// Active book theme identifier (`'shanshui_ink'`, `'jardin'`, `'abstract_blue'`, `'day_at_beach'`, `'playful_rainbow'`).
  final String activeThemeId;

  AlbumStudioDocument({
    List<AlbumPageModel> pages = const [],
    List<String> removedPhotoIds = const [],
    List<int> recentBackgroundColors = const [],
    this.activeThemeId = 'shanshui_ink',
  })  : pages = List<AlbumPageModel>.unmodifiable(pages),
        removedPhotoIds = List<String>.unmodifiable(removedPhotoIds),
        recentBackgroundColors =
            List<int>.unmodifiable(recentBackgroundColors);

  AlbumStudioDocument copyWith({
    List<AlbumPageModel>? pages,
    List<String>? removedPhotoIds,
    List<int>? recentBackgroundColors,
    String? activeThemeId,
  }) {
    return AlbumStudioDocument(
      pages: pages ?? this.pages,
      removedPhotoIds: removedPhotoIds ?? this.removedPhotoIds,
      recentBackgroundColors:
          recentBackgroundColors ?? this.recentBackgroundColors,
      activeThemeId: activeThemeId ?? this.activeThemeId,
    );
  }

  Map<String, dynamic> toJson() => {
        'pages': pages.map((page) => page.toJson()).toList(),
        'removedPhotoIds': removedPhotoIds,
        'recentBackgroundColors': recentBackgroundColors,
        'activeThemeId': activeThemeId,
      };

  String toJsonString() => jsonEncode(toJson());

  /// Collects all non-empty photo IDs referenced across all page photo slots.
  Set<String> collectReferencedPhotoIds() {
    final ids = <String>{};
    for (final page in pages) {
      for (final slot in page.photoSlots) {
        final id = slot.photoId.trim();
        if (id.isNotEmpty) {
          ids.add(id);
        }
      }
    }
    return ids;
  }

  /// Reconciles this document against [currentPhotoIds] existing in the database:
  /// 1. Prunes deleted photos from all pages and [removedPhotoIds].
  /// 2. Automatically places any newly added photos into [removedPhotoIds]
  ///    so they are immediately available in the studio holding tray.
  AlbumStudioDocument reconcileWithPhotoIds(Iterable<String> currentPhotoIds) {
    final validIds = currentPhotoIds.toSet();
    final updatedPages = <AlbumPageModel>[];
    final activePlacedIds = <String>{};

    for (final page in pages) {
      final validSlots = <PhotoSlotAssignment>[];
      for (final slot in page.photoSlots) {
        if (validIds.contains(slot.photoId)) {
          validSlots.add(slot.copyWith(slotIndex: validSlots.length));
          activePlacedIds.add(slot.photoId);
        }
      }

      updatedPages.add(
        page.copyWith(
          photoSlots: validSlots,
        ),
      );
    }

    final updatedRemoved = <String>[];
    for (final id in removedPhotoIds) {
      if (validIds.contains(id) &&
          !activePlacedIds.contains(id) &&
          !updatedRemoved.contains(id)) {
        updatedRemoved.add(id);
      }
    }

    for (final id in currentPhotoIds) {
      if (!activePlacedIds.contains(id) && !updatedRemoved.contains(id)) {
        updatedRemoved.add(id);
      }
    }

    return copyWith(
      pages: updatedPages,
      removedPhotoIds: updatedRemoved,
    );
  }

  /// Partitions the document's pages into facing photobook spreads ([BookSpreadData]),
  /// starting with Spread 0 (Front Cover on the left, Page 1 on the right).
  ///
  /// When [includeBlankTrailing] is true (e.g. in the overview spread feed),
  /// appends an empty spread placeholder allowing users to append subsequent pages
  /// when the page count is odd.
  List<BookSpreadData> buildSpreads({bool includeBlankTrailing = false}) {
    if (pages.isEmpty) {
      return const [
        BookSpreadData(isCoverLeft: true),
      ];
    }

    final spreads = <BookSpreadData>[
      BookSpreadData(
        isCoverLeft: true,
        rightPage: pages[0],
        rightPageIndex: 0,
      ),
    ];

    var cursor = 1;
    while (cursor < pages.length) {
      final left = pages[cursor];
      final leftIdx = cursor;
      final right = (cursor + 1 < pages.length) ? pages[cursor + 1] : null;
      final rightIdx = (cursor + 1 < pages.length) ? cursor + 1 : null;

      spreads.add(
        BookSpreadData(
          leftPage: left,
          leftPageIndex: leftIdx,
          rightPage: right,
          rightPageIndex: rightIdx,
        ),
      );
      cursor += 2;
    }

    if (includeBlankTrailing && pages.length % 2 != 0) {
      spreads.add(
        BookSpreadData(
          leftPage: null,
          rightPage: null,
          expectedNextPageNumber: pages.length + 1,
        ),
      );
    }

    return spreads;
  }

  factory AlbumStudioDocument.fromJson(Map<String, dynamic> json) {
    final rawPages = (json['pages'] as List<dynamic>? ?? [])
        .map((item) =>
            AlbumPageModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    final rawRemoved = (json['removedPhotoIds'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
    final rawColors = (json['recentBackgroundColors'] as List<dynamic>? ?? [])
        .map((item) => (item as num).toInt())
        .toList();

    return AlbumStudioDocument(
      pages: rawPages,
      removedPhotoIds: rawRemoved,
      recentBackgroundColors: rawColors,
      activeThemeId: json['activeThemeId'] as String? ?? 'shanshui_ink',
    );
  }

  factory AlbumStudioDocument.fromJsonString(String jsonStr) {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map) {
      throw const FormatException('Studio document JSON must be an object.');
    }
    return AlbumStudioDocument.fromJson(Map<String, dynamic>.from(decoded));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlbumStudioDocument &&
          listEquals(other.pages, pages) &&
          listEquals(other.removedPhotoIds, removedPhotoIds) &&
          listEquals(other.recentBackgroundColors, recentBackgroundColors) &&
          other.activeThemeId == activeThemeId);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(pages),
        Object.hashAll(removedPhotoIds),
        Object.hashAll(recentBackgroundColors),
        activeThemeId,
      );
}

/// Typed value object bundling spread layout coordinates and page assignments
/// for photobook spread rendering (CODING_STANDARDS.md § 2).
class BookSpreadData {
  final bool isCoverLeft;
  final AlbumPageModel? leftPage;
  final int? leftPageIndex;
  final AlbumPageModel? rightPage;
  final int? rightPageIndex;
  final int? expectedNextPageNumber;

  const BookSpreadData({
    this.isCoverLeft = false,
    this.leftPage,
    this.leftPageIndex,
    this.rightPage,
    this.rightPageIndex,
    this.expectedNextPageNumber,
  });
}

