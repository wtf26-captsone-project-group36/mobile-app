import 'dart:convert';

import 'package:hervest_ai/core/network/api_config.dart';
import 'package:http/http.dart' as http;

class ActivityApiService {
  const ActivityApiService();

  Future<List<Map<String, dynamic>>> getActivities({
    required String accessToken,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _get(
      '/activity?limit=$limit&offset=$offset',
      accessToken: accessToken,
    );
    final rows = response['activities'];
    if (rows is List) {
      return rows.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return [];
  }

  Future<void> insertActivity({
    required String accessToken,
    required String action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {
    await _post(
      '/activity',
      accessToken: accessToken,
      body: {
        'action': action,
        if (entityType != null && entityType.isNotEmpty) 'entity_type': entityType,
        if (entityId != null && entityId.isNotEmpty) 'entity_id': entityId,
        if (details != null && details.isNotEmpty) 'details': details,
      },
    );
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    required String accessToken,
  }) async {
    final primary = ApiConfig.apiUri(path);
    final fallback = ApiConfig.uri(path);
    return _requestGet(
      primaryUri: primary,
      fallbackUri: fallback,
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
      primaryUri: primary,
      fallbackUri: fallback,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  Future<Map<String, dynamic>> _requestGet({
    required Uri primaryUri,
    required Uri fallbackUri,
    required Map<String, String> headers,
  }) async {
    http.Response response = await http
        .get(primaryUri, headers: headers)
        .timeout(const Duration(seconds: 12));
    var jsonBody = _decode(response.body);

    if (response.statusCode == 404 && _isRouteNotFound(jsonBody)) {
      response = await http
          .get(fallbackUri, headers: headers)
          .timeout(const Duration(seconds: 12));
      jsonBody = _decode(response.body);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    throw Exception(
      (jsonBody['error'] ?? jsonBody['message'] ?? 'Request failed').toString(),
    );
  }

  Future<Map<String, dynamic>> _request({
    required Uri primaryUri,
    required Uri fallbackUri,
    required Map<String, String> headers,
    required String body,
  }) async {
    http.Response response = await http
        .post(primaryUri, headers: headers, body: body)
        .timeout(const Duration(seconds: 12));
    var jsonBody = _decode(response.body);

    if (response.statusCode == 404 && _isRouteNotFound(jsonBody)) {
      response = await http
          .post(fallbackUri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
      jsonBody = _decode(response.body);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

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
