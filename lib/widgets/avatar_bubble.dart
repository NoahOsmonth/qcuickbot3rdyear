import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';
// Removed direct import of AppColors, will use Theme.of(context)

class AvatarBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isThinking;

  const AvatarBubble({
    super.key,
    required this.message,
    this.isThinking = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get the current theme
    // Determine properties based on the message object
    final bool isUser = message.isUser; // Use the boolean field directly
    final String text = message.text;
    final String? avatarUrl = message.avatarUrl; // Use the avatarUrl from message
    final bool isButton = message.type == MessageType.quickReplies; // Correctly check for button type
    final VoidCallback? onTap = null; // Placeholder for potential button tap logic

    // Determine colors based on theme and user type
    final bubbleColor = isUser
        ? theme.colorScheme.primaryContainer // User bubble color from theme
        : theme.cardColor; // Bot bubble color from theme (use cardColor for consistency)
    final textColor = isUser
        ? theme.colorScheme.onPrimaryContainer // Text color for user bubble
        : theme.textTheme.bodyLarge?.color; // Text color for bot bubble (use theme's text color)
    final borderRadius = isUser
        ? BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );
    final avatar = avatarUrl != null
        ? CircleAvatar(backgroundImage: NetworkImage(avatarUrl), radius: 24, backgroundColor: theme.colorScheme.surfaceVariant)
        : isUser
            ? CircleAvatar(radius: 24, backgroundColor: theme.cardColor, child: Icon(Icons.person, color: theme.colorScheme.primary))
            : CircleAvatar(backgroundImage: AssetImage('assets/pictures/chatbotprofile.png'), radius: 24, backgroundColor: theme.colorScheme.surfaceVariant);
    
    final Widget bubbleContent;
    if (isThinking) {
      // Remove const here because theme.colorScheme.primary is not constant
      bubbleContent = SizedBox(
        height: 20,
        width: 40,
        child: LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary), // Use theme color
        ),
      );
    } else if (!isUser) {
      // Render bot messages as markdown
      bubbleContent = MarkdownBody(
        data: text,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(color: textColor ?? theme.textTheme.bodyLarge?.color, fontSize: 16), // Use theme text color with fallback
        ),
      );
    } else {
      bubbleContent = Text(
        text,
        style: TextStyle(color: textColor ?? theme.textTheme.bodyLarge?.color, fontSize: 16), // Use theme text color with fallback
      );
    }

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: borderRadius,
        // Use theme divider color for border, or remove if not desired
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: bubbleContent,
    );
    if (isButton) {
      return GestureDetector(
        onTap: onTap,
        child: bubble,
      );
    }
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: isUser
          ? [bubble, SizedBox(width: 8), avatar]
          : [avatar, SizedBox(width: 8), bubble],
    );
  }
}
