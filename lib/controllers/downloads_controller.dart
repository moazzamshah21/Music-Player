import 'package:get/get.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/services/downloads_service.dart';
import 'package:umarplayer/theme/app_colors.dart';

class DownloadsController extends GetxController {
  final RxMap<String, double> downloadProgress = <String, double>{}.obs;
  final RxMap<String, bool> isDownloading = <String, bool>{}.obs;
  final RxList<MediaItem> downloadedSongs = <MediaItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDownloadedSongs();
  }

  Future<void> loadDownloadedSongs() async {
    final songs = await DownloadsService.getDownloadedSongs();
    
    // Get currently downloading song IDs
    final downloadingSongIds = isDownloading.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toSet();
    
    // Preserve currently downloading songs from the existing list
    final currentDownloadingSongs = downloadedSongs
        .where((song) => downloadingSongIds.contains(song.id))
        .toList();
    
    // Combine: downloading songs first, then downloaded songs
    final allSongs = <MediaItem>[];
    
    // Add downloading songs first (they should appear at top)
    for (final song in currentDownloadingSongs) {
      if (!allSongs.any((s) => s.id == song.id)) {
        allSongs.add(song);
      }
    }
    
    // Add downloaded songs (excluding ones that are downloading)
    for (final song in songs) {
      if (!downloadingSongIds.contains(song.id) && !allSongs.any((s) => s.id == song.id)) {
        allSongs.add(song);
      }
    }
    
    downloadedSongs.value = allSongs;
  }

  Future<void> downloadSong(MediaItem song) async {
    // Check if already downloaded
    if (await DownloadsService.isDownloaded(song.id)) {
      return;
    }

    // Check if already downloading
    if (isDownloading[song.id] == true) {
      return;
    }

    // Mark as downloading
    isDownloading[song.id] = true;
    downloadProgress[song.id] = 0.0;

    // Add to list immediately if not already there
    if (!downloadedSongs.any((s) => s.id == song.id)) {
      downloadedSongs.insert(0, song);
    }

    try {
      await DownloadsService.downloadSongWithProgress(
        song,
        onProgress: (progress) {
          downloadProgress[song.id] = progress;
        },
      );

      // Download complete
      isDownloading[song.id] = false;
      downloadProgress[song.id] = 1.0;
      
      // Reload to ensure file exists
      await loadDownloadedSongs();
      
      // Show success notification
      Get.snackbar(
        'Download Complete',
        '${song.title} is ready to play',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      // Download failed
      isDownloading[song.id] = false;
      downloadProgress.remove(song.id);
      
      // Remove from list if download failed
      downloadedSongs.removeWhere((s) => s.id == song.id);
      
      rethrow;
    }
  }

  bool isSongDownloading(String songId) {
    return isDownloading[songId] == true;
  }

  double getDownloadProgress(String songId) {
    return downloadProgress[songId] ?? 0.0;
  }

  Future<bool> isSongDownloaded(String songId) async {
    return await DownloadsService.isDownloaded(songId);
  }
}
