import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umarplayer/theme/app_colors.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/services/recent_searches_service.dart';
import 'package:umarplayer/services/youtube_service.dart';
import 'package:umarplayer/controllers/player_controller.dart';
import 'package:umarplayer/widgets/mini_player.dart';
import 'package:umarplayer/view/player_screen.dart';
import 'package:umarplayer/services/playlists_service.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _searchController = TextEditingController();
  final YouTubeService _youtubeService = YouTubeService();
  final PlayerController _playerController = Get.find<PlayerController>();
  
  List<MediaItem> _recentSearches = [];
  List<MediaItem> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final searches = await RecentSearchesService.getRecentSearches();
    setState(() {
      _recentSearches = searches;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _currentQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _currentQuery = query;
    });

    try {
      // Search for videos/artists
      final results = await _youtubeService.searchVideos(query, limit: 20);
      
      // If we have results, add the first one as a recent search (as an artist)
      if (results.isNotEmpty) {
        final firstResult = results.first;
        // Use artist name as the identifier for recent searches
        final artistName = firstResult.artist ?? query;
        // Create an artist representation from the first result
        // Use a hash of the artist name as ID to ensure uniqueness per artist
        final artistItem = MediaItem(
          id: 'artist_${artistName.hashCode}',
          title: artistName,
          artist: firstResult.artist,
          imageUrl: firstResult.imageUrl,
          type: 'artist',
        );
        await RecentSearchesService.addSearch(artistItem);
        await _loadRecentSearches();
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Error performing search: $e');
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });
    }
  }

  Future<void> _removeRecentSearch(String id) async {
    await RecentSearchesService.removeSearch(id);
    await _loadRecentSearches();
  }

  Future<void> _playMediaItem(MediaItem item) async {
    try {
      // Pass search results as queue when playing from search
      if (_searchResults.isNotEmpty) {
        await _playerController.playMediaItem(item, queue: _searchResults);
      } else {
        await _playerController.playMediaItem(item);
      }
      
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

  void _openPlayerScreen() {
    if (_playerController.currentItem.value != null) {
      Get.to(() => const PlayerScreen());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Content
        Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              color: AppColors.background,
              child: SafeArea(
                bottom: false,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (value) {
                      _performSearch(value);
                    },
                    onChanged: (value) {
                      if (value.isEmpty) {
                        setState(() {
                          _isSearching = false;
                          _searchResults = [];
                          _currentQuery = '';
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: _isSearching
                  ? _buildSearchResults()
                  : _buildRecentSearches(),
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

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return const Center(
        child: Text(
          'No recent searches',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        const Text(
          'Recent searches',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._recentSearches.map((search) => _buildRecentSearchItem(search)),
        const SizedBox(height: 140), // Space for mini player + bottom nav
      ],
    );
  }

  Widget _buildRecentSearchItem(MediaItem item) {
    return InkWell(
      onTap: () {
        _searchController.text = item.title;
        _performSearch(item.title);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Circular Image
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceVariant,
              ),
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            color: AppColors.textSecondary,
                            size: 28,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 16),
            // Artist Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Artist',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Remove Button
            IconButton(
              icon: const Icon(
                Icons.close,
                color: AppColors.textPrimary,
                size: 20,
              ),
              onPressed: () => _removeRecentSearch(item.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.textPrimary,
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: AppColors.textSecondary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$_currentQuery"',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        Text(
          'Search results for "$_currentQuery"',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._searchResults.map((item) => _buildSearchResultItem(item)),
        const SizedBox(height: 140), // Space for mini player + bottom nav
      ],
    );
  }

  Widget _buildSearchResultItem(MediaItem item) {
    return InkWell(
      onTap: () => _playMediaItem(item),
      onLongPress: () => _showAddToPlaylistMenu(item),
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
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        item.imageUrl!,
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
                    item.title,
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
                    item.artist ?? 'Unknown Artist',
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

  void _showAddToPlaylistMenu(MediaItem song) async {
    final playlists = await PlaylistsService.getPlaylists();
    
    if (playlists.isEmpty) {
      Get.snackbar(
        'No Playlists',
        'Create a playlist first',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
      );
      return;
    }

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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Add to Playlist',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
        ),
      ),
    );
  }
}
