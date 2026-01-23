import 'package:flutter/foundation.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/services/recent_searches_service.dart';
import 'package:umarplayer/services/youtube_service.dart';

class SearchProvider extends ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();
  
  List<MediaItem> _recentSearches = [];
  List<MediaItem> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String _currentQuery = '';

  List<MediaItem> get recentSearches => List.unmodifiable(_recentSearches);
  List<MediaItem> get searchResults => List.unmodifiable(_searchResults);
  bool get isSearching => _isSearching;
  bool get isLoading => _isLoading;
  String get currentQuery => _currentQuery;

  SearchProvider() {
    loadRecentSearches();
  }

  Future<void> loadRecentSearches() async {
    final searches = await RecentSearchesService.getRecentSearches();
    _recentSearches = searches;
    notifyListeners();
  }

  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) {
      _isSearching = false;
      _searchResults.clear();
      _currentQuery = '';
      notifyListeners();
      return;
    }

    _isSearching = true;
    _isLoading = true;
    _currentQuery = query;
    notifyListeners();

    try {
      final results = await _youtubeService.searchVideos(query, limit: 20);
      
      if (results.isNotEmpty) {
        final firstResult = results.first;
        final artistName = firstResult.artist ?? query;
        final artistItem = MediaItem(
          id: 'artist_${artistName.hashCode}',
          title: artistName,
          artist: firstResult.artist,
          imageUrl: firstResult.imageUrl,
          type: 'artist',
        );
        await RecentSearchesService.addSearch(artistItem);
        await loadRecentSearches();
      }

      _searchResults = results;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error performing search: $e');
      _isLoading = false;
      _searchResults.clear();
      notifyListeners();
    }
  }

  Future<void> removeRecentSearch(String id) async {
    await RecentSearchesService.removeSearch(id);
    await loadRecentSearches();
  }

  void clearSearch() {
    _isSearching = false;
    _searchResults.clear();
    _currentQuery = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _youtubeService.dispose();
    super.dispose();
  }
}
