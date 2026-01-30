import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umarplayer/theme/app_colors.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/providers/player_provider.dart';
import 'package:umarplayer/providers/search_provider.dart';
import 'package:umarplayer/providers/tab_index_provider.dart';
import 'package:umarplayer/services/playlists_service.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _checkPendingSearch(BuildContext context) {
    final tabProvider = Provider.of<TabIndexProvider>(context, listen: false);
    final query = tabProvider.takePendingSearchQuery();
    if (query != null && query.isNotEmpty) {
      _textController.text = query;
      Provider.of<SearchProvider>(context, listen: false).performSearch(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabProvider = Provider.of<TabIndexProvider>(context, listen: false);
    if (tabProvider.pendingSearchQuery != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingSearch(context));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.glassWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withOpacity(0.06),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'search songs, artists...',
                  hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.9), fontSize: 15),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.neonCyan.withOpacity(0.9), size: 24),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                onSubmitted: (value) {
                  Provider.of<SearchProvider>(context, listen: false).performSearch(value);
                },
                onChanged: (value) {
                  if (value.isEmpty) {
                    Provider.of<SearchProvider>(context, listen: false).clearSearch();
                  }
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: Consumer<SearchProvider>(
            builder: (context, searchProvider, _) {
              return searchProvider.isSearching
                  ? _buildSearchResults(context, searchProvider)
                  : _buildRecentSearches(context, searchProvider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearches(BuildContext context, SearchProvider searchProvider) {
    if (searchProvider.recentSearches.isEmpty) {
      return Center(
        child: Text(
          'no recent searches',
          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.9), fontSize: 15),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 8),
        const Text(
          'Recent',
          style: TextStyle(
            color: AppColors.neonCyan,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ...searchProvider.recentSearches.map((search) => _buildRecentSearchItem(context, search, searchProvider)),
        const SizedBox(height: 140),
      ],
    );
  }

  Widget _buildRecentSearchItem(BuildContext context, MediaItem item, SearchProvider searchProvider) {
    return InkWell(
      onTap: () {
        _textController.text = item.title;
        searchProvider.performSearch(item.title);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceVariant,
                border: Border.all(color: AppColors.neonCyan.withOpacity(0.2)),
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
              onPressed: () => searchProvider.removeRecentSearch(item.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, SearchProvider searchProvider) {
    if (searchProvider.isLoading) {
      return Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonCyan),
        ),
      );
    }

    if (searchProvider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: AppColors.textSecondary.withOpacity(0.8), size: 56),
            const SizedBox(height: 16),
            Text(
              'no results for "${searchProvider.currentQuery}"',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.9), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 8),
        const Text(
          'Results',
          style: TextStyle(
            color: AppColors.neonCyan,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ...searchProvider.searchResults.map((item) => _buildSearchResultItem(context, item, searchProvider)),
        const SizedBox(height: 140),
      ],
    );
  }

  Widget _buildSearchResultItem(BuildContext context, MediaItem item, SearchProvider searchProvider) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    return InkWell(
      onTap: () => _playMediaItem(context, item, searchProvider, playerProvider),
      onLongPress: () => _showAddToPlaylistMenu(context, item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surfaceVariant,
                border: Border.all(color: AppColors.neonCyan.withOpacity(0.15)),
              ),
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
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

  Future<void> _playMediaItem(BuildContext context, MediaItem item, SearchProvider searchProvider, PlayerProvider playerProvider) async {
    try {
      // Pass search results as queue when playing from search
      if (searchProvider.searchResults.isNotEmpty) {
        await playerProvider.playMediaItem(item, queue: searchProvider.searchResults);
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

  void _showAddToPlaylistMenu(BuildContext context, MediaItem song) async {
    final playlists = await PlaylistsService.getPlaylists();
    
    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a playlist first'),
          backgroundColor: AppColors.surface,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceVariant.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
                      Navigator.pop(context);
                      try {
                        await PlaylistsService.addSongToPlaylist(playlist.id, song);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to ${playlist.name}'),
                              backgroundColor: AppColors.surface,
                              duration: const Duration(seconds: 1),
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
