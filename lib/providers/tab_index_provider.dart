import 'package:flutter/foundation.dart';

/// Controls main tab index and supports switching to Search with a query.
class TabIndexProvider extends ChangeNotifier {
  int _index = 0;
  String? _pendingSearchQuery;

  int get index => _index;
  String? get pendingSearchQuery => _pendingSearchQuery;

  void setIndex(int index) {
    if (_index != index) {
      _index = index;
      notifyListeners();
    }
  }

  /// Switch to Search tab and run a search for [query].
  void goToSearchWithQuery(String query) {
    _pendingSearchQuery = query;
    _index = 1;
    notifyListeners();
  }

  /// Consume pending search query (returns it and clears).
  String? takePendingSearchQuery() {
    final q = _pendingSearchQuery;
    _pendingSearchQuery = null;
    if (q != null) notifyListeners();
    return q;
  }
}
