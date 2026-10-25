import 'dart:ui';
import 'package:flutter/foundation.dart';

/// Immutable geometric definition of a single-page multi-photo collage layout.
///
/// All slot rectangles use normalized coordinates in the `[0.0, 1.0]` range
/// relative to the page canvas width and height.
@immutable
class PageLayoutTemplate {
  final String id;
  final String name;
  final int photoCount;
  final List<Rect> slots;
  final Rect? dateHeaderSlot;

  PageLayoutTemplate({
    required this.id,
    required this.name,
    required this.photoCount,
    required List<Rect> slots,
    this.dateHeaderSlot,
  }) : slots = List<Rect>.unmodifiable(slots);
}

/// Catalog of 19 normalized collage layout templates supporting 1 to 6 photos per page.
class PageLayoutCatalog {
  const PageLayoutCatalog._();

  static const int minPhotosPerPage = 1;
  static const int maxPhotosPerPage = 6;

  static final List<PageLayoutTemplate> allTemplates =
      List<PageLayoutTemplate>.unmodifiable([
    // =========================================================================
    // 1 Photo (3 templates)
    // =========================================================================
    PageLayoutTemplate(
      id: 'solo_full_bleed',
      name: '满幅独帧',
      photoCount: 1,
      slots: const [
        Rect.fromLTWH(0.04, 0.04, 0.92, 0.92),
      ],
    ),
    PageLayoutTemplate(
      id: 'solo_framed',
      name: '雅致留白',
      photoCount: 1,
      slots: const [
        Rect.fromLTWH(0.10, 0.10, 0.80, 0.78),
      ],
    ),
    PageLayoutTemplate(
      id: 'solo_dated_polaroid',
      name: '纪年拍立得',
      photoCount: 1,
      dateHeaderSlot: const Rect.fromLTWH(0.08, 0.05, 0.84, 0.08),
      slots: const [
        Rect.fromLTWH(0.08, 0.15, 0.84, 0.75),
      ],
    ),

    // =========================================================================
    // 2 Photos (4 templates)
    // =========================================================================
    PageLayoutTemplate(
      id: 'duo_side_by_side',
      name: '双列并排',
      photoCount: 2,
      slots: const [
        Rect.fromLTWH(0.04, 0.06, 0.445, 0.88),
        Rect.fromLTWH(0.515, 0.06, 0.445, 0.88),
      ],
    ),
    PageLayoutTemplate(
      id: 'duo_stacked',
      name: '上下双叠',
      photoCount: 2,
      slots: const [
        Rect.fromLTWH(0.06, 0.04, 0.88, 0.445),
        Rect.fromLTWH(0.06, 0.515, 0.88, 0.445),
      ],
    ),
    PageLayoutTemplate(
      id: 'duo_dated_columns',
      name: '纪年双列',
      photoCount: 2,
      dateHeaderSlot: const Rect.fromLTWH(0.04, 0.04, 0.92, 0.09),
      slots: const [
        Rect.fromLTWH(0.04, 0.15, 0.445, 0.81),
        Rect.fromLTWH(0.515, 0.15, 0.445, 0.81),
      ],
    ),
    PageLayoutTemplate(
      id: 'duo_asymmetric_60_40',
      name: '主次错落 (6:4)',
      photoCount: 2,
      slots: const [
        Rect.fromLTWH(0.04, 0.06, 0.54, 0.88),
        Rect.fromLTWH(0.61, 0.14, 0.35, 0.72),
      ],
    ),

    // =========================================================================
    // 3 Photos (4 templates)
    // =========================================================================
    PageLayoutTemplate(
      id: 'trio_left_hero_right_stack',
      name: '左主右双 (1+2)',
      photoCount: 3,
      slots: const [
        Rect.fromLTWH(0.04, 0.04, 0.56, 0.92),
        Rect.fromLTWH(0.63, 0.04, 0.33, 0.445),
        Rect.fromLTWH(0.63, 0.515, 0.33, 0.445),
      ],
    ),
    PageLayoutTemplate(
      id: 'trio_dated_columns',
      name: '纪年三列',
      photoCount: 3,
      dateHeaderSlot: const Rect.fromLTWH(0.04, 0.04, 0.92, 0.09),
      slots: const [
        Rect.fromLTWH(0.04, 0.15, 0.29, 0.79),
        Rect.fromLTWH(0.355, 0.15, 0.29, 0.79),
        Rect.fromLTWH(0.67, 0.15, 0.29, 0.79),
      ],
    ),
    PageLayoutTemplate(
      id: 'trio_top_hero_bottom_split',
      name: '上主下双 (1+2)',
      photoCount: 3,
      slots: const [
        Rect.fromLTWH(0.04, 0.04, 0.92, 0.52),
        Rect.fromLTWH(0.04, 0.59, 0.445, 0.37),
        Rect.fromLTWH(0.515, 0.59, 0.445, 0.37),
      ],
    ),
    PageLayoutTemplate(
      id: 'trio_right_hero_left_stack',
      name: '左双右主 (2+1)',
      photoCount: 3,
      slots: const [
        Rect.fromLTWH(0.04, 0.04, 0.33, 0.445),
        Rect.fromLTWH(0.04, 0.515, 0.33, 0.445),
        Rect.fromLTWH(0.40, 0.04, 0.56, 0.92),
      ],
    ),

    // =========================================================================
    // 4 Photos (4 templates)
    // =========================================================================
    PageLayoutTemplate(
      id: 'quad_grid_2x2',
      name: '四宫格 (2×2)',
      photoCount: 4,
      slots: const [
        Rect.fromLTWH(0.04, 0.04, 0.445, 0.445),
        Rect.fromLTWH(0.515, 0.04, 0.445, 0.445),
        Rect.fromLTWH(0.04, 0.515, 0.445, 0.445),
        Rect.fromLTWH(0.515, 0.515, 0.445, 0.445),
      ],
    ),
    PageLayoutTemplate(
      id: 'quad_dated_grid_2x2',
      name: '纪年四宫格',
      photoCount: 4,
      dateHeaderSlot: const Rect.fromLTWH(0.04, 0.04, 0.92, 0.08),
      slots: const [
        Rect.fromLTWH(0.04, 0.14, 0.445, 0.395),
        Rect.fromLTWH(0.515, 0.14, 0.445, 0.395),
        Rect.fromLTWH(0.04, 0.565, 0.445, 0.395),
        Rect.fromLTWH(0.515, 0.565, 0.445, 0.395),
      ],
    ),
    PageLayoutTemplate(
      id: 'quad_top_hero_bottom_trio',
      name: '上主下三 (1+3)',
      photoCount: 4,
      slots: const [
        Rect.fromLTWH(0.04, 0.04, 0.92, 0.56),
        Rect.fromLTWH(0.04, 0.63, 0.29, 0.33),
        Rect.fromLTWH(0.355, 0.63, 0.29, 0.33),
        Rect.fromLTWH(0.67, 0.63, 0.29, 0.33),
      ],
    ),
    PageLayoutTemplate(
      id: 'quad_left_hero_right_trio',
      name: '左主右三 (1+3)',
      photoCount: 4,
      slots: const [
        Rect.fromLTWH(0.04, 0.04, 0.56, 0.92),
        Rect.fromLTWH(0.63, 0.04, 0.33, 0.29),
        Rect.fromLTWH(0.63, 0.355, 0.33, 0.29),
        Rect.fromLTWH(0.63, 0.67, 0.33, 0.29),
      ],
    ),

    // =========================================================================
    // 5 Photos (2 templates)
    // =========================================================================
    PageLayoutTemplate(
      id: 'penta_top_duo_bottom_trio',
      name: '上二下三 (2+3)',
      photoCount: 5,
      slots: const [
        Rect.fromLTWH(0.04, 0.04, 0.445, 0.46),
        Rect.fromLTWH(0.515, 0.04, 0.445, 0.46),
        Rect.fromLTWH(0.04, 0.53, 0.29, 0.43),
        Rect.fromLTWH(0.355, 0.53, 0.29, 0.43),
        Rect.fromLTWH(0.67, 0.53, 0.29, 0.43),
      ],
    ),
    PageLayoutTemplate(
      id: 'penta_left_hero_right_quad',
      name: '左主右四 (1+4)',
      photoCount: 5,
      slots: const [
        Rect.fromLTWH(0.04, 0.04, 0.44, 0.92),
        Rect.fromLTWH(0.51, 0.04, 0.215, 0.445),
        Rect.fromLTWH(0.745, 0.04, 0.215, 0.445),
        Rect.fromLTWH(0.51, 0.515, 0.215, 0.445),
        Rect.fromLTWH(0.745, 0.515, 0.215, 0.445),
      ],
    ),

    // =========================================================================
    // 6 Photos (2 templates)
    // =========================================================================
    PageLayoutTemplate(
      id: 'hexa_grid_3x2',
      name: '六宫格横版 (3×2)',
      photoCount: 6,
      slots: const [
        Rect.fromLTWH(0.04, 0.04, 0.29, 0.445),
        Rect.fromLTWH(0.355, 0.04, 0.29, 0.445),
        Rect.fromLTWH(0.67, 0.04, 0.29, 0.445),
        Rect.fromLTWH(0.04, 0.515, 0.29, 0.445),
        Rect.fromLTWH(0.355, 0.515, 0.29, 0.445),
        Rect.fromLTWH(0.67, 0.515, 0.29, 0.445),
      ],
    ),
    PageLayoutTemplate(
      id: 'hexa_grid_2x3',
      name: '六宫格竖版 (2×3)',
      photoCount: 6,
      slots: const [
        Rect.fromLTWH(0.04, 0.04, 0.445, 0.29),
        Rect.fromLTWH(0.515, 0.04, 0.445, 0.29),
        Rect.fromLTWH(0.04, 0.355, 0.445, 0.29),
        Rect.fromLTWH(0.515, 0.355, 0.445, 0.29),
        Rect.fromLTWH(0.04, 0.67, 0.445, 0.29),
        Rect.fromLTWH(0.515, 0.67, 0.445, 0.29),
      ],
    ),
  ]);

