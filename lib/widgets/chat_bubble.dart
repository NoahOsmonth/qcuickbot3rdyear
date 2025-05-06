import 'package:flutter/material.dart';
// Removed developer log import

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get the current theme
    // Removed logging

    // Determine colors based on theme and user type
    final bubbleColor = isUser
        ? theme.colorScheme.primaryContainer // User bubble color from theme
        : theme.cardColor; // Bot bubble color from theme (or theme.colorScheme.surfaceVariant)
    final textColor = isUser
        ? theme.colorScheme.onPrimaryContainer // Text color for user bubble
        : theme.textTheme.bodyLarge?.color; // Text color for bot bubble

    // Removed logging

    final borderRadius = BorderRadius.circular(18);
    final textAlign = TextAlign.left; // always left-aligned

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: bubbleColor, // Use theme-aware color
                borderRadius: borderRadius,
                // No shadow or very subtle shadow for modern flat look
                boxShadow: [
                  BoxShadow(
                    // Use a theme-aware shadow color if desired, or keep subtle black
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              child: Text(
                text,
                style: TextStyle(
                  color: textColor, // Use theme-aware text color
                  fontSize: 16,
                ),
                textAlign: textAlign,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
