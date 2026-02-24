import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hervest_ai/core/network/api_config.dart';

class AuthApiException implements Exception {
  AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthSession {
  AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;
}

class AuthApiService {
  const AuthApiService();

  Future<String> signUp({
    required String email,
    required String password,
    required String fullName,
    required String businessType,
    required String businessName,
    required String role,
  }) async {
    final response = await _post(
      '/auth/signup',
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'business_type': businessType,
        'business_name': businessName,
        'role': role,
      },
    );
    return (response['message'] ?? 'Verification code sent.').toString();
  }

  Future<AuthSession> verifySignUp({
    required String email,
    required String otp,
  }) async {
    final response = await _post(
      '/auth/signup/verify',
      body: {'email': email, 'otp': otp},
    );
    return AuthSession(
      accessToken: (response['access_token'] ?? '').toString(),
      refreshToken: (response['refresh_token'] ?? '').toString(),
      user: Map<String, dynamic>.from(response['user'] ?? {}),
    );
  }

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      '/auth/signin',
      body: {'email': email, 'password': password},
    );
    return AuthSession(
      accessToken: (response['access_token'] ?? '').toString(),
      refreshToken: (response['refresh_token'] ?? '').toString(),
      user: Map<String, dynamic>.from(response['user'] ?? {}),
    );
  }

  Future<void> sendPasswordResetOtp({required String email}) async {
    try {
      await _post('/auth/password/reset', body: {'email': email});
    } on AuthApiException catch (e) {
      if (e.statusCode == 404) {
        await _post('/password/reset', body: {'email': email});
        return;
      }
      rethrow;
    }
  }

  Future<void> verifyOtpAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final body = {
      'email': email,
      'otp': otp,
      'new_password': newPassword,
    };
    try {
      await _post('/auth/password/verify', body: body);
    } on AuthApiException catch (e) {
      if (e.statusCode == 404) {
        await _post('/password/verify', body: body);
        return;
      }
      rethrow;
    }
  }

  Future<void> signOut({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _post(
      '/auth/signout',
      body: {
        if (refreshToken != null && refreshToken.isNotEmpty)
          'refreshToken': refreshToken,
      },
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
  }

  Future<Map<String, dynamic>> getProfile({
    required String accessToken,
  }) async {
    final response = await _get(
      '/auth/profile',
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    final user = response['user'];
    if (user is Map) return user.cast<String, dynamic>();
    return {};
  }

  Future<Map<String, dynamic>> updateProfile({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final response = await _put(
      '/auth/profile',
      body: body,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    final user = response['user'];
    if (user is Map) return user.cast<String, dynamic>();
    return {};
  }

  Future<AuthSession> refreshSession({
    required String refreshToken,
  }) async {
    final response = await _post(
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
    );
    return AuthSession(
      accessToken: (response['access_token'] ?? '').toString(),
      refreshToken: (response['refresh_token'] ?? '').toString(),
      user: const <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    http.Response response;
    Map<String, dynamic> jsonBody;
    try {
      // Primary target: /api/... routes.
      final uri = ApiConfig.apiUri(path);
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ...?headers,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      throw AuthApiException(
        'Unable to reach server. Check connection and backend URL.',
      );
    }

    jsonBody = _decodeToMap(response.body);
    // Fallback target: root-mounted routes (/auth/...) when /api is not used.
    if (response.statusCode == 404 && _isRouteNotFound(jsonBody)) {
      try {
        final fallbackUri = ApiConfig.uri(path);
        response = await http
            .post(
              fallbackUri,
              headers: {
                'Content-Type': 'application/json',
                ...?headers,
              },
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 12));
        jsonBody = _decodeToMap(response.body);
      } catch (_) {
        // Preserve original failure handling below.
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    final message = (jsonBody['error'] ??
            jsonBody['message'] ??
            'Request failed (${response.statusCode})')
        .toString();
    throw AuthApiException(message, statusCode: response.statusCode);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? headers,
  }) async {
    return _requestWithoutBody(
      method: 'GET',
      path: path,
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> _put(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    return _requestWithBody(
      method: 'PUT',
      path: path,
      body: body,
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> _requestWithBody({
    required String method,
    required String path,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    http.Response response;
    Map<String, dynamic> jsonBody;

    try {
      response = await _sendWithBody(
        method: method,
        uri: ApiConfig.apiUri(path),
        headers: headers,
        body: body,
      );
    } catch (_) {
      throw AuthApiException(
        'Unable to reach server. Check connection and backend URL.',
      );
    }

    jsonBody = _decodeToMap(response.body);
    if (response.statusCode == 404 && _isRouteNotFound(jsonBody)) {
      try {
        response = await _sendWithBody(
          method: method,
          uri: ApiConfig.uri(path),
          headers: headers,
          body: body,
        );
        jsonBody = _decodeToMap(response.body);
      } catch (_) {
        // Preserve original failure handling below.
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    final message = (jsonBody['error'] ??
            jsonBody['message'] ??
            'Request failed (${response.statusCode})')
        .toString();
    throw AuthApiException(message, statusCode: response.statusCode);
  }

  Future<Map<String, dynamic>> _requestWithoutBody({
    required String method,
    required String path,
    Map<String, String>? headers,
  }) async {
    http.Response response;
    Map<String, dynamic> jsonBody;

    try {
      response = await _sendWithoutBody(
        method: method,
        uri: ApiConfig.apiUri(path),
        headers: headers,
      );
    } catch (_) {
      throw AuthApiException(
        'Unable to reach server. Check connection and backend URL.',
      );
    }

    jsonBody = _decodeToMap(response.body);
    if (response.statusCode == 404 && _isRouteNotFound(jsonBody)) {
      try {
        response = await _sendWithoutBody(
          method: method,
          uri: ApiConfig.uri(path),
          headers: headers,
        );
        jsonBody = _decodeToMap(response.body);
      } catch (_) {
        // Preserve original failure handling below.
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    final message = (jsonBody['error'] ??
            jsonBody['message'] ??
            'Request failed (${response.statusCode})')
        .toString();
    throw AuthApiException(message, statusCode: response.statusCode);
  }

  Future<http.Response> _sendWithBody({
    required String method,
    required Uri uri,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final requestHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };
    if (method == 'PUT') {
      return http
          .put(uri, headers: requestHeaders, body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));
    }
    return http
        .post(uri, headers: requestHeaders, body: jsonEncode(body))
        .timeout(const Duration(seconds: 12));
  }

  Future<http.Response> _sendWithoutBody({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
  }) async {
    final requestHeaders = {...?headers};
    if (method == 'GET') {
      return http.get(uri, headers: requestHeaders).timeout(const Duration(seconds: 12));
    }
    return http
        .post(uri, headers: requestHeaders)
        .timeout(const Duration(seconds: 12));
  }

  bool _isRouteNotFound(Map<String, dynamic> jsonBody) {
    final message = (jsonBody['error'] ?? jsonBody['message'] ?? '')
        .toString()
        .toLowerCase();
    return message.contains('route') && message.contains('not found');
  }

  Map<String, dynamic> _decodeToMap(String body) {
    if (body.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }
}
