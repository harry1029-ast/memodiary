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
