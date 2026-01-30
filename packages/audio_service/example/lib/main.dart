// ignore_for_file: public_member_api_docs

// FOR MORE EXAMPLES, VISIT THE GITHUB REPOSITORY AT:
//
//  https://github.com/ryanheise/audio_service
//
// This example implements a minimal audio handler that renders the current
// media item and playback state to the system notification and responds to 4
// media actions:
//
// - play
// - pause
// - seek
// - stop
//
// To run this example, use:
//
// flutter run

import 'dart:async';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:audio_service_example/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

// Gen-Z / futuristic palette
const Color _neonCyan = Color(0xFF00F5D4);
const Color _neonMagenta = Color(0xFFF72585);
const Color _deepPurple = Color(0xFF0D0221);
const Color _surfaceDark = Color(0xFF1A0B2E);
const Color _glassWhite = Color(0x18FFFFFF);

// You might want to provide this using dependency injection rather than a
// global variable.
late AudioHandler _audioHandler;

Future<void> main() async {
  _audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Service Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _deepPurple,
        primaryColor: _neonCyan,
        colorScheme: const ColorScheme.dark(
          primary: _neonCyan,
          secondary: _neonMagenta,
          surface: _surfaceDark,
          onPrimary: _deepPurple,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          onSurfaceVariant: Color(0xFFB8B8D1),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: _neonCyan),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('vibes'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _deepPurple,
              Color(0xFF2D1B4E),
              _surfaceDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glass card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: _glassWhite,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Media title with gradient text
                            StreamBuilder<MediaItem?>(
                              stream: _audioHandler.mediaItem,
                              builder: (context, snapshot) {
                                final mediaItem = snapshot.data;
                                final title =
                                    mediaItem?.title ?? 'nothing playing';
                                return ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: [_neonCyan, _neonMagenta],
                                  ).createShader(bounds),
                                  child: Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 28),
                            // Control buttons with glow
                            StreamBuilder<bool>(
                              stream: _audioHandler.playbackState
                                  .map((state) => state.playing)
                                  .distinct(),
                              builder: (context, snapshot) {
                                final playing = snapshot.data ?? false;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _glowButton(
                                        context, Icons.fast_rewind, _audioHandler.rewind),
                                    const SizedBox(width: 8),
                                    _glowButton(
                                      context,
                                      playing ? Icons.pause : Icons.play_arrow,
                                      playing
                                          ? _audioHandler.pause
                                          : _audioHandler.play,
                                      isPrimary: true,
                                    ),
                                    const SizedBox(width: 8),
                                    _glowButton(
                                        context, Icons.stop, _audioHandler.stop),
                                    const SizedBox(width: 8),
                                    _glowButton(
                                        context, Icons.fast_forward, _audioHandler.fastForward),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            // Seek bar
                            StreamBuilder<MediaState>(
                              stream: _mediaStateStream,
                              builder: (context, snapshot) {
                                final mediaState = snapshot.data;
                                return SeekBar(
                                  duration: mediaState?.mediaItem?.duration ??
                                      Duration.zero,
                                  position: mediaState?.position ?? Duration.zero,
                                  onChangeEnd: (newPosition) {
                                    _audioHandler.seek(newPosition);
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            // Processing state pill
                            StreamBuilder<AudioProcessingState>(
                              stream: _audioHandler.playbackState
                                  .map((state) => state.processingState)
                                  .distinct(),
                              builder: (context, snapshot) {
                                final processingState = snapshot.data ??
                                    AudioProcessingState.idle;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _neonCyan.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _neonCyan.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    // ignore: deprecated_member_use
                                    describeEnum(processingState),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _neonCyan,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A stream reporting the combined state of the current media item and its
  /// current position.
  Stream<MediaState> get _mediaStateStream =>
      Rx.combineLatest2<MediaItem?, Duration, MediaState>(
          _audioHandler.mediaItem,
          AudioService.position,
          (mediaItem, position) => MediaState(mediaItem, position));

  Widget _glowButton(
    BuildContext context,
    IconData iconData,
    VoidCallback onPressed, {
    bool isPrimary = false,
  }) {
    final color = isPrimary ? _neonMagenta : _neonCyan;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: isPrimary ? 72 : 56,
          height: isPrimary ? 72 : 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
            border: Border.all(color: color.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: isPrimary ? 20 : 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(iconData, color: color, size: isPrimary ? 36 : 28),
        ),
      ),
    );
  }
}

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}

/// An [AudioHandler] for playing a single item.
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  static final _item = MediaItem(
    id: 'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3',
    album: "Science Friday",
    title: "A Salute To Head-Scratching Science",
    artist: "Science Friday and WNYC Studios",
    duration: const Duration(milliseconds: 5739820),
    artUri: Uri.parse(
        'https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg'),
  );

  final _player = AudioPlayer();

  /// Initialise our audio handler.
  AudioPlayerHandler() {
    // So that our clients (the Flutter UI and the system notification) know
    // what state to display, here we set up our audio handler to broadcast all
    // playback state changes as they happen via playbackState...
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    // ... and also the current media item via mediaItem.
    mediaItem.add(_item);

    // Load the player.
    _player.setAudioSource(AudioSource.uri(Uri.parse(_item.id)));
  }

  // In this simple example, we handle only 4 actions: play, pause, seek and
  // stop. Any button press from the Flutter UI, notification, lock screen or
  // headset will be routed through to these 4 methods so that you can handle
  // your audio playback logic in one place.

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  /// Transform a just_audio event into an audio_service state.
  ///
  /// This method is used from the constructor. Every event received from the
  /// just_audio player will be transformed into an audio_service state so that
  /// it can be broadcast to audio_service clients.
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
