import 'dart:async';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:umarplayer/models/media_item.dart';

// Cache entry for search results
class _CachedResult {
  final List<MediaItem> items;
  final DateTime timestamp;
  static const _cacheExpiry = Duration(minutes: 30);
  
  _CachedResult(this.items) : timestamp = DateTime.now();
  
  bool get isExpired => DateTime.now().difference(timestamp) > _cacheExpiry;
}

class YouTubeService {
  final YoutubeExplode _ytExplode = YoutubeExplode();
  
  // Simple in-memory cache for search results (expires after 30 minutes)
  final Map<String, _CachedResult> _searchCache = {};

  // Search for videos - Optimized for faster loading with caching
  // Uses search result data directly to avoid extra API calls
  Future<List<MediaItem>> searchVideos(String query, {int limit = 10}) async {
    try {
      // Check cache first
      final cacheKey = '$query:$limit';
      final cached = _searchCache[cacheKey];
      if (cached != null && !cached.isExpired) {
        print('Using cached results for: $query');
        return cached.items;
      }
      
      final searchResults = await _ytExplode.search.search(query);
      final videos = searchResults.take(limit).toList();

      // Use search result data directly - much faster than fetching full video details
      // Only fetch full details if we need additional info (lazy loading)
      final List<MediaItem> mediaItems = videos.map((video) {
        return MediaItem(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          imageUrl: video.thumbnails.highResUrl.isNotEmpty
              ? video.thumbnails.highResUrl
              : (video.thumbnails.mediumResUrl.isNotEmpty
                  ? video.thumbnails.mediumResUrl
                  : video.thumbnails.lowResUrl.isNotEmpty
                      ? video.thumbnails.lowResUrl
                      : ''),
          type: 'song',
          duration: video.duration,
          description: video.description,
        );
      }).toList();
      
      // Cache the results
      _searchCache[cacheKey] = _CachedResult(mediaItems);
      
      // Clean up expired cache entries periodically
      _cleanExpiredCache();
      
      return mediaItems;
    } catch (e) {
      print('Error searching videos: $e');
      return [];
    }
  }
  
  void _cleanExpiredCache() {
    _searchCache.removeWhere((key, value) => value.isExpired);
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
  
  // Get audio stream info directly - Optimized to get ONLY audio stream manifest
  // This is fast because it only fetches stream metadata, not the full video
  Future<AudioOnlyStreamInfo?> getAudioStreamInfo(String videoId) async {
    try {
      // Get manifest which contains stream URLs - this is fast, doesn't download video
      // Using multiple clients for better compatibility
      final manifest = await _ytExplode.videos.streams.getManifest(
        videoId,
        ytClients: [
          YoutubeApiClient.ios,
          YoutubeApiClient.androidVr,
        ],
      );
      
      // Get ONLY audio streams (not video) - this is what we want
      final audioStreams = manifest.audioOnly;
      
      if (audioStreams.isEmpty) {
        print('No audio-only streams available for video: $videoId');
        return null;
      }
      
      // Get the best quality audio stream (highest bitrate)
      final bestAudio = audioStreams.withHighestBitrate();
      print('Selected audio stream: ${bestAudio.bitrate}bps, codec: ${bestAudio.codec}');
      
      return bestAudio;
    } catch (e) {
      print('Error getting audio stream info: $e');
      // Try with default client as fallback
      try {
        final manifest = await _ytExplode.videos.streams.getManifest(videoId);
        final audioStreams = manifest.audioOnly;
        if (audioStreams.isNotEmpty) {
          return audioStreams.withHighestBitrate();
        }
      } catch (e2) {
        print('Fallback also failed: $e2');
      }
      return null;
    }
  }

  // Dispose
  void dispose() {
    _ytExplode.close();
  }
}
