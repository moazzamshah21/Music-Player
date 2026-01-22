import 'package:flutter/material.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/theme/app_colors.dart';
import 'package:umarplayer/services/liked_songs_service.dart';

class MiniPlayer extends StatefulWidget {
  final MediaItem? currentItem;
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final VoidCallback? onTap;

  const MiniPlayer({
    super.key,
    this.currentItem,
    this.isPlaying = false,
    this.onPlayPause,
    this.onTap,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  bool _isLiked = false;
  bool _isCheckingLike = true;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  @override
  void didUpdateWidget(MiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentItem?.id != widget.currentItem?.id) {
      _checkLikeStatus();
    }
  }

  Future<void> _checkLikeStatus() async {
    if (widget.currentItem == null) {
      setState(() {
        _isLiked = false;
        _isCheckingLike = false;
      });
      return;
    }

    final isLiked = await LikedSongsService.isLiked(widget.currentItem!.id);
    setState(() {
      _isLiked = isLiked;
      _isCheckingLike = false;
    });
  }

  Future<void> _toggleLike() async {
    if (widget.currentItem == null) return;

    final newLikeStatus = await LikedSongsService.toggleLike(widget.currentItem!);
    setState(() {
      _isLiked = newLikeStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentItem == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Album Art
            Container(
              width: 80,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(0),
              ),
              child: widget.currentItem!.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        widget.currentItem!.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.music_note,
                      color: AppColors.textTertiary,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 12),
            // Song Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.currentItem!.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.currentItem!.artist ?? 'Devices Available',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Icons
            IconButton(
              icon: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_outline,
                color: _isLiked ? Colors.red : AppColors.textPrimary,
                size: 24,
              ),
              onPressed: _isCheckingLike ? null : _toggleLike,
            ),
            IconButton(
              icon: Icon(
                widget.isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppColors.textPrimary,
                size: 28,
              ),
              onPressed: widget.onPlayPause,
            ),
          ],
        ),
      ),
    );
  }
}
