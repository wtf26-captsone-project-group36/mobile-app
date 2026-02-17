import 'package:flutter/material.dart';

class FinancesScreen extends StatelessWidget {
  const FinancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F9F4),
      body: Center(
        child: Text(
          "Finances Screen",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}