import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safevege/data/api/api_client.dart';
import 'package:safevege/data/api/session_store.dart';
import 'package:safevege/screens/admin/admin_users_screen.dart';
import 'package:safevege/state/app_state.dart';

void main() {
  testWidgets('super admin accounts cannot be edited from user management', (
    WidgetTester tester,
  ) async {
    final appState = AppState(
      apiClient: ApiClient(
        baseUrl: 'http://localhost/api/v1',
        httpClient: MockClient((request) async {
          if (request.url.path.contains('/auth/login')) {
            return http.Response(
              jsonEncode({
                'token': 'mock-superadmin-token',
                'user': {
                  'id': '1',
                  'username': 'superadmin',
                  'role': 'super_admin',
                  'display_name': 'Super Administrator',
                  'is_active': true,
                },
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          if (request.url.path.endsWith('/admin/users') &&
              request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'data': [
                  {
                    'id': '1',
                    'username': 'superadmin',
                    'display_name': 'ผู้ดูแลสูงสุด',
                    'role': 'super_admin',
                    'is_active': 1,
                  },
                  {
                    'id': '2',
                    'username': 'second-superadmin',
                    'display_name': 'ผู้ดูแลสูงสุดสำรอง',
                    'role': 'super_admin',
                    'is_active': 1,
                  },
                  {
                    'id': '3',
                    'username': 'inspector1',
                    'display_name': 'นายตรวจ ผักดี',
                    'role': 'admin',
                    'is_active': 1,
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          return http.Response(
            '{"data":[]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      sessionStore: MemorySessionStore(),
    );
    addTearDown(appState.dispose);

    await appState.loginAdmin('superadmin', 'SuperAdminPass!2026');

    await tester.pumpWidget(
      MaterialApp(home: AdminUsersScreen(appState: appState)),
    );
    await tester.pumpAndSettle();

    final targetTile = find.ancestor(
      of: find.text('ผู้ดูแลสูงสุดสำรอง'),
      matching: find.byType(ListTile),
    );
    final targetKey = find.descendant(
      of: targetTile,
      matching: find.byType(IconButton),
    );
    final targetSwitch = find.descendant(
      of: targetTile,
      matching: find.byType(Switch),
    );

    expect(tester.widget<IconButton>(targetKey).onPressed, isNull);
    expect(tester.widget<Switch>(targetSwitch).onChanged, isNull);
  });

  testWidgets(
    'superadmin reset password requires username confirmation and succeeds without controller disposal crash',
    (WidgetTester tester) async {
      String? sentPassword;
      String? requestedUserId;

      final appState = AppState(
        apiClient: ApiClient(
          baseUrl: 'http://localhost/api/v1',
          httpClient: MockClient((request) async {
            if (request.url.path.contains('/auth/login')) {
              return http.Response(
                jsonEncode({
                  'token': 'mock-superadmin-token',
                  'user': {
                    'id': '1',
                    'username': 'superadmin',
                    'role': 'super_admin',
                    'display_name': 'Super Administrator',
                    'is_active': true,
                  },
                }),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }
            if (request.url.path.endsWith('/admin/users') &&
                request.method == 'GET') {
              return http.Response(
                jsonEncode({
                  'data': [
                    {
                      'id': '1',
                      'username': 'superadmin',
                      'display_name': 'ผู้ดูแลสูงสุด',
                      'role': 'super_admin',
                      'is_active': 1,
                      'created_at': '2026-01-01T00:00:00Z',
                    },
                    {
                      'id': '2',
                      'username': 'inspector1',
                      'display_name': 'นายตรวจ ผักดี',
                      'role': 'admin',
                      'is_active': 1,
                      'created_at': '2026-01-02T00:00:00Z',
                    },
                  ],
                }),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }
            if (request.url.path.contains('/admin/users/') &&
                request.url.path.endsWith('/password') &&
                request.method == 'POST') {
              final segments = request.url.pathSegments;
              requestedUserId = segments[segments.length - 2];
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              sentPassword = body['new_password'] as String?;
              return http.Response(
                jsonEncode({'message': 'Password updated'}),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }
            return http.Response('{"data":[]}', 200, headers: {'content-type': 'application/json'});
          }),
        ),
        sessionStore: MemorySessionStore(),
      );
      addTearDown(appState.dispose);

      // Log in as superadmin
      await appState.loginAdmin('superadmin', 'SuperAdminPass!2026');

      await tester.pumpWidget(
        MaterialApp(
          home: AdminUsersScreen(appState: appState),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure users are displayed
      expect(find.text('นายตรวจ ผักดี'), findsOneWidget);
      expect(find.textContaining('inspector1'), findsOneWidget);

      // Find the key button on inspector1's ListTile
      final keyIcons = find.byIcon(Icons.key_rounded);
      expect(keyIcons, findsWidgets);

      // Tap on the key icon for inspector1 (the second one, as first is superadmin and disabled)
      await tester.tap(keyIcons.last);
      await tester.pumpAndSettle();

      // Dialog is open
      expect(find.text('เปลี่ยนรหัสผ่าน inspector1'), findsOneWidget);
      expect(find.text('เพื่อยืนยัน กรุณาพิมพ์ชื่อผู้ใช้ "inspector1" อีกครั้ง'), findsOneWidget);

      // Enter new password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'รหัสผ่านใหม่'),
        'newPassword123!',
      );

      // Enter confirm password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ยืนยันรหัสผ่านใหม่อีกครั้ง'),
        'newPassword123!',
      );

      // Enter WRONG username to test confirmation requirement
      await tester.enterText(
        find.widgetWithText(TextFormField, 'พิมพ์ชื่อผู้ใช้ (inspector1) เพื่อยืนยัน'),
        'wrongUsername',
      );

      // Tap confirm button
      await tester.tap(find.widgetWithText(FilledButton, 'ยืนยันเปลี่ยนรหัสผ่าน'));
      await tester.pumpAndSettle();

      // Validation error should show and API NOT called
      expect(find.text('ชื่อผู้ใช้ไม่ตรงกัน กรุณาพิมพ์ "inspector1"'), findsOneWidget);
      expect(sentPassword, isNull);

      // Now enter the CORRECT username to confirm
      await tester.enterText(
        find.widgetWithText(TextFormField, 'พิมพ์ชื่อผู้ใช้ (inspector1) เพื่อยืนยัน'),
        'inspector1',
      );

      // Tap confirm button again
      await tester.tap(find.widgetWithText(FilledButton, 'ยืนยันเปลี่ยนรหัสผ่าน'));
      await tester.pumpAndSettle();

      // Verify API was called with the correct user and password
      expect(requestedUserId, '2');
      expect(sentPassword, 'newPassword123!');

      // Verify dialog dismissed and no crash (no TextEditingController disposed assertion)
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('เปลี่ยนรหัสผ่านให้ inspector1 สำเร็จแล้ว'), findsOneWidget);
    },
  );
}
