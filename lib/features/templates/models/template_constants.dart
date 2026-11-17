import '../../../core/database/app_database.dart';

/// The 4 immutable system default template identifiers:
/// - Minimalist White (澄心素宣 / Minimalist)
/// - Lined Paper (乌丝栏笺 / Line)
/// - Weekly Review (九宫格笺 / Grid)
/// - Retro Kraft Scrapbook (怀旧牛皮 / Kraft)
const Set<String> kDefaultTemplateIds = {
  'template_minimalist_white',
  'template_lined_paper',
  'template_weekly_review',
  'template_retro_kraft',
};

/// Returns whether a given template can be deleted by the diarist.
/// Default system templates cannot be deleted under any circumstances.
bool isTemplateDeletable(Template template) {
  if (!template.isCustom) return false;
  if (kDefaultTemplateIds.contains(template.id)) return false;
  return true;
}

/// Maps built-in system template IDs to plain modern Chinese display names
/// without mutating persisted database seed records.
String displayTemplateName(Template template) {
  switch (template.id) {
    case 'template_minimalist_white':
      return '素白信纸';
    case 'template_lined_paper':
      return '横线信纸';
    case 'template_retro_kraft':
      return '牛皮纸';
    case 'template_weekly_review':
      return '方格信纸';
    default:
      return template.name;
  }
}
