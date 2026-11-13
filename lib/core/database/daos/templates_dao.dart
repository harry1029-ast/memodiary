import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../app_database.dart';
import '../tables/entries.dart';
import '../tables/notebooks.dart';
import '../tables/templates.dart';

part 'templates_dao.g.dart';

/// Data access object for visual stationery [Templates] and [Notebooks],
/// including the single canonical seed definitions for built-in templates.
@DriftAccessor(tables: [Templates, Notebooks, Entries])
class TemplatesDao extends DatabaseAccessor<AppDatabase>
    with _$TemplatesDaoMixin {
  TemplatesDao(super.attachedDatabase);

  static const List<String> builtInTemplateIds = [
    'template_minimalist_white',
    'template_lined_paper',
    'template_retro_kraft',
    'template_weekly_review',
  ];

  /// Returns the canonical seed companions for the four built-in system templates.
  static List<TemplatesCompanion> buildDefaultTemplateCompanions() => [
        TemplatesCompanion.insert(
          id: 'template_minimalist_white',
          name: 'Minimalist White',
          backgroundType: 'color',
          backgroundValue: '#FFFFFF',
          fontFamily: const Value('System'),
          lineSpacing: const Value(1.5),
          marginHorizontal: const Value(20.0),
          isCustom: const Value(false),
        ),
        TemplatesCompanion.insert(
          id: 'template_lined_paper',
          name: 'Lined Paper',
          backgroundType: 'lined',
          backgroundValue: '#FDFBF7',
          fontFamily: const Value('System'),
          lineSpacing: const Value(1.8),
          marginHorizontal: const Value(24.0),
          isCustom: const Value(false),
        ),
        TemplatesCompanion.insert(
          id: 'template_retro_kraft',
          name: 'Retro Kraft Scrapbook',
          backgroundType: 'paper_texture',
          backgroundValue: '#EFE6D5',
          fontFamily: const Value('System'),
          lineSpacing: const Value(1.6),
          marginHorizontal: const Value(20.0),
          isCustom: const Value(false),
        ),
        TemplatesCompanion.insert(
          id: 'template_weekly_review',
          name: 'Weekly Review',
          backgroundType: 'grid',
          backgroundValue: '#F4F5F7',
          fontFamily: const Value('System'),
          lineSpacing: const Value(1.5),
          marginHorizontal: const Value(16.0),
          isCustom: const Value(false),
        ),
      ];

  /// Returns the canonical seed companion for the default diary notebook.
  static NotebooksCompanion buildDefaultNotebookCompanion() =>
      NotebooksCompanion.insert(
        id: 'notebook_default',
        title: 'My Diary',
        defaultTemplateId: 'template_minimalist_white',
      );

  /// Retrieves all visual templates.
  Future<List<Template>> getAllTemplates() => select(templates).get();

  /// Retrieves a template by its [id].
  Future<Template?> getTemplateById(String id) {
    return (select(templates)..where((template) => template.id.equals(id)))
        .getSingleOrNull();
  }

  /// Retrieves only user-defined custom templates (`isCustom = true`).
  Future<List<Template>> getCustomTemplates() {
    return (select(templates)
          ..where((template) => template.isCustom.equals(true)))
        .get();
  }

  /// Creates and persists a new user-defined custom template (`isCustom = true`).
  Future<Template> createCustomTemplate({
    String? id,
    required String name,
    required String backgroundType,
    required String backgroundValue,
    String? fontFamily = 'System',
    double lineSpacing = 1.5,
    double marginHorizontal = 16.0,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Template name cannot be empty.');
    }

    final templateId = id ?? 'template_custom_${const Uuid().v4()}';
    await into(templates).insert(
      TemplatesCompanion.insert(
        id: templateId,
        name: trimmedName,
        backgroundType: backgroundType,
        backgroundValue: backgroundValue,
        fontFamily: Value(fontFamily),
        lineSpacing: Value(lineSpacing),
        marginHorizontal: Value(marginHorizontal),
        isCustom: const Value(true),
      ),
    );

    return (select(templates)
          ..where((template) => template.id.equals(templateId)))
        .getSingle();
  }

  /// Updates an existing custom template.
  /// Throws [StateError] when attempting to modify a seeded system template.
  Future<int> updateCustomTemplate(
    String id, {
    String? name,
    String? backgroundType,
    String? backgroundValue,
    String? fontFamily,
    double? lineSpacing,
    double? marginHorizontal,
  }) async {
    final existing = await getTemplateById(id);
    if (existing == null) {
      throw ArgumentError('Template not found: $id');
    }
    if (!existing.isCustom) {
      throw StateError('Default system templates cannot be modified.');
    }
    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Template name cannot be empty.');
    }

    return (update(templates)..where((template) => template.id.equals(id)))
        .write(
      TemplatesCompanion(
        name: name != null ? Value(name.trim()) : const Value.absent(),
        backgroundType: backgroundType != null
            ? Value(backgroundType)
            : const Value.absent(),
        backgroundValue: backgroundValue != null
            ? Value(backgroundValue)
            : const Value.absent(),
        fontFamily:
            fontFamily != null ? Value(fontFamily) : const Value.absent(),
        lineSpacing:
            lineSpacing != null ? Value(lineSpacing) : const Value.absent(),
        marginHorizontal: marginHorizontal != null
            ? Value(marginHorizontal)
            : const Value.absent(),
      ),
    );
  }

  /// Reassigns all entries referencing [fromTemplateId] to [toTemplateId]
  /// without mutating entry contentDelta or plainText.
  Future<int> reassignEntriesTemplate({
    required String fromTemplateId,
    required String toTemplateId,
  }) {
    return (update(entries)
          ..where((entry) => entry.templateId.equals(fromTemplateId)))
        .write(
      EntriesCompanion(
        templateId: Value(toTemplateId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Safely deletes a user-defined custom template inside a transaction after
  /// reassigning dependent entries to [fallbackTemplateId].
  Future<void> deleteCustomTemplate(
    String templateId, {
    String fallbackTemplateId = 'template_minimalist_white',
  }) async {
    final existing = await getTemplateById(templateId);
    if (existing == null) {
      throw ArgumentError('Template not found: $templateId');
    }
    if (!existing.isCustom || builtInTemplateIds.contains(existing.id)) {
      throw StateError('Default system templates cannot be deleted.');
    }

    await transaction(() async {
      await reassignEntriesTemplate(
        fromTemplateId: templateId,
        toTemplateId: fallbackTemplateId,
      );
      await (delete(templates)
            ..where((template) => template.id.equals(templateId)))
          .go();
    });
  }

  /// Retrieves all notebooks.
  Future<List<Notebook>> getAllNotebooks() => select(notebooks).get();

  /// Inserts a new notebook into the database.
  Future<int> createNotebook(NotebooksCompanion notebook) =>
      into(notebooks).insert(notebook);
}
