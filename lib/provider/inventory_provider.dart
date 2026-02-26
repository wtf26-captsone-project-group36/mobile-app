import 'package:flutter/material.dart';
import 'package:hervest_ai/models/inventory_model.dart';
import 'package:hervest_ai/mock_data/inventory_mock.dart'; 
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/core/network/inventory_api_service.dart';
import 'package:hervest_ai/features/rescue/data/rescue_local_db.dart';

class InventoryProvider extends ChangeNotifier {
  final List<InventoryItem> _items = [];
  final int criticalThresholdDays = 3;
  final InventoryApiService _api = const InventoryApiService();
  final RescueLocalDb _db = RescueLocalDb.instance;
  
  // Conflict tracking
  Map<String, ConflictResolution> _pendingConflicts = {};

  List<InventoryItem> get items => _items;
  Map<String, ConflictResolution> get pendingConflicts => _pendingConflicts;

  InventoryProvider() {
    _initializeAsync();
  }

  void _initializeAsync() {
    _loadInitialData();
    _loadFromLocalCache(); // NEW: Load cached inventory first
    loadFromBackend();     // Then sync with backend
  }

  /// Loads inventory from SQLite cache for offline access
  Future<void> _loadFromLocalCache() async {
    try {
      final cached = await _db.loadInventoryCache();
      if (cached.isEmpty) return;
      
      for (var row in cached) {
        final item = InventoryItem(
          id: (row['item_id'] ?? '').toString(),
          name: (row['item_name'] ?? '').toString(),
          category: (row['category'] ?? '').toString(),
          quantity: (row['quantity'] as num?)?.toDouble() ?? 0.0,
          unit: (row['unit'] ?? 'units').toString(),
          expiryDate: row['expiry_date'] != null 
            ? DateTime.tryParse(row['expiry_date'].toString())
            : null,
          purchasePrice: (row['purchase_price'] as num?)?.toDouble(),
          version: (row['version'] as num?)?.toInt() ?? 1,
          updatedAt: row['updated_at'] != null
            ? DateTime.tryParse(row['updated_at'].toString())
            : null,
          syncedAt: row['synced_at'] != null
            ? DateTime.tryParse(row['synced_at'].toString())
            : null,
        );
        _validateItem(item);
        
        // Don't add if already in list (from mock data)
        if (!_items.any((existing) => existing.id == item.id)) {
          _items.add(item);
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('[InventoryProvider] Cache load failed: $e');
      // Fail silently, continue with mock data
    }
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

    // Check for conflicts before updating
    final localVersion = _items[index].version;
    final cachedVersion = await _db.getItemVersion(itemId);
    
    if (cachedVersion != null && cachedVersion > localVersion) {
      // Conflict detected: item was edited on another device
      final conflict = ConflictResolution(
        itemId: itemId,
        itemName: _items[index].name,
        localVersion: localVersion,
        remoteVersion: cachedVersion,
      );
      _pendingConflicts[itemId] = conflict;
      notifyListeners();
      return; // Wait for user to resolve
    }

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
      version: (current.version) + 1, // Increment version
      updatedAt: DateTime.now(),
    );
    _validateItem(updated);

    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) {
      return;
    }

    // Optimistic Update
    _items[index] = updated;
    notifyListeners();

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
        final parsed = _fromApi(apiUpdated);
        _items[index] = parsed;
        
        // Save to cache with new version
        await _db.updateItemVersion(itemId, parsed.version);
        notifyListeners();
      }
    } catch (e) {
      // Revert optimistic update on API error
      _items[index] = current;
      notifyListeners();
      debugPrint('[InventoryProvider] Update failed: $e');
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
      // Do NOT add locally if API fails (e.g. 403 Forbidden for Staff)
      rethrow;
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
      
      // Save to cache for offline access
      await _db.saveInventoryCache(rows);
      
      notifyListeners();
    } catch (e) {
      // Keep local fallback data (from cache or mock) if API load fails
      debugPrint('[InventoryProvider] Backend load failed: $e');
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

  /// Resolves a conflict by using server version (discard local changes)
  Future<void> resolveConflictWithServerVersion(String itemId) async {
    _pendingConflicts.remove(itemId);
    
    // Reload from cache (server version)
    final cached = await _db.loadInventoryCache();
    final serverItem = cached.firstWhere(
      (item) => item['item_id'].toString() == itemId,
      orElse: () => {},
    );
    
    if (serverItem.isNotEmpty) {
      final index = _items.indexWhere((e) => e.id == itemId);
      if (index >= 0) {
        final updated = InventoryItem(
          id: (serverItem['item_id'] ?? '').toString(),
          name: (serverItem['item_name'] ?? '').toString(),
          category: (serverItem['category'] ?? '').toString(),
          quantity: (serverItem['quantity'] as num?)?.toDouble() ?? 0.0,
          unit: (serverItem['unit'] ?? 'units').toString(),
          expiryDate: serverItem['expiry_date'] != null
            ? DateTime.tryParse(serverItem['expiry_date'].toString())
            : null,
          purchasePrice: (serverItem['purchase_price'] as num?)?.toDouble(),
          version: (serverItem['version'] as num?)?.toInt() ?? 1,
          updatedAt: serverItem['updated_at'] != null
            ? DateTime.tryParse(serverItem['updated_at'].toString())
            : null,
          syncedAt: serverItem['synced_at'] != null
            ? DateTime.tryParse(serverItem['synced_at'].toString())
            : null,
        );
        _validateItem(updated);
        _items[index] = updated;
        notifyListeners();
      }
    }
  }

  /// Resolves a conflict by keeping local changes (force update)
  Future<void> resolveConflictForceLocal(String itemId) async {
    _pendingConflicts.remove(itemId);
    
    final index = _items.indexWhere((e) => e.id == itemId);
    if (index >= 0) {
      final item = _items[index];
      
      // Retry the update with incremented version
      final token = await AppSessionStore.instance.getAccessToken();
      if (token == null || token.isEmpty) return;
      
      try {
        await _api.updateInventoryItem(
          accessToken: token,
          itemId: itemId,
          body: {
            'item_name': item.name,
            'category': item.category,
            'quantity': item.quantity,
            'unit': item.unit,
            'expiry_date': item.expiryDate?.toIso8601String().split('T').first,
            'purchase_price': item.purchasePrice,
          },
        );
        
        // Update cache with new version
        item.version += 1;
        item.updatedAt = DateTime.now();
        item.syncedAt = DateTime.now();
        await _db.updateItemVersion(itemId, item.version);
        
        notifyListeners();
      } catch (e) {
        debugPrint('[InventoryProvider] Force update failed: $e');
      }
    }
  }

  /// Clears old cache entries (default: older than 7 days)
  Future<void> clearOldCache({Duration? olderThan}) async {
    final threshold = olderThan ?? Duration(days: 7);
    await _db.clearInventoryCacheOlderThan(threshold);
  }

  /// Gets conflict info for a specific item (for UI display)
  ConflictResolution? getConflict(String itemId) => _pendingConflicts[itemId];
}

/// Represents a conflict where an item was edited on multiple devices
class ConflictResolution {
  final String itemId;
  final String itemName;
  final int localVersion;
  final int remoteVersion;
  final DateTime detectedAt;

  ConflictResolution({
    required this.itemId,
    required this.itemName,
    required this.localVersion,
    required this.remoteVersion,
  }) : detectedAt = DateTime.now();

  String get conflictMessage =>
      'Item "$itemName" was edited on another device. '
      'Local version: $localVersion, Remote version: $remoteVersion';
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
