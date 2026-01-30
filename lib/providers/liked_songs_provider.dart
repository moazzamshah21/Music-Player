import 'package:flutter/foundation.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/services/liked_songs_service.dart';
import 'package:umarplayer/providers/player_provider.dart';
import 'package:umarplayer/providers/library_provider.dart';

class LikedSongsProvider extends ChangeNotifier {
  List<MediaItem> _likedSongs = [];
  bool _isLoading = true;
  PlayerProvider? _playerProvider;
  LibraryProvider? _libraryProvider;

  List<MediaItem> get likedSongs => List.unmodifiable(_likedSongs);
  bool get isLoading => _isLoading;

  void setPlayerProvider(PlayerProvider playerProvider) {
    _playerProvider = playerProvider;
  }

  void setLibraryProvider(LibraryProvider libraryProvider) {
    _libraryProvider = libraryProvider;
  }

  LikedSongsProvider() {
    loadLikedSongs();
  }

  Future<void> loadLikedSongs() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final songs = await LikedSongsService.getLikedSongs();
      _likedSongs = songs;
    } catch (e) {
      print('Error loading liked songs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeLikedSong(MediaItem item) async {
    await LikedSongsService.removeLikedSong(item.id);
    await loadLikedSongs();
    _libraryProvider?.loadData(); // Refresh library screen

    if (_playerProvider?.currentItem?.id == item.id) {
      _playerProvider?.refreshLikedStatus();
    }
  }
}
