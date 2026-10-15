import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safevege/data/api/api_client.dart';

void main() {
  test(
    'joins the configured API prefix and sends bearer auth on GET',
    () async {
      http.Request? captured;
      final client = ApiClient(
        baseUrl: 'http://localhost:8081/api/v1/',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('{"data":[]}', 200);
        }),
      )..accessToken = 'session-token';

      final response = await client.getJson(
        '/shops',
        queryParameters: const {'q': 'ผัก กาด'},
      );

      expect(captured!.url.path, '/api/v1/shops');
      expect(captured!.url.queryParameters['q'], 'ผัก กาด');
      expect(captured!.headers['authorization'], 'Bearer session-token');
      expect(response['data'], isEmpty);
    },
  );

  test('encodes JSON request bodies without adding credentials', () async {
    http.Request? captured;
    final client = ApiClient(
      baseUrl: 'http://localhost:8081/api/v1',
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response('{"token":"issued-token"}', 200);
      }),
    );

    await client.postJson('/auth/login', const {
      'username': 'shop-user',
      'password': 'private-password',
    });

    expect(captured!.url.path, '/api/v1/auth/login');
    expect(captured!.headers['content-type'], contains('application/json'));
    expect(jsonDecode(captured!.body), {
      'username': 'shop-user',
      'password': 'private-password',
    });
    expect(captured!.headers.containsKey('authorization'), isFalse);
  });

  test('turns the API error envelope into a useful exception', () async {
    final client = ApiClient(
      baseUrl: 'http://localhost:8081/api/v1',
      httpClient: MockClient((_) async {
        return http.Response(
          '{"error":"radius_km must be 1 to 100"}',
          422,
          headers: const {'content-type': 'application/json'},
        );
      }),
    );

    await expectLater(
      client.getJson('/shops'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 422)
            .having(
              (error) => error.message,
              'message',
              'radius_km must be 1 to 100',
            ),
      ),
    );
  });
}
