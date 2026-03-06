import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/firestore_service.dart';
import '../models/listing.dart';

final userLocationProvider = FutureProvider<Position?>((ref) async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) return null;
  final perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    final requested = await Geolocator.requestPermission();
    if (requested != LocationPermission.whileInUse &&
        requested != LocationPermission.always) {
      return null;
    }
  }
  return Geolocator.getCurrentPosition(
    locationSettings: LocationSettings(accuracy: LocationAccuracy.medium),
  );
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final listingsProvider = StreamProvider<List<Listing>>((ref) {
  return ref.watch(firestoreServiceProvider).getListingsStream();
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String>((ref) => '');

final filteredListingsProvider = Provider<List<Listing>>((ref) {
  final asyncListings = ref.watch(listingsProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final category = ref.watch(selectedCategoryProvider);

  return asyncListings.when(
    data: (listings) {
      var filtered = listings;
      if (category.isNotEmpty) {
        filtered = filtered.where((l) => l.category == category).toList();
      }
      if (searchQuery.isNotEmpty) {
        filtered = filtered
            .where((l) => l.name.toLowerCase().contains(searchQuery))
            .toList();
      }
      return filtered;
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

final myListingsProvider = StreamProvider<List<Listing>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getMyListings(user.uid);
});

final listingDetailProvider =
    FutureProvider.family<Listing?, String>((ref, id) async {
  return ref.watch(firestoreServiceProvider).getListingById(id);
});
