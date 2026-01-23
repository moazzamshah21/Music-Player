import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/theme/app_colors.dart';

class MediaCard extends StatelessWidget {
  final MediaItem item;
  final double width;
  final VoidCallback? onTap;

  const MediaCard({
    super.key,
    required this.item,
    this.width = 150,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: width,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album Art with caching
          Container(
            width: width,
            height: width,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.music_note,
                        color: AppColors.textTertiary,
                        size: 48,
                      ),
                      memCacheWidth: (width * MediaQuery.of(context).devicePixelRatio).round(),
                      memCacheHeight: (width * MediaQuery.of(context).devicePixelRatio).round(),
                    ),
                  )
                : Icon(
                    Icons.music_note,
                    color: AppColors.textTertiary,
                    size: 48,
                  ),
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            item.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Artist/Album info
          if (item.artist != null || item.album != null) ...[
            const SizedBox(height: 4),
            Text(
              item.artist != null && item.album != null
                  ? '${item.artist} - ${item.album}'
                  : item.artist ?? item.album ?? '',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    ));
  }
}
