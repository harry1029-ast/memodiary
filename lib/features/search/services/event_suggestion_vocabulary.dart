/// Curated topic group for matching bilingual diary event suggestions.
class CuratedTopicGroup {
  final String zhCanonical;
  final String enCanonical;
  final List<String> zhSynonyms;
  final List<String> enSynonyms;

  const CuratedTopicGroup({
    required this.zhCanonical,
    required this.enCanonical,
    required this.zhSynonyms,
    required this.enSynonyms,
  });
}

/// Curated bilingual vocabulary and stop-word lists for [EventSuggestionService].
class EventSuggestionVocabulary {
  const EventSuggestionVocabulary._();

  static const List<CuratedTopicGroup> curatedGroups = [
    CuratedTopicGroup(
      zhCanonical: '旅行',
      enCanonical: 'Travel',
      zhSynonyms: ['旅行', '旅游'],
      enSynonyms: ['travel', 'trip'],
    ),
    CuratedTopicGroup(
      zhCanonical: '考试',
      enCanonical: 'Exam',
      zhSynonyms: ['考试', '测验'],
      enSynonyms: ['exam', 'exams'],
    ),
    CuratedTopicGroup(
      zhCanonical: '生日',
      enCanonical: 'Birthday',
      zhSynonyms: ['生日'],
      enSynonyms: ['birthday'],
    ),
    CuratedTopicGroup(
      zhCanonical: '工作',
      enCanonical: 'Work',
      zhSynonyms: ['工作', '加班'],
      enSynonyms: ['work', 'project'],
    ),
    CuratedTopicGroup(
      zhCanonical: '复盘',
      enCanonical: 'Review',
      zhSynonyms: ['复盘', '总结'],
      enSynonyms: ['review', 'retrospective'],
    ),
    CuratedTopicGroup(
      zhCanonical: '运动',
      enCanonical: 'Workout',
      zhSynonyms: ['运动', '跑步', '健身'],
      enSynonyms: ['workout', 'fitness', 'running'],
    ),
    CuratedTopicGroup(
      zhCanonical: '阅读',
      enCanonical: 'Reading',
      zhSynonyms: ['阅读', '读书'],
      enSynonyms: ['reading', 'book'],
    ),
    CuratedTopicGroup(
      zhCanonical: '电影',
      enCanonical: 'Movie',
      zhSynonyms: ['电影'],
      enSynonyms: ['movie', 'cinema'],
    ),
    CuratedTopicGroup(
      zhCanonical: '聚会',
      enCanonical: 'Party',
      zhSynonyms: ['聚会', '朋友'],
      enSynonyms: ['party', 'gathering'],
    ),
    CuratedTopicGroup(
      zhCanonical: '家人',
      enCanonical: 'Family',
      zhSynonyms: ['家人', '家庭'],
      enSynonyms: ['family'],
    ),
    CuratedTopicGroup(
      zhCanonical: '学习',
      enCanonical: 'Study',
      zhSynonyms: ['学习'],
      enSynonyms: ['study', 'studying'],
    ),
    CuratedTopicGroup(
      zhCanonical: '音乐',
      enCanonical: 'Music',
      zhSynonyms: ['音乐', '演唱会'],
      enSynonyms: ['music', 'concert'],
    ),
  ];

  static const Set<String> enStopWords = {
    'the',
    'and',
    'for',
    'with',
    'day',
    'diary',
    'note',
    'notes',
    'entry',
    'entries',
    'week',
    'weekly',
    'from',
    'this',
    'that',
    'about',
    'into',
    'today',
  };

  static const Set<String> zhStopWords = {
    '日记',
    '周记',
    '今天',
    '今日',
    '记录',
    '随笔',
    '生活',
    '心情',
  };
}
