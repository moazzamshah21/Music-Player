import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umarplayer/theme/app_colors.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/models/playlist.dart';
import 'package:umarplayer/services/playlists_service.dart';
import 'package:umarplayer/providers/player_provider.dart';
import 'package:umarplayer/providers/playlist_detail_provider.dart';
import 'package:umarplayer/widgets/mini_player.dart';
import 'package:umarplayer/view/player_screen.dart';
import 'package:umarplayer/widgets/add_to_playlist_dialog.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlaylistDetailProvider(playlistId),
      child: _PlaylistDetailContent(playlistId: playlistId),
    );
  }
}

class _PlaylistDetailContent extends StatelessWidget {
  final String playlistId;

  const _PlaylistDetailContent({required this.playlistId});

  Future<void> _playMediaItem(BuildContext context, MediaItem item, Playlist? playlist) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    
    try {
      if (playlist != null && playlist.songs.isNotEmpty) {
        await playerProvider.playMediaItem(item, queue: playlist.songs);
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

  Future<void> _removeSongFromPlaylist(BuildContext context, MediaItem song, PlaylistDetailProvider provider) async {
    try {
      await provider.removeSongFromPlaylist(song);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from playlist'),
            backgroundColor: AppColors.surface,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove song'),
            backgroundColor: AppColors.accent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistDetailProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
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
            ),
            body: const Center(
              child: CircularProgressIndicator(
                color: AppColors.textPrimary,
              ),
            ),
          );
        }

        if (provider.playlist == null) {
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
            ),
            body: const Center(
              child: Text(
                'Playlist not found',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          );
        }

        final playlist = provider.playlist!;

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
            title: Text(
              playlist.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.add,
                  color: AppColors.textPrimary,
                ),
                onPressed: () async {
                  final song = await showDialog<MediaItem>(
                    context: context,
                    builder: (context) => const AddToPlaylistDialog(),
                  );
                  
                  if (song != null && context.mounted) {
                    try {
                      await PlaylistsService.addSongToPlaylist(playlistId, song);
                      await provider.loadPlaylist();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Song added to playlist'),
                            backgroundColor: AppColors.surface,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to add song'),
                            backgroundColor: AppColors.accent,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              // Main Content
              playlist.songs.isEmpty
                  ? _buildEmptyState()
                  : _buildSongsList(context, playlist, provider),
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
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_music,
            color: AppColors.textSecondary,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No songs in playlist',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to add songs',
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

  Widget _buildSongsList(BuildContext context, Playlist playlist, PlaylistDetailProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: playlist.songs.length,
      itemBuilder: (context, index) {
        final song = playlist.songs[index];
        return _buildSongItem(context, song, index + 1, playlist, provider);
      },
    );
  }

  Widget _buildSongItem(BuildContext context, MediaItem song, int index, Playlist playlist, PlaylistDetailProvider provider) {
    return InkWell(
      onTap: () => _playMediaItem(context, song, playlist),
      onLongPress: () {
        _removeSongFromPlaylist(context, song, provider);
      },
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
            // Remove Button
            IconButton(
              icon: const Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () => _removeSongFromPlaylist(context, song, provider),
            ),
          ],
        ),
      ),
    );
  }
}
