import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/services/youtube_service.dart';
import 'package:umarplayer/services/recently_played_service.dart';

class HomeData {
  final YouTubeService _youtubeService = YouTubeService();

  // Quick Access Items (Good evening section) - Use static data for faster loading
  Future<List<QuickAccessItem>> getQuickAccessItems() async {
    // Return static items for faster loading - can be made dynamic later
    return [
      QuickAccessItem(
        id: '1',
        title: 'Machine Gun Kelly',
        imageUrl: null,
      ),
      QuickAccessItem(
        id: '2',
        title: 'The Oral History of The Office',
        imageUrl: null,
      ),
      QuickAccessItem(
        id: '3',
        title: 'Greta Van Fleet',
        imageUrl: null,
      ),
      QuickAccessItem(
        id: '4',
        title: 'Bryce Vine',
        imageUrl: null,
      ),
      QuickAccessItem(
        id: '5',
        title: 'Chon',
        imageUrl: null,
      ),
      QuickAccessItem(
        id: '6',
        title: 'Tycho',
        imageUrl: null,
      ),
    ];
    
    // Uncomment below for dynamic search (slower but more accurate)
    /*
    final queries = [
      'Machine Gun Kelly',
      'The Oral History of The Office',
      'Greta Van Fleet',
      'Bryce Vine',
      'Chon',
      'Tycho',
    ];

    try {
      // Run searches in parallel for faster loading
      final futures = queries.map((query) => 
        _youtubeService.searchVideos(query, limit: 1)
      ).toList();
      
      final results = await Future.wait(futures);
      final List<QuickAccessItem> items = [];
      
      for (int i = 0; i < queries.length; i++) {
        if (results[i].isNotEmpty) {
          items.add(QuickAccessItem(
            id: results[i].first.id,
            title: queries[i],
            imageUrl: results[i].first.imageUrl,
          ));
        } else {
          items.add(QuickAccessItem(
            id: queries[i],
            title: queries[i],
            imageUrl: null,
          ));
        }
      }
      return items;
    } catch (e) {
      print('Error fetching quick access items: $e');
      return queries.map((query) => QuickAccessItem(
        id: query,
        title: query,
        imageUrl: null,
      )).toList();
    }
    */
  }

  // Recently Played - Get from storage
  Future<List<MediaItem>> getRecentlyPlayed() async {
    try {
      return await RecentlyPlayedService.getRecentlyPlayed();
    } catch (e) {
      print('Error fetching recently played: $e');
      return [];
    }
  }

  // Get trending songs - Use multiple search queries for better results
  Future<List<MediaItem>> getTrendingSongs({int limit = 10}) async {
    try {
      // Try multiple trending queries to get better results
      final queries = [
        'trending music',
        'popular songs 2024',
        'top hits 2024',
      ];
      
      // Try first query, if fails try others
      for (final query in queries) {
        try {
          final results = await _youtubeService.searchVideos(query, limit: limit);
          if (results.isNotEmpty) {
            return results;
          }
        } catch (e) {
          print('Error with query "$query": $e');
          continue;
        }
      }
      
      return [];
    } catch (e) {
      print('Error fetching trending songs: $e');
      return [];
    }
  }

  // Get songs from Pakistan
  Future<List<MediaItem>> getPakistaniSongs({int limit = 10}) async {
    try {
      return await _youtubeService.searchVideos('pakistani songs 2024', limit: limit);
    } catch (e) {
      print('Error fetching Pakistani songs: $e');
      return [];
    }
  }

  // Get Bollywood songs
  Future<List<MediaItem>> getBollywoodSongs({int limit = 10}) async {
    try {
      return await _youtubeService.searchVideos('bollywood songs 2024', limit: limit);
    } catch (e) {
      print('Error fetching Bollywood songs: $e');
      return [];
    }
  }

  // Get English pop songs
  Future<List<MediaItem>> getEnglishPopSongs({int limit = 10}) async {
    try {
      return await _youtubeService.searchVideos('english pop songs 2024', limit: limit);
    } catch (e) {
      print('Error fetching English pop songs: $e');
      return [];
    }
  }

  // Get Punjabi songs
  Future<List<MediaItem>> getPunjabiSongs({int limit = 10}) async {
    try {
      return await _youtubeService.searchVideos('punjabi songs 2024', limit: limit);
    } catch (e) {
      print('Error fetching Punjabi songs: $e');
      return [];
    }
  }

  // Get Hip Hop songs
  Future<List<MediaItem>> getHipHopSongs({int limit = 10}) async {
    try {
      return await _youtubeService.searchVideos('hip hop songs 2024', limit: limit);
    } catch (e) {
      print('Error fetching Hip Hop songs: $e');
      return [];
    }
  }

  // Currently Playing - Can be set from any video
  MediaItem? getCurrentlyPlaying() {
    // This would typically come from a player state manager
    return null;
  }

  // Search videos
  Future<List<MediaItem>> searchVideos(String query) async {
    return await _youtubeService.searchVideos(query);
  }

  // Get video stream URL for playback
  Future<String?> getVideoStreamUrl(String videoId) async {
    return await _youtubeService.getVideoStreamUrl(videoId);
  }

  // Dispose service
  void dispose() {
    _youtubeService.dispose();
  }
}
