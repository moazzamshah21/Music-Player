import 'dart:async';
import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:just_audio/just_audio.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/services/player_service.dart';

// Global reference to audio handler
AudioHandlerService? globalAudioHandler;

class AudioHandlerService extends audio_service.BaseAudioHandler
    with audio_service.QueueHandler, audio_service.SeekHandler {
  final PlayerService _playerService;
  
  final _mediaItemController = StreamController<List<MediaItem>>();
  final _currentIndexController = StreamController<int>();
  
  int _currentIndex = -1;
  List<MediaItem> _queue = [];
  MediaItem? _currentMediaItem;

  AudioHandlerService(this._playerService) {
    globalAudioHandler = this;
    // Initialize with default playback state
    playbackState.add(_getInitialPlaybackState());
    _setupListeners();
  }

  audio_service.PlaybackState _getInitialPlaybackState() {
    return audio_service.PlaybackState(
      controls: [
        audio_service.MediaControl.skipToPrevious,
        audio_service.MediaControl.play,
        audio_service.MediaControl.skipToNext,
        audio_service.MediaControl.stop,
      ],
      systemActions: const {
        audio_service.MediaAction.seek,
        audio_service.MediaAction.seekForward,
        audio_service.MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: audio_service.AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
      speed: 1.0,
      updateTime: DateTime.now(),
    );
  }

  void _setupListeners() {
    // Listen to player state changes
    _playerService.audioPlayer.playerStateStream.listen((state) {
      try {
        final playbackStateValue = _getPlaybackState(state);
        playbackState.add(playbackStateValue);
        
        // Clear notification when playback completes or stops
        if (state.processingState == ProcessingState.completed && !state.playing) {
          _clearNotification();
        }
      } catch (e) {
        print('Error updating playback state: $e');
      }
    });

    // Listen to position changes
    _playerService.audioPlayer.positionStream.listen((position) {
      try {
        final currentState = playbackState.valueOrNull;
        if (currentState != null) {
          playbackState.add(currentState.copyWith(
            updatePosition: position,
          ));
        }
      } catch (e) {
        print('Error updating position: $e');
      }
    });

    // Listen to duration changes
    _playerService.audioPlayer.durationStream.listen((duration) {
      try {
        if (duration != null && _currentMediaItem != null) {
          mediaItem.add(_createAudioServiceMediaItem(_currentMediaItem!));
        }
      } catch (e) {
        print('Error updating duration: $e');
      }
    });
  }

  void _clearNotification() {
    // Clear media item and set to idle state to hide notification
    mediaItem.add(null);
    playbackState.add(_getInitialPlaybackState());
    _currentMediaItem = null;
  }

  audio_service.PlaybackState _getPlaybackState(PlayerState state) {
    return audio_service.PlaybackState(
      controls: [
        audio_service.MediaControl.skipToPrevious,
        if (state.playing) audio_service.MediaControl.pause else audio_service.MediaControl.play,
        audio_service.MediaControl.skipToNext,
        audio_service.MediaControl.stop,
      ],
      systemActions: const {
        audio_service.MediaAction.seek,
        audio_service.MediaAction.seekForward,
        audio_service.MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _getProcessingState(state.processingState),
      playing: state.playing,
      updatePosition: _playerService.audioPlayer.position,
      speed: _playerService.audioPlayer.speed,
      queueIndex: _currentIndex >= 0 ? _currentIndex : null,
      updateTime: DateTime.now(),
    );
  }

  audio_service.AudioProcessingState _getProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return audio_service.AudioProcessingState.idle;
      case ProcessingState.loading:
        return audio_service.AudioProcessingState.loading;
      case ProcessingState.buffering:
        return audio_service.AudioProcessingState.buffering;
      case ProcessingState.ready:
        return audio_service.AudioProcessingState.ready;
      case ProcessingState.completed:
        return audio_service.AudioProcessingState.completed;
    }
  }

  @override
  Future<void> play() async {
    // Ensure media item is set before playing
    if (_currentMediaItem != null) {
      mediaItem.add(_createAudioServiceMediaItem(_currentMediaItem!));
    }
    await _playerService.audioPlayer.play();
    // Playback state will be updated automatically by the listener
  }

  @override
  Future<void> pause() async {
    await _playerService.audioPlayer.pause();
    // Playback state will be updated automatically by the listener
  }

  @override
  Future<void> stop() async {
    await _playerService.audioPlayer.stop();
    _clearNotification();
  }

  @override
  Future<void> seek(Duration position) async {
    await _playerService.audioPlayer.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty || _currentIndex < 0) return;
    final nextIndex = (_currentIndex + 1) % _queue.length;
    await _playItem(_queue[nextIndex], nextIndex);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty || _currentIndex < 0) return;
    final prevIndex = (_currentIndex - 1) % _queue.length;
    if (prevIndex < 0) {
      await seek(Duration.zero);
    } else {
      await _playItem(_queue[prevIndex], prevIndex);
    }
  }

  Future<void> _playItem(MediaItem item, int index) async {
    try {
      print('🎵 AudioHandler: Starting playback for ${item.title}');
      _currentMediaItem = item;
      _currentIndex = index;
      
      // Update media item for audio_service notification FIRST
      // This is important - audio_service needs the media item set before playback
      // This will automatically show the media notification with controls
      final audioServiceMediaItem = _createAudioServiceMediaItem(item);
      print('📱 AudioHandler: Setting media item for notification');
      mediaItem.add(audioServiceMediaItem);
      
      // Update queue
      if (_queue.isNotEmpty) {
        queue.add(_queue.map((item) => _createAudioServiceMediaItem(item)).toList());
      }
      
      // Set initial playback state to loading to show notification
      print('📱 AudioHandler: Setting playback state to loading');
      playbackState.add(audio_service.PlaybackState(
        controls: [
          audio_service.MediaControl.skipToPrevious,
          audio_service.MediaControl.pause,
          audio_service.MediaControl.skipToNext,
          audio_service.MediaControl.stop,
        ],
        systemActions: const {
          audio_service.MediaAction.seek,
          audio_service.MediaAction.seekForward,
          audio_service.MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: audio_service.AudioProcessingState.loading,
        playing: false,
        updatePosition: Duration.zero,
        speed: 1.0,
        queueIndex: index >= 0 ? index : null,
        updateTime: DateTime.now(),
      ));
      
      // Play the item using player service
      print('▶️ AudioHandler: Starting playback via PlayerService');
      await _playerService.playMediaItem(item);
      print('✅ AudioHandler: Playback started, notification should be visible');
      
      // Playback state will be updated automatically by the listener
      // This will show/update the notification with play/pause controls
      
    } catch (e) {
      print('❌ Error playing item in audio handler: $e');
      // Set error state
      playbackState.add(audio_service.PlaybackState(
        controls: [
          audio_service.MediaControl.skipToPrevious,
          audio_service.MediaControl.play,
          audio_service.MediaControl.skipToNext,
          audio_service.MediaControl.stop,
        ],
        systemActions: const {
          audio_service.MediaAction.seek,
          audio_service.MediaAction.seekForward,
          audio_service.MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: audio_service.AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        speed: 1.0,
        updateTime: DateTime.now(),
      ));
    }
  }

  Future<void> setQueue(List<MediaItem> items, {int? initialIndex}) async {
    _queue = items;
    _currentIndex = initialIndex ?? 0;
    
    if (items.isNotEmpty && _currentIndex >= 0 && _currentIndex < items.length) {
      await _playItem(items[_currentIndex], _currentIndex);
    }
    
    queue.add(items.map((item) => _createAudioServiceMediaItem(item)).toList());
  }

  // Custom method to play media items (not overriding base class)
  Future<void> playMediaItemFromApp(MediaItem item, {List<MediaItem>? queue}) async {
    if (queue != null && queue.isNotEmpty) {
      final index = queue.indexWhere((i) => i.id == item.id);
      await setQueue(queue, initialIndex: index >= 0 ? index : 0);
    } else {
      _queue = [item];
      _currentIndex = 0;
      await _playItem(item, 0);
    }
  }

  audio_service.MediaItem _createAudioServiceMediaItem(MediaItem item) {
    return audio_service.MediaItem(
      id: item.id,
      title: item.title,
      artist: item.artist ?? item.subtitle ?? 'Unknown Artist',
      album: item.album,
      duration: item.duration,
      artUri: item.imageUrl != null ? Uri.parse(item.imageUrl!) : null,
      extras: {
        'type': item.type,
        'description': item.description,
      },
    );
  }


  @override
  Future<void> setSpeed(double speed) async {
    await _playerService.audioPlayer.setSpeed(speed);
  }

  @override
  Future<void> setShuffleMode(audio_service.AudioServiceShuffleMode shuffleMode) async {
    _playerService.toggleShuffle();
  }

  @override
  Future<void> setRepeatMode(audio_service.AudioServiceRepeatMode repeatMode) async {
    _playerService.toggleRepeat();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _queue.length) {
      await _playItem(_queue[index], index);
    }
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      if (_currentIndex >= index) {
        _currentIndex--;
      }
      queue.add(_queue.map((item) => _createAudioServiceMediaItem(item)).toList());
    }
  }

  @override
  Future<void> addQueueItems(List<audio_service.MediaItem> mediaItems) async {
    // This can be implemented if needed for dynamic queue management
  }

  @override
  Future<void> removeQueueItem(audio_service.MediaItem mediaItem) async {
    final index = _queue.indexWhere((item) => item.id == mediaItem.id);
    if (index >= 0) {
      await removeQueueItemAt(index);
    }
  }

  @override
  Future<void> updateQueue(List<audio_service.MediaItem> queue) async {
    // This can be implemented if needed
  }

  @override
  Future<void> updateMediaItem(audio_service.MediaItem mediaItem) async {
    // This can be implemented if needed
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    // Handle custom actions if needed
  }

  Future<void> dispose() async {
    await _mediaItemController.close();
    await _currentIndexController.close();
  }
}
