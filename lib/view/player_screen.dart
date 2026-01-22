import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umarplayer/theme/app_colors.dart';
import 'package:umarplayer/controllers/player_controller.dart';
import 'package:umarplayer/services/liked_songs_service.dart';
import 'package:umarplayer/services/playlists_service.dart';
import 'package:umarplayer/services/downloads_service.dart';
import 'package:umarplayer/controllers/downloads_controller.dart';
import 'package:umarplayer/models/media_item.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isLiked = false;
  bool _isCheckingLike = true;
  String? _currentSongId;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkLikeStatus(String? songId) async {
    if (songId == null) {
      setState(() {
        _isLiked = false;
        _isCheckingLike = false;
      });
      return;
    }

    if (_currentSongId != songId) {
      _currentSongId = songId;
      final isLiked = await LikedSongsService.isLiked(songId);
      setState(() {
        _isLiked = isLiked;
        _isCheckingLike = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final playerController = Get.find<PlayerController>();
    final currentItem = playerController.currentItem.value;
    if (currentItem == null) return;

    final newLikeStatus = await LikedSongsService.toggleLike(currentItem);
    setState(() {
      _isLiked = newLikeStatus;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    final playerService = playerController.playerService;

    return Obx(() {
      final currentItem = playerController.currentItem.value;
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

      // Check like status when song changes
      if (_currentSongId != currentItem.id) {
        _checkLikeStatus(currentItem.id);
      }

      final position = playerController.position.value;
      final duration = playerController.duration.value;
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
                    onPressed: () => _showMenu(context, currentItem),
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
                        child: currentItem.imageUrl != null
                            ? Image.network(
                                currentItem.imageUrl!,
                                fit: BoxFit.cover,
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
                  IconButton(
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_outline,
                      color: _isLiked ? Colors.red : AppColors.textPrimary,
                      size: 28,
                    ),
                    onPressed: _isCheckingLike ? null : _toggleLike,
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
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (value) {
                        final newPosition = Duration(
                          milliseconds: (value * duration.inMilliseconds).toInt(),
                        );
                        playerController.seek(newPosition);
                      },
                      activeColor: AppColors.textPrimary,
                      inactiveColor: AppColors.border,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: playerController.isShuffleEnabled
                              ? AppColors.accent
                              : AppColors.textPrimary,
                          size: 24,
                        ),
                        onPressed: () {
                          playerController.toggleShuffle();
                        },
                      ),
                      if (playerController.isShuffleEnabled)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  // Previous
                  IconButton(
                    icon: const Icon(
                      Icons.skip_previous,
                      color: AppColors.textPrimary,
                      size: 32,
                    ),
                    onPressed: () {
                      // Implement previous track
                    },
                  ),
                  // Play/Pause
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        playerController.isPlaying.value
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: AppColors.background,
                        size: 32,
                      ),
                      onPressed: () => playerController.playPause(),
                    ),
                  ),
                  // Next
                  IconButton(
                    icon: const Icon(
                      Icons.skip_next,
                      color: AppColors.textPrimary,
                      size: 32,
                    ),
                    onPressed: () {
                      // Implement next track
                    },
                  ),
                  // Repeat
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.repeat,
                          color: playerService.isRepeatEnabled
                              ? AppColors.accent
                              : AppColors.textPrimary,
                          size: 24,
                        ),
                        onPressed: () {
                          playerService.toggleRepeat();
                        },
                      ),
                      if (playerService.isRepeatEnabled)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Bottom controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cast,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Devices Available',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.queue_music,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    });
  }

  void _showMenu(BuildContext context, MediaItem currentItem) async {
    final downloadsController = Get.find<DownloadsController>();
    final isDownloaded = await DownloadsService.isDownloaded(currentItem.id);
    final isDownloading = downloadsController.isSongDownloading(currentItem.id);
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.playlist_add,
                color: AppColors.textPrimary,
              ),
              title: const Text(
                'Add to playlist',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Get.back();
                _showAddToPlaylistDialog(currentItem);
              },
            ),
            ListTile(
              leading: Icon(
                isDownloaded
                    ? Icons.download_done
                    : isDownloading
                        ? Icons.downloading
                        : Icons.download,
                color: isDownloaded
                    ? Colors.green
                    : isDownloading
                        ? AppColors.textPrimary
                        : AppColors.textPrimary,
              ),
              title: Text(
                isDownloaded
                    ? 'Downloaded'
                    : isDownloading
                        ? 'Downloading...'
                        : 'Download',
                style: TextStyle(
                  color: isDownloaded
                      ? Colors.green
                      : AppColors.textPrimary,
                ),
              ),
              onTap: (isDownloaded || isDownloading)
                  ? null
                  : () {
                      Get.back();
                      _downloadSong(currentItem);
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadSong(MediaItem song) async {
    final downloadsController = Get.find<DownloadsController>();
    
    try {
      // Start download in background
      downloadsController.downloadSong(song).catchError((error) {
        Get.snackbar(
          'Error',
          'Failed to download: ${error.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 3),
        );
      });
      
      Get.snackbar(
        'Downloading',
        '${song.title} is downloading in background',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to start download',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.accent,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _showAddToPlaylistDialog(MediaItem song) async {
    final playlists = await PlaylistsService.getPlaylists();
    
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surface,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.6,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add to Playlist',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Create New Playlist Button
              InkWell(
                onTap: () async {
                  Get.back(); // Close current dialog
                  await _createNewPlaylistAndAdd(song);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.textPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Create new playlist',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Existing Playlists
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No playlists yet. Create one above.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                const Text(
                  'Your Playlists',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
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
                          '${playlist.songCount} ${playlist.songCount == 1 ? 'song' : 'songs'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () async {
                          Get.back();
                          try {
                            await PlaylistsService.addSongToPlaylist(playlist.id, song);
                            Get.snackbar(
                              'Added',
                              'Added to ${playlist.name}',
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
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createNewPlaylistAndAdd(MediaItem song) async {
    final TextEditingController nameController = TextEditingController();
    
    final result = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Create playlist',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textPrimary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Get.back(result: true);
              }
            },
            child: const Text(
              'Create',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        final newPlaylist = await PlaylistsService.createPlaylist(nameController.text.trim());
        await PlaylistsService.addSongToPlaylist(newPlaylist.id, song);
        Get.snackbar(
          'Created',
          'Playlist created and song added',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          duration: const Duration(seconds: 1),
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to create playlist',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }
}
