import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F9F4),
      body: Center(
        child: Text(
          "Inventory Screen",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}