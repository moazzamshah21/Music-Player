import 'package:flutter/material.dart';
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
      
      // Show success briefly
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing ${item.title}'),
          backgroundColor: AppColors.surface,
          duration: const Duration(seconds: 1),
        ),
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Content
        CustomScrollView(
          slivers: [
            // App Bar with Gradient and Good evening
            SliverAppBar(
              expandedHeight: 65,
              collapsedHeight: 60,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.background,
              toolbarHeight: 60,
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.settings,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () {},
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFD7B3A7),
                        AppColors.background,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Good evening',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Content
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.background,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // Recently Played section
                      const Text(
                        'Recently Played',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Recently Played horizontal scroll
                      Consumer<HomeProvider>(
                        builder: (context, homeProvider, _) {
                          return SizedBox(
                            height: 220,
                            child: homeProvider.recentlyPlayed.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No recent items',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
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
                      // Category Sections
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
                                      // Category Title
                                      Text(
                                        category.title,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Category Items horizontal scroll
                                      SizedBox(
                                        height: 220,
                                        child: isLoading
                                            ? const Center(
                                                child: CircularProgressIndicator(
                                                  color: AppColors.textPrimary,
                                                ),
                                              )
                                            : items.isEmpty
                                                ? const Center(
                                                    child: Text(
                                                      'No items available',
                                                      style: TextStyle(
                                                        color: AppColors.textSecondary,
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
                      const SizedBox(height: 80), // Space for mini player + bottom nav
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
