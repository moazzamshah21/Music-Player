import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/services/youtube_service.dart';

class DownloadsService {
  static const String _key = 'downloaded_songs';
  static const String _downloadsFolderName = 'umarplayer_downloads';

  // Get downloads directory
  static Future<Directory> _getDownloadsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${appDir.path}/$_downloadsFolderName');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir;
  }

  // Get file path for a downloaded song
  static Future<String> _getFilePath(String songId) async {
    final downloadsDir = await _getDownloadsDirectory();
    return '${downloadsDir.path}/$songId.mp3';
  }

  // Download a song
  static Future<bool> downloadSong(MediaItem song) async {
    return await downloadSongWithProgress(song);
  }

  // Download a song with progress callback
  static Future<bool> downloadSongWithProgress(
    MediaItem song, {
    Function(double)? onProgress,
  }) async {
    try {
      // Check if already downloaded
      if (await isDownloaded(song.id)) {
        onProgress?.call(1.0);
        return true;
      }

      // Get audio stream URL
      final youtubeService = YouTubeService();
      onProgress?.call(0.1);
      final audioStreamInfo = await youtubeService.getAudioStreamInfo(song.id);
      
      if (audioStreamInfo == null) {
        throw Exception('Could not get audio stream');
      }

      onProgress?.call(0.2);

      // Download the audio file with progress tracking
      final request = http.Request('GET', Uri.parse(audioStreamInfo.url.toString()));
      request.headers.addAll({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': '*/*',
        'Referer': 'https://www.youtube.com/',
      });

      final streamedResponse = await http.Client().send(request).timeout(
        const Duration(minutes: 5),
      );

      if (streamedResponse.statusCode != 200) {
        throw Exception('Failed to download: ${streamedResponse.statusCode}');
      }

      final contentLength = streamedResponse.contentLength ?? 0;
      final filePath = await _getFilePath(song.id);
      final file = File(filePath);
      final sink = file.openWrite();

      int bytesDownloaded = 0;

      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        bytesDownloaded += chunk.length;
        
        if (contentLength > 0) {
          final progress = 0.2 + (bytesDownloaded / contentLength) * 0.7;
          onProgress?.call(progress.clamp(0.0, 0.9));
        } else {
          // If content length is unknown, estimate progress
          onProgress?.call(0.5);
        }
      }

      await sink.close();
      onProgress?.call(0.95);

      // Save metadata
      await _addDownloadedSong(song);
      onProgress?.call(1.0);

      return true;
    } catch (e) {
      print('Error downloading song: $e');
      onProgress?.call(0.0);
      rethrow;
    }
  }

  // Check if a song is downloaded
  static Future<bool> isDownloaded(String songId) async {
    try {
      final filePath = await _getFilePath(songId);
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get local file path if downloaded
  static Future<String?> getLocalFilePath(String songId) async {
    try {
      final filePath = await _getFilePath(songId);
      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get all downloaded songs
  static Future<List<MediaItem>> getDownloadedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<MediaItem> songs = jsonList.map((json) => _mediaItemFromJson(json)).toList();
      
      // Filter out songs that don't have files anymore
      final List<MediaItem> validSongs = [];
      for (final song in songs) {
        if (await isDownloaded(song.id)) {
          validSongs.add(song);
        }
      }
      
      // Update the list if some files were deleted
      if (validSongs.length != songs.length) {
        await _saveDownloadedSongs(validSongs);
      }
      
      return validSongs;
    } catch (e) {
      print('Error loading downloaded songs: $e');
      return [];
    }
  }

  // Remove a downloaded song
  static Future<void> removeDownloadedSong(String songId) async {
    try {
      // Delete file
      final filePath = await _getFilePath(songId);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from metadata
      final songs = await getDownloadedSongs();
      songs.removeWhere((song) => song.id == songId);
      await _saveDownloadedSongs(songs);
    } catch (e) {
      print('Error removing downloaded song: $e');
    }
  }

  // Clear all downloads
  static Future<void> clearAllDownloads() async {
    try {
      final songs = await getDownloadedSongs();
      for (final song in songs) {
        final filePath = await _getFilePath(song.id);
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      print('Error clearing downloads: $e');
    }
  }

  // Add downloaded song to metadata
  static Future<void> _addDownloadedSong(MediaItem song) async {
    final songs = await getDownloadedSongs();
    
    // Check if already exists
    if (songs.any((s) => s.id == song.id)) {
      return;
    }
    
    songs.insert(0, song);
    await _saveDownloadedSongs(songs);
  }

  // Save downloaded songs metadata
  static Future<void> _saveDownloadedSongs(List<MediaItem> songs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = songs.map((item) => _mediaItemToJson(item)).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving downloaded songs: $e');
    }
  }

  // Convert MediaItem to JSON
  static Map<String, dynamic> _mediaItemToJson(MediaItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'subtitle': item.subtitle,
      'artist': item.artist,
      'album': item.album,
      'imageUrl': item.imageUrl,
      'type': item.type,
      'duration': item.duration?.inSeconds,
      'description': item.description,
      'viewCount': item.viewCount,
      'uploadDate': item.uploadDate?.toIso8601String(),
    };
  }

  // Convert JSON to MediaItem
  static MediaItem _mediaItemFromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      imageUrl: json['imageUrl'] as String?,
      type: json['type'] as String,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      description: json['description'] as String?,
      viewCount: json['viewCount'] as int?,
      uploadDate: json['uploadDate'] != null
          ? DateTime.parse(json['uploadDate'] as String)
          : null,
    );
  }
}
