import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../listings/providers/listings_providers.dart';
import '../models/review.dart';

final reviewsProvider = StreamProvider.family<List<Review>, String>((ref, listingId) {
  return ref.watch(firestoreServiceProvider).getReviewsStream(listingId);
});

final listingRatingProvider = Provider.family<AsyncValue<({double avgRating, int count})>, String>((ref, listingId) {
  final reviewsAsync = ref.watch(reviewsProvider(listingId));
  return reviewsAsync.when(
    data: (reviews) {
      if (reviews.isEmpty) return AsyncData((avgRating: 0.0, count: 0));
      final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
      return AsyncData((avgRating: avg, count: reviews.length));
    },
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});
