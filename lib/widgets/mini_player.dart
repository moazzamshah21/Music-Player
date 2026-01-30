import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/theme/app_colors.dart';

class MiniPlayer extends StatelessWidget {
  final MediaItem? currentItem;
  final bool isPlaying;
  final bool isLiked;
  final bool isLoading;
  final String? loadingMessage;
  final VoidCallback? onPlayPause;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  const MiniPlayer({
    super.key,
    this.currentItem,
    this.isPlaying = false,
    this.isLiked = false,
    this.isLoading = false,
    this.loadingMessage,
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
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: 76,
            margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            decoration: BoxDecoration(
              color: AppColors.glassWhite,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonCyan.withOpacity(0.06),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                // Album art — glossy edge
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),
                      bottomLeft: Radius.circular(0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan.withOpacity(0.12),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),
                      bottomLeft: Radius.circular(0),
                    ),
                    child: currentItem!.imageUrl != null && currentItem!.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: currentItem!.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.neonCyan,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Icon(
                                Icons.music_note_rounded,
                                color: AppColors.neonCyan,
                                size: 28,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(
                              Icons.music_note_rounded,
                              color: AppColors.neonCyan,
                              size: 28,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Song info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentItem!.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentItem!.artist ?? 'Unknown',
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
                // Like
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isLiked ? AppColors.neonCyan : AppColors.textSecondary,
                    size: 24,
                  ),
                  onPressed: onFavorite,
                ),
                // Play/Pause with glow
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isLoading ? null : onPlayPause,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.neonCyan.withOpacity(0.15),
                          border: Border.all(
                            color: AppColors.neonCyan.withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonCyan.withOpacity(0.25),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.neonCyan,
                                  ),
                                ),
                              )
                            : Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: AppColors.neonCyan,
                                size: 28,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
