import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umarplayer/theme/app_colors.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/providers/player_provider.dart';
import 'package:umarplayer/providers/liked_songs_provider.dart';
import 'package:umarplayer/widgets/mini_player.dart';
import 'package:umarplayer/view/player_screen.dart';

class LikedSongsScreen extends StatefulWidget {
  const LikedSongsScreen({super.key});

  @override
  State<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends State<LikedSongsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LikedSongsProvider>().loadLikedSongs();
    });
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
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Liked Songs',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Consumer<LikedSongsProvider>(
                      builder: (context, likedSongsProvider, _) {
                        return likedSongsProvider.isLoading
                            ? Center(
                                child: SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonCyan),
                                ),
                              )
                            : likedSongsProvider.likedSongs.isEmpty
                                ? _buildEmptyState()
                                : _buildLikedSongsList(context, likedSongsProvider);
                      },
                    ),
                  ),
                ],
              ),
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
                  Icons.favorite_border_rounded,
                  color: AppColors.neonCyan.withOpacity(0.8),
                  size: 56,
                ),
                const SizedBox(height: 20),
                const Text(
                  'No liked songs yet',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the heart icon to add songs\nyou like to your library',
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

  Widget _buildLikedSongsList(BuildContext context, LikedSongsProvider likedSongsProvider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: likedSongsProvider.likedSongs.length,
      itemBuilder: (context, index) {
        final song = likedSongsProvider.likedSongs[index];
        return _buildSongItem(context, song, index + 1, likedSongsProvider);
      },
    );
  }

  Widget _buildSongItem(BuildContext context, MediaItem song, int index, LikedSongsProvider likedSongsProvider) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: InkWell(
            onTap: () => _playMediaItem(context, song, likedSongsProvider, playerProvider),
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
                    child: Text(
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
                        Text(
                          song.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.neonMagenta,
                      size: 24,
                    ),
                    onPressed: () => likedSongsProvider.removeLikedSong(song),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _playMediaItem(BuildContext context, MediaItem item, LikedSongsProvider likedSongsProvider, PlayerProvider playerProvider) async {
    try {
      if (likedSongsProvider.likedSongs.isNotEmpty) {
        await playerProvider.playMediaItem(item, queue: likedSongsProvider.likedSongs);
      } else {
        await playerProvider.playMediaItem(item);
      }
      
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
}
