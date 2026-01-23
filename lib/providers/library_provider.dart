import 'package:flutter/foundation.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/models/playlist.dart';
import 'package:umarplayer/services/liked_songs_service.dart';
import 'package:umarplayer/services/playlists_service.dart';

class LibraryProvider extends ChangeNotifier {
  List<MediaItem> _likedSongs = [];
  List<Playlist> _playlists = [];
  bool _isLoading = true;

  List<MediaItem> get likedSongs => List.unmodifiable(_likedSongs);
  List<Playlist> get playlists => List.unmodifiable(_playlists);
  bool get isLoading => _isLoading;

  LibraryProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final liked = await LikedSongsService.getLikedSongs();
      final playlistsList = await PlaylistsService.getPlaylists();
      
      _likedSongs = liked;
      _playlists = playlistsList;
    } catch (e) {
      print('Error loading library data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPlaylist(String name) async {
    try {
      await PlaylistsService.createPlaylist(name);
      await loadData();
    } catch (e) {
      print('Error creating playlist: $e');
      rethrow;
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await PlaylistsService.deletePlaylist(playlistId);
      await loadData();
    } catch (e) {
      print('Error deleting playlist: $e');
      rethrow;
    }
  }
}
