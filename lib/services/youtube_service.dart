import 'dart:async';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:umarplayer/models/media_item.dart';

class YouTubeService {
  final YoutubeExplode _ytExplode = YoutubeExplode();

  // Search for videos - Optimized for faster loading
  Future<List<MediaItem>> searchVideos(String query, {int limit = 10}) async {
    try {
      final searchResults = await _ytExplode.search.search(query);
      final videos = searchResults.take(limit).toList();

      // Process videos in parallel but with timeout per video
      final List<Future<MediaItem?>> futures = videos.map((video) async {
        try {
          // Get only video info first (faster), skip manifest check for search
          final videoInfo = await _ytExplode.videos.get(video.id).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Video fetch timeout'),
          );

          return MediaItem(
            id: videoInfo.id.value,
            title: videoInfo.title,
            artist: videoInfo.author,
            imageUrl: videoInfo.thumbnails.highResUrl.isNotEmpty
                ? videoInfo.thumbnails.highResUrl
                : (videoInfo.thumbnails.mediumResUrl.isNotEmpty
                    ? videoInfo.thumbnails.mediumResUrl
                    : ''),
            type: 'song',
            duration: videoInfo.duration,
            description: videoInfo.description,
            viewCount: videoInfo.engagement.viewCount,
            uploadDate: videoInfo.uploadDate,
          );
        } catch (e) {
          // Skip videos that fail to load
          print('Error fetching video ${video.id}: $e');
          return null;
        }
      }).toList();
      
      // Wait for all videos with overall timeout
      final results = await Future.wait(futures).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          print('Search timeout for query: $query');
          return List<MediaItem?>.filled(futures.length, null);
        },
      );
      
      // Filter out null results and return
      return results.whereType<MediaItem>().toList();
    } catch (e) {
      print('Error searching videos: $e');
      return [];
    }
  }

  // Get complete video details by ID
  Future<MediaItem?> getVideoById(String videoId) async {
    try {
      final video = await _ytExplode.videos.get(videoId);
      return MediaItem(
        id: video.id.value,
        title: video.title,
        artist: video.author,
        imageUrl: video.thumbnails.highResUrl,
        type: 'song',
        duration: video.duration,
        description: video.description,
        viewCount: video.engagement.viewCount,
        uploadDate: video.uploadDate,
      );
    } catch (e) {
      print('Error getting video: $e');
      return null;
    }
  }

  // Get videos from a playlist
  Future<List<MediaItem>> getPlaylistVideos(String playlistId) async {
    try {
      // Get videos from playlist - using the videos stream
      final videos = <Video>[];
      await for (final video in _ytExplode.playlists.getVideos(playlistId)) {
        videos.add(video);
        if (videos.length >= 50) break;
      }

      // Fetch full video details for each video in playlist
      final List<MediaItem> mediaItems = [];
      for (final video in videos) {
        try {
          final fullVideo = await _ytExplode.videos.get(video.id);
          mediaItems.add(MediaItem(
            id: fullVideo.id.value,
            title: fullVideo.title,
            artist: fullVideo.author,
            imageUrl: fullVideo.thumbnails.highResUrl,
            type: 'song',
            duration: fullVideo.duration,
            description: fullVideo.description,
            viewCount: fullVideo.engagement.viewCount,
            uploadDate: fullVideo.uploadDate,
          ));
        } catch (e) {
          print('Error fetching full video ${video.id}: $e');
          mediaItems.add(MediaItem(
            id: video.id.value,
            title: video.title,
            artist: video.author,
            imageUrl: video.thumbnails.highResUrl,
            type: 'song',
          ));
        }
      }
      return mediaItems;
    } catch (e) {
      print('Error getting playlist videos: $e');
      return [];
    }
  }

  // Get trending videos - Using search as trending may not be available
  Future<List<MediaItem>> getTrendingVideos({int limit = 10}) async {
    try {
      // Search for popular music instead of trending
      return await searchVideos('popular music', limit: limit);
    } catch (e) {
      print('Error getting trending videos: $e');
      return [];
    }
  }

  // Get channel videos - Search by channel name instead
  Future<List<MediaItem>> getChannelVideos(String channelId, {int limit = 10}) async {
    try {
      // For now, search by channel name or use channel uploads search
      // This is a simplified approach - you may need to adjust based on actual API
      final channel = await _ytExplode.channels.get(channelId);
      // Search for videos from this channel
      return await searchVideos(channel.title, limit: limit);
    } catch (e) {
      print('Error getting channel videos: $e');
      return [];
    }
  }

  // Get audio-only stream URL for playback (extracted from full video)
  // Uses ytClients to avoid 403 errors
  Future<String?> getVideoStreamUrl(String videoId) async {
    try {
      // Get the full video manifest with specific clients to avoid 403
      final manifest = await _ytExplode.videos.streams.getManifest(
        videoId,
        ytClients: [
          YoutubeApiClient.ios,
          YoutubeApiClient.androidVr,
        ],
      );
      
      // Extract ONLY audio stream from the full video
      final audioStreams = manifest.audioOnly;
      
      if (audioStreams.isEmpty) {
        print('No audio-only streams available for video: $videoId');
        return null;
      }
      
      // Get the best quality audio stream
      try {
        // Try highest bitrate audio stream
        final audioStream = audioStreams.withHighestBitrate();
        print('Using audio stream: ${audioStream.bitrate}bps, codec: ${audioStream.codec}');
        return audioStream.url.toString();
      } catch (e) {
        // Fallback to first available audio stream
        print('Error getting highest bitrate, using first available: $e');
        final audioStream = audioStreams.first;
        return audioStream.url.toString();
      }
    } catch (e) {
      print('Error getting audio stream URL: $e');
      return null;
    }
  }
  
  // Get all available audio streams for a video
  Future<List<AudioOnlyStreamInfo>> getAvailableAudioStreams(String videoId) async {
    try {
      final manifest = await _ytExplode.videos.streams.getManifest(
        videoId,
        ytClients: [
          YoutubeApiClient.ios,
          YoutubeApiClient.androidVr,
        ],
      );
      return manifest.audioOnly.toList();
    } catch (e) {
      print('Error getting audio streams: $e');
      return [];
    }
  }
  
  // Get audio stream info directly (alternative method) - Uses ytClients to avoid 403
  Future<AudioOnlyStreamInfo?> getAudioStreamInfo(String videoId) async {
    try {
      final manifest = await _ytExplode.videos.streams.getManifest(
        videoId,
        ytClients: [
          YoutubeApiClient.ios,
          YoutubeApiClient.androidVr,
        ],
      );
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isNotEmpty) {
        return audioStreams.withHighestBitrate();
      }
      return null;
    } catch (e) {
      print('Error getting audio stream info: $e');
      return null;
    }
  }

  // Dispose
  void dispose() {
    _ytExplode.close();
  }
}
