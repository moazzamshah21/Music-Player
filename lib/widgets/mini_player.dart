import 'package:flutter/material.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/theme/app_colors.dart';

class MiniPlayer extends StatelessWidget {
  final MediaItem? currentItem;
  final bool isPlaying;
  final bool isLiked;
  final VoidCallback? onPlayPause;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  const MiniPlayer({
    super.key,
    this.currentItem,
    this.isPlaying = false,
    this.isLiked = false,
    this.onPlayPause,
    this.onTap,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    if (currentItem == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
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
              child: currentItem!.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        currentItem!.imageUrl!,
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
                    currentItem!.title,
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
                    currentItem!.artist ?? 'Devices Available',
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
                isLiked ? Icons.favorite : Icons.favorite_outline,
                color: isLiked ? Colors.red : AppColors.textPrimary,
                size: 24,
              ),
              onPressed: onFavorite,
            ),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppColors.textPrimary,
                size: 28,
              ),
              onPressed: onPlayPause,
            ),
          ],
        ),
      ),
    );
  }
}
