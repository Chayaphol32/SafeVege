import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safevege/data/api/api_client.dart';
import 'package:safevege/data/api/session_store.dart';
import 'package:safevege/models/app_models.dart';
import 'package:safevege/state/app_state.dart';

void main() {
  test(
    'admin login accepts a super admin and exposes the special role',
    () async {
      final api = ApiClient(
        baseUrl: 'http://localhost/api/v1',
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/auth/login')) {
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'token': 'super-token',
                  'user': {
                    'id': 4,
                    'username': 'root-admin',
                    'display_name': 'ผู้ดูแลระบบ',
                    'role': 'super_admin',
                    'is_active': 1,
                  },
                }),
              ),
              200,
            );
          }
          if (request.url.path.endsWith('/admin/shops') ||
              request.url.path.endsWith('/admin/requests')) {
            return http.Response('{"data":[]}', 200);
          }
          throw StateError(
            'Unexpected request: ${request.method} ${request.url}',
          );
        }),
      );
      final state = AppState(
        apiClient: api,
        sessionStore: MemorySessionStore(),
      );

      await state.loginAdmin('root-admin', 'super-password-123');

      expect(state.currentRole, UserRole.superAdmin);
      expect(state.isAdminLoggedIn, isTrue);
      expect(state.isSuperAdmin, isTrue);
    },
  );

  test(
    'returns stable Super Admin collections when the API has empty settings',
    () async {
      final api = ApiClient(
        baseUrl: 'http://localhost/api/v1',
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/auth/login')) {
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'token': 'super-token',
                  'user': {
                    'id': 4,
                    'username': 'root-admin',
                    'display_name': 'ผู้ดูแลระบบ',
                    'role': 'super_admin',
                    'is_active': 1,
                  },
                }),
              ),
              200,
            );
          }
          if (request.url.path.endsWith('/admin/shops') ||
              request.url.path.endsWith('/admin/requests')) {
            return http.Response('{"data":[]}', 200);
          }
          if (request.url.path.endsWith('/admin/users')) {
            return http.Response(
              '{"data":[{"id":4,"username":"root-admin","display_name":"Root Admin","role":"super_admin","is_active":1}]}',
              200,
            );
          }
          if (request.url.path.endsWith('/admin/settings')) {
            return http.Response('{"data":[]}', 200);
          }
          if (request.url.path.endsWith('/admin/audit')) {
            return http.Response(
              '{"data":[{"id":1,"actor_user_id":4,"actor_username":"root-admin","entity_type":"user","entity_id":4,"action":"created","details":"{}"}]}',
              200,
            );
          }
          throw StateError(
            'Unexpected request: ${request.method} ${request.url}',
          );
        }),
      );
      final state = AppState(
        apiClient: api,
        sessionStore: MemorySessionStore(),
      );

      await state.loginAdmin('root-admin', 'super-password-123');

      final users = await state.loadAdminUsers();
      final settings = await state.loadAdminSettings();
      final audit = await state.loadAuditEvents();

      expect(users, hasLength(1));
      expect(users.single.username, 'root-admin');
      expect(settings, isEmpty);
      expect(audit, hasLength(1));
      expect(audit.single.action, 'created');
    },
  );
}
