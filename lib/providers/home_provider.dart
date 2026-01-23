import 'package:flutter/foundation.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/models/category_section.dart';
import 'package:umarplayer/services/recently_played_service.dart';
import 'package:umarplayer/services/youtube_service.dart';

class HomeProvider extends ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();

  List<MediaItem> _recentlyPlayed = [];
  Map<String, List<MediaItem>> _categoryItems = {};
  Map<String, bool> _categoryLoading = {};
  bool _isLoading = true;

  List<CategorySection> categories = [];

  // Getters
  List<MediaItem> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);
  Map<String, List<MediaItem>> get categoryItems => Map.unmodifiable(_categoryItems);
  Map<String, bool> get categoryLoading => Map.unmodifiable(_categoryLoading);
  bool get isLoading => _isLoading;

  HomeProvider() {
    _initializeCategories();
    loadData();
  }

  void _initializeCategories() {
    categories.addAll([
      CategorySection(
        title: 'Trending Now',
        fetchItems: () => _youtubeService.searchVideos('trending music 2024', limit: 10),
      ),
      CategorySection(
        title: 'Songs from Pakistan',
        fetchItems: () => _youtubeService.searchVideos('pakistani songs', limit: 10),
      ),
      CategorySection(
        title: 'Bollywood Hits',
        fetchItems: () => _youtubeService.searchVideos('bollywood songs', limit: 10),
      ),
      CategorySection(
        title: 'English Pop',
        fetchItems: () => _youtubeService.searchVideos('english pop songs', limit: 10),
      ),
      CategorySection(
        title: 'Punjabi Songs',
        fetchItems: () => _youtubeService.searchVideos('punjabi songs', limit: 10),
      ),
      CategorySection(
        title: 'Hip Hop',
        fetchItems: () => _youtubeService.searchVideos('hip hop music', limit: 10),
      ),
    ]);

    for (final category in categories) {
      _categoryLoading[category.title] = true;
      _categoryItems[category.title] = [];
    }
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await loadRecentlyPlayed();
      _loadCategories();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecentlyPlayed() async {
    try {
      final items = await RecentlyPlayedService.getRecentlyPlayed();
      _recentlyPlayed = items;
      notifyListeners();
    } catch (e) {
      print('Error loading recently played: $e');
    }
  }

  Future<void> _loadCategories() async {
    // Load all categories in parallel for faster loading
    final List<Future<void>> futures = categories.map((category) async {
      try {
        _categoryLoading[category.title] = true;
        notifyListeners();
        
        final items = await category.fetchItems();
        
        _categoryItems[category.title] = items;
        _categoryLoading[category.title] = false;
        notifyListeners();
      } catch (e) {
        print('Error loading category ${category.title}: $e');
        _categoryLoading[category.title] = false;
        notifyListeners();
      }
    }).toList();
    
    await Future.wait(futures);
  }

  Future<void> addToRecentlyPlayed(MediaItem item) async {
    try {
      await RecentlyPlayedService.addSong(item);
      await loadRecentlyPlayed();
    } catch (e) {
      print('Error adding to recently played: $e');
    }
  }

  @override
  void dispose() {
    _youtubeService.dispose();
    super.dispose();
  }
}
