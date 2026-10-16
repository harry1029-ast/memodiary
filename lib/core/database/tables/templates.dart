import 'package:drift/drift.dart';

/// Templates table for diary visual styling, strictly decoupled from content.
@DataClassName('Template')
class Templates extends Table {
  /// Unique template identifier (e.g., 'template_minimalist_white')
  TextColumn get id => text()();

  /// Human-readable template name
  TextColumn get name => text()();

  /// Template background style: 'color', 'paper_texture', 'grid', 'lined'
  TextColumn get backgroundType => text()();

  /// Value for background: hex color code (e.g., '#FFFFFF') or asset key
  TextColumn get backgroundValue => text()();

  /// Font family (null defaults to system font)
  TextColumn get fontFamily => text().nullable()();

  /// Line height multiplier (e.g., 1.5, 1.8)
  RealColumn get lineSpacing => real().withDefault(const Constant(1.5))();

  /// Horizontal page margins in logical pixels
  RealColumn get marginHorizontal => real().withDefault(const Constant(16.0))();

  /// Flag indicating user-customized template vs system preset
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

