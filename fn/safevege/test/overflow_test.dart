import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safevege/data/api/api_client.dart';
import 'package:safevege/data/api/session_store.dart';
import 'package:safevege/main.dart';
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
  final testSizes = [
    const Size(320, 568),
    const Size(360, 640),
    const Size(375, 667),
    const Size(390, 844),
    const Size(412, 915),
  ];

  for (final size in testSizes) {
    testWidgets('Explore map has no overflow at ${size.width}x${size.height}', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(SafeVegeApp(appState: _emptyApiState()));
      await tester.pumpAndSettle();
      expect(
        find.text('ไม่พบร้านค้าในบริเวณนี้ ลองเปลี่ยนตัวกรอง'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Explore feed has no overflow at ${size.width}x${size.height}',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(SafeVegeApp(appState: _emptyApiState()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('หน้าหลัก'));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
