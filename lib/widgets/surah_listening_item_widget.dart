import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:azkar_app/model/quran_models/reciters_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;
import '../cubit/fav_surah_cubit/fav_surah_item_cubit.dart';
import '../database_helper.dart';
import '../main.dart';
import '../model/quran_models/fav_model.dart';
import '../methods.dart';
import '../constants.dart';
import '../pages/sevices/audio_handler.dart';
import '../utils/app_images.dart';
import '../utils/app_style.dart';

class SurahListeningItem extends StatefulWidget {
  final int index;
  final String audioUrl;
  final void Function(int surahIndex)? onAudioTap;
  final RecitersModel reciter;

  const SurahListeningItem({
    super.key,
    required this.index,
    required this.audioUrl,
    this.onAudioTap,
    required this.reciter,
  });

  @override
  State<SurahListeningItem> createState() => _SurahListeningItemState();
}

class _SurahListeningItemState extends State<SurahListeningItem> {
  bool isExpanded = false;
  bool isPlaying = false;
  bool isFavorite = false;
  Duration totalDuration = Duration.zero;
  Duration currentDuration = Duration.zero;
  late ConnectivityResult _connectivityStatus;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late int currentIndex;
  @override
  void initState() {
    super.initState();
    _initializeFavoriteState();
    _checkInternetConnection();
    currentIndex = widget.index;
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInternetConnection() async {
    final List<ConnectivityResult> connectivityResults =
        await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _connectivityStatus =
            connectivityResults.contains(ConnectivityResult.none)
                ? ConnectivityResult.none
                : connectivityResults.first;
      });
    }
  }

  void _handleAudioAction(Function() action) {
    _checkInternetConnection();
    if (_connectivityStatus == ConnectivityResult.none) {
      showOfflineMessage();
    } else {
      action();
    }
  }

  Future<void> _initializeFavoriteState() async {
    // Check if this surah is marked as favorite
    final favoriteState = await _databaseHelper.isFavoriteExists(
        widget.index, widget.reciter.name);
    if (mounted) {
      setState(() {
        isFavorite = favoriteState;
      });
    }
  }

  void toggleFavorite() {
    if (mounted) {
      setState(() {
        isFavorite = !isFavorite;
        if (isFavorite) {
          var favSurahModel = FavModel(
            url: widget.audioUrl,
            reciter: widget.reciter,
            surahIndex: widget.index,
          );
          BlocProvider.of<FavSurahItemCubit>(context)
              .addFavSurahItem(favSurahModel);
        } else {
          BlocProvider.of<FavSurahItemCubit>(context)
              .deleteFavSurah(widget.index, widget.reciter.name);
        }
      });
    }
  }

  void playPreviousSurah(AudioPlayerHandler audioHandler) {
    currentIndex -= 1;
    // showMessage("جاري تشغيل السورة السابقة");

    // if (currentIndex < 0) {
    //   showMessage("لا يوجد سورة سابقة");
    //   return;
    // }

    audioHandler.togglePlayPause(
      isPlaying: false,
      audioUrl: widget.reciter.zeroPaddingSurahNumber
          ? '${widget.reciter.url}${(currentIndex + 1).toString().padLeft(3, '0')}.mp3'
          : '${widget.reciter.url}${currentIndex + 1}.mp3',
      albumName: widget.reciter.name,
      title: quran.getSurahNameArabic(currentIndex + 1),
      index: currentIndex,
      playlistIndex: currentIndex, // Pass the playlist index here!
      setIsPlaying: (_) {},
    );
    setState(() {
      isExpanded = true;
    });
  }

  void playNextSurah(AudioPlayerHandler audioHandler) {
    currentIndex += 1;
    // showMessage("جاري تشغيل السورة التالية");

    // if (currentIndex >= 114) {
    //   showMessage("لا يوجد سورة تالية");
    //   return;
    // }

    audioHandler.togglePlayPause(
      isPlaying: false,
      audioUrl: widget.reciter.zeroPaddingSurahNumber
          ? '${widget.reciter.url}${(currentIndex + 1).toString().padLeft(3, '0')}.mp3'
          : '${widget.reciter.url}${currentIndex + 1}.mp3',
      albumName: widget.reciter.name,
      title: quran.getSurahNameArabic(currentIndex + 1),
      index: currentIndex,
      playlistIndex: currentIndex, // Important: pass the updated index!
      setIsPlaying: (_) {},
    );
    setState(() {
      isExpanded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: globalAudioHandler.mediaItem,
      builder: (context, snapshot) {
        final currentMedia = snapshot.data;

        if (currentMedia != null && currentMedia.extras != null) {
          if (globalAudioHandler.mediaItem.value?.extras?['URL'] ==
              widget.audioUrl) {
            Future.microtask(() {
              setState(() {
                isExpanded = true;
              });
            });
          }
        }
        return Column(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: buildSurahItem(),
            ),
          ],
        );
      },
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
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            spreadRadius: .1,
          )
        ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 10),
        GestureDetector(
          onTap: toggleFavorite,
          child: isFavorite
              ? const Icon(Icons.favorite, color: Colors.red, size: 30)
              : SvgPicture.asset(
                  height: 30,
                  Assets.imagesHeart,
                  placeholderBuilder: (context) => const Icon(Icons.error),
                ),
        ),
        const SizedBox(width: 10),
        Text(
          'سورة ${quran.getSurahNameArabic(widget.index + 1)}',
          style: AppStyles.styleRajdhaniMedium18(context)
              .copyWith(color: Colors.black),
        ),
        const Spacer(),
        buildActionButtons(),
      ],
    );
  }

  Widget buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => shareAudio(widget.audioUrl),
          child: SvgPicture.asset(
            height: 30,
            Assets.imagesShare,
            placeholderBuilder: (context) => const Icon(Icons.error),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _handleAudioAction(() {
            // showMessage("جاري التحميل...");
            downloadAudio(widget.audioUrl,
                quran.getSurahNameArabic(widget.index + 1), context);
          }),
          child: SvgPicture.asset(
            height: 30,
            Assets.imagesDocumentDownload,
            placeholderBuilder: (context) => const Icon(Icons.error),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget buildExpandedContent() {
    return Column(
      children: [
        buildDurationRow(),
        buildSlider(),
        buildControlButtons(),
      ],
    );
  }

  Widget buildDurationRow() {
    return StreamBuilder<MediaItem?>(
      stream: globalAudioHandler.mediaItem,
      builder: (context, mediaSnapshot) {
        if (globalAudioHandler.mediaItem.value?.extras?['URL'] ==
            widget.audioUrl) {
          return StreamBuilder<Duration>(
            stream: globalAudioHandler.positionStream,
            builder: (context, posSnapshot) {
              final position = posSnapshot.data ?? Duration.zero;
              return StreamBuilder<Duration?>(
                stream: globalAudioHandler.durationStream,
                builder: (context, durSnapshot) {
                  final duration = durSnapshot.data ?? Duration.zero;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: AppStyles.alwaysBlack18(context),
                        ),
                        Text(
                          '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: AppStyles.alwaysBlack18(context),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        } else {
          // Not playing: show zeros.
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0:00', style: AppStyles.alwaysBlack18(context)),
                Text('0:00', style: AppStyles.alwaysBlack18(context)),
              ],
            ),
          );
        }
      },
    );
  }

  Widget buildSlider() {
    return StreamBuilder<MediaItem?>(
      stream: globalAudioHandler.mediaItem,
      builder: (context, snapshot) {
        if (globalAudioHandler.mediaItem.value?.extras?['URL'] ==
            widget.audioUrl) {
          return StreamBuilder<Duration>(
            stream: globalAudioHandler.positionStream,
            builder: (context, posSnapshot) {
              final position = posSnapshot.data ?? Duration.zero;
              return StreamBuilder<Duration?>(
                stream: globalAudioHandler.durationStream,
                builder: (context, durSnapshot) {
                  final duration = durSnapshot.data ?? Duration.zero;
                  // Remove the manual next track trigger here
                  return Slider(
                    activeColor: AppColors.kSecondaryColor,
                    inactiveColor: AppColors.kPrimaryColor,
                    value: position.inSeconds.toDouble(),
                    max: duration.inSeconds > 0
                        ? duration.inSeconds.toDouble()
                        : 1,
                    onChanged: (value) {
                      globalAudioHandler.seek(Duration(seconds: value.toInt()));
                    },
                  );
                },
              );
            },
          );
        } else {
          return Slider(
            activeColor: AppColors.kSecondaryColor,
            inactiveColor: AppColors.kPrimaryColor,
            value: 0,
            max: 1,
            onChanged: null,
          );
        }
      },
    );
  }

  Widget buildControlButtons() {
    return StreamBuilder<PlaybackState>(
      stream: globalAudioHandler.playbackState,
      builder: (context, snapshot) {
        final playbackState = snapshot.data;
        final isCurrentItem =
            globalAudioHandler.mediaItem.value?.extras?['URL'] ==
                widget.audioUrl;

        final bool playing = playbackState?.playing ?? false;
        final bool isLoading = playbackState?.processingState ==
                AudioProcessingState.loading ||
            playbackState?.processingState == AudioProcessingState.buffering;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: isCurrentItem && playing
                  ? () => playPreviousSurah(globalAudioHandler)
                  : null,
              icon: Icon(
                Icons.skip_next,
                size: 30,
                color: isCurrentItem && playing ? Colors.black : Colors.grey,
              ),
            ),
            IconButton(
              onPressed: isCurrentItem && playing
                  ? () => globalAudioHandler.decreaseSpeed()
                  : null,
              icon: Icon(
                Icons.fast_forward,
                size: 30,
                color: isCurrentItem && playing ? Colors.black : Colors.grey,
              ),
            ),
            IconButton(
              onPressed: () {
                _handleAudioAction(() {
                  globalAudioHandler.togglePlayPause(
                    isPlaying: isCurrentItem && playing,
                    audioUrl: widget.audioUrl,
                    albumName: widget.reciter.name,
                    title: quran.getSurahNameArabic(widget.index + 1),
                    index: widget.index,
                    playlistIndex: widget.index,
                    setIsPlaying: (playing) {
                      if (mounted) {
                        setState(() {
                          isPlaying = playing;
                        });
                      }
                    },
                    onAudioTap: widget.onAudioTap != null
                        ? () => widget.onAudioTap!(widget.index)
                        : null,
                  );
                });
              },
              icon: isLoading
                  ? SizedBox(
                      height: 45,
                      width: 45,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.kSecondaryColor),
                      ),
                    )
                  : Icon(
                      isCurrentItem && playing
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      color: Colors.black,
                      size: 45,
                    ),
            ),
            IconButton(
              onPressed: isCurrentItem && playing
                  ? () => globalAudioHandler.increaseSpeed()
                  : null,
              icon: Icon(
                Icons.fast_rewind,
                size: 30,
                color: isCurrentItem && playing ? Colors.black : Colors.grey,
              ),
            ),
            IconButton(
              onPressed: isCurrentItem && playing
                  ? () => playNextSurah(globalAudioHandler)
                  : null,
              icon: Icon(
                Icons.skip_previous,
                size: 30,
                color: isCurrentItem && playing ? Colors.black : Colors.grey,
              ),
            ),
          ],
        );
      },
    );
  }
}
