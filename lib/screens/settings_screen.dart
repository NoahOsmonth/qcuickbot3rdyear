import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import '../services/auth_service.dart'; // Import AuthService
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget { // Change to ConsumerWidget
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Add WidgetRef
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(color: const Color.fromARGB(255, 64, 140, 255)),
        ),
      ),
      body: Container(
        color: AppColors.mainBackground,
        child: Center(
          child: Column( // Use Column for multiple widgets
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Settings Page',
                style: TextStyle(fontSize: 18, color: const Color.fromARGB(255, 64, 140, 255)),
              ),
              const SizedBox(height: 30), // Add some spacing
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ref.read(authServiceProvider).signOut();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false); // Clear stack and navigate to login
                  } catch (e) {
                    // Optionally show an error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: ${e.toString()}')),
                    );
                  }
                },
                child: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
