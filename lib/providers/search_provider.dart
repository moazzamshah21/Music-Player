import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/services/recent_searches_service.dart';
import 'package:umarplayer/services/youtube_service.dart';

class SearchProvider extends ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();
  final _random = Random();

  List<MediaItem> _recentSearches = [];
  List<MediaItem> _topArtists = [];
  bool _topArtistsLoading = false;
  List<MediaItem> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String _currentQuery = '';

  List<MediaItem> get recentSearches => List.unmodifiable(_recentSearches);
  List<MediaItem> get topArtists => List.unmodifiable(_topArtists);
  bool get topArtistsLoading => _topArtistsLoading;
  List<MediaItem> get searchResults => List.unmodifiable(_searchResults);
  bool get isSearching => _isSearching;
  bool get isLoading => _isLoading;
  String get currentQuery => _currentQuery;

  /// Artists to show in home carousel: recent searches, or top artists fallback.
  List<MediaItem> get carouselArtists =>
      _recentSearches.isNotEmpty ? _recentSearches : _topArtists;
  bool get carouselArtistsLoading =>
      _recentSearches.isEmpty && _topArtistsLoading;

  SearchProvider() {
    loadRecentSearches();
    loadTopArtists();
  }

  static const _popularArtists = [
    'The Weeknd',
    'Justin Bieber',
    'Taylor Swift',
    'Ed Sheeran',
    'Ariana Grande',
    'Drake',
    'Billie Eilish',
    'Bad Bunny',
    'Dua Lipa',
    'Post Malone',
    'Bruno Mars',
    'The Chainsmokers',
  ];

  Future<void> loadTopArtists() async {
    if (_topArtists.isNotEmpty) return;
    _topArtistsLoading = true;
    notifyListeners();
    try {
      final shuffled = List<String>.from(_popularArtists)..shuffle(_random);
      final results = await Future.wait(
        shuffled.take(8).map((name) => _youtubeService.searchVideos(name, limit: 1)),
      );
      final artists = <MediaItem>[];
      for (var i = 0; i < results.length; i++) {
        if (results[i].isEmpty) continue;
        final v = results[i].first;
        final name = shuffled[i];
        final artistName = v.artist ?? name;
        artists.add(MediaItem(
          id: 'artist_${artistName.hashCode}',
          title: artistName,
          artist: v.artist,
          imageUrl: v.imageUrl ?? '',
          type: 'artist',
        ));
      }
      _topArtists = artists;
    } catch (e) {
      print('Error loading top artists: $e');
    } finally {
      _topArtistsLoading = false;
      notifyListeners();
    }
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
