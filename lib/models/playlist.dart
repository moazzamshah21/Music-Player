import 'package:umarplayer/models/media_item.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<MediaItem> songs;
  final DateTime createdAt;
  final String? createdBy; // User ID or name

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.songs,
    required this.createdAt,
    this.createdBy,
  });

  int get songCount => songs.length;

  // Get the first song's image as playlist image if no image is set
  String? get displayImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl;
    }
    if (songs.isNotEmpty && songs.first.imageUrl != null) {
      return songs.first.imageUrl;
    }
    return null;
  }
}
