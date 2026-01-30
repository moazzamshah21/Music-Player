import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/services/player_service.dart';
import 'package:umarplayer/services/audio_service_manager.dart';
import 'package:umarplayer/services/liked_songs_service.dart';
import 'package:umarplayer/providers/home_provider.dart';
import 'package:umarplayer/providers/liked_songs_provider.dart';

class PlayerProvider extends ChangeNotifier {
  final PlayerService playerService = PlayerService();
  AudioServiceManager? audioServiceManager;
  HomeProvider? homeProvider;
  LikedSongsProvider? likedSongsProvider;

  MediaItem? _currentItem;
  bool _isPlaying = false;
  bool _isLoading = false;
  String _loadingMessage = '';
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLiked = false;
  ProcessingState _processingState = ProcessingState.idle;
  bool _isSeeking = false;

  // Queue management
  List<MediaItem> _queue = [];
  int _currentIndex = -1;
  List<MediaItem> _originalQueue = []; // For shuffle

  // Stream subscriptions
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  // Getters
  MediaItem? get currentItem => _currentItem;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isLiked => _isLiked;
  ProcessingState get processingState => _processingState;
  bool get isBuffering =>
      _processingState == ProcessingState.buffering ||
      _processingState == ProcessingState.loading;
  List<MediaItem> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  bool get isShuffleEnabled => playerService.isShuffleEnabled;
  bool get isRepeatEnabled => playerService.isRepeatEnabled;

  /// Call during slider drag to prevent position stream from overwriting user input.
  void setSeeking(bool seeking) {
    if (_isSeeking != seeking) {
      _isSeeking = seeking;
      if (!seeking) {
        _position = playerService.audioPlayer.position;
      }
      notifyListeners();
    }
  }

  /// Force sync state from actual player - call when app resumes or to fix desync.
  void syncStateFromPlayer() {
    final state = playerService.audioPlayer.playerState;
    final pos = playerService.audioPlayer.position;
    final dur = playerService.audioPlayer.duration ?? Duration.zero;

    bool changed = false;
    if (_isPlaying != state.playing) {
      _isPlaying = state.playing;
      changed = true;
    }
    if (_processingState != state.processingState) {
      _processingState = state.processingState;
      changed = true;
    }
    if (!_isSeeking && _position != pos) {
      _position = pos;
      changed = true;
    }
    if (_duration != dur) {
      _duration = dur;
      changed = true;
    }
    if (playerService.currentItem != null &&
        (_currentItem == null || _currentItem!.id != playerService.currentItem!.id)) {
      _currentItem = playerService.currentItem;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void initialize(
    AudioServiceManager audioServiceManager,
    HomeProvider homeProvider, {
    LikedSongsProvider? likedSongsProvider,
  }) {
    this.audioServiceManager = audioServiceManager;
    this.homeProvider = homeProvider;
    this.likedSongsProvider = likedSongsProvider;
    // Connect the app's player to notification bar controls - critical for
    // background mini player interaction
    audioServiceManager.setPlayerService(playerService);
    // Sync UI when user changes track via notification bar (next/previous)
    audioServiceManager.setOnTrackChanged((item, queue, index) {
      _currentItem = item;
      _queue = queue;
      _currentIndex = index;
      _updateLikedStatus(item.id);
      homeProvider.addToRecentlyPlayed(item);
      notifyListeners();
    });
    _setupListeners();
  }

  void _setupListeners() {
    // Position updates - skip when user is dragging slider to prevent jump-back
    _positionSubscription = playerService.audioPlayer.positionStream.listen((pos) {
      if (_isSeeking) return;
      _position = pos;

      // Clear loading when progress bar starts moving (position > 0 and duration > 0)
      if (_isLoading && pos.inMilliseconds > 0 && _duration.inMilliseconds > 0) {
        _isLoading = false;
        _loadingMessage = '';
      }
      notifyListeners();
    });

    // Duration updates
    _durationSubscription = playerService.audioPlayer.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    // Player state updates - source of truth for play state and processing
    _playerStateSubscription = playerService.audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _processingState = state.processingState;

      // Clear loading state when playback actually starts
      if (_isLoading &&
          (state.processingState == ProcessingState.ready ||
              state.processingState == ProcessingState.buffering ||
              state.playing)) {
        _isLoading = false;
        _loadingMessage = '';
      }

      notifyListeners();
      
      // Auto-play next song when current song ends
      if (state.processingState == ProcessingState.completed && 
          !state.playing &&
          !isRepeatEnabled) {
        playNext();
      }
    });
  }

