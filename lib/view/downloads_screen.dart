import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umarplayer/theme/app_colors.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/services/downloads_service.dart';
import 'package:umarplayer/controllers/player_controller.dart';
import 'package:umarplayer/controllers/downloads_controller.dart';
import 'package:umarplayer/widgets/mini_player.dart';
import 'package:umarplayer/view/player_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final PlayerController _playerController = Get.find<PlayerController>();
  final DownloadsController _downloadsController = Get.find<DownloadsController>();
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedSongs();
  }

  Future<void> _loadDownloadedSongs() async {
    setState(() {
      _isLoading = true;
    });
    
    // Load existing downloads (this will preserve downloading songs)
    await _downloadsController.loadDownloadedSongs();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _playMediaItem(MediaItem item) async {
    try {
      // Player service will automatically use local file if available
      await _playerController.playMediaItem(item);
      
      Get.snackbar(
        'Playing',
        item.title,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      String errorMessage = 'Error playing song';
      if (e.toString().contains('MissingPluginException')) {
        errorMessage = 'Audio plugin not initialized. Please restart the app.';
      } else if (e.toString().contains('stream URL') || e.toString().contains('audio stream')) {
        errorMessage = 'Could not get audio stream. Please try another song.';
      } else if (e.toString().contains('file') || e.toString().contains('path')) {
        errorMessage = 'Song file not found. Please download again.';
        // Remove from list if file doesn't exist
        await _downloadsController.loadDownloadedSongs();
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.accent,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _removeDownloadedSong(MediaItem item) async {
    await DownloadsService.removeDownloadedSong(item.id);
    await _loadDownloadedSongs();
    
    Get.snackbar(
      'Removed',
      'Download removed',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      duration: const Duration(seconds: 1),
    );
  }

  void _openPlayerScreen() {
    if (_playerController.currentItem.value != null) {
      Get.to(() => const PlayerScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Your Downloads',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Main Content
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.textPrimary,
                  ),
                )
              : Obx(() => _downloadsController.downloadedSongs.isEmpty
                  ? _buildEmptyState()
                  : _buildDownloadedSongsList()),
          // Mini Player - positioned above bottom nav
          Obx(() => _playerController.currentItem.value != null
              ? Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: MiniPlayer(
                    currentItem: _playerController.currentItem.value,
                    isPlaying: _playerController.isPlaying.value,
                    isLiked: _playerController.isLiked.value,
                    onPlayPause: () => _playerController.playPause(),
                    onTap: _openPlayerScreen,
                    onFavorite: () => _playerController.toggleFavorite(),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            color: AppColors.textSecondary,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No downloads yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Download songs to listen offline',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadedSongsList() {
    return Obx(() => ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _downloadsController.downloadedSongs.length,
      itemBuilder: (context, index) {
        final song = _downloadsController.downloadedSongs[index];
        return _buildSongItem(song, index + 1);
      },
    ));
  }

  Widget _buildSongItem(MediaItem song, int index) {
    return Obx(() {
      final currentProgress = _downloadsController.getDownloadProgress(song.id);
      final currentlyDownloading = _downloadsController.isSongDownloading(song.id);
      
      // Allow playing if not currently downloading
      // Songs in the downloads list should be playable (player will check file existence)
      final canPlay = !currentlyDownloading;

      return InkWell(
        onTap: canPlay ? () => _playMediaItem(song) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // Index
              SizedBox(
                width: 32,
                child: currentlyDownloading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: currentProgress,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : Text(
                        '$index',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              const SizedBox(width: 16),
              // Thumbnail
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: AppColors.surfaceVariant,
                ),
                child: song.imageUrl != null && song.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          song.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.music_note,
                              color: AppColors.textSecondary,
                              size: 28,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.music_note,
                        color: AppColors.textSecondary,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 16),
              // Song Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            song.title,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (canPlay && !currentlyDownloading)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          )
                        else if (currentlyDownloading)
                          Text(
                            '${(currentProgress * 100).toInt()}%',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist ?? 'Unknown Artist',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (currentlyDownloading) ...[
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: currentProgress,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Remove Button (only if not downloading)
              if (canPlay && !currentlyDownloading)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                  onPressed: () => _removeDownloadedSong(song),
                ),
            ],
          ),
        ),
      );
    });
  }
}
