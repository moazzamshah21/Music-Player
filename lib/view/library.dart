import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umarplayer/theme/app_colors.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/models/playlist.dart';
import 'package:umarplayer/services/liked_songs_service.dart';
import 'package:umarplayer/services/playlists_service.dart';
import 'package:umarplayer/controllers/player_controller.dart';
import 'package:umarplayer/widgets/mini_player.dart';
import 'package:umarplayer/view/player_screen.dart';
import 'package:umarplayer/view/playlist_detail_screen.dart';
import 'package:umarplayer/view/liked_songs_screen.dart';
import 'package:umarplayer/view/downloads_screen.dart';
import 'package:umarplayer/controllers/downloads_controller.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  final PlayerController _playerController = Get.find<PlayerController>();
  final DownloadsController _downloadsController = Get.find<DownloadsController>();
  
  List<MediaItem> _likedSongs = [];
  List<Playlist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    final likedSongs = await LikedSongsService.getLikedSongs();
    final playlists = await PlaylistsService.getPlaylists();
    await _downloadsController.loadDownloadedSongs();
    
    setState(() {
      _likedSongs = likedSongs;
      _playlists = playlists;
      _isLoading = false;
    });
  }

  Future<void> _createPlaylist() async {
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
        await PlaylistsService.createPlaylist(nameController.text.trim());
        await _loadData();
        Get.snackbar(
          'Created',
          'Playlist created',
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

  Future<void> _deletePlaylist(Playlist playlist) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete playlist',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
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
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await PlaylistsService.deletePlaylist(playlist.id);
        await _loadData();
        Get.snackbar(
          'Deleted',
          'Playlist deleted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          duration: const Duration(seconds: 1),
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to delete playlist',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  void _openPlayerScreen() {
    if (_playerController.currentItem.value != null) {
      Get.to(() => const PlayerScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Content
        Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              color: AppColors.background,
              child: SafeArea(
                bottom: false,
                child: const Text(
                  'Your Library',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.textPrimary,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.textPrimary,
                        ),
                      )
                    : _buildContent(),
              ),
            ),
          ],
        ),
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
    );
  }

  Widget _buildContent() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        // Create playlist
        _buildCreatePlaylistItem(),
        const SizedBox(height: 16),
        // Liked Songs
        _buildLikedSongsItem(),
        const SizedBox(height: 16),
        // Your Downloads
        _buildDownloadsItem(),
        const SizedBox(height: 24),
        // Playlists
        if (_playlists.isNotEmpty) ...[
          ..._playlists.map((playlist) => _buildPlaylistItem(playlist)),
        ],
        const SizedBox(height: 140), // Space for mini player + bottom nav
      ],
    );
  }

  Widget _buildCreatePlaylistItem() {
    return InkWell(
      onTap: _createPlaylist,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.textPrimary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Create playlist',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikedSongsItem() {
    return InkWell(
      onTap: () {
        Get.to(() => const LikedSongsScreen());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF450AF5),
                    Color(0xFFC13584),
                    Color(0xFFE1306C),
                    Color(0xFFFD1D1D),
                    Color(0xFFF77737),
                    Color(0xFFFCAF45),
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Liked Songs',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_likedSongs.length} ${_likedSongs.length == 1 ? 'song' : 'songs'}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadsItem() {
    return Obx(() {
      final downloadedCount = _downloadsController.downloadedSongs.length;
      final downloadingCount = _downloadsController.isDownloading.values
          .where((isDownloading) => isDownloading == true)
          .length;
      
      return InkWell(
        onTap: () {
          Get.to(() => const DownloadsScreen());
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1DB954),
                      Color(0xFF1ED760),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.download,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Downloads',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      downloadingCount > 0
                          ? '$downloadedCount ${downloadedCount == 1 ? 'song' : 'songs'} • $downloadingCount downloading'
                          : '$downloadedCount ${downloadedCount == 1 ? 'song' : 'songs'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPlaylistItem(Playlist playlist) {
    return InkWell(
      onTap: () {
        Get.to(() => PlaylistDetailScreen(playlistId: playlist.id));
      },
      onLongPress: () {
        _showPlaylistOptions(playlist);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 56,
              height: 56,
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
                            size: 28,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.queue_music,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 16),
            // Playlist Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
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
                    playlist.createdBy ?? 'Playlist',
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
          ],
        ),
      ),
    );
  }

  void _showPlaylistOptions(Playlist playlist) {
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
                Icons.delete,
                color: Colors.red,
              ),
              title: const Text(
                'Delete playlist',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Get.back();
                _deletePlaylist(playlist);
              },
            ),
          ],
        ),
      ),
    );
  }
}
