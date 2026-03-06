# KCS – Kigali City Services & Places Directory

Flutter app for browsing services and places in Kigali: listings, map view, search, and reviews.

## Firebase setup

1. Install [Firebase CLI](https://firebase.google.com/docs/cli).
2. Enable Firebase Auth (Email/Password, optionally Google Sign-In) and Cloud Firestore in the [Firebase Console](https://console.firebase.google.com).
3. From the `kcs` directory, run:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   This generates `lib/firebase_options.dart` and downloads `google-services.json` (Android) and `GoogleService-Info.plist` (iOS). Do not commit these files if they contain your project's API keys.

## Firestore collections

- **`listings`** – Services and places: name, category, address, contact, description, location (lat/lng), `createdBy`, `createdAt`, `updatedAt`, `imageUrl`. Used for both services and places.
- **`users`** – User profiles. Write access restricted to the owning user.
- **`listings/{listingId}/reviews`** – Reviews subcollection per listing. Anyone can read; create/update/delete restricted to the review author.

## State management

Uses [Riverpod](https://riverpod.dev/):

- **Auth:** `authStateProvider`, `authStateNotifierProvider` for auth state and redirects.
- **Listings:** `listingsProvider`, `filteredListingsProvider`, `myListingsProvider`, `listingDetailProvider`.
- **Search/filter:** `searchQueryProvider`, `selectedCategoryProvider`.
- **Reviews:** `reviewsProvider` for listing reviews.
- **Settings:** `settings_providers.dart` for app preferences.

## Navigation

Uses [GoRouter](https://pub.dev/packages/go_router):

- Auth redirect: unauthenticated users go to `/login`; unverified email goes to `/verify-email`.
- Shell route with bottom nav: Directory, My Listings, Map View, Settings.
- Main routes: `/login`, `/sign-up`, `/verify-email`, `/listing/:id`, `/listing/:id/reviews`, `/add-listing`, `/edit-listing`.
