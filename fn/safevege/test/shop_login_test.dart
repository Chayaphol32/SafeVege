import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safevege/data/api/api_client.dart';
import 'package:safevege/data/api/session_store.dart';
import 'package:safevege/screens/shop/shop_login_screen.dart';
import 'package:safevege/state/app_state.dart';

void main() {
  testWidgets(
    'shows inline banner and highlights password field without modal popup when password is wrong',
    (WidgetTester tester) async {
      final appState = AppState(
        apiClient: ApiClient(
          baseUrl: 'http://localhost/api/v1',
          httpClient: MockClient((request) async {
            if (request.url.path.contains('/auth/login')) {
              return http.Response(
                jsonEncode({'error': 'Invalid credentials'}),
                401,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }
            return http.Response('{}', 200);
          }),
        ),
        sessionStore: MemorySessionStore(),
      );
      addTearDown(appState.dispose);

      await tester.pumpWidget(
        MaterialApp(home: ShopLoginScreen(appState: appState)),
      );
      await tester.pumpAndSettle();

      // Fill in credentials
      await tester.enterText(
        find.widgetWithText(TextField, 'ชื่อผู้ใช้'),
        'chayaphol',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'รหัสผ่าน'),
        'wrongpassword',
      );

      // Tap login button
      await tester.tap(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
      await tester.pumpAndSettle();

      // 1. NO AlertDialog modal popup should be shown
      expect(find.byType(AlertDialog), findsNothing);

      // 2. In-card error banner and password error text are displayed immediately
      expect(
        find.text('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง'),
        findsWidgets, // in card banner and SnackBar
      );
      expect(find.text('รหัสผ่านไม่ถูกต้อง'), findsOneWidget);

      // 3. User modifies password -> error clears automatically
      await tester.enterText(
        find.widgetWithText(TextField, 'รหัสผ่าน'),
        'newattempt',
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(find.text('รหัสผ่านไม่ถูกต้อง'), findsNothing);
      expect(
        find.text('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง'),
        findsNothing,
      );
    },
  );
}
