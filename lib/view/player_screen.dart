import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:umarplayer/theme/app_colors.dart';
import 'package:umarplayer/providers/player_provider.dart';
import 'package:umarplayer/providers/downloads_provider.dart';
import 'package:umarplayer/services/downloads_service.dart';
import 'package:umarplayer/services/playlists_service.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, _) {
        final currentItem = playerProvider.currentItem;
        if (currentItem == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(
              child: Text(
                'No song playing',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          );
        }

        final position = playerProvider.position;
        final duration = playerProvider.duration;
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.textPrimary,
                          size: 32,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Column(
                        children: [
                          const Text(
                            'PLAYING FROM ALBUM',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentItem.album ?? 'Unknown Album',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () => _showOptionsMenu(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Album Art
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: currentItem.imageUrl != null && currentItem.imageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: currentItem.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: AppColors.surfaceVariant,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: AppColors.surfaceVariant,
                                      child: const Icon(
                                        Icons.music_note,
                                        color: AppColors.textTertiary,
                                        size: 80,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.surfaceVariant,
                                    child: const Icon(
                                      Icons.music_note,
                                      color: AppColors.textTertiary,
                                      size: 80,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Song Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentItem.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentItem.artist ?? 'Unknown Artist',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Consumer<PlayerProvider>(
                        builder: (context, playerProvider, _) {
                          return IconButton(
                            icon: Icon(
                              playerProvider.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_outline,
                              color: playerProvider.isLiked
                                  ? Colors.red
                                  : AppColors.textPrimary,
                              size: 28,
                            ),
                            onPressed: () => playerProvider.toggleFavorite(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                        ),
                        child: Consumer<PlayerProvider>(
                          builder: (context, playerProvider, _) {
                            return Slider(
                              value: progress.clamp(0.0, 1.0),
                              onChangeStart: (value) {},
                              onChanged: (value) {
                                final newPosition = Duration(
                                  milliseconds: (value * duration.inMilliseconds).toInt(),
                                );
                                // Update position directly for smooth slider feedback
                                playerProvider.updatePosition(newPosition);
                              },
                              onChangeEnd: (value) {
                                final newPosition = Duration(
                                  milliseconds: (value * duration.inMilliseconds).toInt(),
                                );
                                playerProvider.seek(newPosition);
                              },
                              activeColor: AppColors.textPrimary,
                              inactiveColor: AppColors.border,
                            );
                          },
                        ),
                      ),
                      Consumer<PlayerProvider>(
                        builder: (context, playerProvider, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(playerProvider.position),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(playerProvider.duration),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Playback Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Shuffle
                      Consumer<PlayerProvider>(
                        builder: (context, playerProvider, _) {
                          return Column(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.shuffle,
                                  color: playerProvider.isShuffleEnabled
                                      ? AppColors.accent
                                      : AppColors.textPrimary,
                                  size: 24,
                                ),
                                onPressed: () => playerProvider.toggleShuffle(),
                              ),
                              if (playerProvider.isShuffleEnabled)
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      // Previous
                      IconButton(
                        icon: const Icon(
                          Icons.skip_previous,
                          color: AppColors.textPrimary,
                          size: 32,
                        ),
                        onPressed: () => playerProvider.playPrevious(),
                      ),
                      // Play/Pause
                      Consumer<PlayerProvider>(
                        builder: (context, playerProvider, _) {
                          return Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppColors.textPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                playerProvider.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: AppColors.background,
                                size: 32,
                              ),
                              onPressed: () => playerProvider.playPause(),
                            ),
                          );
                        },
                      ),
                      // Next
                      IconButton(
                        icon: const Icon(
                          Icons.skip_next,
                          color: AppColors.textPrimary,
                          size: 32,
                        ),
                        onPressed: () => playerProvider.playNext(),
                      ),
                      // Repeat
                      Consumer<PlayerProvider>(
                        builder: (context, playerProvider, _) {
                          return Column(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.repeat,
                                  color: playerProvider.isRepeatEnabled
                                      ? AppColors.accent
                                      : AppColors.textPrimary,
                                  size: 24,
                                ),
                                onPressed: () => playerProvider.toggleRepeat(),
                              ),
                              if (playerProvider.isRepeatEnabled)
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOptionsMenu(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final downloadsProvider = Provider.of<DownloadsProvider>(context, listen: false);
    final currentItem = playerProvider.currentItem;
    if (currentItem == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.download,
                color: AppColors.textPrimary,
              ),
              title: const Text(
                'Download',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _downloadSong(context, currentItem, downloadsProvider);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.playlist_add,
                color: AppColors.textPrimary,
              ),
              title: const Text(
                'Add to Playlist',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylistDialog(context, currentItem);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadSong(BuildContext context, currentItem, DownloadsProvider downloadsProvider) async {
    final isDownloaded = await DownloadsService.isDownloaded(currentItem.id);
    if (isDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This song is already downloaded'),
          backgroundColor: AppColors.surface,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (downloadsProvider.isSongDownloading(currentItem.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This song is already being downloaded'),
          backgroundColor: AppColors.surface,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      downloadsProvider.downloadSong(currentItem).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not download song. Check Downloads for details.'),
            backgroundColor: AppColors.accent,
            duration: Duration(seconds: 3),
          ),
        );
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading in background. Check Downloads for progress.'),
          backgroundColor: AppColors.surface,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start download: ${e.toString()}'),
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<String?> _showCreatePlaylistDialog(BuildContext context) async {
    final controller = TextEditingController();
    String? result;
    
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create Playlist',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Playlist name',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    result = value.trim();
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final value = controller.text.trim();
                      if (value.isNotEmpty) {
                        result = value;
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                    ),
                    child: const Text(
                      'Create',
                      style: TextStyle(color: AppColors.background),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    
    return result;
  }

  Future<void> _showAddToPlaylistDialog(BuildContext context, currentItem) async {
    final playlists = await PlaylistsService.getPlaylists();
    
    if (playlists.isEmpty) {
      final playlistName = await _showCreatePlaylistDialog(context);
      
      if (playlistName != null && playlistName.isNotEmpty) {
        try {
          final newPlaylist = await PlaylistsService.createPlaylist(playlistName);
          await PlaylistsService.addSongToPlaylist(newPlaylist.id, currentItem);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added to $playlistName'),
              backgroundColor: AppColors.surface,
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create playlist'),
              backgroundColor: AppColors.accent,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add to Playlist',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final playlistName = await _showCreatePlaylistDialog(context);
                      
                      if (playlistName != null && playlistName.isNotEmpty) {
                        try {
                          final newPlaylist = await PlaylistsService.createPlaylist(playlistName);
                          await PlaylistsService.addSongToPlaylist(newPlaylist.id, currentItem);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to $playlistName'),
                              backgroundColor: AppColors.surface,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to create playlist'),
                              backgroundColor: AppColors.accent,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  final isInPlaylist = playlist.songs.any((s) => s.id == currentItem.id);
                  
                  return ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: AppColors.surfaceVariant,
                      ),
                      child: playlist.displayImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                playlist.displayImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.queue_music,
                                    color: AppColors.textSecondary,
                                    size: 24,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.queue_music,
                              color: AppColors.textSecondary,
                              size: 24,
                            ),
                    ),
                    title: Text(
                      playlist.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      isInPlaylist
                          ? 'Already in playlist • ${playlist.songCount} ${playlist.songCount == 1 ? 'song' : 'songs'}'
                          : '${playlist.songCount} ${playlist.songCount == 1 ? 'song' : 'songs'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    trailing: isInPlaylist
                        ? const Icon(
                            Icons.check,
                            color: AppColors.accent,
                          )
                        : null,
                    onTap: isInPlaylist
                        ? null
                        : () async {
                            Navigator.pop(context);
                            try {
                              await PlaylistsService.addSongToPlaylist(playlist.id, currentItem);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added to ${playlist.name}'),
                                  backgroundColor: AppColors.surface,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to add song'),
                                  backgroundColor: AppColors.accent,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
