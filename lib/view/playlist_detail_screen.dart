import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umarplayer/theme/app_colors.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/models/playlist.dart';
import 'package:umarplayer/services/playlists_service.dart';
import 'package:umarplayer/controllers/player_controller.dart';
import 'package:umarplayer/widgets/mini_player.dart';
import 'package:umarplayer/view/player_screen.dart';
import 'package:umarplayer/widgets/add_to_playlist_dialog.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final PlayerController _playerController = Get.find<PlayerController>();
  
  Playlist? _playlist;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    setState(() {
      _isLoading = true;
    });
    
    final playlist = await PlaylistsService.getPlaylistById(widget.playlistId);
    setState(() {
      _playlist = playlist;
      _isLoading = false;
    });
  }

  Future<void> _playMediaItem(MediaItem item) async {
    try {
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

  Future<void> _removeSongFromPlaylist(MediaItem song) async {
    try {
      await PlaylistsService.removeSongFromPlaylist(widget.playlistId, song.id);
      await _loadPlaylist();
      
      Get.snackbar(
        'Removed',
        'Removed from playlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove song',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.accent,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _openPlayerScreen() {
    if (_playerController.currentItem.value != null) {
      Get.to(() => const PlayerScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.textPrimary,
          ),
        ),
      );
    }

    if (_playlist == null) {
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
        ),
        body: const Center(
          child: Text(
            'Playlist not found',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }

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
        title: Text(
          _playlist!.name,
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
              
              if (song != null) {
                try {
                  await PlaylistsService.addSongToPlaylist(widget.playlistId, song);
                  await _loadPlaylist();
                  Get.snackbar(
                    'Added',
                    'Song added to playlist',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.surface,
                    duration: const Duration(seconds: 1),
                  );
                } catch (e) {
                  Get.snackbar(
                    'Error',
                    'Failed to add song',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.accent,
                    duration: const Duration(seconds: 2),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Content
          _playlist!.songs.isEmpty
              ? _buildEmptyState()
              : _buildSongsList(),
          // Mini Player - positioned above bottom nav
          Obx(() => _playerController.currentItem.value != null
              ? Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: MiniPlayer(
                    currentItem: _playerController.currentItem.value,
                    isPlaying: _playerController.isPlaying.value,
                    onPlayPause: () => _playerController.playPause(),
                    onTap: _openPlayerScreen,
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

  Widget _buildSongsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _playlist!.songs.length,
      itemBuilder: (context, index) {
        final song = _playlist!.songs[index];
        return _buildSongItem(song, index + 1);
      },
    );
  }

  Widget _buildSongItem(MediaItem song, int index) {
    return InkWell(
      onTap: () => _playMediaItem(song),
      onLongPress: () {
        _removeSongFromPlaylist(song);
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
              onPressed: () => _removeSongFromPlaylist(song),
            ),
          ],
        ),
      ),
    );
  }
}
