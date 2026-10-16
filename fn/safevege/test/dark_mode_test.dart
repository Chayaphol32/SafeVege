import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safevege/data/api/api_client.dart';
import 'package:safevege/data/api/session_store.dart';
import 'package:safevege/models/app_models.dart';
import 'package:safevege/screens/main_navigation_screen.dart';
import 'package:safevege/screens/guest/shop_details_screen.dart';
import 'package:safevege/screens/guest/certificate_viewer_screen.dart';
import 'package:safevege/screens/admin/admin_request_details_screen.dart';
import 'package:safevege/screens/admin/super_admin_dashboard_screen.dart';
import 'package:safevege/screens/shop/shop_dashboard_screen.dart';
import 'package:safevege/state/app_state.dart';
import 'package:safevege/theme/app_theme.dart';

AppState _superAdminApiState() => AppState(
  apiClient: ApiClient(
    baseUrl: 'http://localhost/api/v1',
    httpClient: MockClient(
      (request) async {
        if (request.url.path.contains('/auth/login') ||
            request.url.path.contains('/login')) {
          return http.Response(
            jsonEncode({
              'token': 'mock-superadmin-token',
              'user': {
                'id': 'superadmin-1',
                'username': 'superadmin',
                'role': 'super_admin',
                'display_name': 'Super Administrator',
                'is_active': true,
              }
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.contains('/admin/audit') ||
            request.url.path.contains('/audit')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'audit-1',
                  'action': 'LOGIN_SUCCESS',
                  'actor_user_id': 'superadmin-1',
                  'actor_username': 'superadmin',
                  'entity_type': 'session',
                  'entity_id': 'sess-1234',
                  'created_at': '2026-10-16T22:38:00.000Z',
                },
                {
                  'id': 'audit-2',
                  'action': 'APPROVE_REQUEST',
                  'actor_user_id': 'superadmin-1',
                  'actor_username': 'superadmin',
                  'entity_type': 'request',
                  'entity_id': 'req-9876',
                  'created_at': '2026-10-16T22:24:00.000Z',
                },
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.contains('/public/shops') ||
            request.url.path.contains('/shops') ||
            request.url.path.contains('/admin/shops')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'shop-1',
                  'name': 'ฟาร์มผักปลอดภัยแม่จัน',
                  'ownerFirstName': 'สมพล',
                  'ownerLastName': 'เกษตรมั่นคง',
                  'phone': '0812345678',
                  'houseNo': '88',
                  'subDistrict': 'ป่าตึง',
                  'district': 'แม่จัน',
                  'province': 'เชียงราย',
                  'latitude': 20.14,
                  'longitude': 99.85,
                  'isVerified': true,
                  'verifiedVegetables': ['ผักสลัด', 'คะน้า'],
                  'createdAt': '2025-01-01T00:00:00.000Z',
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.contains('/admin/users')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'u1',
                  'username': 'inspector1',
                  'displayName': 'ผู้ตรวจการ 1',
                  'role': 'admin',
                  'isActive': true,
                  'createdAt': '2026-01-01T00:00:00.000Z',
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.contains('/admin/settings')) {
          return http.Response(
            jsonEncode({
              'data': {'default_certificate_expiry_days': 30}
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          jsonEncode({'data': []}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      },
    ),
  ),
  sessionStore: MemorySessionStore(),
);

AppState _shopApiState() => AppState(
  apiClient: ApiClient(
    baseUrl: 'http://localhost/api/v1',
    httpClient: MockClient(
      (request) async {
        if (request.url.path.contains('/public/shops') ||
            request.url.path.contains('/shop/me') ||
            request.url.path.contains('/shops')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'shop-1',
                  'name': 'ฟาร์มผักปลอดภัยแม่จัน',
                  'ownerFirstName': 'สมพล',
                  'ownerLastName': 'เกษตรมั่นคง',
                  'phone': '0812345678',
                  'houseNo': '88',
                  'subDistrict': 'ป่าตึง',
                  'district': 'แม่จัน',
                  'province': 'เชียงราย',
                  'latitude': 20.14,
                  'longitude': 99.85,
                  'isVerified': true,
                  'verifiedVegetables': ['ผักสลัด', 'คะน้า'],
                  'createdAt': '2025-01-01T00:00:00.000Z',
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          jsonEncode({'data': []}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      },
    ),
  ),
  sessionStore: MemorySessionStore(),
);

void main() {
  testWidgets('Renders MainNavigationScreen in dark mode without crashing', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: MainNavigationScreen(appState: appState, initialIndex: 0),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Renders ShopDetailsScreen in light mode with new UX layout', (tester) async {
    final appState = AppState();
    final testShop = ShopModel(
      id: 'test-1',
      name: 'ตลาดผักปลอดภัยริมกก (DEMO)',
      ownerFirstName: 'สมชาย',
      ownerLastName: 'ใจดี',
      phone: '0810000102',
      houseNo: '12',
      road: 'ถนนริมกก',
      subDistrict: 'เวียง',
      district: 'เมืองเชียงราย',
      province: 'เชียงราย',
      latitude: 19.91,
      longitude: 99.83,
      isVerified: true,
      verifiedVegetables: ['มะเขือเทศ', 'ผักกาดหอม'],
      createdAt: DateTime(2025, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ShopDetailsScreen(shop: testShop, appState: appState),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ShopDetailsScreen), findsOneWidget);
    expect(find.text('รายละเอียดร้านค้า'), findsOneWidget);
    expect(find.text('การรับรองมาตรฐาน SafeVege'), findsOneWidget);
    expect(find.text('โทรออก'), findsWidgets);
    expect(find.text('นำทาง Maps'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('มะเขือเทศ'), 100);
    expect(find.text('มะเขือเทศ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Renders ShopDetailsScreen in dark mode with new UX layout', (tester) async {
    final appState = AppState();
    final testShop = ShopModel(
      id: 'test-1',
      name: 'ตลาดผักปลอดภัยริมกก (DEMO)',
      ownerFirstName: 'สมชาย',
      ownerLastName: 'ใจดี',
      phone: '0810000102',
      houseNo: '12',
      road: 'ถนนริมกก',
      subDistrict: 'เวียง',
      district: 'เมืองเชียงราย',
      province: 'เชียงราย',
      latitude: 19.91,
      longitude: 99.83,
      isVerified: true,
      verifiedVegetables: ['มะเขือเทศ', 'ผักกาดหอม'],
      createdAt: DateTime(2025, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: ShopDetailsScreen(shop: testShop, appState: appState),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ShopDetailsScreen), findsOneWidget);
    expect(find.text('รายละเอียดร้านค้า'), findsOneWidget);
    expect(find.text('การรับรองมาตรฐาน SafeVege'), findsOneWidget);
    expect(find.text('โทรออก'), findsWidgets);
    expect(find.text('นำทาง Maps'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('มะเขือเทศ'), 100);
    expect(find.text('มะเขือเทศ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Renders ShopDashboardScreen in light mode without QR system', (tester) async {
    final appState = _shopApiState();
    await appState.loadPublicShops();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ShopDashboardScreen(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ShopDashboardScreen), findsOneWidget);
    expect(find.text('SafeVege เกษตรกร'), findsOneWidget);
    expect(find.text('ฟาร์มผักปลอดภัยแม่จัน'), findsOneWidget);
    expect(find.text('ยื่นขอตรวจแปลงผักใหม่'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('บริการสำหรับร้านค้า'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('บริการสำหรับร้านค้า'), findsOneWidget);
    expect(find.text('ผลตรวจแล็บ'), findsOneWidget);
    expect(find.text('พิกัดแปลงผัก'), findsOneWidget);
    expect(find.text('รายการคำขอ'), findsOneWidget);

    // Verify QR system is completely removed
    expect(find.textContaining('QR'), findsNothing);
    expect(find.text('QR หน้าร้าน'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Renders ShopDashboardScreen in dark mode and wide screen without QR system', (tester) async {
    final appState = _shopApiState();
    await appState.loadPublicShops();

    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: ShopDashboardScreen(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ShopDashboardScreen), findsOneWidget);
    expect(find.text('SafeVege เกษตรกร'), findsOneWidget);
    expect(find.text('ฟาร์มผักปลอดภัยแม่จัน'), findsOneWidget);
    expect(find.text('ยื่นขอตรวจแปลงผักใหม่'), findsOneWidget);
    expect(find.text('ผลตรวจแล็บ'), findsOneWidget);
    expect(find.text('พิกัดแปลงผัก'), findsOneWidget);
    expect(find.text('รายการคำขอ'), findsOneWidget);

    // Verify QR system is completely removed
    expect(find.textContaining('QR'), findsNothing);
    expect(find.text('QR หน้าร้าน'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Renders AdminRequestDetailsScreen with request details even when shop is not in appState.shops',
      (tester) async {
    final appState = _shopApiState();
    final request = InspectionRequestModel(
      id: '15',
      requestNumber: 'SV-20261016-8F4A6C7B',
      shopId: 'shop-unlisted',
      shopName: 'chaya',
      vegetables: ['เห็ดหอม', 'ผักบุ้ง'],
      status: RequestStatus.scheduled,
      submissionDate: DateTime(2026, 10, 16, 13, 58),
      appointmentDate: DateTime(2026, 10, 16),
      appointmentNotes: 'เข้าตรวจแปลงเวลา 10:00 น.',
      shopAddress: 'เลขที่ 1 หมู่ 2 ต.แม่ปะ อ.แม่สอด จ.ตาก',
      latitude: 16.7158,
      longitude: 98.5686,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: AdminRequestDetailsScreen(
          request: request,
          appState: appState,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AdminRequestDetailsScreen), findsOneWidget);
    expect(find.text('รายละเอียดคำขอตรวจ'), findsOneWidget);
    expect(find.text('คำขอ #15'), findsOneWidget);
    expect(find.text('chaya'), findsOneWidget);
    expect(find.text('เห็ดหอม'), findsOneWidget);
    expect(find.text('ผักบุ้ง'), findsOneWidget);
    expect(find.text('บันทึกผลการตรวจแล็บ', skipOffstage: false), findsOneWidget);
    expect(find.text('แก้ไขวันนัดหมาย', skipOffstage: false), findsOneWidget);
    expect(find.text('ไม่พบข้อมูลร้านค้า'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Renders AdminRequestDetailsScreen in dark mode without crashing',
      (tester) async {
    final appState = _shopApiState();
    final request = InspectionRequestModel(
      id: '15',
      requestNumber: 'SV-20261016-8F4A6C7B',
      shopId: 'shop-unlisted',
      shopName: 'chaya',
      vegetables: ['เห็ดหอม', 'ผักบุ้ง'],
      status: RequestStatus.scheduled,
      submissionDate: DateTime(2026, 10, 16, 13, 58),
      appointmentDate: DateTime(2026, 10, 16),
      shopAddress: 'เลขที่ 1 หมู่ 2 ต.แม่ปะ อ.แม่สอด จ.ตาก',
      latitude: 16.7158,
      longitude: 98.5686,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: AdminRequestDetailsScreen(
          request: request,
          appState: appState,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AdminRequestDetailsScreen), findsOneWidget);
    expect(find.text('คำขอ #15'), findsOneWidget);
    expect(find.text('chaya'), findsOneWidget);
    expect(find.text('ไม่พบข้อมูลร้านค้า'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CertificateViewerScreen renders without any QR code elements',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const CertificateViewerScreen(
          shopName: 'chaya',
          certNumber: '1321',
          vegetables: ['เห็ดหอม'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CertificateViewerScreen), findsOneWidget);
    expect(find.text('ใบรับรองมาตรฐานผักปลอดภัย'), findsOneWidget);
    expect(find.text('chaya'), findsOneWidget);
    expect(find.text('เลขที่รับรอง: '), findsOneWidget);
    expect(find.text('1321'), findsWidgets);
    expect(find.text('การรับรองมาตรฐานทางการ SafeVege'), findsOneWidget);

    // Verify QR code text and icon are completely absent
    expect(find.textContaining('QR'), findsNothing);
    expect(find.textContaining('สแกน'), findsNothing);
    expect(find.byIcon(Icons.qr_code_2_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'SuperAdminDashboardScreen renders in light mode without overflow at 360x640',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = _superAdminApiState();
    await appState.loginAdmin('superadmin', 'secret');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: SuperAdminDashboardScreen(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SuperAdminDashboardScreen), findsOneWidget);
    expect(find.text('เมนูผู้ดูแลระบบขั้นสูง'), findsOneWidget);
    // Scroll down to verify the architecture card
    await tester.scrollUntilVisible(
      find.text('v1.0.0 Production', skipOffstage: false),
      300,
    );
    await tester.pumpAndSettle();
    expect(find.text('v1.0.0 Production', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'SuperAdminDashboardScreen renders in dark mode without overflow at 320x568',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = _superAdminApiState();
    await appState.loginAdmin('superadmin', 'secret');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: SuperAdminDashboardScreen(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SuperAdminDashboardScreen), findsOneWidget);
    expect(find.text('เมนูผู้ดูแลระบบขั้นสูง'), findsOneWidget);
    // Scroll down to verify the architecture card
    await tester.scrollUntilVisible(
      find.text('v1.0.0 Production', skipOffstage: false),
      300,
    );
    await tester.pumpAndSettle();
    expect(find.text('v1.0.0 Production', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

