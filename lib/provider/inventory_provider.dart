import 'package:flutter/material.dart';
import 'package:hervest_ai/models/inventory_model.dart';
import 'package:hervest_ai/mock_data/inventory_mock.dart'; 
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/core/network/inventory_api_service.dart';

class InventoryProvider extends ChangeNotifier {
  final List<InventoryItem> _items = [];
  final int criticalThresholdDays = 3;
  final InventoryApiService _api = const InventoryApiService();

  List<InventoryItem> get items => _items;

  InventoryProvider() {
    _loadInitialData();
    loadFromBackend();
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

  Future<void> updateItemFromApi({
    required String itemId,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    DateTime? expiryDate,
    double? purchasePrice,
  }) async {
    final index = _items.indexWhere((e) => e.id == itemId);
    if (index < 0) return;

    final current = _items[index];
    final updated = InventoryItem(
      id: current.id,
      name: name ?? current.name,
      category: category ?? current.category,
      quantity: quantity ?? current.quantity,
      unit: unit ?? current.unit,
      expiryDate: expiryDate ?? current.expiryDate,
      purchasePrice: purchasePrice ?? current.purchasePrice,
      dateReceived: current.dateReceived,
    );
    _validateItem(updated);
    _items[index] = updated;
    notifyListeners();

    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final apiUpdated = await _api.updateInventoryItem(
        accessToken: token,
        itemId: itemId,
        body: {
          if (name != null) 'item_name': name,
          if (category != null) 'category': category,
          if (quantity != null) 'quantity': quantity,
          if (unit != null) 'unit': unit,
          if (expiryDate != null)
            'expiry_date': expiryDate.toIso8601String().split('T').first,
          if (purchasePrice != null) 'purchase_price': purchasePrice,
        },
      );
      if (apiUpdated.isNotEmpty) {
        _items[index] = _fromApi(apiUpdated);
        notifyListeners();
      }
    } catch (_) {
      // Keep optimistic update on API error.
    }
  }

  Future<void> deleteItemFromApi(String itemId) async {
    final index = _items.indexWhere((e) => e.id == itemId);
    if (index < 0) return;
    final removed = _items.removeAt(index);
    notifyListeners();

    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      await _api.deleteInventoryItem(accessToken: token, itemId: itemId);
    } catch (_) {
      _items.insert(index, removed);
      notifyListeners();
    }
  }

  Future<void> addItemFromApi(InventoryItem item) async {
    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) {
      addItem(item);
      return;
    }

    try {
      final created = await _api.createInventoryItem(
        accessToken: token,
        body: {
          'item_name': item.name,
          'quantity': item.quantity,
          'unit': item.unit,
          'category': item.category,
          'purchase_price': item.purchasePrice ?? 0,
          'expiry_date': item.expiryDate?.toIso8601String().split('T').first,
        },
      );
      final mapped = _fromApi(created);
      addItem(mapped);
    } catch (_) {
      addItem(item);
    }
  }

  Future<void> loadFromBackend() async {
    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final rows = await _api.getInventory(accessToken: token);
      if (rows.isEmpty) return;

      _items
        ..clear()
        ..addAll(rows.map(_fromApi));
      notifyListeners();
    } catch (_) {
      // Keep local fallback data if API load fails.
    }
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

  InventoryItem _fromApi(Map<String, dynamic> json) {
    final id = (json['item_id'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString();
    final name = (json['item_name'] ?? json['name'] ?? 'Unknown').toString();
    final category = (json['category'] ?? 'General').toString();
    final quantity = (json['quantity'] as num?)?.toDouble() ?? 0.0;
    final unit = (json['unit'] ?? 'units').toString();
    final purchasePrice = (json['purchase_price'] as num?)?.toDouble() ??
        (json['unit_price'] as num?)?.toDouble() ??
        0.0;
    final expiryRaw = json['expiry_date']?.toString();

    return InventoryItem(
      id: id,
      name: name,
      category: category,
      quantity: quantity,
      unit: unit,
      expiryDate: expiryRaw == null || expiryRaw.isEmpty ? null : DateTime.tryParse(expiryRaw),
      purchasePrice: purchasePrice,
    );
  }
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
