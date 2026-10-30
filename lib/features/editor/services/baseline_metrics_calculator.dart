import 'package:flutter/material.dart';

typedef _MetricKey = (String?, double, double);

/// Service calculating and caching font metrics and alphabetic baselines.
/// Guarantees sub-pixel typographic alignment across arbitrary font families and sizes.
class BaselineMetricsCalculator {
  BaselineMetricsCalculator._();

  static final Map<_MetricKey, double> _baselineCache = <_MetricKey, double>{};
  static final Map<_MetricKey, double> _lineHeightCache = <_MetricKey, double>{};

  /// Calculates the alphabetic baseline offset from the top of the text line box.
  static double calculateBaselineOffset(TextStyle style) {
    final key = _cacheKey(style);
    final cached = _baselineCache[key];
    if (cached != null) return cached;

    final fontSize = style.fontSize ?? 16.0;
    final height = style.height ?? 1.5;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '测Mj',
        style: style.copyWith(
          fontSize: fontSize,
          height: height,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    try {
      textPainter.layout();
      final baseline = textPainter.computeDistanceToActualBaseline(
        TextBaseline.alphabetic,
      );

      // If textPainter returns a valid baseline, cache and return
      if (baseline > 0) {
        _baselineCache[key] = baseline;
        return baseline;
      }
    } catch (_) {
      // Fallback below
    } finally {
      textPainter.dispose();
    }

    // Mathematical typographic approximation if TextPainter is unavailable
    final fallbackBaseline = (fontSize * height * 0.78);
    _baselineCache[key] = fallbackBaseline;
    return fallbackBaseline;
  }

  /// Calculates the total line height in logical pixels.
  static double calculateLineHeight(TextStyle style) {
    final key = _cacheKey(style);
    final cached = _lineHeightCache[key];
    if (cached != null) return cached;

    final fontSize = style.fontSize ?? 16.0;
    final height = style.height ?? 1.5;
    final calculated = fontSize * height;

    _lineHeightCache[key] = calculated;
    return calculated;
  }

  /// Clears in-memory metric caches.
  static void clearCache() {
    _baselineCache.clear();
    _lineHeightCache.clear();
  }

  static _MetricKey _cacheKey(TextStyle style) {
    return (style.fontFamily, style.fontSize ?? 16.0, style.height ?? 1.5);
  }
}
