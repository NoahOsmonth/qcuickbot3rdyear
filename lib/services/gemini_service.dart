import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:developer';
import '../models/chat_message.dart';

class GeminiService {
  // API key for Gemini
  static const String apiKey = 'AIzaSyBEmBvYmE6Y14dZ6RZgAjByh7dPxdYOCQI';

  // Define the Gemini model and chat session
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-preview-04-17',
      apiKey: apiKey,
    );
    _chatSession = _model.startChat();
    log('Gemini Service Instantiated with 2.5 Flash model');
  }

  // Sends a message to the Gemini model using full conversation history
  Future<String> sendMessage(List<ChatMessage> history, String message) async {
    try {
      // Convert history to the new format and add to chat session
      for (final msg in history) {
        await _chatSession.sendMessage(Content.text(msg.text));
      }
      
      // Send the new message
      final response = await _chatSession.sendMessage(Content.text(message));
      
      // Handle potential null response or empty output
      return response?.text ?? 'Sorry, I could not process that.';
    } catch (e, stackTrace) {
      log('Gemini chat error: $e');
      log('StackTrace: $stackTrace');
      // Provide a user-friendly error message
      return 'An error occurred while contacting the AI. Please try again later.';
    }
  }
}
