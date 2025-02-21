import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import '../pages/quran_pages/search_provider.dart';
import '../utils/app_style.dart';
import '../constants.dart';
import '../pages/quran_pages/surah_page.dart';

class SurahListWidget extends StatefulWidget {
  const SurahListWidget({super.key});

  @override
  State<SurahListWidget> createState() => _SurahListWidgetState();
}

class _SurahListWidgetState extends State<SurahListWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Ensure keep-alive works

    final searchProvider = Provider.of<SearchProvider>(context);
    final query = searchProvider.query.trim().toLowerCase();

    // Filter surahs based on the query
    final filteredSurahs =
        List.generate(quran.totalSurahCount, (index) => index + 1)
            .where((surahNumber) =>
                query.isEmpty ||
                quran.getSurahNameArabic(surahNumber).contains(query) ||
                quran.getSurahName(surahNumber).toLowerCase().contains(query))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.kPrimaryColor,
      body: ListView.builder(
        key: const PageStorageKey('surahList'), // Retains scroll position
        itemCount: filteredSurahs.length,
        itemBuilder: (context, index) {
          final surahNumber = filteredSurahs[index];
          final currentJuz = quran.getJuzNumber(surahNumber, 1);
          bool showHeader = false;

          // Show header if it's the first item or if the juz number changes
          if (index == 0) {
            showHeader = true;
          } else {
            final previousJuz =
                quran.getJuzNumber(filteredSurahs[index - 1], 1);
            if (previousJuz != currentJuz) {
              showHeader = true;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) _buildJuzHeader(context, currentJuz),
              _buildSurahRow(context, surahNumber, currentJuz),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSurahRow(BuildContext context, int surahNumber, int juzIndex) {
    final surahType =
        quran.getPlaceOfRevelation(surahNumber) == "Makkah" ? "مكية" : "مدنية";
    final firstVersePage = quran.getSurahPages(surahNumber).first;
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    final query = searchProvider.query.trim();
    final surahName = 'سورة ${quran.getSurahNameArabic(surahNumber)}';
    final queryIndex = surahName.indexOf(query);

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 30),
            Text(
              '$surahNumber', // Surah number
              style: AppStyles.styleCairoMedium15white(context),
            ),
            Expanded(
              child: ListTile(
                trailing: Text(
                  '$firstVersePage', // First page of the surah
                  style: AppStyles.styleDiodrumArabicMedium11(context),
                ),
                title: RichText(
                  text: TextSpan(
                    children: [
                      if (queryIndex != -1) ...[
                        TextSpan(
                          text: surahName.substring(0, queryIndex),
                          style: AppStyles.styleDiodrumArabicbold20(context),
                        ),
                        TextSpan(
                          text: query,
                          style: AppStyles.styleDiodrumArabicbold20(context)
                              .copyWith(color: Colors.red),
                        ),
                        TextSpan(
                          text: surahName.substring(queryIndex + query.length),
                          style: AppStyles.styleDiodrumArabicbold20(context),
                        ),
                      ] else ...[
                        TextSpan(
                          text: surahName,
                          style: AppStyles.styleDiodrumArabicbold20(context),
                        ),
                      ],
                    ],
                  ),
                ),
                subtitle: Row(
                  children: [
                    Text(
                      '$surahType - ${quran.getVerseCount(surahNumber)} اية',
                      style: AppStyles.styleDiodrumArabicMedium11(context),
                    ),
                  ],
                ),
                onTap: () => _navigateToSurahPage(context, firstVersePage),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJuzHeader(BuildContext context, int index) {
    return Container(
      height: 41,
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: .1,
          )
        ],
        color: AppColors.kSecondaryColor,
        gradient: LinearGradient(
          colors: [AppColors.kSecondaryColor, AppColors.kPrimaryColor],
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Text(
            'الجزء ${arabicOrdinals[index - 1]}',
            style: AppStyles.styleDiodrumArabicMedium15(context),
          ),
          const Spacer(),
          Text(
            '${quran.getSurahPages(index).first}', // Page number where each Juz starts
            style: AppStyles.styleCairoMedium15white(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  void _navigateToSurahPage(BuildContext context, int firstVersePage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurahPage(
          pageNumber: firstVersePage,
        ),
      ),
    );
    Provider.of<SearchProvider>(context, listen: false).updateQuery('');
  }
}
