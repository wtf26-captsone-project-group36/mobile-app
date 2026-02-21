import 'package:flutter/material.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';

class AppStateController extends ChangeNotifier {
  String userName = 'John Doe';
  bool expiryAlertsEnabled = true;
  bool cashflowUpdatesEnabled = false;
  bool lowStockEnabled = true;

  AppStateController() {
    _initializeUserName();
  }

  Future<void> _initializeUserName() async {
    final storedName = await AppSessionStore.instance.getUserName();
    if (storedName != null && storedName.isNotEmpty) {
      userName = storedName;
      notifyListeners();
    }
  }

  void setUserName(String name) {
    if (name.isNotEmpty) {
      userName = name;
      AppSessionStore.instance.setUserName(name);
      notifyListeners();
    }
  }

  // Mock Inventory Data (Page 1-4)
  List<Map<String, dynamic>> inventory = [
    {'id': '1', 'name': 'Golden Penny Beans', 'qty': '20 Units', 'expiry': 7},
    {'id': '2', 'name': 'Mama Gold Rice', 'qty': '15 Bags', 'expiry': 45},
    {'id': '3', 'name': 'Peak Milk', 'qty': '10 Cartons', 'expiry': 3},
  ];

  // Mock Transaction Data (Page 8-11)
  List<Map<String, dynamic>> transactions = [
    {'title': 'Electricity bill', 'amount': 'NGN 10,000', 'type': 'Expense', 'date': 'Feb 20'},
    {'title': 'Direct Sales', 'amount': 'NGN 45,000', 'type': 'Income', 'date': 'Feb 21'},
    {'title': 'Water Refill', 'amount': 'NGN 2,500', 'type': 'Expense', 'date': 'Feb 18'},
  ];

  void addTransaction({
    required String title,
    required String amount,
    required String type,
    required String date,
  }) {
    transactions.insert(0, {
      'title': title,
      'amount': amount,
      'type': type,
      'date': date,
    });
    notifyListeners();
  }

  // --- Master Search Logic ---
  List<Map<String, dynamic>> searchResults = [];

  void performSearch(String query) {
    if (query.isEmpty) {
      searchResults = [];
    } else {
      final invResults = inventory
          .where((item) => item['name'].toLowerCase().contains(query.toLowerCase()))
          .map((item) => {...item, 'source': 'Inventory', 'icon': Icons.inventory_2})
          .toList();

      final transResults = transactions
          .where((t) => t['title'].toLowerCase().contains(query.toLowerCase()))
          .map((t) => {...t, 'source': 'Transaction', 'icon': Icons.receipt_long})
          .toList();

      searchResults = [...invResults, ...transResults];
    }
    notifyListeners();
  }

  void toggleExpiryAlerts(bool val) {
    expiryAlertsEnabled = val;
    notifyListeners();
  }

  void toggleCashflowUpdates(bool val) {
    cashflowUpdatesEnabled = val;
    notifyListeners();
  }

  void toggleLowStock(bool val) {
    lowStockEnabled = val;
    notifyListeners();
  }

  void updateUserName(String name) {
    userName = name;
    notifyListeners();
  }
}
