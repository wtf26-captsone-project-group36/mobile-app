import 'package:flutter/material.dart';

class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F9F4),
      body: Center(
        child: Text(
          "Suggestions Screen",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}