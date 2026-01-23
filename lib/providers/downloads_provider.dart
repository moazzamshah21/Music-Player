import 'package:flutter/foundation.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/services/downloads_service.dart';

class DownloadsProvider extends ChangeNotifier {
  Map<String, double> _downloadProgress = {};
  Map<String, bool> _isDownloading = {};
  List<MediaItem> _downloadedSongs = [];

  Map<String, double> get downloadProgress => Map.unmodifiable(_downloadProgress);
  Map<String, bool> get isDownloading => Map.unmodifiable(_isDownloading);
  List<MediaItem> get downloadedSongs => List.unmodifiable(_downloadedSongs);

  DownloadsProvider() {
    loadDownloadedSongs();
  }

  Future<void> loadDownloadedSongs() async {
    final songs = await DownloadsService.getDownloadedSongs();
    
    final downloadingSongIds = _isDownloading.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toSet();
    
    final currentDownloadingSongs = _downloadedSongs
        .where((song) => downloadingSongIds.contains(song.id))
        .toList();
    
    final allSongs = <MediaItem>[];
    
    for (final song in currentDownloadingSongs) {
      if (!allSongs.any((s) => s.id == song.id)) {
        allSongs.add(song);
      }
    }
    
    for (final song in songs) {
      if (!downloadingSongIds.contains(song.id) && !allSongs.any((s) => s.id == song.id)) {
        allSongs.add(song);
      }
    }
    
    _downloadedSongs = allSongs;
    notifyListeners();
  }

  Future<void> downloadSong(MediaItem song) async {
    if (await DownloadsService.isDownloaded(song.id)) {
      return;
    }

    if (_isDownloading[song.id] == true) {
      return;
    }

    _isDownloading[song.id] = true;
    _downloadProgress[song.id] = 0.0;

    if (!_downloadedSongs.any((s) => s.id == song.id)) {
      _downloadedSongs.insert(0, song);
    }
    notifyListeners();

    try {
      await DownloadsService.downloadSongWithProgress(
        song,
        onProgress: (progress) {
          _downloadProgress[song.id] = progress;
          notifyListeners();
        },
      );

      _isDownloading[song.id] = false;
      _downloadProgress[song.id] = 1.0;
      
      await loadDownloadedSongs();
      
      // Show success notification would be handled by UI
    } catch (e) {
      _isDownloading[song.id] = false;
      _downloadProgress.remove(song.id);
      _downloadedSongs.removeWhere((s) => s.id == song.id);
      notifyListeners();
      rethrow;
    }
  }

  bool isSongDownloading(String songId) {
    return _isDownloading[songId] == true;
  }

  double getDownloadProgress(String songId) {
    return _downloadProgress[songId] ?? 0.0;
  }

  Future<bool> isSongDownloaded(String songId) async {
    return await DownloadsService.isDownloaded(songId);
  }
}
