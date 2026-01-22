import 'package:umarplayer/models/media_item.dart';

class CategorySection {
  final String title;
  final Future<List<MediaItem>> Function() fetchItems;

  CategorySection({
    required this.title,
    required this.fetchItems,
  });
}