  Future<void> playMediaItem(MediaItem item, {List<MediaItem>? queue}) async {
    try {
      // CRITICAL: Stop any currently playing song IMMEDIATELY and show loading
      // This prevents the old song from continuing to play while fetching new song
      if (playerService.audioPlayer.processingState != ProcessingState.idle) {
        print('Stopping current song before playing new one...');
        
        // Show loading immediately
        _isLoading = true;
        _loadingMessage = 'Stopping current song...';
        _currentItem = item; // Update UI to show new song info
        notifyListeners();
        
        // Pause first to stop playback immediately
        await playerService.audioPlayer.pause();
        // Small delay to ensure pause takes effect
        await Future.delayed(const Duration(milliseconds: 50));
        // Then stop to reset the player and clear audio source
        await playerService.audioPlayer.stop();
        // Wait for player to fully reach idle state (this clears the audio source)
        int waitAttempts = 0;
        while (playerService.audioPlayer.processingState != ProcessingState.idle && waitAttempts < 30) {
          await Future.delayed(const Duration(milliseconds: 50));
          waitAttempts++;
        }
        // Additional delay to ensure audio stream/cache is completely released
        await Future.delayed(const Duration(milliseconds: 200));
        print('Current song fully stopped and audio source cleared');
      } else {
        // No song playing, just show loading
        _isLoading = true;
        _loadingMessage = 'Loading...';
        _currentItem = item;
        notifyListeners();
      }
      
      // Set queue if provided
      if (queue != null && queue.isNotEmpty) {
        _originalQueue = List.from(queue);
        _queue = isShuffleEnabled ? _shuffleList(List.from(queue)) : List.from(queue);
        _currentIndex = _queue.indexWhere((s) => s.id == item.id);
        if (_currentIndex == -1) {
          _currentIndex = 0;
        }
      } else {
        // Single item queue
        _queue = [item];
        _originalQueue = [item];
        _currentIndex = 0;
      }
      
      // Check if song is liked (non-blocking)
      _updateLikedStatus(item.id);
      
      // just_audio_background shows notification automatically via MediaItem tag.
      // Also init our handler for notification bar next/previous controls.
      await (audioServiceManager?.ensureInitialized() ?? Future<void>.value());

      _loadingMessage = 'Getting audio stream...';
      notifyListeners();
      await playerService.playMediaItem(item);

      final audioHandler = audioServiceManager?.audioHandler;
      if (audioHandler != null) {
        audioHandler.updateNotificationOnly(item, queueList: _queue);
      }
      
      // Wait a bit for playback to start, then check if we should clear loading
      // The playerStateStream listener will clear it when playback actually starts
      // But add a timeout fallback in case the state doesn't update
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Fallback: Clear loading if player is playing or ready
      final currentState = playerService.audioPlayer.playerState;
      if (_isLoading && (currentState.playing || 
          currentState.processingState == ProcessingState.ready ||
          currentState.processingState == ProcessingState.buffering)) {
        _isLoading = false;
        _loadingMessage = '';
        notifyListeners();
        print('Loading cleared via fallback - playback state detected');
      }
      
      // Add to recently played in background
      homeProvider?.addToRecentlyPlayed(item);
    } catch (e) {
      _isLoading = false;
      _loadingMessage = '';
      notifyListeners();
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
    if (_queue.isEmpty || _currentIndex == -1) return;
    
    int nextIndex;
    if (isShuffleEnabled) {
      if (_originalQueue.isEmpty) return;
      final random = Random();
      nextIndex = random.nextInt(_originalQueue.length);
      final nextItem = _originalQueue[nextIndex];
      final indexInShuffled = _queue.indexWhere((s) => s.id == nextItem.id);
      if (indexInShuffled != -1) {
        _currentIndex = indexInShuffled;
      } else {
        _queue.add(nextItem);
        _currentIndex = _queue.length - 1;
      }
    } else {
      nextIndex = (_currentIndex + 1) % _queue.length;
      _currentIndex = nextIndex;
    }
    
    if (_currentIndex < _queue.length) {
      await _playItemFromQueue(_queue[_currentIndex]);
    }
  }
  
  Future<void> _playPrevious() async {
    if (_queue.isEmpty || _currentIndex == -1) return;
    
    int prevIndex;
    if (isShuffleEnabled) {
      if (_originalQueue.isEmpty) return;
      final random = Random();
      prevIndex = random.nextInt(_originalQueue.length);
      final prevItem = _originalQueue[prevIndex];
      final indexInShuffled = _queue.indexWhere((s) => s.id == prevItem.id);
      if (indexInShuffled != -1) {
        _currentIndex = indexInShuffled;
      } else {
        _queue.insert(0, prevItem);
        _currentIndex = 0;
      }
    } else {
      prevIndex = (_currentIndex - 1) % _queue.length;
      if (prevIndex < 0) prevIndex = _queue.length - 1;
      _currentIndex = prevIndex;
    }
    
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      await _playItemFromQueue(_queue[_currentIndex]);
    }
  }
  
