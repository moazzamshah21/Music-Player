import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/services/player_service.dart';
import 'package:umarplayer/controllers/home_controller.dart';

class PlayerController extends GetxController {
  final PlayerService playerService = PlayerService();
  late final HomeController homeController;

  final Rx<MediaItem?> currentItem = Rx<MediaItem?>(null);
  final RxBool isPlaying = false.obs;
  final RxBool isLoading = false.obs;
  final RxString loadingMessage = ''.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;

  @override
  void onInit() {
    super.onInit();
    homeController = Get.find<HomeController>();
    _setupListeners();
  }

  void _setupListeners() {
    playerService.audioPlayer.positionStream.listen((pos) {
      position.value = pos;
    });

    playerService.audioPlayer.durationStream.listen((dur) {
      duration.value = dur ?? Duration.zero;
    });

    playerService.audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
    });
  }

  Future<void> playMediaItem(MediaItem item) async {
    try {
      isLoading.value = true;
      loadingMessage.value = 'Fetching audio stream...';
      
      // Set current item immediately for UI feedback
      currentItem.value = item;
      
      // Fetch stream URL
      loadingMessage.value = 'Getting audio stream...';
      await playerService.playMediaItem(item);
      
      // Wait for player to be ready
      loadingMessage.value = 'Preparing playback...';
      
      // Listen for when playback actually starts
      await _waitForPlaybackReady();
      
      // Add to recently played using GetX
      await homeController.addToRecentlyPlayed(item);
      
      isLoading.value = false;
      loadingMessage.value = '';
    } catch (e) {
      isLoading.value = false;
      loadingMessage.value = '';
      print('Error playing media: $e');
      rethrow;
    }
  }

  Future<void> _waitForPlaybackReady() async {
    // Wait for player to be ready (buffering or playing state)
    await for (final state in playerService.audioPlayer.playerStateStream) {
      if (state.processingState == ProcessingState.ready ||
          state.processingState == ProcessingState.buffering ||
          (state.playing && state.processingState == ProcessingState.ready)) {
        break;
      }
      // Timeout after 30 seconds
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> playPause() async {
    await playerService.playPause();
  }

  Future<void> seek(Duration position) async {
    await playerService.seek(position);
  }

  void toggleShuffle() {
    playerService.toggleShuffle();
  }

  void toggleRepeat() {
    playerService.toggleRepeat();
  }

  bool get isShuffleEnabled => playerService.isShuffleEnabled;
  bool get isRepeatEnabled => playerService.isRepeatEnabled;

  @override
  void onClose() {
    playerService.dispose();
    super.onClose();
  }
}
