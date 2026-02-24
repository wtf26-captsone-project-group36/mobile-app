import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hervest_ai/core/network/api_config.dart';

class ApiHealthResult {
  const ApiHealthResult({
    required this.ok,
    required this.statusCode,
    required this.endpointTried,
    this.payload,
    this.error,
  });

  final bool ok;
  final int? statusCode;
  final String endpointTried;
  final Map<String, dynamic>? payload;
  final String? error;
}

class ApiHealthService {
  const ApiHealthService();

  Future<ApiHealthResult> check() async {
    final apiHealth = ApiConfig.apiUri('/');
    final rootHealth = ApiConfig.uri('/');

    try {
      final apiResponse = await http.get(apiHealth).timeout(
        const Duration(seconds: 8),
      );
      if (apiResponse.statusCode == 200) {
        return ApiHealthResult(
          ok: true,
          statusCode: apiResponse.statusCode,
          endpointTried: apiHealth.toString(),
          payload: _tryDecode(apiResponse.body),
        );
      }
    } catch (_) {
      // Try fallback below.
    }

    try {
      final fallbackResponse = await http.get(rootHealth).timeout(
        const Duration(seconds: 8),
      );
      return ApiHealthResult(
        ok: fallbackResponse.statusCode == 200,
        statusCode: fallbackResponse.statusCode,
        endpointTried: rootHealth.toString(),
        payload: _tryDecode(fallbackResponse.body),
      );
    } catch (e) {
      return ApiHealthResult(
        ok: false,
        statusCode: null,
        endpointTried: rootHealth.toString(),
        error: e.toString(),
      );
    }
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }
}
