import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safevege/data/api/api_client.dart';
import 'package:safevege/data/repositories/safevege_repository.dart';
import 'package:safevege/models/app_models.dart';

void main() {
  test('creates an inspector admin with the server role value', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost/api/v1',
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/admin/users');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['role'], 'admin');
        expect(body['password'], 'inspector-password-123');
        return http.Response(
          '{"id":9,"username":"inspector","role":"admin","is_active":1}',
          201,
        );
      }),
    )..accessToken = 'super-token';

    final user = await SafeVegeRepository(api: api).createAdminUser(
      username: 'inspector',
      displayName: 'Inspector',
      password: 'inspector-password-123',
      role: UserRole.admin,
    );

    expect(user.role, UserRole.admin);
  });
}
