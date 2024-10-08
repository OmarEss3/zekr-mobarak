import 'package:azkar_app/cubit/praying_cubit/praying_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';

import '../../constants.dart';
import 'qiplah_compass.dart';

class ParyPage extends StatefulWidget {
  const ParyPage({super.key});

  @override
  State<ParyPage> createState() => _ParyPageState();
}

class _ParyPageState extends State<ParyPage> {
  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  void getLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low);
    latitude = position.latitude;
    longitude = position.longitude;
    final prayingCubit = context.read<PrayingCubit>();
    prayingCubit.getPrayerTimesByAddress(
      year: "${DateTime.now().year}",
      month: "${DateTime.now().month}",
      latitude: latitude!,
      longitude: longitude!,
    );
    print("${DateTime.now().year}");
    print("${DateTime.now().month}");
    print(latitude.toString());
    print(longitude.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kPrimaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.kSecondaryColor,
        centerTitle: true,
        title: Text(
          "الصلاة",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.kSecondaryColor),
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  BlocBuilder<PrayingCubit, PrayingState>(
                      builder: (context, state) {
                    if (state is PrayingLoading) {
                      return CircularProgressIndicator();
                    } else if (state is PrayingLoaded) {
                      return Column(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: MediaQuery.of(context).size.height * 0.12,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white),
                            child: Row(
                              children: [
                                Container(
                                  child: Image.asset(
                                    "assets/images/next_prayer.png",
                                  ),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.05,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "صلاة ${state.nextPrayerName}",
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: AppColors.kSecondaryColor),
                                    ),
                                    Flexible(
                                      // Use Flexible here
                                      child: Text(
                                        state.nextPraying,
                                        style: TextStyle(
                                            fontSize: 17,
                                            color: AppColors.kSecondaryColor),
                                        overflow: TextOverflow
                                            .ellipsis, // Handle overflow
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    "الفجر",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                  Text(
                                    "${state.timings.fajr}",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              //---------------
                              Column(
                                children: [
                                  Text(
                                    "الظهر",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                  Text(
                                    "${state.timings.dhuhr}",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),

                              //--------------------
                              Column(
                                children: [
                                  Text(
                                    "العصر",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                  Text(
                                    "${state.timings.asr}",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              //-----------------
                              Column(
                                children: [
                                  Text(
                                    "المغرب",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                  Text(
                                    "${state.timings.maghrib}",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              //----------------
                              Column(
                                children: [
                                  Text(
                                    "العشاء",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                  Text(
                                    "${state.timings.isha}",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      );
                    } else if (state is PrayingEError) {
                      // Handle error state
                      return Text(state.error);
                    }
                    return Container();
                  })
                ],
              ),
            ),
            //-----------
            Container(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: FutureBuilder(
                  future: FlutterQiblah.androidDeviceSensorSupport(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error.toString()}'),
                      );
                    }
                    if (snapshot.hasData) {
                      return const QiblaCompass();
                    } else {
                      return const Text('Error');
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
FutureBuilder(
        future: FlutterQiblah.androidDeviceSensorSupport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error.toString()}'),
            );
          }
          if (snapshot.hasData) {
            return const QiblaCompass();
          } else {
            return const Text('Error');
          }
        },
      ),


*/
