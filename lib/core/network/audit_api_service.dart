import 'dart:convert';

import 'package:hervest_ai/core/network/api_config.dart';
import 'package:hervest_ai/models/api_response_models.dart';
import 'package:http/http.dart' as http;

class AuditApiService {
  const AuditApiService();

  Future<List<AuditLog>> getAuditLogs({
    required String accessToken,
  }) async {
    final response = await _request(
      path: '/audit-logs',
      accessToken: accessToken,
    );
    final rows = response['audit_logs'];
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map((e) => AuditLog.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> _request({
    required String path,
    required String accessToken,
  }) async {
    final primary = ApiConfig.apiUri(path);
    final fallback = ApiConfig.uri(path);
    http.Response response = await http
        .get(primary, headers: {'Authorization': 'Bearer $accessToken'})
        .timeout(const Duration(seconds: 12));
    var jsonBody = _decode(response.body);

    if (response.statusCode == 404 && _isRouteNotFound(jsonBody)) {
      response = await http
          .get(fallback, headers: {'Authorization': 'Bearer $accessToken'})
          .timeout(const Duration(seconds: 12));
      jsonBody = _decode(response.body);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return jsonBody;
    throw Exception(
      (jsonBody['error'] ?? jsonBody['message'] ?? 'Request failed').toString(),
    );
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
