import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart'; // Import the theme provider

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider); // Watch the current theme mode

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          // Style adjustments might be needed based on theme
          // style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        // Ensure AppBar background adapts to theme
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: Theme.of(context).appBarTheme.iconTheme, // Ensure back button color adapts
      ),
      body: Container(
        // Use scaffold background color which adapts to the theme
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView( // Use ListView for potentially more settings
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              secondary: Icon(
                themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
              ),
              value: themeMode == ThemeMode.dark,
              onChanged: (isDark) {
                ref.read(themeProvider.notifier).setTheme(
                      isDark ? ThemeMode.dark : ThemeMode.light,
                    );
              },
              // Adapt colors based on theme if needed, though defaults often work
              // activeColor: Theme.of(context).colorScheme.primary,
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
                // Navigate back to login or handle post-logout state
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              iconColor: Theme.of(context).iconTheme.color,
              textColor: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            // Add other settings tiles here
          ],
        ),
      ),
    );
  }
}
