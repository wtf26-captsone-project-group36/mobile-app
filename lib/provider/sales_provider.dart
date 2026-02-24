import 'package:flutter/material.dart';
import 'package:hervest_ai/core/network/sales_api_service.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';

/// Sales State Provider
/// Manages inventory sales operations with error handling and UI feedback
class SalesProvider extends ChangeNotifier {
  final SalesApiService _api = const SalesApiService();

  // Sale history tracking
  List<Map<String, dynamic>> _saleHistory = [];
  List<Map<String, dynamic>> _purchaseHistory = [];

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<Map<String, dynamic>> get saleHistory => _saleHistory;
  List<Map<String, dynamic>> get purchaseHistory => _purchaseHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Sell an inventory item
  /// Atomically decrements inventory and records income transaction
  /// Returns true on success, false on failure
  Future<bool> sellItem({
    required String inventoryId,
    required double quantitySold,
    required double sellingPrice,
    String? transactionCategory,
    String? transactionDescription,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final token = await AppSessionStore.instance.getAccessToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'Authentication failed. Please log in again.';
        notifyListeners();
        return false;
      }

      final result = await _api.sellInventoryItem(
        accessToken: token,
        inventoryId: inventoryId,
        quantitySold: quantitySold,
        sellingPrice: sellingPrice,
        transactionCategory: transactionCategory,
        transactionDescription: transactionDescription,
      );

      // Update success message with remaining quantity
      final remainingQty = result['remaining_quantity'];
      _successMessage = 'Sale completed! Remaining stock: $remainingQty units';

      // Update sale history
      await loadSaleHistory();

      _isLoading = false;
      notifyListeners();
      return true;

    } on SalesException catch (e) {
      _isLoading = false;

      // Provide user-friendly error messages
      if (e.isInsufficientStock) {
        _errorMessage = 'Insufficient inventory. ${e.details?['remaining_quantity']?.toString() ?? 'Check available stock.'}';
      } else if (e.isValidationError) {
        _errorMessage = 'Invalid input: ${e.message}';
      } else if (e.isNetworkError) {
        _errorMessage = 'Network error: ${e.message}';
      } else {
        _errorMessage = 'Sale failed: ${e.message}';
      }

      notifyListeners();
      return false;

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Unexpected error during sale: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Purchase inventory item
  /// Atomically increments inventory and records expense transaction
  Future<bool> purchaseItem({
    required String inventoryId,
    required double quantityPurchased,
    required double costPrice,
    String? transactionCategory,
    String? transactionDescription,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final token = await AppSessionStore.instance.getAccessToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'Authentication failed. Please log in again.';
        notifyListeners();
        return false;
      }

      final result = await _api.purchaseInventoryItem(
        accessToken: token,
        inventoryId: inventoryId,
        quantityPurchased: quantityPurchased,
        costPrice: costPrice,
        transactionCategory: transactionCategory,
        transactionDescription: transactionDescription,
      );

      final newQty = result['new_quantity'];
      _successMessage = 'Purchase recorded! New stock: $newQty units';

      await loadPurchaseHistory();

      _isLoading = false;
      notifyListeners();
      return true;

    } on SalesException catch (e) {
      _isLoading = false;

      if (e.isValidationError) {
        _errorMessage = 'Invalid input: ${e.message}';
      } else if (e.isNetworkError) {
        _errorMessage = 'Network error: ${e.message}';
      } else {
        _errorMessage = 'Purchase failed: ${e.message}';
      }

      notifyListeners();
      return false;

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Unexpected error during purchase: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Load sale history from backend
  Future<void> loadSaleHistory({
    int limit = 50,
    int offset = 0,
    String? fromDate,
    String? toDate,
    String? category,
  }) async {
    try {
      final token = await AppSessionStore.instance.getAccessToken();
      if (token == null || token.isEmpty) return;

      _saleHistory = await _api.getSaleHistory(
        accessToken: token,
        limit: limit,
        offset: offset,
        fromDate: fromDate,
        toDate: toDate,
        category: category,
      );

      notifyListeners();
    } catch (e) {
      // Silently fail - keep existing history
      print('Error loading sale history: $e');
    }
  }

  /// Load purchase history from backend
  Future<void> loadPurchaseHistory({
    int limit = 50,
    int offset = 0,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final token = await AppSessionStore.instance.getAccessToken();
      if (token == null || token.isEmpty) return;

      _purchaseHistory = await _api.getPurchaseHistory(
        accessToken: token,
        limit: limit,
        offset: offset,
        fromDate: fromDate,
        toDate: toDate,
      );

      notifyListeners();
    } catch (e) {
      print('Error loading purchase history: $e');
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear success message
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  /// Clear both messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
