import 'package:azkar_app/cubit/add_fav_surahcubit/add_fav_surah_item_cubit.dart';
import 'package:azkar_app/model/quran_models/reciters_model.dart';
import 'package:flutter/material.dart';
import 'package:azkar_app/utils/app_style.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:quran/quran.dart' as quran;
import '../../../constants.dart';
import '../../../widgets/surah_listening_item_widget.dart';

class ListSurahsListeningPage extends StatefulWidget {
  final RecitersModel reciter;
  const ListSurahsListeningPage({
    super.key,
    required this.reciter,
  });

  @override
  State<ListSurahsListeningPage> createState() =>
      _ListSurahsListeningPageState();
}

class _ListSurahsListeningPageState extends State<ListSurahsListeningPage> {
  String? tappedSurahName;
  final TextEditingController _searchController = TextEditingController();
  List<int> filteredSurahs = List.generate(114, (index) => index + 1);
  bool _isSearching = false;

  void updateTappedSurahName(int surahIndex) {
    setState(() {
      tappedSurahName =
          'تشغيل سورة ${quran.getSurahNameArabic(surahIndex + 1)} الآن';
    });
  }

  void _filterSurahs(String query) {
    setState(() {
      filteredSurahs = List.generate(114, (index) => index + 1)
          .where((index) => quran.getSurahNameArabic(index).contains(query))
          .toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching; // Toggle search visibility
      if (!_isSearching) {
        _searchController.clear();
        _filterSurahs(''); // Reset the list when closing search
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kSecondaryColor,
      appBar: AppBar(
          iconTheme: IconThemeData(
              color: AppStyles.styleCairoMedium15white(context).color),
          centerTitle: true,
          title: _isSearching
              ? TextField(
                  style: AppStyles.styleCairoMedium15white(context),
                  controller: _searchController,
                  onChanged: _filterSurahs,
                  decoration: const InputDecoration(
                    hintText: 'إبحث عن سورة ...',
                    border: InputBorder.none,
                  ),
                  autofocus: true, // Focus automatically when search is toggled
                )
              : Text('استماع القران الكريم',
                  style: AppStyles.styleCairoMedium15white(context)),
          backgroundColor: AppColors.kPrimaryColor,
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: _toggleSearch,
                child: Icon(_isSearching ? Icons.close : Icons.search),
              ),
            )
          ]),
      body: BlocConsumer<AddFavSurahItemCubit, AddFavSurahItemState>(
        listener: (context, state) {},
        builder: (context, state) {
          return ModalProgressHUD(
            inAsyncCall: state is AddFavSurahItemLoading ? true : false,
            child: Column(
              children: [
                // Non-scrollable content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        widget.reciter.name,
                        style: AppStyles.styleDiodrumArabicbold20(context),
                      ),
                      if (tappedSurahName != null)
                        Text(
                          tappedSurahName!,
                          style: AppStyles.styleCairoMedium15white(context),
                        ),
                    ],
                  ),
                ),

                // Scrollable list of surahs
                Expanded(
                  child: filteredSurahs.isNotEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: filteredSurahs.length,
                          itemBuilder: (context, index) {
                            final surahIndex = filteredSurahs[index] -
                                1; // Adjusting to 0-based index
                            final audioUrl = widget
                                    .reciter.zeroPaddingSurahNumber
                                ? '${widget.reciter.url}${(surahIndex + 1).toString().padLeft(3, '0')}.mp3'
                                : '${widget.reciter.url}${surahIndex + 1}.mp3';

                            return SurahListeningItem(
                              surahIndex: surahIndex,
                              audioUrl: audioUrl,
                              onSurahTap: updateTappedSurahName,
                              reciter: widget.reciter,
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            'اسم السورة غير صحيح.',
                            style: AppStyles.styleDiodrumArabicbold20(context),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
