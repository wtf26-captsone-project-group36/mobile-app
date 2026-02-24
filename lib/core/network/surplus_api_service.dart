import 'dart:convert';

import 'package:hervest_ai/core/network/api_config.dart';
import 'package:http/http.dart' as http;

class SurplusApiService {
  const SurplusApiService();

  Future<List<Map<String, dynamic>>> getAvailableSurplus({
    required String accessToken,
  }) async {
    final response = await _get('/surplus', accessToken: accessToken);
    final rows = response['surplus'];
    if (rows is List) {
      return rows.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getMySurplus({
    required String accessToken,
  }) async {
    final response = await _get('/surplus/mine', accessToken: accessToken);
    final rows = response['surplus'];
    if (rows is List) {
      return rows.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createSurplus({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final response = await _post('/surplus', accessToken: accessToken, body: body);
    final row = response['surplus'];
    if (row is Map) return row.cast<String, dynamic>();
    return {};
  }

  Future<Map<String, dynamic>> claimSurplus({
    required String accessToken,
    required String id,
  }) async {
    final response = await _put('/surplus/$id/claim', accessToken: accessToken);
    final row = response['surplus'];
    if (row is Map) return row.cast<String, dynamic>();
    return {};
  }

  Future<Map<String, dynamic>> updateSurplusStatus({
    required String accessToken,
    required String id,
    required String status,
  }) async {
    final response = await _put(
      '/surplus/$id/status',
      accessToken: accessToken,
      body: {'status': status},
    );
    final row = response['surplus'];
    if (row is Map) return row.cast<String, dynamic>();
    return {};
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

  Future<Map<String, dynamic>> _put(
    String path, {
    required String accessToken,
    Map<String, dynamic>? body,
  }) async {
    final primary = ApiConfig.apiUri(path);
    final fallback = ApiConfig.uri(path);
    return _request(
      method: 'PUT',
      primaryUri: primary,
      fallbackUri: fallback,
      headers: {
        'Authorization': 'Bearer $accessToken',
        if (body != null) 'Content-Type': 'application/json',
      },
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required Uri primaryUri,
    required Uri fallbackUri,
    required Map<String, String> headers,
    String? body,
  }) async {
    http.Response response = await _send(
      method: method,
      uri: primaryUri,
      headers: headers,
      body: body,
    );
    var jsonBody = _decode(response.body);

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

    throw Exception(
      (jsonBody['error'] ?? jsonBody['message'] ?? 'Request failed').toString(),
    );
  }

  Future<http.Response> _send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    if (method == 'GET') {
      return http.get(uri, headers: headers).timeout(const Duration(seconds: 12));
    }
    if (method == 'PUT') {
      return http
          .put(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
    }
    return http
        .post(uri, headers: headers, body: body)
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
