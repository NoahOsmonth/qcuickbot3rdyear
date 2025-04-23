import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class AvatarBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isThinking;

  const AvatarBubble({
    Key? key,
    required this.message,
    this.isThinking = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine properties based on the message object
    final bool isUser = message.isUser; // Use the boolean field directly
    final String text = message.text;
    final String? avatarUrl = message.avatarUrl; // Use the avatarUrl from message
    final bool isButton = message.type == MessageType.quickReplies; // Correctly check for button type
    final VoidCallback? onTap = null; // Placeholder for potential button tap logic

    final bubbleColor = isUser ? AppColors.userBubble : AppColors.botBubble;
    final textColor = AppColors.bubbleText;
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
        ? CircleAvatar(backgroundImage: NetworkImage(avatarUrl), radius: 18, backgroundColor: AppColors.sidebar)
        : CircleAvatar(child: Icon(isUser ? Icons.person : Icons.android, color: AppColors.accentBlue), radius: 18, backgroundColor: AppColors.sidebarCard);
    
    final Widget bubbleContent;
    if (isThinking) {
      bubbleContent = const SizedBox(
        height: 20,
        width: 40,
        child: LinearProgressIndicator( 
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 64, 140, 255)),
        ),
      );
    } else if (!isUser) {
      // Render bot messages as markdown
      bubbleContent = MarkdownBody(
        data: text,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(color: textColor, fontSize: 16),
        ),
      );
    } else {
      bubbleContent = Text(
        text,
        style: TextStyle(color: textColor, fontSize: 16),
      );
    }

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.sidebarCard),
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
