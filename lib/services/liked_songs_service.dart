import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umarplayer/models/media_item.dart';

class LikedSongsService {
  static const String _key = 'liked_songs';

  // Add a song to liked songs
  static Future<void> addLikedSong(MediaItem song) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<MediaItem> songs = await getLikedSongs();
      
      // Check if already exists
      if (songs.any((item) => item.id == song.id)) {
        return; // Already liked
      }
      
      // Add to beginning
      songs.insert(0, song);
      
      // Save to preferences
      final jsonList = songs.map((item) => _mediaItemToJson(item)).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving liked song: $e');
    }
  }

  // Remove a song from liked songs
  static Future<void> removeLikedSong(String songId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<MediaItem> songs = await getLikedSongs();
      
      songs.removeWhere((item) => item.id == songId);
      
      // Save to preferences
      final jsonList = songs.map((item) => _mediaItemToJson(item)).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
    } catch (e) {
      print('Error removing liked song: $e');
    }
  }

  // Check if a song is liked
  static Future<bool> isLiked(String songId) async {
    try {
      final songs = await getLikedSongs();
      return songs.any((item) => item.id == songId);
    } catch (e) {
      print('Error checking if song is liked: $e');
      return false;
    }
  }

  // Toggle like status
  static Future<bool> toggleLike(MediaItem song) async {
    try {
      final isCurrentlyLiked = await isLiked(song.id);
      if (isCurrentlyLiked) {
        await removeLikedSong(song.id);
        return false;
      } else {
        await addLikedSong(song);
        return true;
      }
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  // Get all liked songs
  static Future<List<MediaItem>> getLikedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => _mediaItemFromJson(json)).toList();
    } catch (e) {
      print('Error loading liked songs: $e');
      return [];
    }
  }

  // Clear all liked songs
  static Future<void> clearLikedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      print('Error clearing liked songs: $e');
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
