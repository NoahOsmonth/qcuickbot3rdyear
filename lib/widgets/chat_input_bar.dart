import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:speech_to_text/speech_to_text.dart'; // Import speech_to_text
import 'package:speech_to_text/speech_recognition_result.dart'; // Import result type
import '../theme/app_theme.dart';
import 'platform_helper.dart';
import 'dart:developer'; // For logging

// Convert to ConsumerStatefulWidget
class ChatInputBar extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isLoading,
  });

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  // String _lastWords = ''; // Not strictly needed if we directly update controller

  @override
  void initState() {
    super.initState();
    _initSpeech();
    // Add listener to rebuild widget when text changes, updating button state
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    // Remove listener
    widget.controller.removeListener(_onTextChanged);
    // Stop speech if listening
    if (_isListening) {
      _speechToText.stop();
    }
    // Note: The controller itself is managed by the parent (ChatScreen)
    // and disposed there, so we don't dispose it here.
    super.dispose();
  }

  void _onTextChanged() {
    // Call setState to rebuild the widget and update the send button state
    if (mounted) {
      setState(() {});
    }
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (errorNotification) => log('[Speech] onError: $errorNotification'),
        onStatus: (status) => _handleSpeechStatus(status),
      );
      if (mounted) {
        setState(() {});
      }
      log('[Speech] Initialization successful: $_speechEnabled');
    } catch (e) {
       log('[Speech] Error initializing speech: $e');
       if (mounted) {
          setState(() {
             _speechEnabled = false;
          });
       }
    }
  }

  void _handleSpeechStatus(String status) {
    log('[Speech] Status: $status');
    if (mounted) {
      setState(() {
        // Update _isListening based on status if needed, e.g., stop on 'notListening'
        if (status == 'notListening' || status == 'done') {
          _isListening = false;
        }
      });
    }
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    if (!_speechEnabled || _isListening || widget.isLoading) return;
    log('[Speech] Starting listening...');
    // Clear previous text before starting new recognition
    // widget.controller.clear(); // Decided against this based on user preference (replace on result)
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30), // Adjust duration as needed
      localeId: "en_US", // Optional: Specify locale
      cancelOnError: true,
      partialResults: false, // Set to true if you want intermediate results
      listenMode: ListenMode.confirmation, // Or .dictation
    );
    if (mounted) {
      setState(() {
        _isListening = true;
      });
    }
  }

  /// Manually stop the active speech recognition session
  /// Note: This will also trigger onStatus: 'notListening'
  void _stopListening() async {
    if (!_isListening) return;
    log('[Speech] Stopping listening...');
    await _speechToText.stop();
    // No need to setState here, _handleSpeechStatus will do it
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    log('[Speech] Result: ${result.recognizedWords}, Final: ${result.finalResult}');
    if (mounted) {
      setState(() {
        // Replace text field content with the latest recognized words
        widget.controller.text = result.recognizedWords;
        // Move cursor to the end
        widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length));

        // If it's the final result, mark as not listening
        // Note: onStatus callback might handle this already
        if (result.finalResult) {
          _isListening = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get the current theme

    // Determine mic icon and color based on state
    IconData micIcon = Icons.mic_none;
    // Use theme colors for the mic icon
    Color micColor = theme.iconTheme.color?.withOpacity(0.6) ?? Colors.grey[400]!;
    VoidCallback? micOnPressed = _startListening; // Default action

    if (!_speechEnabled || widget.isLoading) {
      micIcon = Icons.mic_off;
      micColor = theme.disabledColor; // Use theme's disabled color
      micOnPressed = null; // Disable button
    } else if (_isListening) {
      micIcon = Icons.mic; // Listening icon
      micColor = theme.primaryColor; // Active color (already theme-aware)
      micOnPressed = _stopListening; // Action to stop
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        // Use a theme-aware background color (e.g., cardColor or surface)
        color: theme.colorScheme.surface, // Use surface color for better contrast
        // Use a theme-aware border color
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          // Microphone Button
          Material(
            color: Colors.transparent,
            child: IconButton(
              icon: Icon(micIcon, color: micColor),
              onPressed: micOnPressed,
              tooltip: _isListening ? 'Stop listening' : 'Start voice input',
            ),
          ),
          // Text Input Field
          Expanded(
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: 'Type or tap mic...',
                // Ensure hint style uses theme color
                hintStyle: TextStyle(color: theme.hintColor),
                // Use the theme's input decoration (already configured in main.dart)
                // border: InputBorder.none, // Remove this if you want the theme's border
                // fillColor: Colors.transparent, // Remove this to use theme's fillColor
                filled: true, // Ensure theme's fillColor is used
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              // style: TextStyle(color: theme.textTheme.bodyLarge?.color), // Rely on default theme text style
              enabled: !widget.isLoading,
              keyboardType: TextInputType.multiline, // Allow multiline input
              maxLines: null, // Allow text field to grow
              textInputAction: TextInputAction.newline, // Change action to newline
              // onSubmitted: (_) => widget.onSend(), // Remove sending on submit
            ),
          ),
          // Send Button
          Material(
            color: Colors.transparent,
            child: IconButton(
              icon: Icon(
                Icons.send,
                // Use primary color for send button, potentially disabled
                color: widget.controller.text.isNotEmpty && !widget.isLoading
                    ? theme.primaryColor
                    : theme.disabledColor,
              ),
              onPressed: widget.controller.text.isNotEmpty && !widget.isLoading
                  ? widget.onSend
                  : null,
              tooltip: 'Send message',
            ),
          ),
        ],
      ),
    );
  }
}
