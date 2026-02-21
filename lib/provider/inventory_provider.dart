import 'package:flutter/material.dart';
import 'package:hervest_ai/models/inventory_model.dart';
import 'package:hervest_ai/mock_data/inventory_mock.dart'; 

class InventoryProvider extends ChangeNotifier {
  final List<InventoryItem> _items = [];
  final int criticalThresholdDays = 3;

  List<InventoryItem> get items => _items;

  InventoryProvider() {
    _loadInitialData();
  }

  void _loadInitialData() {
    for (var json in rawInventoryData) {
      addItem(
        InventoryItem(
          id: json['item_id'] as String,
          name: json['item_name'] as String,
          category: json['category'] as String,
          quantity: (json['quantity'] as num).toDouble(),
          unit: json['unit'] as String,
          expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date'] as String) : null,
          purchasePrice: (json['purchase_price'] as num).toDouble(),
        ),
        isInitialLoad: true,
      );
    }
  }

  void addItem(InventoryItem item, {bool isInitialLoad = false}) {
    _validateItem(item);
    _items.add(item);
    if (!isInitialLoad) notifyListeners();
  }

  void _validateItem(InventoryItem item) {
    if (item.expiryDate == null) {
      item.status = ItemStatus.error;
      item.errorMessage = "Missing Expiry Date";
      return;
    }
    final daysUntil = item.expiryDate!.difference(DateTime.now()).inDays;
    if (daysUntil < 0) {
      item.status = ItemStatus.expired;
    } else if (daysUntil <= criticalThresholdDays) {
      item.status = ItemStatus.warning;
    } else {
      item.status = ItemStatus.normal;
    }
  }

  int get criticalCount => _items.where((i) => i.status == ItemStatus.warning || i.status == ItemStatus.expired || i.status == ItemStatus.error).length;

  int get errorCount => _items.where((i) => i.status == ItemStatus.error).length;

  List<InventoryItem> get donationSuggestions => _items.where((i) => i.status == ItemStatus.warning).toList();

  double get totalLedgerValue => _items.fold(0, (sum, item) => sum + (item.purchasePrice ?? 0));
}



/*import 'package:flutter/material.dart';
import 'package:hervest_ai/models/inventory_model.dart';
import 'package:hervest_ai/mock_data/inventory_mock.dart'; 

class InventoryProvider extends ChangeNotifier {
  final List<InventoryItem> _items = [];
  
  // Set the "AI Threshold" (days before expiry to trigger alerts)
  final int criticalThresholdDays = 3;

  List<InventoryItem> get items => _items;

  InventoryProvider() {
    _loadInitialData();
  }

  void _loadInitialData() {
    for (var json in rawInventoryData) {
      addItem(
        InventoryItem(
          id: json['item_id'],
          name: json['item_name'],
          category: json['category'],
          quantity: (json['quantity'] as num).toDouble(),
          unit: json['unit'],
          expiryDate: json['expiry_date'] != null 
              ? DateTime.parse(json['expiry_date']) 
              : null,
          purchasePrice: (json['purchase_price'] as num).toDouble(),
        ),
        isInitialLoad: true,
      );
    }
  }

  void addItem(InventoryItem item, {bool isInitialLoad = false}) {
    _validateItem(item);
    _items.add(item);
    if (!isInitialLoad) notifyListeners();
  }

  /// Removes an item (useful for donation success or sales)
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// Internal AI Validation Logic
  void _validateItem(InventoryItem item) {
    if (item.expiryDate == null) {
      item.status = ItemStatus.error;
      item.errorMessage = "Missing Expiry Date - AI cannot suggest donees.";
      return;
    }

    final daysUntil = item.expiryDate!.difference(DateTime.now()).inDays;

    if (daysUntil < 0) {
      item.status = ItemStatus.expired;
    } else if (daysUntil <= criticalThresholdDays) {
      item.status = ItemStatus.warning; // This triggers the orange/red UI on Dashboard
    } else {
      item.status = ItemStatus.normal;
    }
  }

  // --- SMART GETTERS ---

  int get errorCount => _items.where((i) => i.status == ItemStatus.error).length;

  /// Used for the Dashboard "AI Alerts" Card
  int get criticalCount => _items.where((i) => i.status == ItemStatus.warning || i.status == ItemStatus.expired).length;

  /// Feeds the Page 5 Suggestions List
  List<InventoryItem> get donationSuggestions => _items.where((item) {
    if (item.expiryDate == null) return false;
    final daysUntil = item.expiryDate!.difference(DateTime.now()).inDays;
    return daysUntil >= 0 && daysUntil <= criticalThresholdDays;
  }).toList();

  double get totalLedgerValue => _items.fold(0, (sum, item) => sum + (item.purchasePrice ?? 0));

  double get valueAtRisk => _items
        .where((i) => i.status == ItemStatus.error || i.status == ItemStatus.expired || i.status == ItemStatus.warning)
        .fold(0, (sum, item) => sum + (item.purchasePrice ?? 0));
}

*/







