import 'package:flutter/material.dart';
import 'package:meditrack/screens/main/settings/chat_support_screen.dart';
import 'package:meditrack/style/colors.dart';

class FloatingChatButton extends StatelessWidget {
  const FloatingChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChatSupportScreen(),
          ),
        );
      },
      backgroundColor: AppColors.primary,
      child: const Icon(
        Icons.chat_bubble_outline,
        color: Colors.white,
      ),
    );
  }
}