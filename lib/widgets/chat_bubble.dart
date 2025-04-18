import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({Key? key, required this.text, required this.isUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isUser ? AppColors.userBubble : AppColors.botBubble;
    final borderRadius = BorderRadius.circular(18); // more rounded for both
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
                color: bubbleColor,
                borderRadius: borderRadius,
                // No shadow or very subtle shadow for modern flat look
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              child: Text(
                text,
                style: TextStyle(color: AppColors.bubbleText, fontSize: 16),
                textAlign: textAlign,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
