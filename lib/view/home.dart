import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:umarplayer/theme/app_colors.dart';
import 'package:umarplayer/widgets/media_card.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/providers/home_provider.dart';
import 'package:umarplayer/providers/player_provider.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  Future<void> _playMediaItem(BuildContext context, MediaItem item) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    try {
      await playerProvider.playMediaItem(item);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing ${item.title}'),
            backgroundColor: AppColors.surfaceVariant,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Error playing song';
      if (e.toString().contains('MissingPluginException')) {
        errorMessage = 'Audio plugin not initialized. Restart the app.';
      } else if (e.toString().contains('stream URL') || e.toString().contains('audio stream')) {
        errorMessage = 'Could not get audio stream. Try another song.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.neonPink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
            SliverAppBar(
              expandedHeight: 120,
              collapsedHeight: 70,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              toolbarHeight: 70,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'RΛVE',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _sectionTitle('Recently Played'),
                const SizedBox(height: 16),
                Consumer<HomeProvider>(
                  builder: (context, homeProvider, _) {
                    return SizedBox(
                      height: 220,
                      child: homeProvider.recentlyPlayed.isEmpty
                          ? Center(
                              child: Text(
                                'no recent items',
                                style: TextStyle(
                                  color: AppColors.textSecondary.withOpacity(0.8),
                                  fontSize: 15,
                                ),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: homeProvider.recentlyPlayed.length,
                              cacheExtent: 500,
                              itemBuilder: (context, index) {
                                return MediaCard(
                                  item: homeProvider.recentlyPlayed[index],
                                  width: 150,
                                  onTap: () => _playMediaItem(context, homeProvider.recentlyPlayed[index]),
                                );
                              },
                            ),
                    );
                  },
                ),
                Consumer<HomeProvider>(
                  builder: (context, homeProvider, _) {
                    return Column(
                      children: homeProvider.categories.map((category) {
                        return Consumer<HomeProvider>(
                          builder: (context, homeProvider, _) {
                            final items = homeProvider.categoryItems[category.title] ?? [];
                            final isLoading = homeProvider.categoryLoading[category.title] ?? true;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 32),
                                _sectionTitle(category.title),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 220,
                                  child: isLoading
                                      ? Center(
                                          child: SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.brandy,
                                            ),
                                          ),
                                        )
                                      : items.isEmpty
                                          ? Center(
                                              child: Text(
                                                'no items',
                                                style: TextStyle(
                                                  color: AppColors.textSecondary.withOpacity(0.8),
                                                  fontSize: 15,
                                                ),
                                              ),
                                            )
                                          : ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: items.length,
                                              cacheExtent: 500,
                                              itemBuilder: (context, index) {
                                                return MediaCard(
                                                  item: items[index],
                                                  width: 150,
                                                  onTap: () => _playMediaItem(context, items[index]),
                                                );
                                              },
                                            ),
                                ),
                              ],
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
