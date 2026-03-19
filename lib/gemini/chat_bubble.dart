import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool user;

  const ChatBubble({
    super.key,
    required this.text,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          user
              ? Alignment.centerRight
              : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            user
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
        children: [
          if (!user)
            const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
              ),
            ),
          Container(
            margin:
                const EdgeInsets.all(6),
            padding:
                const EdgeInsets.all(12),
            constraints:
                const BoxConstraints(
              maxWidth: 260,
            ),
            decoration:
                BoxDecoration(
              color: user
                  ? Colors.blueAccent
                  : Colors.grey.shade900,
              borderRadius:
                  BorderRadius.circular(
                      18),
            ),
            child: Text(
              text,
              style:
                  const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}