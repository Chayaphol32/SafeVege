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

  test('localizes error message when deleting shop with inspection history', () {
    expect(
      AppState.localizeErrorMessage('Shop with inspection history cannot be deleted'),
      'ไม่สามารถลบร้านค้าที่มีประวัติการตรวจได้ (เฉพาะ Super Admin เท่านั้น)',
    );
  });

  test('deleteShop calls DELETE /admin/shops/{id} and removes shop from state', () async {
    bool deleteCalled = false;
    final api = ApiClient(
      baseUrl: 'http://localhost/api/v1',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'token': 'super-token',
                'user': {
                  'id': 1,
                  'username': 'superadmin',
                  'display_name': 'Super Admin',
                  'role': 'super_admin',
                  'is_active': 1,
                },
              }),
            ),
            200,
          );
        }
        if (request.url.path.endsWith('/admin/shops') && request.method == 'GET') {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'data': [
                  {
                    'id': 17,
                    'name': 'ร้านทดสอบ',
                    'owner_first_name': 'สมชาย',
                    'owner_last_name': 'ใจดี',
                    'phone': '0812345678',
                    'house_number': '123',
                    'subdistrict': 'เวียง',
                    'district': 'เมือง',
                    'province': 'เชียงราย',
                    'latitude': 19.9,
                    'longitude': 99.8,
                    'is_public': 1,
                    'created_at': '2026-10-10 12:00:00',
                    'verified_vegetables': [],
                  }
                ]
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.endsWith('/admin/requests')) {
          return http.Response('{"data":[]}', 200);
        }
        if (request.url.path.endsWith('/admin/shops/17') && request.method == 'DELETE') {
          deleteCalled = true;
          return http.Response(jsonEncode({'message': 'Shop deleted'}), 200);
        }
        throw StateError('Unexpected request: ${request.method} ${request.url}');
      }),
    );

    final state = AppState(
      apiClient: api,
      sessionStore: MemorySessionStore(),
    );

    await state.loginAdmin('superadmin', 'password123456');
    expect(state.shops, hasLength(1));
    expect(state.shops.first.id, '17');

    await state.deleteShop('17');
    expect(deleteCalled, isTrue);
    expect(state.shops, isEmpty);
  });
}
