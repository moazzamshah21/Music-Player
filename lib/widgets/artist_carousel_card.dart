import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:umarplayer/models/media_item.dart';
import 'package:umarplayer/theme/app_colors.dart';

/// Artist card for horizontal carousels: circular image with text below.
class ArtistCarouselCard extends StatelessWidget {
  final MediaItem item;
  final double size;
  final VoidCallback? onTap;

  const ArtistCarouselCard({
    super.key,
    required this.item,
    this.size = 52,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size + 12,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceVariant,
                border: Border.all(color: AppColors.neonCyan.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withOpacity(0.08),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ],
                image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(item.imageUrl!),
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      )
                    : null,
              ),
              child: item.imageUrl == null || item.imageUrl!.isEmpty
                  ? _buildPlaceholder(size)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        Icons.person_rounded,
        color: AppColors.textSecondary,
        size: size * 0.5,
      ),
    );
  }
}