  /// Looks up a template by [id], falling back to `'solo_full_bleed'` if not found.
  static PageLayoutTemplate getById(String id) {
    for (final template in allTemplates) {
      if (template.id == id) {
        return template;
      }
    }
    return allTemplates.first;
  }

  /// Returns all collage layout templates matching [photoCount] (clamped to `1..6`).
  static List<PageLayoutTemplate> templatesForPhotoCount(int photoCount) {
    final clamped = photoCount.clamp(minPhotosPerPage, maxPhotosPerPage);
    return allTemplates
        .where((template) => template.photoCount == clamped)
        .toList(growable: false);
  }

  /// Selects an intelligent default layout template for [photoCount] and optional
  /// photo [aspectRatios].
  static PageLayoutTemplate defaultTemplateForPhotoCount(
    int photoCount, {
    List<double>? aspectRatios,
    int pageVariationIndex = 0,
  }) {
    final candidates = templatesForPhotoCount(photoCount);
    if (candidates.isEmpty) {
      return allTemplates.first;
    }

    if (photoCount == 2 && aspectRatios != null && aspectRatios.length >= 2) {
      final bothWide = aspectRatios[0] > 1.25 && aspectRatios[1] > 1.25;
      if (bothWide) {
        return getById('duo_stacked');
      }
      return getById('duo_side_by_side');
    }

    if (photoCount == 3 && aspectRatios != null && aspectRatios.isNotEmpty) {
      if (aspectRatios.first > 1.35) {
        return getById('trio_top_hero_bottom_split');
      }
      if (pageVariationIndex.isOdd) {
        return getById('trio_dated_columns');
      }
      return getById('trio_left_hero_right_stack');
    }

    if (photoCount == 4 && aspectRatios != null && aspectRatios.isNotEmpty) {
      if (aspectRatios.first > 1.35) {
        return getById('quad_top_hero_bottom_trio');
      }
      if (pageVariationIndex.isOdd) {
        return getById('quad_dated_grid_2x2');
      }
      return getById('quad_grid_2x2');
    }

    return candidates[pageVariationIndex % candidates.length];
  }
}

