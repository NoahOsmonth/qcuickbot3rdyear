import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/settings_screen.dart';
import 'screens/chat_screen.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

// Define API Key here for initialization
const String geminiApiKey = 'AIzaSyBEmBvYmE6Y14dZ6RZgAjByh7dPxdYOCQI'; // Replace with your actual key

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Gemini SDK
  if (geminiApiKey.startsWith('REPLACE_WITH_YOUR') || geminiApiKey.isEmpty) {
    // Throw a more informative error if the key hasn't been replaced.
    throw Exception('Gemini API Key is not set in main.dart. Please replace the placeholder.');
  }
  Gemini.init(apiKey: geminiApiKey, enableDebugging: true);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QCUIckBot',
      theme: AppTheme.darkTheme,
      home: ChatScreen(),
      routes: {'/settings': (context) => SettingsScreen()},
    );
  }
}
