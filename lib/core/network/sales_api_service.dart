import 'dart:convert';

import 'package:hervest_ai/core/network/api_config.dart';
import 'package:http/http.dart' as http;

/// Sales API Service
/// Handles atomic inventory sales and purchases with transactional integrity
class SalesApiService {
  const SalesApiService();

  /// Sell Inventory Item (Atomic Transaction)
  /// Atomically decrements inventory and creates income transaction
  /// 
  /// Returns success with remaining quantity and transaction ID
  /// Throws exception on validation errors or insufficient stock
  Future<Map<String, dynamic>> sellInventoryItem({
    required String accessToken,
    required String inventoryId,
    required double quantitySold,
    required double sellingPrice,
    String? transactionCategory,
    String? transactionDescription,
  }) async {
    final body = {
      'inventory_id': inventoryId,
      'quantity_sold': quantitySold,
      'selling_price': sellingPrice,
      if (transactionCategory != null) 'transaction_category': transactionCategory,
      if (transactionDescription != null) 'transaction_description': transactionDescription,
    };

    final response = await _post(
      '/sales/sell-item',
      accessToken: accessToken,
      body: body,
    );

    // Handle error response
    if (response.containsKey('error')) {
      throw SalesException(
        message: response['error'].toString(),
        code: response['code']?.toString(),
        details: response['details'],
      );
    }

    final data = response['data'];
    if (data is Map) {
      return data.cast<String, dynamic>();
    }

    return response.cast<String, dynamic>();
  }

  /// Purchase Inventory Item (Atomic Transaction)
  /// Atomically increments inventory and creates expense transaction
  Future<Map<String, dynamic>> purchaseInventoryItem({
    required String accessToken,
    required String inventoryId,
    required double quantityPurchased,
    required double costPrice,
    String? transactionCategory,
    String? transactionDescription,
  }) async {
    final body = {
      'inventory_id': inventoryId,
      'quantity_purchased': quantityPurchased,
      'cost_price': costPrice,
      if (transactionCategory != null) 'transaction_category': transactionCategory,
      if (transactionDescription != null) 'transaction_description': transactionDescription,
    };

    final response = await _post(
      '/sales/purchase-item',
      accessToken: accessToken,
      body: body,
    );

    if (response.containsKey('error')) {
      throw SalesException(
        message: response['error'].toString(),
        code: response['code']?.toString(),
        details: response['details'],
      );
    }

    final data = response['data'];
    if (data is Map) {
      return data.cast<String, dynamic>();
    }

    return response.cast<String, dynamic>();
  }

  /// Get Sale History
  /// Retrieves all sales (income transactions) for the business
  Future<List<Map<String, dynamic>>> getSaleHistory({
    required String accessToken,
    int limit = 50,
    int offset = 0,
    String? fromDate,
    String? toDate,
    String? category,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
      if (category != null) 'category': category,
    };

    final response = await _get(
      '/sales/history',
      accessToken: accessToken,
      queryParams: queryParams,
    );

    final sales = response['sales'];
    if (sales is List) {
      return sales
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }

    return [];
  }

  /// Get Purchase History
  /// Retrieves all purchases (expense transactions) for the business
  Future<List<Map<String, dynamic>>> getPurchaseHistory({
    required String accessToken,
    int limit = 50,
    int offset = 0,
    String? fromDate,
    String? toDate,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
    };

    final response = await _get(
      '/sales/purchases',
      accessToken: accessToken,
      queryParams: queryParams,
    );

    final purchases = response['purchases'];
    if (purchases is List) {
      return purchases
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }

    return [];
  }

  // ===== PRIVATE METHODS =====

  Future<Map<String, dynamic>> _get(
    String path, {
    required String accessToken,
    Map<String, String>? queryParams,
  }) async {
    Uri primaryUri = ApiConfig.apiUri(path);
    Uri fallbackUri = ApiConfig.uri(path);

    // Add query parameters
    if (queryParams != null && queryParams.isNotEmpty) {
      primaryUri = primaryUri.replace(queryParameters: queryParams);
      fallbackUri = fallbackUri.replace(queryParameters: queryParams);
    }

    return _request(
      method: 'GET',
      primaryUri: primaryUri,
      fallbackUri: fallbackUri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final primary = ApiConfig.apiUri(path);
    final fallback = ApiConfig.uri(path);

    return _request(
      method: 'POST',
      primaryUri: primary,
      fallbackUri: fallback,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required Uri primaryUri,
    required Uri fallbackUri,
    required Map<String, String> headers,
    String? body,
  }) async {
    try {
      http.Response response = await _send(
        method: method,
        uri: primaryUri,
        headers: headers,
        body: body,
      );

      var jsonBody = _decode(response.body);

      // Try fallback endpoint if primary returns 404
      if (response.statusCode == 404 && _isRouteNotFound(jsonBody)) {
        response = await _send(
          method: method,
          uri: fallbackUri,
          headers: headers,
          body: body,
        );
        jsonBody = _decode(response.body);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonBody;
      }

      // Error response
      throw Exception(
        (jsonBody['error'] ?? jsonBody['message'] ?? 'Request failed').toString(),
      );
    } on SocketException catch (_) {
      throw SalesException(
        message: 'Network connection failed',
        code: 'NETWORK_ERROR',
      );
    } on TimeoutException catch (_) {
      throw SalesException(
        message: 'Request timeout - please check your connection',
        code: 'REQUEST_TIMEOUT',
      );
    }
  }

  Future<http.Response> _send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    if (method == 'GET') {
      return http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
    }
    return http
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 15));
  }

  Map<String, dynamic> _decode(String body) {
    if (body.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  bool _isRouteNotFound(Map<String, dynamic> jsonBody) {
    final message = (jsonBody['error'] ?? jsonBody['message'] ?? '')
        .toString()
        .toLowerCase();
    return message.contains('route') && message.contains('not found');
  }
}

/// Custom exception for sales operations
class SalesException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  SalesException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'SalesException: $message (code: $code)';

  /// Check if this is an insufficient stock error
  bool get isInsufficientStock => code == 'INSUFFICIENT_STOCK';

  /// Check if this is a not found error
  bool get isNotFound => code == 'ITEM_NOT_FOUND';

  /// Check if this is a validation error
  bool get isValidationError => code == 'INVALID_QUANTITY' || code == 'INVALID_PRICE';

  /// Check if this is a network error
  bool get isNetworkError => code == 'NETWORK_ERROR' || code == 'REQUEST_TIMEOUT';
}

// Wrapper for SocketException and TimeoutException
class SocketException implements Exception {
  final String message;
  SocketException(this.message);

  @override
  String toString() => 'SocketException: $message';
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
