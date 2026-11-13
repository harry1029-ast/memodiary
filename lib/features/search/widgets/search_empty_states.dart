import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/ink_diary_theme.dart';

/// Initial empty state with quick inspiration keywords before the user searches.
class SearchInitialPrompt extends StatelessWidget {
  final List<String> quickInspirations;
  final ValueChanged<String> onInspirationTapped;

  const SearchInitialPrompt({
    super.key,
    required this.quickInspirations,
    required this.onInspirationTapped,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.ricePaper,
                  border: Border.all(color: tokens.agedFiber),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.jiaomo.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.pageview_outlined,
                  size: 44,
                  color: tokens.nongmo,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.cinnabarWash,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: tokens.cinnabar.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '印',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: tokens.cinnabar,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '墨海探微 · 静候落字',
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: tokens.jiaomo,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '输入字句、年份或叩问心境，\n在泛黄宣纸深处翻寻旧日回响。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontKaiti,
              fontSize: 13,
              height: 1.45,
              color: tokens.danmo,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.cinnabar,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '案头灵犀 · 快捷索引',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: tokens.nongmo,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.cinnabar,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: quickInspirations.map((inspiration) {
              return InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onInspirationTapped(inspiration);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.ricePaper,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tokens.agedFiber),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '「',
                        style: TextStyle(color: tokens.cinnabar, fontSize: 11),
                      ),
                      Text(
                        inspiration,
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontKaiti,
                          fontSize: 12,
                          color: tokens.jiaomo,
                        ),
                      ),
                      Text(
                        '」',
                        style: TextStyle(color: tokens.cinnabar, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no diary entries or photo OCR matches are found.
class SearchNoResultsView extends StatelessWidget {
  const SearchNoResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.find_in_page_outlined,
              size: 52,
              color: tokens.danmo.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              '墨痕杳然 · 暂无匹配记录',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '试探更换关键词、放宽时日范围，或重置筛选条件重新翻阅。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 13,
                color: tokens.danmo,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state specifically for the photo OCR segment.
class SearchNoPhotoResultsView extends StatelessWidget {
  const SearchNoPhotoResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 52,
              color: tokens.danmo.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              '图中文字杳然 · 暂无匹配照片',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '未在照片题字或路标存照中检索到匹配内容。\n可尝试更简短的字词，或确认照片已建立文字索引。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 13,
                color: tokens.danmo,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
