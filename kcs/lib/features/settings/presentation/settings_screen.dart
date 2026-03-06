import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;
    final notificationsEnabled = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        children: [
          if (user != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Account',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: user.email ?? '',
                    ),
                    Divider(height: 1, color: AppColors.divider),
                    _SettingsTile(
                      icon: Icons.person_outline,
                      title: 'Display Name',
                      subtitle: user.displayName ?? 'Not set',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Preferences',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: notificationsEnabled == null
                ? const ListTile(
                    title: Text('Location-based notifications'),
                    subtitle: Text('Loading...'),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    trailing: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : SwitchListTile(
                    title: const Text('Location-based notifications'),
                    subtitle: const Text('Get notified about nearby places'),
                    value: notificationsEnabled,
                    onChanged: (v) =>
                        ref.read(notificationPreferencesProvider.notifier).setEnabled(v),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
              ),
              child: const Text('Log Out'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
