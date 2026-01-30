import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final imageSize = width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.04),
                border: Border.all(
                  color: AppColors.brandy.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandy.withOpacity(0.08),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image area with inner glass frame and play hint
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        child: SizedBox(
                          width: width,
                          height: imageSize,
                          child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: item.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => _buildPlaceholder(imageSize),
                                  errorWidget: (context, url, error) => _buildErrorPlaceholder(imageSize),
                                  memCacheWidth: (width * MediaQuery.of(context).devicePixelRatio).round(),
                                  memCacheHeight: (imageSize * MediaQuery.of(context).devicePixelRatio).round(),
                                )
                              : _buildErrorPlaceholder(imageSize),
                        ),
                      ),
                      // Subtle gradient overlay at bottom for depth
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.35),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Glassy play icon pill
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.brandy.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.brandy.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: AppColors.brandyLight,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Top-edge glass highlight
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Text block in glass strip
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(10),
                    ),
                    child: Container(
                      width: width,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(10),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: AppColors.brandy.withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.artist != null || item.album != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.artist != null && item.album != null
                                  ? '${item.artist} · ${item.album}'
                                  : item.artist ?? item.album ?? '',
                              style: GoogleFonts.outfit(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.surfaceVariant.withOpacity(0.5),
      child: const Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.brandy,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.surfaceVariant.withOpacity(0.5),
      child: const Icon(
        Icons.music_note_rounded,
        color: AppColors.brandy,
        size: 48,
      ),
    );
  }
}
