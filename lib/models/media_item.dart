class MediaItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? artist;
  final String? album;
  final String? imageUrl;
  final String type; // 'song', 'album', 'playlist', 'artist'
  final Duration? duration;
  final String? description;
  final int? viewCount;
  final DateTime? uploadDate;

  MediaItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.artist,
    this.album,
    this.imageUrl,
    required this.type,
    this.duration,
    this.description,
    this.viewCount,
    this.uploadDate,
  });
}

class QuickAccessItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;

  QuickAccessItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
  });
}
