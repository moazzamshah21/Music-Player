import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umarplayer/theme/app_colors.dart';
import 'package:umarplayer/data/home_data.dart';
import 'package:umarplayer/widgets/quick_access_card.dart';
import 'package:umarplayer/widgets/media_card.dart';
import 'package:umarplayer/widgets/mini_player.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/view/player_screen.dart';
import 'package:umarplayer/controllers/home_controller.dart';
import 'package:umarplayer/controllers/player_controller.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final HomeController _homeController = Get.find<HomeController>();
  final PlayerController _playerController = Get.find<PlayerController>();
  final HomeData _homeData = HomeData();
  
  List<QuickAccessItem> _quickAccessItems = [];

  @override
  void initState() {
    super.initState();
    _loadQuickAccess();
  }

  Future<void> _loadQuickAccess() async {
    final quickAccess = await _homeData.getQuickAccessItems();
    setState(() {
      _quickAccessItems = quickAccess;
    });
  }

  Future<void> _playMediaItem(MediaItem item) async {
    try {
      await _playerController.playMediaItem(item);
      
      // Show success briefly
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
    _homeData.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate expanded height based on content
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final titleHeight = 40.0; // Title text + padding
    final titleSpacing = 16.0;
    final gridRows = (_quickAccessItems.length / 2).ceil(); // 2 columns
    final cardHeight = 60.0;
    final gridSpacing = 12.0;
    final gridHeight = (gridRows * cardHeight) + ((gridRows - 1) * gridSpacing);
    final padding = 16.0; // Top and bottom padding
    final expandedHeight = safeAreaTop + titleHeight + titleSpacing + gridHeight + padding;
    final collapsedHeight = 60.0; // Small collapsed height

    return Stack(
      children: [
        // Main Content
        CustomScrollView(
          slivers: [
            // App Bar with Gradient, Good evening, and Tabs
            SliverAppBar(
              expandedHeight: expandedHeight,
              collapsedHeight: collapsedHeight,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.background,
              toolbarHeight: collapsedHeight,
              // title: const Text(
              //   'Good evening',
              //   style: TextStyle(
              //     color: AppColors.textPrimary,
              //     fontSize: 20,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
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
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row with title and settings
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Good evening',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // IconButton(
                              //   icon: const Icon(
                              //     Icons.settings,
                              //     color: AppColors.textPrimary,
                              //   ),
                              //   onPressed: () {},
                              // ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Quick Access Grid
                          Expanded(
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 2.5,
                              ),
                              itemCount: _quickAccessItems.length,
                              itemBuilder: (context, index) {
                                return QuickAccessCard(
                                  item: _quickAccessItems[index],
                                );
                              },
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
                      const SizedBox(height: 25),
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
                      // Recently Played horizontal scroll - Using GetX Obx for real-time updates
                      Obx(() => SizedBox(
                        height: 220,
                        child: _homeController.recentlyPlayed.isEmpty
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
                                itemCount: _homeController.recentlyPlayed.length,
                                itemBuilder: (context, index) {
                                  return MediaCard(
                                    item: _homeController.recentlyPlayed[index],
                                    width: 150,
                                    onTap: () => _playMediaItem(_homeController.recentlyPlayed[index]),
                                  );
                                },
                              ),
                      )),
                      // Category Sections - Using GetX Obx for real-time updates
                      ..._homeController.categories.map((category) {
                        return Obx(() {
                          final items = _homeController.categoryItems[category.title] ?? [];
                          final isLoading = _homeController.categoryLoading[category.title] ?? true;
                          
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
                                            itemBuilder: (context, index) {
                                              return MediaCard(
                                                item: items[index],
                                                width: 150,
                                                onTap: () => _playMediaItem(items[index]),
                                              );
                                            },
                                          ),
                              ),
                            ],
                          );
                        });
                      }).toList(),
                      const SizedBox(height: 140), // Space for mini player + bottom nav
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Mini Player - positioned above bottom nav - Using GetX Obx
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
    );
  }
}