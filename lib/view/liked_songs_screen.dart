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
          'Liked Songs',
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
          Consumer<LikedSongsProvider>(
            builder: (context, likedSongsProvider, _) {
              return likedSongsProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.textPrimary,
                      ),
                    )
                  : likedSongsProvider.likedSongs.isEmpty
                      ? _buildEmptyState()
                      : _buildLikedSongsList(context, likedSongsProvider);
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            color: AppColors.textSecondary,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No liked songs yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
    );
  }

  Widget _buildLikedSongsList(BuildContext context, LikedSongsProvider likedSongsProvider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: likedSongsProvider.likedSongs.length,
      itemBuilder: (context, index) {
        final song = likedSongsProvider.likedSongs[index];
        return _buildSongItem(context, song, index + 1, likedSongsProvider);
      },
    );
  }

  Widget _buildSongItem(BuildContext context, MediaItem song, int index, LikedSongsProvider likedSongsProvider) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    
    return InkWell(
      onTap: () => _playMediaItem(context, song, likedSongsProvider, playerProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Index
            SizedBox(
              width: 32,
              child: Text(
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
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                ],
              ),
            ),
            // Like Button
            IconButton(
              icon: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 24,
              ),
              onPressed: () => likedSongsProvider.removeLikedSong(song),
            ),
          ],
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
