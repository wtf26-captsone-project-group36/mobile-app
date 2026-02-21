import 'package:flutter/material.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:go_router/go_router.dart';

import '../pages/dashboard_page.dart';
import 'inventory_screen.dart';
import 'cashflow_screen.dart';
import 'suggestions_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isGuest = false;
  bool _bannerVisible = true;

  final List<Widget> _pages = [
    DashboardScreen(),
    InventoryPageOne(),
    CashflowScreen(),
    SuggestionsScreen(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_isGuest && _bannerVisible)
            MaterialBanner(
              content: const Text("You're exploring as a guest — create an account to save your data."),
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
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.black54,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Finances'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline), label: 'Suggestions'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    AppSessionStore.instance.isGuest().then((value) {
      if (mounted) setState(() => _isGuest = value);
    });
  }
}