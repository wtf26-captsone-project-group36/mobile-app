import 'dart:convert';

import 'package:hervest_ai/core/network/api_config.dart';
import 'package:http/http.dart' as http;

class PredictionsApiService {
  const PredictionsApiService();

  Future<Map<String, dynamic>> getLatestPredictions({
    required String accessToken,
  }) async {
    return _get('/predictions', accessToken: accessToken);
  }

  Future<List<Map<String, dynamic>>> getAnomalies({
    required String accessToken,
  }) async {
    final response = await _get('/predictions/anomalies', accessToken: accessToken);
    final anomalies = response['anomalies'];
    if (anomalies is List) {
      return anomalies.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> insertCashflowPrediction({
    required String businessId,
    required String riskLevel,
    required int daysUntilBroke,
    required double confidenceScore,
  }) async {
    final response = await _post(
      '/predictions/cashflow',
      body: {
        'business_id': businessId,
        'risk_level': riskLevel,
        'days_until_broke': daysUntilBroke,
        'confidence_score': confidenceScore,
      },
    );
    final prediction = response['prediction'];
    if (prediction is Map) return prediction.cast<String, dynamic>();
    return {};
  }

  Future<Map<String, dynamic>> insertInventoryPrediction({
    required String businessId,
    required int criticalItems,
    required int warningItems,
    required double totalValueAtRisk,
  }) async {
    final response = await _post(
      '/predictions/inventory',
      body: {
        'business_id': businessId,
        'critical_items': criticalItems,
        'warning_items': warningItems,
        'total_value_at_risk': totalValueAtRisk,
      },
    );
    final prediction = response['prediction'];
    if (prediction is Map) return prediction.cast<String, dynamic>();
    return {};
  }

  Future<Map<String, dynamic>> insertAnomaly({
    required String transactionId,
    required String anomalyLevel,
    required double zScore,
    required double deviationPercentage,
  }) async {
    final response = await _post(
      '/predictions/anomalies',
      body: {
        'transaction_id': transactionId,
        'anomaly_level': anomalyLevel,
        'z_score': zScore,
        'deviation_percentage': deviationPercentage,
      },
    );
    final anomaly = response['anomaly'];
    if (anomaly is Map) return anomaly.cast<String, dynamic>();
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
    required Map<String, dynamic> body,
  }) async {
    final primary = ApiConfig.apiUri(path);
    final fallback = ApiConfig.uri(path);
    return _request(
      method: 'POST',
      primaryUri: primary,
      fallbackUri: fallback,
      headers: {'Content-Type': 'application/json'},
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
