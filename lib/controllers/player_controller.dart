import 'dart:math';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/services/player_service.dart';
import 'package:umarplayer/services/liked_songs_service.dart';
import 'package:umarplayer/services/recently_played_service.dart';
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
  final RxBool isLiked = false.obs;
  
  // Queue management
  final RxList<MediaItem> _queue = <MediaItem>[].obs;
  final RxInt _currentIndex = (-1).obs;
  final RxList<MediaItem> _originalQueue = <MediaItem>[].obs; // For shuffle
  
  List<MediaItem> get queue => _queue.toList();
  int get currentIndex => _currentIndex.value;

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
      
      // Auto-play next song when current song ends (if not repeating)
      if (state.processingState == ProcessingState.completed && 
          !state.playing &&
          !isRepeatEnabled) {
        _playNext();
      }
    });
  }

  Future<void> playMediaItem(MediaItem item, {List<MediaItem>? queue}) async {
    try {
      isLoading.value = true;
      loadingMessage.value = 'Fetching audio stream...';
      
      // Set queue if provided
      if (queue != null && queue.isNotEmpty) {
        _originalQueue.value = List.from(queue);
        _queue.value = isShuffleEnabled ? _shuffleList(List.from(queue)) : List.from(queue);
        _currentIndex.value = _queue.indexWhere((s) => s.id == item.id);
        if (_currentIndex.value == -1) {
          _currentIndex.value = 0;
        }
      } else {
        // If no queue, use recently played as fallback
        final recentlyPlayed = await RecentlyPlayedService.getRecentlyPlayed();
        if (recentlyPlayed.isNotEmpty) {
          _originalQueue.value = List.from(recentlyPlayed);
          _queue.value = isShuffleEnabled ? _shuffleList(List.from(recentlyPlayed)) : List.from(recentlyPlayed);
          _currentIndex.value = _queue.indexWhere((s) => s.id == item.id);
          if (_currentIndex.value == -1) {
            _currentIndex.value = 0;
          }
        } else {
          // Single item queue
          _queue.value = [item];
          _originalQueue.value = [item];
          _currentIndex.value = 0;
        }
      }
      
      // Set current item immediately for UI feedback
      currentItem.value = item;
      
      // Check if song is liked
      _updateLikedStatus(item.id);
      
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
  
  List<MediaItem> _shuffleList(List<MediaItem> list) {
    final shuffled = List<MediaItem>.from(list);
    shuffled.shuffle(Random());
    return shuffled;
  }
  
  Future<void> _playNext() async {
    if (_queue.isEmpty || _currentIndex.value == -1) return;
    
    int nextIndex;
    if (isShuffleEnabled) {
      // In shuffle mode, pick random from original queue
      if (_originalQueue.isEmpty) return;
      final random = Random();
      nextIndex = random.nextInt(_originalQueue.length);
      final nextItem = _originalQueue[nextIndex];
      // Find in shuffled queue or add
      final indexInShuffled = _queue.indexWhere((s) => s.id == nextItem.id);
      if (indexInShuffled != -1) {
        _currentIndex.value = indexInShuffled;
      } else {
        _queue.add(nextItem);
        _currentIndex.value = _queue.length - 1;
      }
    } else {
      // Normal mode: play next in queue
      nextIndex = (_currentIndex.value + 1) % _queue.length;
      _currentIndex.value = nextIndex;
    }
    
    if (_currentIndex.value < _queue.length) {
      await _playItemFromQueue(_queue[_currentIndex.value]);
    }
  }
  
  Future<void> _playPrevious() async {
    if (_queue.isEmpty || _currentIndex.value == -1) return;
    
    int prevIndex;
    if (isShuffleEnabled) {
      // In shuffle mode, pick random from original queue
      if (_originalQueue.isEmpty) return;
      final random = Random();
      prevIndex = random.nextInt(_originalQueue.length);
      final prevItem = _originalQueue[prevIndex];
      // Find in shuffled queue or add
      final indexInShuffled = _queue.indexWhere((s) => s.id == prevItem.id);
      if (indexInShuffled != -1) {
        _currentIndex.value = indexInShuffled;
      } else {
        _queue.insert(0, prevItem);
        _currentIndex.value = 0;
      }
    } else {
      // Normal mode: play previous in queue
      prevIndex = (_currentIndex.value - 1) % _queue.length;
      if (prevIndex < 0) prevIndex = _queue.length - 1;
      _currentIndex.value = prevIndex;
    }
    
    if (_currentIndex.value >= 0 && _currentIndex.value < _queue.length) {
      await _playItemFromQueue(_queue[_currentIndex.value]);
    }
  }
  
  Future<void> _playItemFromQueue(MediaItem item) async {
    try {
      isLoading.value = true;
      loadingMessage.value = 'Loading next song...';
      
      // Set current item immediately for UI feedback
      currentItem.value = item;
      
      // Check if song is liked
      _updateLikedStatus(item.id);
      
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
  
  Future<void> playNext() async {
    await _playNext();
  }
  
  Future<void> playPrevious() async {
    // If less than 3 seconds into song, go to previous track
    // Otherwise, restart current track
    if (position.value.inSeconds < 3) {
      await _playPrevious();
    } else {
      await seek(Duration.zero);
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
    
    // Reshuffle queue if shuffle is enabled
    if (isShuffleEnabled && _originalQueue.isNotEmpty) {
      _queue.value = _shuffleList(List.from(_originalQueue));
      // Update current index to match current item
      if (currentItem.value != null) {
        final newIndex = _queue.indexWhere((s) => s.id == currentItem.value!.id);
        if (newIndex != -1) {
          _currentIndex.value = newIndex;
        }
      }
    } else if (!isShuffleEnabled && _originalQueue.isNotEmpty) {
      // Restore original order
      _queue.value = List.from(_originalQueue);
      // Update current index to match current item
      if (currentItem.value != null) {
        final newIndex = _queue.indexWhere((s) => s.id == currentItem.value!.id);
        if (newIndex != -1) {
          _currentIndex.value = newIndex;
        }
      }
    }
  }

  void toggleRepeat() {
    playerService.toggleRepeat();
  }

  bool get isShuffleEnabled => playerService.isShuffleEnabled;
  bool get isRepeatEnabled => playerService.isRepeatEnabled;

  Future<void> _updateLikedStatus(String songId) async {
    final liked = await LikedSongsService.isLiked(songId);
    isLiked.value = liked;
  }

  Future<void> toggleFavorite() async {
    if (currentItem.value == null) return;
    
    final newLikedStatus = await LikedSongsService.toggleLike(currentItem.value!);
    isLiked.value = newLikedStatus;
  }

  @override
  void onClose() {
    playerService.dispose();
    super.onClose();
  }
}
