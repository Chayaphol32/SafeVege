import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safevege/state/app_state.dart';
import 'package:safevege/screens/admin/admin_login_screen.dart';

void main() {
  testWidgets('admin login does not expose OTP recovery', (tester) async {
    final state = AppState();
    await tester.pumpWidget(
      MaterialApp(home: AdminLoginScreen(appState: state)),
    );

    expect(find.text('ลืมรหัสผ่าน?'), findsNothing);
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
  });
}
