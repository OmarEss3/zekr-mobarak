import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../model/quran_models/reciters_model.dart';
import '../../../utils/app_style.dart';
import '../../../widgets/reciturs_item.dart';
import 'list_surahs_listening_page.dart';

class QaloonPage extends StatelessWidget {
  const QaloonPage({super.key});

  final List<RecitersModel> reciters = const [
    RecitersModel(
      url: 'https://download.quranicaudio.com/quran/huthayfi_qaloon//',
      name: 'الحذيفي برواية قالون  ',
      zeroPaddingSurahNumber: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kPrimaryColor,
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: AppStyles.styleCairoMedium15white(context).color),
        backgroundColor: AppColors.kSecondaryColor,
        title: Text(
          'رواية قالون',
          style: AppStyles.styleDiodrumArabicbold20(context),
        ),
      ),
      body: ListView.builder(
        itemCount: reciters.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListSurahsListeningPage(
                    reciter: reciters[index],
                  ),
                ),
              );
            },
            child: RecitursItem(
              title: reciters[index].name,
            ),
          );
        },
      ),
    );
  }
}
