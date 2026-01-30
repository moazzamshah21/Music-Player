import 'dart:ui';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.deepPurple, AppColors.violetMid, AppColors.surfaceDark],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Your Downloads',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  _isLoading
                      ? Center(
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonCyan),
                          ),
                        )
                      : Consumer<DownloadsProvider>(
                          builder: (context, downloadsProvider, _) {
                            return downloadsProvider.downloadedSongs.isEmpty
                                ? _buildEmptyState()
                                : _buildDownloadedSongsList(context, downloadsProvider);
                          },
                        ),
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
                                isLoading: playerProvider.isLoading,
                                loadingMessage: playerProvider.loadingMessage,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            decoration: BoxDecoration(
              color: AppColors.glassWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download_outlined,
                  color: AppColors.neonCyan.withOpacity(0.8),
                  size: 56,
                ),
                const SizedBox(height: 20),
                const Text(
                  'No downloads yet',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
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
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadedSongsList(BuildContext context, DownloadsProvider downloadsProvider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: InkWell(
            onTap: canPlay ? () => _playMediaItem(context, song) : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.glassWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder, width: 1),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: currentlyDownloading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: currentProgress,
                              color: AppColors.neonCyan,
                            ),
                          )
                        : Text(
                            '$index',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.surfaceVariant.withOpacity(0.5),
                      border: Border.all(color: AppColors.glassBorder.withOpacity(0.5)),
                    ),
                    child: song.imageUrl != null && song.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              song.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.music_note_rounded,
                                  color: AppColors.neonCyan.withOpacity(0.8),
                                  size: 24,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.music_note_rounded,
                            color: AppColors.neonCyan.withOpacity(0.8),
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 14),
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (canPlay && !currentlyDownloading)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.neonCyan,
                                size: 18,
                              )
                            else if (currentlyDownloading)
                              Text(
                                '${(currentProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist ?? 'Unknown Artist',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (currentlyDownloading) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: currentProgress,
                              backgroundColor: AppColors.surfaceVariant.withOpacity(0.6),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (canPlay && !currentlyDownloading)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      onPressed: () => _removeDownloadedSong(context, song),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
