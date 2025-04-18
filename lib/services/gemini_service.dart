import 'package:flutter_gemini/flutter_gemini.dart';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Provider Definition ---

// Provider for the GeminiService instance
final geminiServiceProvider = Provider<GeminiService>((ref) {
  // API Key definition and check removed - handled in main.dart
  // Gemini.init removed - handled in main.dart

  // Simply return the service instance; initialization is done globally.
  return GeminiService();
});

// --- Gemini Service Class ---

class GeminiService {
  // API key field removed - not needed here anymore
  final Gemini _gemini =
      Gemini.instance; // Access the globally initialized instance

  // Constructor no longer needs apiKey
  GeminiService() {
    // Gemini.init removed - handled in main.dart
    log('Gemini Service Instantiated'); // Updated log message
  }

  // Sends a message to the Gemini model and returns the response
  // Method is now non-static
  Future<String> sendMessage(String message) async {
    try {
      final response = await _gemini.chat([
        Content(parts: [Part.text(message)], role: 'user'),
      ], modelName: 'gemini-2.0-flash'); // Updated model name if needed

      log('Gemini response: ${response?.output}');
      // Handle potential null response or empty output
      return response?.output?.trim() ?? 'Sorry, I could not process that.';
    } catch (e, stackTrace) {
      log('Gemini chat error: $e');
      log('StackTrace: $stackTrace');
      // Provide a user-friendly error message
      return 'An error occurred while contacting the AI. Please try again later.';
    }
  }
}
