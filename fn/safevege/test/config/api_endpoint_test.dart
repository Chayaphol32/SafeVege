import 'package:flutter_test/flutter_test.dart';
import 'package:safevege/config/api_endpoint.dart';

void main() {
  test('web development points to the host API', () {
    expect(
      resolveApiBaseUrl(
        configuredUrl: '',
        isWeb: true,
        isAndroid: false,
        isRelease: false,
      ),
      'http://127.0.0.1:8081/api/v1',
    );
  });

  test('Android development points through the emulator host alias', () {
    expect(
      resolveApiBaseUrl(
        configuredUrl: '',
        isWeb: false,
        isAndroid: true,
        isRelease: false,
      ),
      'http://10.0.2.2:8081/api/v1',
    );
  });

  test('an explicit API URL is shared by every platform', () {
    expect(
      resolveApiBaseUrl(
        configuredUrl: ' https://api.safevege.example/api/v1 ',
        isWeb: true,
        isAndroid: false,
        isRelease: true,
      ),
      'https://api.safevege.example/api/v1',
    );
  });

  test('release builds require an API URL', () {
    expect(
      () => resolveApiBaseUrl(
        configuredUrl: '',
        isWeb: true,
        isAndroid: false,
        isRelease: true,
      ),
      throwsStateError,
    );
  });
}
