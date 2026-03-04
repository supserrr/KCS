import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/validators.dart';
import '../models/listing.dart';
import '../providers/listings_providers.dart';

// sealed class so we handle success/not-found/network separately, compiler checks we don't miss a case
sealed class GeocodeOutcome {}

class GeocodeSuccess implements GeocodeOutcome {
  final double lat;
  final double lng;
  GeocodeSuccess(this.lat, this.lng);
}

class GeocodeAddressNotFound implements GeocodeOutcome {}

class GeocodeNetworkError implements GeocodeOutcome {}

class AddEditListingScreen extends ConsumerStatefulWidget {
  final Listing? listing;

  const AddEditListingScreen({super.key, this.listing});

  @override
  ConsumerState<AddEditListingScreen> createState() => _AddEditListingScreenState();
}

class _AddEditListingScreenState extends ConsumerState<AddEditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = listingCategories.first;
  bool _isLoading = false;
  double _latitude = 0;
  double _longitude = 0;
  String? _imageUrl;

  Listing? get listing => widget.listing;
  bool get isEditing => listing != null;

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    if (listing != null) {
      _nameController.text = listing.name;
      _addressController.text = listing.address;
      _contactController.text = listing.contactNumber;
      _descriptionController.text = listing.description;
      _latitude = listing.latitude;
      _longitude = listing.longitude;
      _selectedCategory = listing.category;
      _imageUrl = listing.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<GeocodeOutcome> _geocodeAddress(String address) async {
    if (address.trim().isEmpty) return GeocodeAddressNotFound();
    // geocoding works better if we add city/country - most addresses are in Kigali anyway
    final query = address.trim().toLowerCase().contains('kigali') ||
            address.trim().toLowerCase().contains('rwanda')
        ? address.trim()
        : '${address.trim()}, Kigali, Rwanda';
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        return GeocodeSuccess(
          locations.first.latitude,
          locations.first.longitude,
        );
      }
      return GeocodeAddressNotFound();
    } on NoResultFoundException {
      return GeocodeAddressNotFound();
    } on TimeoutException {
      return GeocodeNetworkError();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('socket') ||
          msg.contains('connection') ||
          msg.contains('network') ||
          msg.contains('timed out') ||
          msg.contains('failed host lookup')) {
        return GeocodeNetworkError();
      }
      return GeocodeAddressNotFound();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final address = _addressController.text.trim();
    double lat = _latitude;
    double lng = _longitude;

    if ((lat == 0 && lng == 0) && address.isNotEmpty) {
      setState(() => _isLoading = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geocoding...')),
        );
      }
      final result = await _geocodeAddress(address);
      if (mounted) {
        switch (result) {
          case GeocodeSuccess(lat: final coordLat, lng: final coordLng):
            lat = coordLat;
            lng = coordLng;
            break;
          case GeocodeAddressNotFound():
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Address not found - try adding Kigali, Rwanda or street name',
                ),
              ),
            );
            return;
          case GeocodeNetworkError():
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Check your connection and try again',
                ),
              ),
            );
            return;
        }
      }
    }

    setState(() => _isLoading = true);
    try {
      final firestore = ref.read(firestoreServiceProvider);
      final listingData = Listing(
        id: listing?.id ?? '',
        name: _nameController.text.trim(),
        category: _selectedCategory,
        address: address,
        contactNumber: _contactController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: lat,
        longitude: lng,
        createdBy: user.uid,
        createdAt: listing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrl: _imageUrl,
      );

      if (isEditing) {
        await firestore.updateListing(listing!.id, listingData);
      } else {
        await firestore.createListing(listingData);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Listing updated' : 'Listing created'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Listing' : 'Add Listing'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ImagePlaceholderSection(imageUrl: _imageUrl),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Place or Service Name',
                ),
                validator: (v) => Validators.required(v, 'Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                items: listingCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'e.g. KN 4 Ave, Kicukiro, Kigali',
                ),
                validator: (v) => Validators.required(v, 'Address'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : () async {
                  final address = _addressController.text.trim();
                  if (address.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter an address first')),
                      );
                    }
                    return;
                  }
                  if (!mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() => _isLoading = true);
                  final result = await _geocodeAddress(address);
                  if (!mounted) return;
                  setState(() => _isLoading = false);
                  switch (result) {
                    case GeocodeSuccess(lat: final coordLat, lng: final coordLng):
                      _latitude = coordLat;
                      _longitude = coordLng;
                      setState(() {});
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Coordinates updated')),
                      );
                      break;
                    case GeocodeAddressNotFound():
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Address not found'),
                        ),
                      );
                      break;
                    case GeocodeNetworkError():
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Check your connection and try again'),
                        ),
                      );
                      break;
                  }
                },
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Get coordinates from address'),
              ),
              if (_latitude != 0 || _longitude != 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Coordinates: ${_latitude.toStringAsFixed(5)}, ${_longitude.toStringAsFixed(5)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 3,
                validator: (v) => Validators.required(v, 'Description'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholderSection extends StatelessWidget {
  final String? imageUrl;

  const _ImagePlaceholderSection({this.imageUrl});

  bool get _hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Listing image',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.scaffoldBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: _hasImage
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _placeholder(context),
                )
              : _placeholder(context),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to add photo',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Add image',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
