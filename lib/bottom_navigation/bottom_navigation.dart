import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  bool _isGuest = false;
  bool _bannerVisible = true;

  @override
  void initState() {
    super.initState();
    AppSessionStore.instance.isGuest().then((value) {
      if (mounted) setState(() => _isGuest = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    return Scaffold(
      body: Column(
        children: [
          if (_isGuest && _bannerVisible)
            MaterialBanner(
              content: const Text(
                "You're exploring as a guest -- create an account to save your data.",
              ),
              leading: const Icon(Icons.person_outline),
              actions: [
                TextButton(
                  onPressed: () => context.push('/signup'),
                  child: const Text('Create Account'),
                ),
                TextButton(
                  onPressed: () => setState(() => _bannerVisible = false),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          Expanded(
            child: widget.navigationShell,
          ),
        ],
      ),
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.reactCircle,
        backgroundColor: const Color(0xFFFDFBF7),
        activeColor: const Color(0xFF2A8C68),
        color: Colors.black54,
        height: 56,
        elevation: 6,
        curveSize: 85,
        top: -14,
        initialActiveIndex: currentIndex,
        onTap: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == currentIndex,
          );
        },
        items: const [
          TabItem(icon: Icons.home, title: 'Home'),
          TabItem(icon: Icons.inventory_2, title: 'Inventory'),
          TabItem(icon: Icons.attach_money, title: 'Finances'),
          TabItem(icon: Icons.lightbulb_outline, title: 'Ideas'),
          TabItem(icon: Icons.person_outline, title: 'Profile'),
        ],
      ),
    );
  }
}
