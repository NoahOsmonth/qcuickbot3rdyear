import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'platform_helper.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;

  const ChatInputBar({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mainBackground, // match dark mode
        border: Border(top: BorderSide(color: AppColors.sidebarCard)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type here...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                filled: true,
                fillColor: AppColors.userBubble, // dark bubble for input
              ),
              minLines: 1,
              maxLines: PlatformHelper.isMobile ? 4 : 1,
              enabled: !isLoading,
              onSubmitted: PlatformHelper.isMobile ? null : ((_) => onSend()),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: IconButton(
              icon: Icon(
                Icons.send,
                color:
                    isLoading ? AppColors.sidebarCard : const Color.fromARGB(255, 64, 140, 255),
              ),
              onPressed: isLoading ? null : onSend,
            ),
          ),
        ],
      ),
    );
  }
}
