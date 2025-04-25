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
    // Determine mic icon and color based on state
    IconData micIcon = Icons.mic_none;
    Color micColor = Colors.grey[400]!; // Default color
    VoidCallback? micOnPressed = _startListening; // Default action

    if (!_speechEnabled || widget.isLoading) {
      micIcon = Icons.mic_off;
      micColor = Colors.grey[700]!; // Disabled color
      micOnPressed = null; // Disable button
    } else if (_isListening) {
      micIcon = Icons.mic; // Listening icon
      micColor = Theme.of(context).primaryColor; // Active color
      micOnPressed = _stopListening; // Action to stop
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mainBackground, // match dark mode
        border: Border(top: BorderSide(color: AppColors.sidebarCard)),
      ),
      child: Row(
        children: [
          // Microphone Button
          Material(
            color: Colors.transparent,
            child: IconButton(
              icon: Icon(micIcon, color: micColor),
              tooltip: _isListening ? 'Stop listening' : (_speechEnabled ? 'Tap to speak' : 'Speech not available'),
              onPressed: micOnPressed,
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: _isListening ? 'Listening...' : 'Type or tap mic...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                filled: true,
                fillColor: AppColors.userBubble, // dark bubble for input
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), // Adjust padding
              ),
              minLines: 1,
              maxLines: PlatformHelper.isMobile ? 4 : 1,
              enabled: !widget.isLoading && !_isListening, // Disable text input while listening
              onSubmitted: PlatformHelper.isMobile ? null : ((_) => widget.onSend()),
              textInputAction: TextInputAction.send, // Add send action
            ),
          ),
          // Send Button
          Material(
            color: Colors.transparent,
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: widget.isLoading
                    ? AppColors.sidebarCard
                    : const Color.fromARGB(255, 64, 140, 255),
              ),
              onPressed: widget.isLoading ? null : widget.onSend,
              tooltip: 'Send message',
            ),
          ),
        ],
      ),
    );
  }
}
