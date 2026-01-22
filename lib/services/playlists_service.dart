import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umarplayer/models/playlist.dart';
import 'package:umarplayer/models/media_item.dart';

class PlaylistsService {
  static const String _key = 'playlists';

  // Create a new playlist
  static Future<Playlist> createPlaylist(String name, {String? description}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Playlist> playlists = await getPlaylists();
      
      final newPlaylist = Playlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        songs: [],
        createdAt: DateTime.now(),
      );
      
      playlists.insert(0, newPlaylist);
      
      // Save to preferences
      final jsonList = playlists.map((p) => _playlistToJson(p)).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
      
      return newPlaylist;
    } catch (e) {
      print('Error creating playlist: $e');
      rethrow;
    }
  }

  // Delete a playlist
  static Future<void> deletePlaylist(String playlistId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Playlist> playlists = await getPlaylists();
      
      playlists.removeWhere((p) => p.id == playlistId);
      
      // Save to preferences
      final jsonList = playlists.map((p) => _playlistToJson(p)).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
    } catch (e) {
      print('Error deleting playlist: $e');
    }
  }

  // Get all playlists
  static Future<List<Playlist>> getPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => _playlistFromJson(json)).toList();
    } catch (e) {
      print('Error loading playlists: $e');
      return [];
    }
  }

  // Get a playlist by ID
  static Future<Playlist?> getPlaylistById(String playlistId) async {
    try {
      final playlists = await getPlaylists();
      return playlists.firstWhere(
        (p) => p.id == playlistId,
        orElse: () => throw Exception('Playlist not found'),
      );
    } catch (e) {
      return null;
    }
  }

  // Add a song to a playlist
  static Future<void> addSongToPlaylist(String playlistId, MediaItem song) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Playlist> playlists = await getPlaylists();
      
      final playlistIndex = playlists.indexWhere((p) => p.id == playlistId);
      if (playlistIndex == -1) {
        throw Exception('Playlist not found');
      }
      
      final playlist = playlists[playlistIndex];
      
      // Check if song already exists
      if (playlist.songs.any((s) => s.id == song.id)) {
        return; // Already in playlist
      }
      
      // Create updated playlist with new song
      final updatedPlaylist = Playlist(
        id: playlist.id,
        name: playlist.name,
        description: playlist.description,
        imageUrl: playlist.imageUrl,
        songs: [...playlist.songs, song],
        createdAt: playlist.createdAt,
        createdBy: playlist.createdBy,
      );
      
      playlists[playlistIndex] = updatedPlaylist;
      
      // Save to preferences
      final jsonList = playlists.map((p) => _playlistToJson(p)).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
    } catch (e) {
      print('Error adding song to playlist: $e');
      rethrow;
    }
  }

  // Remove a song from a playlist
  static Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Playlist> playlists = await getPlaylists();
      
      final playlistIndex = playlists.indexWhere((p) => p.id == playlistId);
      if (playlistIndex == -1) {
        throw Exception('Playlist not found');
      }
      
      final playlist = playlists[playlistIndex];
      final updatedSongs = playlist.songs.where((s) => s.id != songId).toList();
      
      // Create updated playlist
      final updatedPlaylist = Playlist(
        id: playlist.id,
        name: playlist.name,
        description: playlist.description,
        imageUrl: playlist.imageUrl,
        songs: updatedSongs,
        createdAt: playlist.createdAt,
        createdBy: playlist.createdBy,
      );
      
      playlists[playlistIndex] = updatedPlaylist;
      
      // Save to preferences
      final jsonList = playlists.map((p) => _playlistToJson(p)).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
    } catch (e) {
      print('Error removing song from playlist: $e');
      rethrow;
    }
  }

  // Update playlist name
  static Future<void> updatePlaylistName(String playlistId, String newName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Playlist> playlists = await getPlaylists();
      
      final playlistIndex = playlists.indexWhere((p) => p.id == playlistId);
      if (playlistIndex == -1) {
        throw Exception('Playlist not found');
      }
      
      final playlist = playlists[playlistIndex];
      
      // Create updated playlist
      final updatedPlaylist = Playlist(
        id: playlist.id,
        name: newName,
        description: playlist.description,
        imageUrl: playlist.imageUrl,
        songs: playlist.songs,
        createdAt: playlist.createdAt,
        createdBy: playlist.createdBy,
      );
      
      playlists[playlistIndex] = updatedPlaylist;
      
      // Save to preferences
      final jsonList = playlists.map((p) => _playlistToJson(p)).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
    } catch (e) {
      print('Error updating playlist name: $e');
      rethrow;
    }
  }

  // Convert Playlist to JSON
  static Map<String, dynamic> _playlistToJson(Playlist playlist) {
    return {
      'id': playlist.id,
      'name': playlist.name,
      'description': playlist.description,
      'imageUrl': playlist.imageUrl,
      'songs': playlist.songs.map((s) => _mediaItemToJson(s)).toList(),
      'createdAt': playlist.createdAt.toIso8601String(),
      'createdBy': playlist.createdBy,
    };
  }

  // Convert JSON to Playlist
  static Playlist _playlistFromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      songs: (json['songs'] as List<dynamic>)
          .map((s) => _mediaItemFromJson(s))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String?,
    );
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
