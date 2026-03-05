import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../listings/providers/listings_providers.dart';

class MapViewScreen extends ConsumerWidget {
  const MapViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(listingsProvider);
    final listings = ref.watch(filteredListingsProvider);

    return listingsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Map View')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Map View')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load listings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '$e',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      data: (_) {
        if (listings.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Map View')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No listings to show',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No listings yet - add some or change your search',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        const kigaliCenter = LatLng(-1.9536, 30.0606);
        final markers = listings
        .where((l) => l.latitude != 0 && l.longitude != 0)
        .map((l) => Marker(
              point: LatLng(l.latitude, l.longitude),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => context.push('/listing/${l.id}', extra: l),
                child: Icon(
                  Icons.location_pin,
                  color: AppColors.accent,
                  size: 40,
                ),
              ),
            ))
        .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Map View')),
          body: FlutterMap(
            options: const MapOptions(
              initialCenter: kigaliCenter,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kigali.cityservices.kcs',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
        );
      },
    );
  }
}
