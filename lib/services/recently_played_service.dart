import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umarplayer/models/media_item.dart';

class RecentlyPlayedService {
  static const String _key = 'recently_played_songs';
  static const int _maxItems = 50; // Maximum number of recently played songs

  // Add a song to recently played
  static Future<void> addSong(MediaItem song) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<MediaItem> songs = await getRecentlyPlayed();
      
      // Remove if already exists (to move to top)
      songs.removeWhere((item) => item.id == song.id);
      
      // Add to beginning
      songs.insert(0, song);
      
      // Keep only max items
      if (songs.length > _maxItems) {
        songs.removeRange(_maxItems, songs.length);
      }
      
      // Save to preferences
      final jsonList = songs.map((item) => _mediaItemToJson(item)).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving recently played song: $e');
    }
  }

  // Get recently played songs
  static Future<List<MediaItem>> getRecentlyPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => _mediaItemFromJson(json)).toList();
    } catch (e) {
      print('Error loading recently played songs: $e');
      return [];
    }
  }

  // Clear recently played
  static Future<void> clearRecentlyPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      print('Error clearing recently played: $e');
    }
  }

  // Convert MediaItem to JSON
  static Map<String, dynamic> _mediaItemToJson(MediaItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'subtitle': item.subtitle,
      'artist': item.artist,
      'album': item.album,
      'imageUrl': item.imageUrl,
      'type': item.type,
      'duration': item.duration?.inSeconds,
      'description': item.description,
      'viewCount': item.viewCount,
      'uploadDate': item.uploadDate?.toIso8601String(),
    };
  }

  // Convert JSON to MediaItem
  static MediaItem _mediaItemFromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      imageUrl: json['imageUrl'] as String?,
      type: json['type'] as String,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      description: json['description'] as String?,
      viewCount: json['viewCount'] as int?,
      uploadDate: json['uploadDate'] != null
          ? DateTime.parse(json['uploadDate'] as String)
          : null,
    );
  }
}
