import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/location_utils.dart';
import '../models/listing.dart';
import '../../../shared/widgets/category_chips.dart';
import '../../../shared/widgets/listing_card.dart';
import '../../../shared/widgets/search_bar.dart';
import '../../reviews/providers/reviews_providers.dart';
import '../providers/listings_providers.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsProvider);
    final filteredListings = ref.watch(filteredListingsProvider);
    final category = ref.watch(selectedCategoryProvider);

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kigali City'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryChips(
            selectedCategory: category.isEmpty ? null : category,
            onSelected: (c) =>
                ref.read(selectedCategoryProvider.notifier).state = c ?? '',
          ),
          SearchBarWidget(
            controller: _searchController,
            onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Near You',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Places and services in your area',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: listingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: theme.colorScheme.error.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load listings',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$e',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              data: (_) => filteredListings.isEmpty
                  ? _EmptyListingsState()
                  : _ListingList(listings: filteredListings),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingList extends ConsumerWidget {
  final List<Listing> listings;

  const _ListingList({required this.listings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(userLocationProvider).valueOrNull;
    final sorted = [...listings];
    if (position != null) {
      sorted.sort((a, b) {
        final distA = haversineDistance(
          position.latitude, position.longitude,
          a.latitude, a.longitude,
        );
        final distB = haversineDistance(
          position.latitude, position.longitude,
          b.latitude, b.longitude,
        );
        return distA.compareTo(distB);
      });
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final listing = sorted[index];
        final distanceKm = position != null && listing.latitude != 0 && listing.longitude != 0
            ? haversineDistance(
                position.latitude, position.longitude,
                listing.latitude, listing.longitude,
              )
            : null;
        final distanceText = distanceKm != null ? formatDistance(distanceKm) : null;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: _DirectoryListingCard(
            listing: listing,
            distanceText: distanceText,
            onTap: () => context.push('/listing/${listing.id}', extra: listing),
          ),
        );
      },
    );
  }
}

class _DirectoryListingCard extends ConsumerWidget {
  final Listing listing;
  final String? distanceText;
  final VoidCallback onTap;

  const _DirectoryListingCard({
    required this.listing,
    this.distanceText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(listingRatingProvider(listing.id));
    final avgRating = ratingAsync.valueOrNull?.avgRating ?? 0.0;
    final reviewCount = ratingAsync.valueOrNull?.count ?? 0;
    return ListingCard(
      listing: listing,
      rating: avgRating,
      reviewCount: reviewCount,
      distanceText: distanceText,
      onTap: onTap,
    );
  }
}

class _EmptyListingsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No listings found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search or category',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
