import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:umarplayer/theme/app_colors.dart';
import 'package:umarplayer/models/playlist.dart';
import 'package:umarplayer/providers/library_provider.dart';
import 'package:umarplayer/providers/downloads_provider.dart';
import 'package:umarplayer/view/playlist_detail_screen.dart';
import 'package:umarplayer/view/liked_songs_screen.dart';
import 'package:umarplayer/view/downloads_screen.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Library',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Consumer<LibraryProvider>(
            builder: (context, libraryProvider, _) {
              return RefreshIndicator(
                onRefresh: () => libraryProvider.loadData(),
                color: AppColors.neonCyan,
                child: libraryProvider.isLoading
                    ? Center(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonCyan),
                        ),
                      )
                    : _buildContent(context, libraryProvider),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, LibraryProvider libraryProvider) {
    final downloadsProvider = Provider.of<DownloadsProvider>(context, listen: false);
    
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        // Create playlist
        _buildCreatePlaylistItem(context, libraryProvider),
        const SizedBox(height: 16),
        // Liked Songs
        _buildLikedSongsItem(context, libraryProvider),
        const SizedBox(height: 16),
        // Your Downloads
        _buildDownloadsItem(context, downloadsProvider),
        const SizedBox(height: 24),
        // Playlists
        ...libraryProvider.playlists.map((playlist) => _buildPlaylistItem(context, playlist, libraryProvider)),
        const SizedBox(height: 140), // Space for mini player + bottom nav
      ],
    );
  }

  Widget _buildCreatePlaylistItem(BuildContext context, LibraryProvider controller) {
    return InkWell(
      onTap: () => _createPlaylist(context, controller),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.neonCyan.withOpacity(0.25)),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.neonCyan, size: 28),
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

  Widget _buildLikedSongsItem(BuildContext context, LibraryProvider controller) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LikedSongsScreen()),
        );
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
                    AppColors.neonMagenta,
                    Color(0xFFE1306C),
                    Color(0xFFF77737),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonMagenta.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
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
                  Consumer<LibraryProvider>(
                    builder: (context, libraryProvider, _) {
                      return Text(
                        '${libraryProvider.likedSongs.length} ${libraryProvider.likedSongs.length == 1 ? 'song' : 'songs'}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      );
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

  Widget _buildDownloadsItem(BuildContext context, DownloadsProvider downloadsController) {
    return Consumer<DownloadsProvider>(
      builder: (context, downloadsProvider, _) {
        final downloadedCount = downloadsProvider.downloadedSongs.length;
        final downloadingCount = downloadsProvider.isDownloading.values
            .where((isDownloading) => isDownloading == true)
            .length;
        
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DownloadsScreen()),
            );
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
                      colors: [AppColors.neonCyan, AppColors.neonMagenta],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan.withOpacity(0.25),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.download_rounded, color: AppColors.deepPurple, size: 28),
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
      },
    );
  }

  Widget _buildPlaylistItem(BuildContext context, Playlist playlist, LibraryProvider controller) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistDetailScreen(playlistId: playlist.id),
          ),
        );
      },
      onLongPress: () {
        _showPlaylistOptions(context, playlist, controller);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.surfaceVariant,
                border: Border.all(color: AppColors.neonCyan.withOpacity(0.15)),
              ),
              child: playlist.displayImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
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

  Future<void> _createPlaylist(BuildContext context, LibraryProvider controller) async {
    final TextEditingController nameController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Create playlist',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Create', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        await controller.createPlaylist(nameController.text.trim());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Playlist created'),
              backgroundColor: AppColors.surface,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create playlist'),
              backgroundColor: AppColors.accent,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _showPlaylistOptions(BuildContext context, Playlist playlist, LibraryProvider controller) {
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
                Navigator.pop(context);
                _deletePlaylist(context, playlist, controller);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePlaylist(BuildContext context, Playlist playlist, LibraryProvider controller) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Delete playlist',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
        await controller.deletePlaylist(playlist.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Playlist deleted'),
              backgroundColor: AppColors.surface,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete playlist'),
              backgroundColor: AppColors.accent,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }
}
