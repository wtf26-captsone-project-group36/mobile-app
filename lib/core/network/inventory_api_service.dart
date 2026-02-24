import 'dart:convert';

import 'package:hervest_ai/core/network/api_config.dart';
import 'package:http/http.dart' as http;

class InventoryApiService {
  const InventoryApiService();

  Future<List<Map<String, dynamic>>> getInventory({
    required String accessToken,
    String? category,
    String? search,
    int? expiringSoonDays,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String>[];
    if (category != null && category.isNotEmpty) params.add('category=$category');
    if (search != null && search.isNotEmpty) params.add('search=$search');
    if (expiringSoonDays != null) {
      params.add('expiring_soon_days=$expiringSoonDays');
    }
    params.add('limit=$limit');
    params.add('offset=$offset');

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await _request(
      method: 'GET',
      path: '/inventory$query',
      accessToken: accessToken,
    );

    final items = response['items'];
    if (items is List) {
      return items
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createInventoryItem({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final response = await _request(
      method: 'POST',
      path: '/inventory',
      accessToken: accessToken,
      body: body,
    );
    final item = response['item'];
    if (item is Map) return item.cast<String, dynamic>();
    return {};
  }

  Future<Map<String, dynamic>> updateInventoryItem({
    required String accessToken,
    required String itemId,
    required Map<String, dynamic> body,
  }) async {
    final response = await _request(
      method: 'PUT',
      path: '/inventory/$itemId',
      accessToken: accessToken,
      body: body,
    );
    final item = response['item'];
    if (item is Map) return item.cast<String, dynamic>();
    return {};
  }

  Future<void> deleteInventoryItem({
    required String accessToken,
    required String itemId,
  }) async {
    await _request(
      method: 'DELETE',
      path: '/inventory/$itemId',
      accessToken: accessToken,
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    required String accessToken,
    Map<String, dynamic>? body,
  }) async {
    final primary = ApiConfig.apiUri(path);
    final fallback = ApiConfig.uri(path);
    http.Response response = await _send(
      method: method,
      uri: primary,
      accessToken: accessToken,
      body: body,
    );
    var jsonBody = _decode(response.body);

    if (response.statusCode == 404 && _isRouteNotFound(jsonBody)) {
      response = await _send(
        method: method,
        uri: fallback,
        accessToken: accessToken,
        body: body,
      );
      jsonBody = _decode(response.body);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return jsonBody;
    throw Exception(
      (jsonBody['error'] ?? jsonBody['message'] ?? 'Request failed').toString(),
    );
  }

  Future<http.Response> _send({
    required String method,
    required Uri uri,
    required String accessToken,
    Map<String, dynamic>? body,
  }) async {
    final headers = <String, String>{'Authorization': 'Bearer $accessToken'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (method == 'GET') {
      return http.get(uri, headers: headers).timeout(const Duration(seconds: 12));
    }
    if (method == 'PUT') {
      return http
          .put(uri, headers: headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 12));
    }
    if (method == 'DELETE') {
      return http.delete(uri, headers: headers).timeout(const Duration(seconds: 12));
    }
    return http
        .post(uri, headers: headers, body: jsonEncode(body ?? {}))
        .timeout(const Duration(seconds: 12));
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