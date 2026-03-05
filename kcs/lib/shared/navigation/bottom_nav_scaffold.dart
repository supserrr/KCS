import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentNavIndexProvider = StateProvider<int>((ref) => 0);

class BottomNavScaffold extends ConsumerWidget {
  final List<Widget> screens;
  final List<NavigationDestination> destinations;

  const BottomNavScaffold({
    super.key,
    required this.screens,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(currentNavIndexProvider);
    return Scaffold(
      body: SafeArea(
        // keeps all tab screens mounted so scroll position / form state isn't lost when switching
        child: IndexedStack(
          index: index,
          children: screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(currentNavIndexProvider.notifier).state = i,
        destinations: destinations,
      ),
    );
  }
}
