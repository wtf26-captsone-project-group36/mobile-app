import 'package:flutter/material.dart';

//for our Master Search functionality, we need a central controller to manage state across both Inventory and Cashflow domains. This mock controller will provide sample data and search logic for testing our search UI before we integrate with real data sources.

class AppStateController extends ChangeNotifier {
  String userName = 'John Doe';
  bool expiryAlertsEnabled = true;
  bool cashflowUpdatesEnabled = false;
  bool lowStockEnabled = true;

  // Mock Inventory Data (Page 1-4)
  List<Map<String, dynamic>> inventory = [
    {'id': '1', 'name': 'Golden Penny Beans', 'qty': '20 Units', 'expiry': 7},
    {'id': '2', 'name': 'Mama Gold Rice', 'qty': '15 Bags', 'expiry': 45},
    {'id': '3', 'name': 'Peak Milk', 'qty': '10 Cartons', 'expiry': 3}, // Critical
  ];

  // Mock Transaction Data (Page 8-11)
  List<Map<String, dynamic>> transactions = [
    {'title': 'Electricity bill', 'amount': '₦10,000', 'type': 'Expense', 'date': 'Feb 20'},
    {'title': 'Direct Sales', 'amount': '₦45,000', 'type': 'Income', 'date': 'Feb 21'},
    {'title': 'Water Refill', 'amount': '₦2,500', 'type': 'Expense', 'date': 'Feb 18'},
  ];

  // --- Master Search Logic ---
  List<Map<String, dynamic>> searchResults = [];

  void performSearch(String query) {
    if (query.isEmpty) {
      searchResults = [];
    } else {
      // Logic to search through both domains
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
}