import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../features/listings/models/listing.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final String? distanceText;
  final double? rating;
  final int? reviewCount;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ListingCard({
    super.key,
    required this.listing,
    this.distanceText,
    this.rating,
    this.reviewCount,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayRating = rating ?? 0.0;
    final count = reviewCount ?? 0;
    final hasImage = listing.imageUrl != null && listing.imageUrl!.isNotEmpty;

    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.lightImpact();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: hasImage
                        ? Image.network(
                            listing.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
                          )
                        : _buildPlaceholder(theme),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        listing.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _InfoChip(
                            icon: Icons.category_outlined,
                            label: listing.category,
                            color: AppColors.primary,
                          ),
                          if (displayRating > 0)
                            _InfoChip(
                              icon: Icons.star_rounded,
                              label: displayRating.toStringAsFixed(1),
                              color: AppColors.accent,
                              count: count > 0 ? count : null,
                            ),
                          if (distanceText != null)
                            _InfoChip(
                              icon: Icons.near_me_outlined,
                              label: distanceText!,
                              color: AppColors.textSecondary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ] else if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: AppColors.scaffoldBackground,
      child: Icon(
        Icons.place_rounded,
        size: 32,
        color: AppColors.textSecondary.withValues(alpha: 0.4),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int? count;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 2),
            Text(
              '($count)',
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
