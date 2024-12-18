import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import '../utils/app_style.dart';
import '../constants.dart';
import '../pages/quran_pages/surah_page.dart';

class SurahListWidget extends StatefulWidget {
  const SurahListWidget({super.key});

  @override
  State<SurahListWidget> createState() => _SurahListWidgetState();
}

class _SurahListWidgetState extends State<SurahListWidget> {
  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kPrimaryColor,
      body: ListView.builder(
              itemCount: quran.totalJuzCount,
              itemBuilder: (context, index) {
                final surahsInJuz = quran.getSurahAndVersesFromJuz(index + 1);
                return _buildJuzSection(context, index, surahsInJuz);
              },
            ),
    );
  }

  Widget _buildJuzSection(
      BuildContext context, int index, Map<int, List<int>> surahsInJuz) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildJuzHeader(context, index),
        ...surahsInJuz.entries
            .map((entry) => _buildSurahRow(context, entry, index)),
      ],
    );
  }

  Widget _buildSurahRow(
      BuildContext context, MapEntry<int, List<int>> entry, int juzIndex) {
    final surahType =
        quran.getPlaceOfRevelation(entry.key) == "Makkah" ? "مكية" : "مدنية";

    // Fetching the actual page where each Surah starts
    final firstVersePage = quran.getSurahPages(entry.key).first;

    return Row(
      children: [
        const SizedBox(width: 10),
        Text(
          '${entry.key}', // Surah number
          style: AppStyles.styleRajdhaniMedium18(context),
        ),
        Expanded(
          child: ListTile(
            trailing: Text(
              '$firstVersePage', // Display the first page of the Surah
              style: AppStyles.styleRajdhaniBold13(context),
            ),
            title: Text(
              'سورة ${quran.getSurahNameArabic(entry.key)}',
              style: AppStyles.styleRajdhaniMedium18(context),
            ),
            subtitle: Row(
              children: [
                Text(
                  '$surahType - ${surahsAyat[entry.key - 1]['count']} اية',
                  style: AppStyles.styleRajdhaniBold13(context)
                      .copyWith(color: Colors.white),
                ),
              ],
            ),
            onTap: () => _navigateToSurahPage(
                context, entry.key, juzIndex, surahType, firstVersePage),
          ),
        ),
      ],
    );
  }

  Widget _buildJuzHeader(BuildContext context, int index) {
    return Container(
      height: 41,
      width: double.infinity,
      decoration: BoxDecoration(
          color: AppColors.kSecondaryColor,
          gradient: LinearGradient(
              colors: [AppColors.kSecondaryColor, AppColors.kPrimaryColor])),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Text(
            'الجزء ${arabicOrdinals[index]}',
            style: AppStyles.styleDiodrumArabicMedium15(context),
          ),
          const Spacer(),
          Text(
            '${quran.getSurahPages(index + 1).first}', // Page number where each Juz starts
            style: AppStyles.styleRajdhaniMedium18(context)
                .copyWith(color: Colors.white),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  void _navigateToSurahPage(BuildContext context, int surahIndex, int juzNumber,
      String surahType, int firstVersePage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurahPage(
          pageNumber: firstVersePage,
        ),
      ),
    );
  }
}
