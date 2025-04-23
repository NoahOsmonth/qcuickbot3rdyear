import 'package:flutter_gemini/flutter_gemini.dart';
import 'dart:developer';
import '../models/chat_message.dart';

class GeminiService {
  final Gemini _gemini =
      Gemini.instance; // Access the globally initialized instance

  // Constructor no longer needs apiKey
  GeminiService() {
    // Gemini.init removed - handled in main.dart
    log('Gemini Service Instantiated'); // Updated log message
  }

  // Sends a message to the Gemini model using full conversation history
  Future<String> sendMessage(List<ChatMessage> history, String message) async {
    try {
      // Build messages list from history
      final messages = history.map((m) => Content(
            parts: [Part.text(m.text)],
            role: m.isUser ? 'user' : 'assistant',
          )).toList();
      // Append new user message
      messages.add(Content(parts: [Part.text(message)], role: 'user'));
      final response = await _gemini.chat(messages, modelName: 'gemini-2.5-flash-preview-04-17');

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
