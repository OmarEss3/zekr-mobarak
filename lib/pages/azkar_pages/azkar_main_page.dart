import 'package:azkar_app/cubit/azkar_cubit/azkar_cubit.dart';
import 'package:azkar_app/cubit/azkar_cubit/azkar_state.dart';
import 'package:azkar_app/widgets/reciturs_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants.dart';
import '../../model/azkar_model/azkar_model/azkar_model.dart';
import '../../utils/app_images.dart';
import '../../utils/app_style.dart';
import '../../widgets/icon_constrain_widget.dart';
import 'zekr_page.dart';

class AzkarPage extends StatefulWidget {
  const AzkarPage({super.key});

  @override
  State<AzkarPage> createState() => _AzkarPageState();
}

class _AzkarPageState extends State<AzkarPage> {
  final TextEditingController _searchController = TextEditingController();
  List<AzkarModel> filteredAzkar = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    final azkarCubit = context.read<AzkarCubit>();
    azkarCubit.loadAzkar();
    // Initially, the filteredAzkar will display all Azkar
    filteredAzkar = [];
  }

  void _filterAzkar(String query) {
    final azkarCubit = context.read<AzkarCubit>();
    if (azkarCubit.state is AzkarLoaded) {
      final azkarList = (azkarCubit.state as AzkarLoaded).azkar;
      setState(() {
        filteredAzkar = azkarList
            .where((azkar) =>
                azkar.category != null &&
                azkar.category!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        final azkarCubit = context.read<AzkarCubit>();
        if (azkarCubit.state is AzkarLoaded) {
          filteredAzkar =
              (azkarCubit.state as AzkarLoaded).azkar; // Reset to all Azkar
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kPrimaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.kSecondaryColor,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                onChanged: _filterAzkar,
                style: AppStyles.styleCairoMedium15white(context),
                decoration: InputDecoration(
                  hintText: 'إبحث عن ذكر ...',
                  hintStyle: AppStyles.styleCairoMedium15white(context),
                  border: InputBorder.none,
                ),
                autofocus: true,
              )
            : Text(
                'الأذكار',
                style: AppStyles.styleCairoBold20(context),
              ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: _toggleSearch,
              child: _isSearching
                  ? const Icon(Icons.close)
                  : const IconConstrain(
                      height: 30,
                      imagePath: Assets.imagesSearch,
                    ),
            ),
          )
        ],
      ),
      body: BlocBuilder<AzkarCubit, AzkarState>(
        builder: (context, state) {
          if (state is AzkarLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          } else if (state is AzkarLoaded) {
            // If not searching, display all Azkar, else display filtered Azkar
            final azkarToDisplay = _isSearching ? filteredAzkar : state.azkar;

            if (azkarToDisplay.isEmpty) {
              return Center(
                child: Text(
                  'الذكر غير موجود',
                  style: AppStyles.styleCairoBold20(context),
                ),
              );
            }

            return ListView.builder(
              itemCount: azkarToDisplay.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ZekrPage(
                          zekerCategory: azkarToDisplay[index].category!,
                          zekerList: azkarToDisplay[index].array!,
                        ),
                      ),
                    );
                  },
                  child: RecitursItem(
                    title: "${azkarToDisplay[index].category}",
                  ),
                );
              },
            );
          } else if (state is AzkarError) {
            return const Center(
              child: Text("حدث خطأ في تحميل الأذكار"),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
