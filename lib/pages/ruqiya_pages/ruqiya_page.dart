import 'package:azkar_app/cubit/ruqiya_cubit/ruqiya_cubit.dart';
import 'package:azkar_app/utils/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../constants.dart';

class RuqiyaPage extends StatefulWidget {
  const RuqiyaPage({super.key});

  @override
  State<RuqiyaPage> createState() => _RuqiyaPageState();
}

class _RuqiyaPageState extends State<RuqiyaPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RuqiyaCubit()
        ..loadRuqiya(), // Ensure cubit is provided and loadRuqiya is called
      child: Scaffold(
        backgroundColor: AppColors.kPrimaryColor,
        appBar: AppBar(
          backgroundColor: AppColors.kSecondaryColor,
          centerTitle: true,
          title: Text(
            "الرقية الشرعية",
            style: AppStyles.styleCairoBold20(context),
          ),
        ),
        body: BlocBuilder<RuqiyaCubit, RuqiyaState>(
          builder: ((context, state) {
            if (state is RuqiyaLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            } else if (state is RuqiyaLoaded) {
              return Padding(
                padding: const EdgeInsets.all(15),
                child: ListView.builder(
                  itemCount: state.ruqiya.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.kSecondaryColor,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(state.ruqiya[index].text!,
                                  textAlign: TextAlign.justify,
                                  style: AppStyles.styleCairoBold20(context)),
                              Divider(
                                color: AppColors.kPrimaryColor,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    state.ruqiya[index].info!,
                                    textAlign: TextAlign.justify,
                                    style: AppStyles.styleCairoBold20(context),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(
                                          text: state.ruqiya[index].text!));
                                      Fluttertoast.showToast(
                                          msg: "تم النسخ بنجاح للحافظة");
                                    },
                                    icon: const Icon(
                                      Icons.copy,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            } else if (state is RuqiyaError) {
              return Center(
                child: Text(
                  state.error,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            } else {
              return Container();
            }
          }),
        ),
      ),
    );
  }
}