  Future<void> _playItemFromQueue(MediaItem item) async {
    // CRITICAL: Stop current song completely before playing next/previous
    // This ensures old song doesn't continue playing
    if (playerService.audioPlayer.processingState != ProcessingState.idle) {
      print('Stopping current song and clearing audio source before playing next/previous...');
      
      // Show loading immediately
      _isLoading = true;
      _loadingMessage = 'Switching song...';
      notifyListeners();
      
      // Pause first to stop playback immediately
      await playerService.audioPlayer.pause();
      await Future.delayed(const Duration(milliseconds: 50));
      // Stop to reset player and clear audio source
      await playerService.audioPlayer.stop();
      // Wait for idle state (this clears the audio source/cache)
      int waitAttempts = 0;
      while (playerService.audioPlayer.processingState != ProcessingState.idle && waitAttempts < 30) {
        await Future.delayed(const Duration(milliseconds: 50));
        waitAttempts++;
      }
      // Additional delay to ensure audio stream/cache is completely released
      await Future.delayed(const Duration(milliseconds: 200));
      print('Current song stopped and audio source cleared, switching to next/previous');
      
      // Sync state after stopping
      final actualState = playerService.audioPlayer.playerState;
      _isPlaying = actualState.playing;
      notifyListeners();
    }
    
    await playMediaItem(item, queue: _queue);
  }
  
  Future<void> playNext() async {
    if (_currentItem == null) return;
    
    try {
      await _playNext();
    } catch (e) {
      print('Error playing next: $e');
      // Sync state on error
      final actualState = playerService.audioPlayer.playerState;
      if (_isPlaying != actualState.playing) {
        _isPlaying = actualState.playing;
        notifyListeners();
      }
    }
  }
  
  Future<void> playPrevious() async {
    if (_currentItem == null) return;
    
    try {
      if (_position.inSeconds < 3) {
        await _playPrevious();
      } else {
        seek(Duration.zero);
      }
    } catch (e) {
      print('Error playing previous: $e');
      // Sync state on error
      final actualState = playerService.audioPlayer.playerState;
      if (_isPlaying != actualState.playing) {
        _isPlaying = actualState.playing;
        notifyListeners();
      }
    }
  }

