import 'package:just_audio/just_audio.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/services/youtube_service.dart';
import 'package:umarplayer/services/downloads_service.dart';

class PlayerService {
  final AudioPlayer audioPlayer = AudioPlayer();
  final YouTubeService _youtubeService = YouTubeService();
  
  MediaItem? _currentItem;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffleEnabled = false;
  bool _isRepeatEnabled = false;

  // Getters
  MediaItem? get currentItem => _currentItem;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get isRepeatEnabled => _isRepeatEnabled;

  PlayerService() {
    // Listen to position updates
    audioPlayer.positionStream.listen((position) {
      _position = position;
    });
    
    // Listen to duration updates
    audioPlayer.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
    });
    
    // Listen to player state changes - this is the source of truth
    audioPlayer.playerStateStream.listen((state) {
      final newPlayingState = state.playing;
      if (_isPlaying != newPlayingState) {
        _isPlaying = newPlayingState;
        print('Player state changed: ${newPlayingState ? "playing" : "paused"}');
      }
    });
  }

  Future<void> playMediaItem(MediaItem item) async {
    try {
      // CRITICAL: Stop current playback IMMEDIATELY and completely
      // This ensures the old song stops before loading new one
      if (audioPlayer.processingState != ProcessingState.idle) {
        print('Stopping current playback...');
        // Pause first to stop audio immediately (stops playback)
        await audioPlayer.pause();
        // Small delay to ensure pause takes effect
        await Future.delayed(const Duration(milliseconds: 50));
        // Then stop to reset player state completely
        await audioPlayer.stop();
        // Wait for player to fully reach idle state (ensures old source is cleared)
        int waitAttempts = 0;
        while (audioPlayer.processingState != ProcessingState.idle && waitAttempts < 30) {
          await Future.delayed(const Duration(milliseconds: 50));
          waitAttempts++;
        }
        // Additional delay to ensure audio stream is completely released
        await Future.delayed(const Duration(milliseconds: 200));
        print('Current playback fully stopped and cleared');
      }
      
      // Clear current item reference before setting new one
      _currentItem = null;
      
      // Set new item
      _currentItem = item;
      
      // Check if song is downloaded locally first
      final localFilePath = await DownloadsService.getLocalFilePath(item.id);
      if (localFilePath != null) {
        print('Playing local file: $localFilePath');
        await audioPlayer.setFilePath(localFilePath);
        await _waitForPlayerReady();
        await audioPlayer.play();
        // Don't manually set _isPlaying - let the playerStateStream handle it
        print('Local audio playback started');
        return;
      }
      
      print('Fetching audio stream for video: ${item.id}');
      
      // Get audio stream info from YouTube - optimized to get ONLY audio stream
      // This gets the manifest which contains stream URLs, not the full video
      final audioStreamInfo = await _youtubeService.getAudioStreamInfo(item.id);
      
      if (audioStreamInfo == null) {
        throw Exception('Could not get audio stream for video: ${item.id}');
      }

      print('Audio stream obtained: ${audioStreamInfo.bitrate}bps, codec: ${audioStreamInfo.codec}');
      
      final streamUrl = audioStreamInfo.url;
      
      // Use AudioSource.uri with headers to bypass YouTube's 403 error
      try {
        // Create AudioSource with proper headers to avoid 403
        final audioSource = AudioSource.uri(
          streamUrl,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': '*/*',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Referer': 'https://www.youtube.com/',
            'Origin': 'https://www.youtube.com',
            'Connection': 'keep-alive',
            'Sec-Fetch-Dest': 'empty',
            'Sec-Fetch-Mode': 'cors',
            'Sec-Fetch-Site': 'cross-site',
          },
        );
        
        // Set audio source and start playing IMMEDIATELY
        // Don't wait for ready state - just_audio will buffer automatically
        print('Setting audio source and starting playback immediately...');
        await audioPlayer.setAudioSource(audioSource);
        print('Audio source set, starting playback...');
        
        // Start playing immediately - just_audio will buffer in background
        // This allows playback to start while the stream is still loading
        await audioPlayer.play();
        // Don't manually set _isPlaying - let the playerStateStream handle it
        print('Audio playback started immediately (buffering in background)');
        
      } catch (e) {
        print('Error setting audio source with headers: $e');
        // Fallback: try without headers using setUrl
        try {
          print('Trying fallback method (setUrl without headers)...');
          await audioPlayer.setUrl(streamUrl.toString());
          await audioPlayer.play();
          // Don't manually set _isPlaying - let the playerStateStream handle it
          print('Audio source set without headers (fallback)');
        } catch (e2) {
          print('Error in fallback: $e2');
          throw Exception('Could not set audio stream. Error: $e2');
        }
      }
    } catch (e) {
      print('Error playing audio: $e');
      // Reset state on error
      _currentItem = null;
      // Don't manually set _isPlaying - let the playerStateStream handle it
      rethrow;
    }
  }

  Future<void> _waitForPlayerReady() async {
    // Wait for player to be ready (with shorter timeout)
    int attempts = 0;
    const maxAttempts = 50; // 5 seconds max wait (reduced from 10)
    
    // Check current state first (might already be ready)
    var state = audioPlayer.playerState;
    if (state.processingState == ProcessingState.ready ||
        state.processingState == ProcessingState.buffering) {
      print('Player is ready');
      return;
    }
    
    // Poll with shorter intervals for faster response
    while (attempts < maxAttempts) {
      state = audioPlayer.playerState;
      if (state.processingState == ProcessingState.ready ||
          state.processingState == ProcessingState.buffering) {
        print('Player is ready');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    
    print('Player ready timeout, proceeding anyway');
  }

  Future<void> playPause() async {
    try {
      final currentState = audioPlayer.playerState;
      if (currentState.playing) {
        print('Pausing audio player...');
        await audioPlayer.pause();
        print('Audio player paused');
      } else {
        print('Playing audio player...');
        await audioPlayer.play();
        print('Audio player playing');
      }
    } catch (e) {
      print('Error in playPause: $e');
      rethrow;
    }
  }

  Future<void> seek(Duration position) async {
    await audioPlayer.seek(position);
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    // Implement shuffle logic if needed
  }

  void toggleRepeat() {
    _isRepeatEnabled = !_isRepeatEnabled;
    audioPlayer.setLoopMode(
      _isRepeatEnabled ? LoopMode.one : LoopMode.off,
    );
  }

  void dispose() {
    audioPlayer.dispose();
    _youtubeService.dispose();
  }
}
