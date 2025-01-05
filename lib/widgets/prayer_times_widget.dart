import 'package:flutter/material.dart';
import '../model/praying_model/praying_model/timings.dart';

List<Widget> buildPrayerTimes(BuildContext context, Timings timings) {
  final prayerTimes = [
    {"name": "الفجر", "time": timings.fajr},
    {"name": "الشروق", "time": timings.sunrise},
    {"name": "الظهر", "time": timings.dhuhr},
    {"name": "العصر", "time": timings.asr},
    {"name": "المغرب", "time": timings.maghrib},
    {"name": "العشاء", "time": timings.isha},
  ];

  return prayerTimes
      .map(
        (prayer) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                prayer["name"]!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                prayer["time"] ?? "غير متوفر",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      )
      .toList();
}
