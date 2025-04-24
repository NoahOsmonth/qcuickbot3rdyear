import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/settings_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart'; // Import Login Screen
import 'screens/signup_screen.dart'; // Import SignUp Screen
import 'utils/supabase_client.dart'; // Import Supabase client
import 'services/auth_service.dart'; // Import AuthService and providers

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget { // Change to ConsumerWidget
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Add WidgetRef
    // Listen to auth state changes
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'QCUIckBot',
      theme: AppTheme.darkTheme,
      // Conditionally show Login or Chat screen based on auth state
      home: authState.when(
        data: (user) => user != null ? const ChatScreen() : const LoginScreen(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())), // Show loading indicator
        error: (error, stackTrace) => Scaffold(body: Center(child: Text('Error: $error'))), // Show error
      ),
      routes: {
        '/settings': (context) => SettingsScreen(),
        '/login': (context) => const LoginScreen(), // Add login route
        '/signup': (context) => const SignUpScreen(), // Add signup route
        '/chat': (context) => const ChatScreen(), // Optional: explicit chat route
        // Add other routes as needed
      },
    );
  }
}