/*import 'package:flutter/material.dart';
import 'package:hervest_ai/models/inventory_model.dart';
// Assuming your mock data is stored here
import 'package:hervest_ai/mock_data/inventory_mock.dart'; 

class InventoryProvider extends ChangeNotifier {
  // Use the InventoryItem model we defined earlier
  final List<InventoryItem> _items = [];

  List<InventoryItem> get items => _items;

  // Constructor: Automatically loads the Data Scientist's JSON on startup
  InventoryProvider() {
    _loadInitialData();
  }

  void _loadInitialData() {
    for (var json in rawInventoryData) {
      addItem(
        InventoryItem(
          id: json['item_id'],
          name: json['item_name'],
          category: json['category'],
          quantity: (json['quantity'] as num).toDouble(),
          unit: json['unit'],
          // Convert JSON string date to Flutter DateTime
          expiryDate: json['expiry_date'] != null 
              ? DateTime.parse(json['expiry_date']) 
              : null,
          // We can also store the purchase price in the model if you updated it
          purchasePrice: (json['purchase_price'] as num).toDouble(),
        ),
        isInitialLoad: true,
      );
    }
  }

  /// Adds an item and runs the "Smart Ledger" validation
  void addItem(InventoryItem item, {bool isInitialLoad = false}) {
    // AI Validation: Flag missing expiry dates (like the Onions in your JSON)
    if (item.expiryDate == null) {
      item.status = ItemStatus.error;
      item.errorMessage = "Missing Expiry Date - AI cannot suggest donees.";
    } else if (item.expiryDate!.isBefore(DateTime.now())) {
      item.status = ItemStatus.expired;
    }

    _items.add(item);
    
    // Only notify listeners if we aren't in the middle of a bulk load
    if (!isInitialLoad) notifyListeners();
  }

  // --- SMART LOGIC GETTERS ---

  /// Page 3 Logic: Count of items that need manual fixing
  int get errorCount => _items.where((i) => i.status == ItemStatus.error).length;

  /// Suggestions Logic: Items expiring in the next 3 days
  List<InventoryItem> get soonToExpire => _items.where((item) {
    if (item.expiryDate == null) return false;
    final daysUntil = item.expiryDate!.difference(DateTime.now()).inDays;
    return daysUntil >= 0 && daysUntil <= 3;
  }).toList();

  /// Financial Logic: Sum of all purchase prices
  double get totalLedgerValue {
    return _items.fold(0, (sum, item) => sum + (item.purchasePrice ?? 0));
  }

  /// Risk Logic: Total value of items currently in 'Error' or 'Expired' state
  double get valueAtRisk {
    return _items
        .where((i) => i.status == ItemStatus.error || i.status == ItemStatus.expired)
        .fold(0, (sum, item) => sum + (item.purchasePrice ?? 0));
  }
} */










/*import 'package:flutter/material.dart';
import 'package:hervest_ai/models/inventory_model.dart';
import 'inventory_model.dart';

class InventoryProvider extends ChangeNotifier {
  final List<InventoryItem> _items = [];

  List<InventoryItem> get items => _items;

  // Logic: Add a new item and run a quick "AI validation"
  void addItem(InventoryItem item) {
    // Simple logic: If expiry date is missing, mark as error
    if (item.expiryDate == null) {
      item.status = ItemStatus.error;
      item.errorMessage = "Missing Expiry Date";
    }
    
    _items.add(item);
    notifyListeners(); // This tells Page 1 to rebuild the list
  }

  // Logic: Get count of items with errors for Page 3 banner
  int get errorCount => _items.where((i) => i.status == ItemStatus.error).length;

  // Logic: Calculate total ledger value (mock calculation)
  double get totalValue => _items.length * 2500.0; 
}

// Inside InventoryProvider
List<InventoryItem> get donationSuggestions => _items.where((item) {
    if (item.expiryDate == null) return false;
    // Suggest items expiring in the next 3 days
    return item.expiryDate!.difference(DateTime.now()).inDays <= 3;
}).toList(); */