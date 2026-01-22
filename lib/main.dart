import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umarplayer/navigation/main_navigation.dart';
import 'package:umarplayer/theme/app_theme.dart';
import 'package:umarplayer/controllers/home_controller.dart';
import 'package:umarplayer/controllers/player_controller.dart';
import 'package:umarplayer/controllers/downloads_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize GetX controllers
    Get.put(HomeController());
    Get.put(PlayerController());
    Get.put(DownloadsController());

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Umar Player',
      theme: AppTheme.darkTheme,
      home: const MainNavigation(),
    );
  }
}