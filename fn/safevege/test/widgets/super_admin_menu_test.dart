import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safevege/data/api/api_client.dart';
import 'package:safevege/data/api/session_store.dart';
import 'package:safevege/screens/admin/super_admin_dashboard_screen.dart';
import 'package:safevege/state/app_state.dart';

AppState _stateForRole(String role) {
  final api = ApiClient(
    baseUrl: 'http://localhost/api/v1',
    httpClient: MockClient((request) async {
      if (request.url.path.endsWith('/auth/login')) {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'token': 'role-token',
              'user': {
                'id': 4,
                'username': 'role-user',
                'display_name': 'Role User',
                'role': role,
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
      throw StateError('Unexpected request: ${request.method} ${request.url}');
    }),
  );
  return AppState(apiClient: api, sessionStore: MemorySessionStore());
}

void main() {
  testWidgets('super admin sees the special management menu', (
    WidgetTester tester,
  ) async {
    final state = _stateForRole('super_admin');
    await state.loginAdmin('role-user', 'password');

    await tester.pumpWidget(
      MaterialApp(home: SuperAdminDashboardScreen(appState: state)),
    );
    await tester.pumpAndSettle();

    expect(find.text('เมนูผู้ดูแลระบบขั้นสูง'), findsOneWidget);
    expect(find.text('จัดการบัญชีผู้ใช้'), findsOneWidget);
    expect(find.text('ตั้งค่าระบบ'), findsOneWidget);
    expect(find.text('ประวัติการใช้งาน'), findsOneWidget);
  });

  testWidgets('inspector admin cannot open the special menu', (
    WidgetTester tester,
  ) async {
    final state = _stateForRole('admin');
    await state.loginAdmin('role-user', 'password');

    await tester.pumpWidget(
      MaterialApp(home: SuperAdminDashboardScreen(appState: state)),
    );
    await tester.pumpAndSettle();

    expect(find.text('ไม่มีสิทธิ์เข้าถึงเมนูนี้'), findsOneWidget);
    expect(find.text('จัดการบัญชีผู้ใช้'), findsNothing);
  });
}
