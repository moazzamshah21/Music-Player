import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umarplayer/models/media_item.dart';

class RecentSearchesService {
  static const String _key = 'recent_searches';
  static const int _maxItems = 8; // Maximum number of recent searches

  // Add a search to recent searches
  static Future<void> addSearch(MediaItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<MediaItem> searches = await getRecentSearches();
      
      // Remove if already exists (to move to top)
      searches.removeWhere((search) => search.id == item.id);
      
      // Add to beginning
      searches.insert(0, item);
      
      // Keep only max items
      if (searches.length > _maxItems) {
        searches.removeRange(_maxItems, searches.length);
      }
      
      // Save to preferences
      final jsonList = searches.map((item) => _mediaItemToJson(item)).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving recent search: $e');
    }
  }

  // Get recent searches
  static Future<List<MediaItem>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => _mediaItemFromJson(json)).toList();
    } catch (e) {
      print('Error loading recent searches: $e');
      return [];
    }
  }

  // Remove a search from recent searches
  static Future<void> removeSearch(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<MediaItem> searches = await getRecentSearches();
      
      searches.removeWhere((search) => search.id == id);
      
      // Save to preferences
      final jsonList = searches.map((item) => _mediaItemToJson(item)).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
    } catch (e) {
      print('Error removing recent search: $e');
    }
  }

  // Clear all recent searches
  static Future<void> clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      print('Error clearing recent searches: $e');
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
