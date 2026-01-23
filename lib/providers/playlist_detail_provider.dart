import 'package:flutter/foundation.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/models/playlist.dart';
import 'package:umarplayer/services/playlists_service.dart';

class PlaylistDetailProvider extends ChangeNotifier {
  final String playlistId;
  
  Playlist? _playlist;
  bool _isLoading = true;

  Playlist? get playlist => _playlist;
  bool get isLoading => _isLoading;

  PlaylistDetailProvider(this.playlistId) {
    loadPlaylist();
  }

  Future<void> loadPlaylist() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final playlistData = await PlaylistsService.getPlaylistById(playlistId);
      _playlist = playlistData;
    } catch (e) {
      print('Error loading playlist: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeSongFromPlaylist(MediaItem song) async {
    try {
      await PlaylistsService.removeSongFromPlaylist(playlistId, song.id);
      await loadPlaylist();
    } catch (e) {
      print('Error removing song from playlist: $e');
      rethrow;
    }
  }
}