  Future<void> playPause() async {
    if (_currentItem == null) return;
    
    // Get current actual state from player (source of truth)
    // Use the actual player state, not our cached state
    final currentState = playerService.audioPlayer.playerState;
    final isCurrentlyPlaying = currentState.playing;
    
    try {
      // Execute play/pause based on ACTUAL current state
      if (isCurrentlyPlaying) {
        // Currently playing, so pause it
        print('Pausing playback...');
        await playerService.audioPlayer.pause();
        
        // Don't sync audio handler here - it listens to player state automatically
        // Calling audioHandler.pause() would call player.pause() again, causing conflicts
        // The audio handler's listener will update automatically via playerStateStream
      } else {
        // Currently paused, so play it
        print('Resuming playback...');
        await playerService.audioPlayer.play();
        
        // Don't sync audio handler here - it listens to player state automatically
        // Calling audioHandler.play() would call player.play() again, causing conflicts
        // The audio handler's listener will update automatically via playerStateStream
      }
      
      // State will be updated automatically by the playerStateStream listener
      // Don't manually update _isPlaying here to avoid race conditions
    } catch (e) {
      print('Error in playPause: $e');
      // On error, sync state from actual player state
      final actualState = playerService.audioPlayer.playerState;
      if (_isPlaying != actualState.playing) {
        _isPlaying = actualState.playing;
        notifyListeners();
      }
    }
  }

  // Allow direct position updates for slider dragging (without triggering seek)
  void updatePosition(Duration value) {
    _position = value;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    if (_currentItem == null) return;

    try {
      setSeeking(true);
      _position = position;
      notifyListeners();

      await playerService.seek(position);
    } catch (e) {
      print('Error seeking: $e');
      syncStateFromPlayer();
    } finally {
      setSeeking(false);
    }
  }

  void toggleShuffle() {
    playerService.toggleShuffle();
    
    if (isShuffleEnabled && _originalQueue.isNotEmpty) {
      _queue = _shuffleList(List.from(_originalQueue));
      if (_currentItem != null) {
        final newIndex = _queue.indexWhere((s) => s.id == _currentItem!.id);
        if (newIndex != -1) {
          _currentIndex = newIndex;
        }
      }
    } else if (!isShuffleEnabled && _originalQueue.isNotEmpty) {
      _queue = List.from(_originalQueue);
      if (_currentItem != null) {
        final newIndex = _queue.indexWhere((s) => s.id == _currentItem!.id);
        if (newIndex != -1) {
          _currentIndex = newIndex;
        }
      }
    }
    notifyListeners();
  }

  void toggleRepeat() {
    playerService.toggleRepeat();
    notifyListeners();
  }

  Future<void> _updateLikedStatus(String songId) async {
    final liked = await LikedSongsService.isLiked(songId);
    _isLiked = liked;
    notifyListeners();
  }

  Future<void> toggleFavorite() async {
    if (_currentItem == null) return;
    
    final wasLiked = _isLiked;
    _isLiked = !wasLiked;
    notifyListeners();
    
    LikedSongsService.toggleLike(_currentItem!).then((newLikedStatus) {
      _isLiked = newLikedStatus;
      likedSongsProvider?.loadLikedSongs(); // Refresh liked songs screen
      notifyListeners();
    }).catchError((e) {
      _isLiked = wasLiked;
      notifyListeners();
      print('Error toggling favorite: $e');
    });
  }

  Future<void> refreshLikedStatus() async {
    if (_currentItem == null) return;
    
    try {
      final isLiked = await LikedSongsService.isLiked(_currentItem!.id);
      if (_isLiked != isLiked) {
        _isLiked = isLiked;
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing liked status: $e');
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    playerService.dispose();
    super.dispose();
  }
}
