import 'dart:convert';

import 'package:hervest_ai/core/network/api_config.dart';
import 'package:http/http.dart' as http;

class AlertsApiService {
  const AlertsApiService();

  Future<Map<String, dynamic>> getAlerts({
    required String accessToken,
  }) async {
    return _get('/alerts', accessToken: accessToken);
  }

  Future<Map<String, dynamic>> markAlertRead({
    required String accessToken,
    required String alertId,
  }) async {
    return _put('/alerts/$alertId/read', accessToken: accessToken);
  }

  Future<Map<String, dynamic>> resolveAlert({
    required String accessToken,
    required String alertId,
  }) async {
    return _put('/alerts/$alertId/resolve', accessToken: accessToken);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    required String accessToken,
  }) async {
    final primary = ApiConfig.apiUri(path);
    final fallback = ApiConfig.uri(path);
    return _request(
      method: 'GET',
      primaryUri: primary,
      fallbackUri: fallback,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }

  Future<Map<String, dynamic>> _put(
    String path, {
    required String accessToken,
  }) async {
    final primary = ApiConfig.apiUri(path);
    final fallback = ApiConfig.uri(path);
    return _request(
      method: 'PUT',
      primaryUri: primary,
      fallbackUri: fallback,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required Uri primaryUri,
    required Uri fallbackUri,
    required Map<String, String> headers,
  }) async {
    http.Response response = await _send(
      method: method,
      uri: primaryUri,
      headers: headers,
    );
    var jsonBody = _decode(response.body);

    if (response.statusCode == 404 && _isRouteNotFound(jsonBody)) {
      response = await _send(
        method: method,
        uri: fallbackUri,
        headers: headers,
      );
      jsonBody = _decode(response.body);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    throw Exception(
      (jsonBody['error'] ?? jsonBody['message'] ?? 'Request failed').toString(),
    );
  }

  Future<http.Response> _send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
  }) async {
    if (method == 'GET') {
      return http.get(uri, headers: headers).timeout(const Duration(seconds: 12));
    }
    return http.put(uri, headers: headers).timeout(const Duration(seconds: 12));
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
