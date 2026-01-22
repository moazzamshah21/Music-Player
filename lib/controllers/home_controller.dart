import 'package:get/get.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/models/category_section.dart';
import 'package:umarplayer/data/home_data.dart';
import 'package:umarplayer/services/recently_played_service.dart';

class HomeController extends GetxController {
  final HomeData _homeData = HomeData();

  // Observable states
  final RxList<MediaItem> recentlyPlayed = <MediaItem>[].obs;
  final RxMap<String, List<MediaItem>> categoryItems = <String, List<MediaItem>>{}.obs;
  final RxMap<String, bool> categoryLoading = <String, bool>{}.obs;
  final RxBool isLoading = true.obs;

  // Categories
  final List<CategorySection> categories = [];

  @override
  void onInit() {
    super.onInit();
    _initializeCategories();
    loadData();
  }

  void _initializeCategories() {
    categories.addAll([
      CategorySection(
        title: 'Trending Now',
        fetchItems: () => _homeData.getTrendingSongs(limit: 10),
      ),
      CategorySection(
        title: 'Songs from Pakistan',
        fetchItems: () => _homeData.getPakistaniSongs(limit: 10),
      ),
      CategorySection(
        title: 'Bollywood Hits',
        fetchItems: () => _homeData.getBollywoodSongs(limit: 10),
      ),
      CategorySection(
        title: 'English Pop',
        fetchItems: () => _homeData.getEnglishPopSongs(limit: 10),
      ),
      CategorySection(
        title: 'Punjabi Songs',
        fetchItems: () => _homeData.getPunjabiSongs(limit: 10),
      ),
      CategorySection(
        title: 'Hip Hop',
        fetchItems: () => _homeData.getHipHopSongs(limit: 10),
      ),
    ]);

    // Initialize loading states
    for (final category in categories) {
      categoryLoading[category.title] = true;
      categoryItems[category.title] = [];
    }
  }

  Future<void> loadData() async {
    isLoading.value = true;

    try {
      // Load recently played first (fast, from storage)
      await loadRecentlyPlayed();

      // Load categories in background
      _loadCategories();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRecentlyPlayed() async {
    try {
      final items = await RecentlyPlayedService.getRecentlyPlayed();
      recentlyPlayed.value = items;
    } catch (e) {
      print('Error loading recently played: $e');
    }
  }

  Future<void> _loadCategories() async {
    // Load categories one by one to avoid overwhelming
    for (final category in categories) {
      try {
        categoryLoading[category.title] = true;
        categoryLoading.refresh();

        final items = await category.fetchItems();
        
        categoryItems[category.title] = items;
        categoryLoading[category.title] = false;
        categoryLoading.refresh();
        categoryItems.refresh();
      } catch (e) {
        print('Error loading category ${category.title}: $e');
        categoryLoading[category.title] = false;
        categoryLoading.refresh();
      }
    }
  }

  Future<void> addToRecentlyPlayed(MediaItem item) async {
    try {
      await RecentlyPlayedService.addSong(item);
      await loadRecentlyPlayed(); // Refresh list
    } catch (e) {
      print('Error adding to recently played: $e');
    }
  }

  @override
  void onClose() {
    _homeData.dispose();
    super.onClose();
  }
}
