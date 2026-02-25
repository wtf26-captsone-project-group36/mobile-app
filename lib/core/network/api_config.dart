class ApiConfig {

  // Old Info Override with:
  // flutter run --dart-define=API_BASE_URL=http://your-server:3000

  
  /// **Production Configuration**
  /// To build for production with a clean database, run:
  /// `flutter build apk --dart-define=API_BASE_URL=https://api.hervest.ai`
  ///
  /// The default value below is for the **Development/Test** environment.
  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://18.175.213.46:3000',
  );

  static const String apiPrefix = '/api';
  static String get baseUrl => _normalizeBaseUrl(_rawBaseUrl);

  static Uri uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }

  static Uri apiUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final alreadyHasApi =
        baseUrl.toLowerCase().endsWith('/api') ||
        baseUrl.toLowerCase().endsWith('/api/');
    final apiBase = alreadyHasApi ? _trimTrailingSlash(baseUrl) : '$baseUrl$apiPrefix';
    return Uri.parse('$apiBase$normalizedPath');
  }

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static String _trimTrailingSlash(String url) {
    if (url.endsWith('/')) return url.substring(0, url.length - 1);
    return url;
  }
}
