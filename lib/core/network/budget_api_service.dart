import 'dart:convert';

import 'package:hervest_ai/core/network/api_config.dart';
import 'package:http/http.dart' as http;

class BudgetApiService {
  const BudgetApiService();

  Future<List<Map<String, dynamic>>> getBudgets({
    required String accessToken,
    bool? isActive,
    String? category,
  }) async {
    final params = <String>[];
    if (isActive != null) params.add('is_active=$isActive');
    if (category != null && category.isNotEmpty) params.add('category=$category');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await _request(
      method: 'GET',
      path: '/budgets$query',
      accessToken: accessToken,
    );
    final rows = response['budgets'];
    if (rows is List) {
      return rows.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getBudgetById({
    required String accessToken,
    required String id,
  }) async {
    final response = await _request(
      method: 'GET',
      path: '/budgets/$id',
      accessToken: accessToken,
    );
    final row = response['budget'];
    if (row is Map) return row.cast<String, dynamic>();
    return {};
  }

  Future<Map<String, dynamic>> createBudget({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final response = await _request(
      method: 'POST',
      path: '/budgets',
      accessToken: accessToken,
      body: body,
    );
    final row = response['budget'];
    if (row is Map) return row.cast<String, dynamic>();
    return {};
  }

  Future<Map<String, dynamic>> updateBudget({
    required String accessToken,
    required String id,
    required Map<String, dynamic> body,
  }) async {
    final response = await _request(
      method: 'PUT',
      path: '/budgets/$id',
      accessToken: accessToken,
      body: body,
    );
    final row = response['budget'];
    if (row is Map) return row.cast<String, dynamic>();
    return {};
  }

  Future<void> deleteBudget({
    required String accessToken,
    required String id,
  }) async {
    await _request(
      method: 'DELETE',
      path: '/budgets/$id',
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
