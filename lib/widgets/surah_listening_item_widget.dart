import 'package:azkar_app/model/quran_models/reciters_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:quran/quran.dart' as quran;
import '../cubit/add_fav_surahcubit/add_fav_surah_item_cubit.dart';
import '../database_helper.dart';
import '../model/quran_models/fav_model.dart';
import '../methods.dart';
import '../constants.dart';
import '../utils/app_images.dart';
import '../utils/app_style.dart';
import 'icon_constrain_widget.dart';

class SurahListeningItem extends StatefulWidget {
  final int surahIndex;
  final String audioUrl;
  final void Function(int surahIndex)? onSurahTap;
  final RecitersModel reciter;
  const SurahListeningItem(
      {super.key,
      required this.surahIndex,
      required this.audioUrl,
      this.onSurahTap,
       required this.reciter});

  @override
  State<SurahListeningItem> createState() => _SurahListeningItemState();
}

class _SurahListeningItemState extends State<SurahListeningItem> {
  bool isExpanded = false;
  bool isPlaying = false;
  bool isFavorite = false;
  Duration totalDuration = Duration.zero;
  Duration currentDuration = Duration.zero;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConnectivityResult _connectivityStatus;
  late DatabaseHelper _databaseHelper;

  @override
  void initState() {
    super.initState();
    initializeAudioPlayer(
        _audioPlayer, setTotalDuration, setCurrentDuration, setIsPlaying);
    _checkInternetConnection();
    _databaseHelper = DatabaseHelper();
  }

  @override
  void dispose() {
      _audioPlayer.stop();
    _audioPlayer.dispose();

    super.dispose();
  }

  void setTotalDuration(Duration duration) {
    setState(() {
      totalDuration = duration;
    });
  }

  void setCurrentDuration(Duration duration) {
    setState(() {
      currentDuration = duration;
    });
  }

  void setIsPlaying(bool playing) {
    setState(() {
      isPlaying = playing;
    });
  }

  Future<void> _checkInternetConnection() async {
    final List<ConnectivityResult> connectivityResults =
        await Connectivity().checkConnectivity();

    setState(() {
      _connectivityStatus =
          connectivityResults.contains(ConnectivityResult.none)
              ? ConnectivityResult.none
              : connectivityResults.first;
    });

    if (_connectivityStatus == ConnectivityResult.none) {
      showMessage('لا يوجد اتصال بالانترنت .');
    }
  }

  void showMessage(String message) {
    Fluttertoast.showToast(msg: message);
  }

  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
      if (isFavorite) {
        var favSurahModel = FavModel(
          url: widget.audioUrl,
          reciter: widget. reciter,
          surahIndex: widget.surahIndex,
        );
        BlocProvider.of<AddFavSurahItemCubit>(context)
            .addFavSurahItem(favSurahModel);
      } else {
        BlocProvider.of<AddFavSurahItemCubit>(context)
            .deleteFavSurah(widget.surahIndex, widget.reciter.name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
            if (widget.onSurahTap != null) {
              widget.onSurahTap!(widget.surahIndex);
            }
          },
          child: buildSurahItem(),
        ),
      ],
    );
  }

  Widget buildSurahItem() {
    return Container(
      height: isExpanded ? null : 53,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildSurahRow(),
          if (isExpanded) buildExpandedContent(),
        ],
      ),
    );
  }

  Widget buildSurahRow() {
    return FutureBuilder<bool>(
      future: _databaseHelper.isFavoriteExists(
          widget.surahIndex, widget.reciter.name),
      builder: (context, snapshot) {
        // Check if the future is complete and has a valid result
        if (snapshot.connectionState == ConnectionState.done) {
          // Check if the future returned a value
          if (snapshot.hasData && snapshot.data == true) {
            isFavorite = true;
            return Row(
              children: [
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: toggleFavorite,
                  child:
                      const Icon(Icons.favorite, color: Colors.red, size: 30),
                ),
                const SizedBox(width: 10),
                Text(
                  'سورة ${quran.getSurahNameArabic(widget.surahIndex + 1)}',
                  style: AppStyles.styleRajdhaniMedium18(context),
                ),
                const Spacer(),
                buildActionButtons(),
              ],
            );
          } else {
            isFavorite = false;
            return Row(
              children: [
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: toggleFavorite,
                  child: const IconConstrain(
                      height: 30, imagePath: Assets.imagesHeart),
                ),
                const SizedBox(width: 10),
                Text(
                  'سورة ${quran.getSurahNameArabic(widget.surahIndex + 1)}',
                  style: AppStyles.styleRajdhaniMedium18(context),
                ),
                const Spacer(),
                buildActionButtons(),
              ],
            );
          }
        } else {
          return Row(
            children: [
              const SizedBox(width: 10),
              const CircularProgressIndicator(),
              const SizedBox(width: 10),
              Text(
                'سورة ${quran.getSurahNameArabic(widget.surahIndex + 1)}',
                style: AppStyles.styleRajdhaniMedium18(context),
              ),
              const Spacer(),
              buildActionButtons(),
            ],
          );
        }
      },
    );
  }

  Widget buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () {
            if (_connectivityStatus == ConnectivityResult.none) {
              showMessage('لا يتوفر اتصال بالانترنت.');
            } else {
              shareAudio(widget.audioUrl);
            }
          },
          child: const IconConstrain(height: 30, imagePath: Assets.imagesShare),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            if (_connectivityStatus == ConnectivityResult.none) {
              showMessage('لا يتوفر اتصال بالانترنت.');
            } else {
              downloadAudio(widget.audioUrl, widget.surahIndex, context);
            }
          },
          child: const IconConstrain(
              height: 30, imagePath: Assets.imagesDocumentDownload),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          buildDurationRow(),
          buildSlider(),
          buildControlButtons(),
        ],
      ),
    );
  }

  Widget buildDurationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${currentDuration.inMinutes}:${(currentDuration.inSeconds % 60).toString().padLeft(2, '0')}',
          style: AppStyles.styleRajdhaniMedium18(context),
        ),
        Text(
          '${totalDuration.inMinutes}:${(totalDuration.inSeconds % 60).toString().padLeft(2, '0')}',
          style: AppStyles.styleRajdhaniMedium18(context),
        ),
      ],
    );
  }

  Widget buildSlider() {
    return Slider(
  activeColor: AppColors.kSecondaryColor,
  inactiveColor: AppColors.kPrimaryColor,
  value: currentDuration.inSeconds.toDouble(),
  max: totalDuration.inSeconds > 0 ? totalDuration.inSeconds.toDouble() : 1,
  onChanged: totalDuration.inSeconds > 0 ? (value) {
    setState(() {
      currentDuration = Duration(seconds: value.toInt());
    });
    _audioPlayer.seek(currentDuration);
  } : null,
);

  }

  Widget buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () => backward(_audioPlayer),
          child:
              const IconConstrain(height: 24, imagePath: Assets.imagesForward),
        ),
        IconButton(
          onPressed: () {
            if (_connectivityStatus == ConnectivityResult.none) {
              showMessage('No internet connection.');
            } else {
              togglePlayPause(
                  _audioPlayer, isPlaying, widget.audioUrl, setIsPlaying);
            }
          },
          icon: Icon(
            isPlaying ? Icons.pause_circle : Icons.play_circle,
            color: AppColors.kSecondaryColor,
            size: 45,
          ),
        ),
        GestureDetector(
          onTap: () => forward(_audioPlayer),
          child:
              const IconConstrain(height: 24, imagePath: Assets.imagesBackward),
        ),
      ],
    );
  }
}
