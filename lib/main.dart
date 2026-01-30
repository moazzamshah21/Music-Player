import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umarplayer/navigation/main_navigation.dart';
import 'package:umarplayer/theme/app_theme.dart';
import 'package:umarplayer/providers/home_provider.dart';
import 'package:umarplayer/providers/player_provider.dart';
import 'package:umarplayer/providers/downloads_provider.dart';
import 'package:umarplayer/providers/library_provider.dart';
import 'package:umarplayer/providers/search_provider.dart';
import 'package:umarplayer/providers/liked_songs_provider.dart';
import 'package:umarplayer/services/audio_service_manager.dart';
import 'package:umarplayer/services/notification_service.dart';

import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.umarplayer.channel.audio',
    androidNotificationChannelName: 'Umar Player',
    androidNotificationOngoing: true,
  );

  print('🚀 Starting app initialization...');
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late AudioServiceManager audioServiceManager;
  late HomeProvider homeProvider;
  late PlayerProvider playerProvider;
  late DownloadsProvider downloadsProvider;
  late LibraryProvider libraryProvider;
  late SearchProvider searchProvider;
  late LikedSongsProvider likedSongsProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize services and providers
    audioServiceManager = AudioServiceManager();
    homeProvider = HomeProvider();
    playerProvider = PlayerProvider();
    downloadsProvider = DownloadsProvider();
    libraryProvider = LibraryProvider();
    searchProvider = SearchProvider();
    likedSongsProvider = LikedSongsProvider();
    
    // Initialize player provider with dependencies
    playerProvider.initialize(audioServiceManager, homeProvider,
        likedSongsProvider: likedSongsProvider);
    likedSongsProvider.setPlayerProvider(playerProvider);

    // Pre-initialize AudioService so media notification is ready when user plays
    WidgetsBinding.instance.addPostFrameCallback((_) {
      audioServiceManager.ensureInitialized();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      playerProvider.syncStateFromPlayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: audioServiceManager),
        ChangeNotifierProvider.value(value: homeProvider),
        ChangeNotifierProvider.value(value: playerProvider),
        ChangeNotifierProvider.value(value: downloadsProvider),
        ChangeNotifierProvider.value(value: libraryProvider),
        ChangeNotifierProvider.value(value: searchProvider),
        ChangeNotifierProvider.value(value: likedSongsProvider),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Umar Player',
        theme: AppTheme.darkTheme,
        home: const MainNavigation(),
      ),
    );
  }
}
