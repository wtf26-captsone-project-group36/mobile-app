import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  Future<void> _handleSave(BuildContext context) async {
    final isGuest = await AppSessionStore.instance.isGuest();
    if (isGuest) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("You're exploring as a guest — sign up to save."),
            action: SnackBarAction(
              label: 'Sign Up',
              onPressed: () => context.push('/signup'),
            ),
          ),
        );
      }
      return;
    }

    // TODO: actual save logic
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inventory saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Inventory Screen',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _handleSave(context),
              icon: const Icon(Icons.save),
              label: const Text('Save Inventory'),
            ),
          ],
        ),
      ),
    );
  }
}