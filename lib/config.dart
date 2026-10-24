class AppConfig {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://151.80.60.71:3000');

  static String? media(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '$apiUrl$path';
  }
}
