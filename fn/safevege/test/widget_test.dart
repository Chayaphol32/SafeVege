import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safevege/data/api/api_client.dart';
import 'package:safevege/data/api/session_store.dart';
import 'package:safevege/main.dart';
import 'package:safevege/models/app_models.dart';
import 'package:safevege/screens/admin/admin_dashboard_screen.dart';
import 'package:safevege/screens/admin/record_result_screen.dart';
import 'package:safevege/screens/main_navigation_screen.dart';
import 'package:safevege/state/app_state.dart';

AppState _emptyApiState() => AppState(
  apiClient: ApiClient(
    baseUrl: 'http://localhost/api/v1',
    httpClient: MockClient(
      (_) async => http.Response.bytes(utf8.encode('{"data":[]}'), 200),
    ),
  ),
  sessionStore: MemorySessionStore(),
);

void main() {
  testWidgets(
    'guest screens use API data and show empty states without samples',
    (WidgetTester tester) async {
      final appState = _emptyApiState();
      await tester.pumpWidget(SafeVegeApp(appState: appState));
      await tester.pumpAndSettle();

      expect(find.text('ค้นหาร้าน ผัก หรือพื้นที่...'), findsOneWidget);
      expect(find.text('สวนผักบ้านดอย ออร์แกนิก'), findsNothing);
      expect(find.textContaining('ข้อมูลตัวอย่าง'), findsNothing);
      expect(find.text('หน้าหลัก'), findsOneWidget);
      expect(find.text('แผนที่'), findsOneWidget);
      expect(find.text('บัญชี'), findsOneWidget);

      await tester.tap(find.text('หน้าหลัก'));
      await tester.pumpAndSettle();
      expect(find.text('ผักปลอดภัย มั่นใจทุกมื้อ'), findsOneWidget);
      expect(find.text('ตรวจสอบสถานะการรับรองก่อนเลือกซื้อ'), findsOneWidget);
    },
  );

  testWidgets(
    'navigation opens the API certificate directory and account tab',
    (WidgetTester tester) async {
      await tester.pumpWidget(SafeVegeApp(appState: _emptyApiState()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('หน้าหลัก'));
      await tester.pumpAndSettle();
      final trustBanner = find.text('ตรวจสอบสถานะการรับรองก่อนเลือกซื้อ');
      await tester.tap(trustBanner);
      await tester.pumpAndSettle();
      expect(find.text('ผลตรวจและใบรับรอง'), findsOneWidget);
      expect(find.text('ยังไม่มีใบรับรองที่เผยแพร่'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('บัญชี'));
      await tester.pumpAndSettle();
      expect(find.text('บัญชีและร้านค้า'), findsOneWidget);
      expect(find.text('สำหรับเกษตรกรและร้านค้า'), findsOneWidget);
    },
  );

  testWidgets(
    'certificate navigation does not show a badge when the directory is empty',
    (WidgetTester tester) async {
      final appState = _emptyApiState();
      addTearDown(appState.dispose);

      await tester.pumpWidget(
        MaterialApp(home: MainNavigationScreen(appState: appState)),
      );
      await tester.pumpAndSettle();

      final visibleBadges = tester
          .widgetList<Badge>(find.byType(Badge))
          .where((badge) => badge.isLabelVisible)
          .toList();

      expect(visibleBadges, isEmpty);
      expect(find.text('2'), findsNothing);
    },
  );

  testWidgets('shop login has blank credentials and no demo access', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(SafeVegeApp(appState: _emptyApiState()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('บัญชี'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('เข้าสู่ระบบร้านค้า'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ยังไม่เชื่อมระบบบัญชี'), findsNothing);
    expect(find.textContaining('เข้าใช้ตัวอย่าง'), findsNothing);
    final usernameField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'ชื่อผู้ใช้',
      ),
    );
    expect(usernameField.controller?.text, isEmpty);
  });

  testWidgets(
    'admin result entry starts without assumed outcomes or certificate',
    (WidgetTester tester) async {
      final appState = _emptyApiState();
      final request = InspectionRequestModel(
        id: '18',
        requestNumber: 'SV-20261011-ABCD',
        shopId: '7',
        shopName: 'สวนผักจริง',
        vegetables: const ['คะน้า', 'ผักบุ้ง'],
        status: RequestStatus.scheduled,
        submissionDate: DateTime(2026, 10, 10),
        results: [
          VegetableInspection(name: 'คะน้า', requestItemId: 81),
          VegetableInspection(name: 'ผักบุ้ง', requestItemId: 82),
        ],
        shopAddress: 'เชียงราย',
        latitude: 19.91,
        longitude: 99.83,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecordResultScreen(request: request, appState: appState),
        ),
      );
      await tester.pumpAndSettle();

      final outcomeButtons = tester.widgetList<SegmentedButton<String>>(
        find.byType(SegmentedButton<String>),
      );
      expect(outcomeButtons, isNotEmpty);
      expect(outcomeButtons.every((button) => button.selected.isEmpty), isTrue);

      await tester.scrollUntilVisible(
        find.text('บันทึกร่าง'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('บันทึกร่าง'), findsOneWidget);
      expect(find.textContaining('CERT_'), findsNothing);
    },
  );

  testWidgets('guest shell keeps the same bottom navigation on wide screens', (
    WidgetTester tester,
  ) async {
    final appState = _emptyApiState();
    addTearDown(appState.dispose);
    tester.view.devicePixelRatio = 1;
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigationScreen(appState: appState, initialIndex: 0),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin dashboard keeps bottom navigation on all screen widths', (
    WidgetTester tester,
  ) async {
    final appState = _emptyApiState();
    addTearDown(appState.dispose);
    tester.view.devicePixelRatio = 1;
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1200, 900)),
          child: AdminDashboardScreen(appState: appState),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('mobile-dashboard'),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: AdminDashboardScreen(appState: appState),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      MediaQuery.sizeOf(tester.element(find.byType(AdminDashboardScreen)))
          .width,
      390,
    );
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

}
