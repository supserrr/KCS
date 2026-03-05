import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/sign_up_screen.dart';
import 'features/auth/presentation/verify_email_screen.dart';
import 'features/listings/presentation/add_edit_listing_screen.dart';
import 'features/listings/presentation/directory_screen.dart';
import 'features/listings/presentation/listing_detail_screen.dart';
import 'features/listings/presentation/my_listings_screen.dart';
import 'features/listings/models/listing.dart';
import 'features/map/presentation/map_view_screen.dart';
import 'features/reviews/presentation/reviews_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'shared/navigation/bottom_nav_scaffold.dart';

final _authStateChanges = FirebaseAuth.instance.authStateChanges();

class AuthStateNotifier extends ChangeNotifier {
  StreamSubscription<User?>? _sub;

  AuthStateNotifier() {
    _sub = _authStateChanges.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final authStateNotifierProvider = Provider<AuthStateNotifier>((ref) {
  final notifier = AuthStateNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authStateNotifierProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      // if they're on login/signup, don't redirect - avoids loop
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/sign-up' ||
          state.matchedLocation == '/verify-email';

      if (user == null) {
        return isLoggingIn ? null : '/login';
      }
      if (!user.emailVerified && state.matchedLocation != '/verify-email') {
        return '/verify-email';
      }
      if (user.emailVerified && isLoggingIn) return '/';
      // null = stay on current route
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return BottomNavScaffold(
            screens: const [
              DirectoryScreen(),
              MyListingsScreen(),
              MapViewScreen(),
              SettingsScreen(),
            ],
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Directory',
              ),
              NavigationDestination(
                icon: Icon(Icons.list_outlined),
                selectedIcon: Icon(Icons.list),
                label: 'My Listings',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Map View',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          );
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SizedBox.shrink(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) {
          final listing = state.extra as Listing?;
          if (listing == null) {
            return const Scaffold(
              body: Center(child: Text('Listing not found')),
            );
          }
          return ListingDetailScreen(listing: listing);
        },
      ),
      GoRoute(
        path: '/listing/:id/reviews',
        builder: (context, state) {
          final listing = state.extra as Listing;
          return ReviewsScreen(listing: listing);
        },
      ),
      GoRoute(
        path: '/add-listing',
        builder: (context, state) => const AddEditListingScreen(),
      ),
      GoRoute(
        path: '/edit-listing',
        builder: (context, state) {
          final listing = state.extra as Listing;
          return AddEditListingScreen(listing: listing);
        },
      ),
    ],
  );
});
