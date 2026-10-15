/// Resolves the SafeVege API URL for a shared Flutter client.
///
/// Release apps must provide the same reachable backend with
/// `--dart-define=API_BASE_URL=...`. Local defaults are only for development.
String resolveApiBaseUrl({
  required String configuredUrl,
  required bool isWeb,
  required bool isAndroid,
  required bool isRelease,
}) {
  final configured = configuredUrl.trim();
  if (configured.isNotEmpty) return configured;

  if (isRelease) {
    throw StateError(
      'Set API_BASE_URL with --dart-define when building SafeVege for release.',
    );
  }

  final host = !isWeb && isAndroid ? '10.0.2.2' : '127.0.0.1';
  return 'http://$host:8081/api/v1';
}
