import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umarplayer/theme/app_colors.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/services/downloads_service.dart';
import 'package:umarplayer/providers/player_provider.dart';
import 'package:umarplayer/providers/downloads_provider.dart';
import 'package:umarplayer/widgets/mini_player.dart';
import 'package:umarplayer/view/player_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
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
    
    final downloadsProvider = Provider.of<DownloadsProvider>(context, listen: false);
    await downloadsProvider.loadDownloadedSongs();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _playMediaItem(BuildContext context, MediaItem item) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final downloadsProvider = Provider.of<DownloadsProvider>(context, listen: false);
    
    try {
      await playerProvider.playMediaItem(item);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing ${item.title}'),
            backgroundColor: AppColors.surface,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Error playing song';
      if (e.toString().contains('MissingPluginException')) {
        errorMessage = 'Audio plugin not initialized. Please restart the app.';
      } else if (e.toString().contains('stream URL') || e.toString().contains('audio stream')) {
        errorMessage = 'Could not get audio stream. Please try another song.';
      } else if (e.toString().contains('file') || e.toString().contains('path')) {
        errorMessage = 'Song file not found. Please download again.';
        await downloadsProvider.loadDownloadedSongs();
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.accent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _removeDownloadedSong(BuildContext context, MediaItem item) async {
    await DownloadsService.removeDownloadedSong(item.id);
    await _loadDownloadedSongs();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download removed'),
          backgroundColor: AppColors.surface,
          duration: Duration(seconds: 1),
        ),
      );
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
          onPressed: () => Navigator.pop(context),
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
              : Consumer<DownloadsProvider>(
                  builder: (context, downloadsProvider, _) {
                    return downloadsProvider.downloadedSongs.isEmpty
                        ? _buildEmptyState()
                        : _buildDownloadedSongsList(context, downloadsProvider);
                  },
                ),
          // Mini Player - positioned above bottom nav
          Consumer<PlayerProvider>(
            builder: (context, playerProvider, _) {
              return playerProvider.currentItem != null
                  ? Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: MiniPlayer(
                        currentItem: playerProvider.currentItem,
                        isPlaying: playerProvider.isPlaying,
                        isLiked: playerProvider.isLiked,
                        onPlayPause: () => playerProvider.playPause(),
                        onTap: () {
                          if (playerProvider.currentItem != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PlayerScreen()),
                            );
                          }
                        },
                        onFavorite: () => playerProvider.toggleFavorite(),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
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

  Widget _buildDownloadedSongsList(BuildContext context, DownloadsProvider downloadsProvider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: downloadsProvider.downloadedSongs.length,
      itemBuilder: (context, index) {
        final song = downloadsProvider.downloadedSongs[index];
        return _buildSongItem(context, song, index + 1, downloadsProvider);
      },
    );
  }

  Widget _buildSongItem(BuildContext context, MediaItem song, int index, DownloadsProvider downloadsProvider) {
    final currentProgress = downloadsProvider.getDownloadProgress(song.id);
    final currentlyDownloading = downloadsProvider.isSongDownloading(song.id);
    final canPlay = !currentlyDownloading;

    return InkWell(
      onTap: canPlay ? () => _playMediaItem(context, song) : null,
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
                          style: const TextStyle(
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
                onPressed: () => _removeDownloadedSong(context, song),
              ),
          ],
        ),
      ),
    );
  }
}
