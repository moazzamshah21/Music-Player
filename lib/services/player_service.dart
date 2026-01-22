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
    audioPlayer.positionStream.listen((position) {
      _position = position;
    });
    
    audioPlayer.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
    });
    
    audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
    });
  }

  Future<void> playMediaItem(MediaItem item) async {
    try {
      _currentItem = item;
      
      // Check if song is downloaded locally first
      final localFilePath = await DownloadsService.getLocalFilePath(item.id);
      if (localFilePath != null) {
        print('Playing local file: $localFilePath');
        await audioPlayer.stop();
        await audioPlayer.setFilePath(localFilePath);
        await _waitForPlayerReady();
        await audioPlayer.play();
        _isPlaying = true;
        print('Local audio playback started');
        return;
      }
      
      print('Fetching audio stream for video: ${item.id}');
      
      // Get audio stream info from YouTube (contains URL and metadata)
      final audioStreamInfo = await _youtubeService.getAudioStreamInfo(item.id);
      
      if (audioStreamInfo == null) {
        throw Exception('Could not get audio stream for video: ${item.id}');
      }

      print('Audio stream obtained: ${audioStreamInfo.bitrate}bps, codec: ${audioStreamInfo.codec}');

      // Stop current playback if any
      await audioPlayer.stop();
      
      // Use AudioSource.uri with headers to bypass YouTube's 403 error
      try {
        final streamUrl = audioStreamInfo.url;
        
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
        
        await audioPlayer.setAudioSource(audioSource);
        print('Audio source set successfully with headers');
      } catch (e) {
        print('Error setting audio source with headers: $e');
        // Fallback: try without headers using setUrl
        try {
          await audioPlayer.setUrl(audioStreamInfo.url.toString());
          print('Audio source set without headers (fallback)');
        } catch (e2) {
          // Last resort: try getting a fresh stream
          print('Error in fallback, trying fresh stream: $e2');
          final freshStream = await _youtubeService.getAudioStreamInfo(item.id);
          if (freshStream != null) {
            final fallbackSource = AudioSource.uri(freshStream.url);
            await audioPlayer.setAudioSource(fallbackSource);
            print('Fresh audio stream set');
          } else {
            throw Exception('Could not get valid audio stream. YouTube may be blocking access.');
          }
        }
      }
      
      // Wait for player to be ready before playing
      print('Waiting for player to be ready...');
      await _waitForPlayerReady();
      
      // Play only the audio (no video will be played)
      await audioPlayer.play();
      _isPlaying = true;
      print('Audio playback started');
    } catch (e) {
      print('Error playing audio: $e');
      // Reset state on error
      _currentItem = null;
      _isPlaying = false;
      rethrow;
    }
  }

  Future<void> _waitForPlayerReady() async {
    // Wait for player to be ready (with timeout)
    int attempts = 0;
    const maxAttempts = 100; // 10 seconds max wait
    
    while (attempts < maxAttempts) {
      final state = audioPlayer.playerState;
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
    if (_isPlaying) {
      await audioPlayer.pause();
    } else {
      await audioPlayer.play();
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
