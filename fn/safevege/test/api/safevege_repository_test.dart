import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safevege/data/api/api_client.dart';
import 'package:safevege/data/repositories/safevege_repository.dart';
import 'package:safevege/models/app_models.dart';

void main() {
  test('maps public shop search records into map-ready shop models', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost/api/v1',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v1/shops');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'data': [
                {
                  'id': 7,
                  'name': 'สวนผักจริง',
                  'phone': '0800000000',
                  'subdistrict': 'รอบเวียง',
                  'district': 'เมืองเชียงราย',
                  'province': 'เชียงราย',
                  'latitude': '19.91',
                  'longitude': 99.83,
                  'distance_km': 1.25,
                },
              ],
            }),
          ),
          200,
        );
      }),
    );

    final shops = await SafeVegeRepository(api: api).searchPublicShops();

    expect(shops, hasLength(1));
    expect(shops.single.id, '7');
    expect(shops.single.name, 'สวนผักจริง');
    expect(shops.single.latitude, 19.91);
    expect(shops.single.longitude, 99.83);
    expect(shops.single.distanceText, '1.3 กม.');
    expect(shops.single.isVerified, isTrue);
    expect(shops.single.verifiedVegetables, isEmpty);
  });

  test(
    'maps published results and their certificate references from shop detail',
    () async {
      final api = ApiClient(
        baseUrl: 'http://localhost/api/v1',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/shops/7');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'data': {
                  'id': 7,
                  'name': 'สวนผักจริง',
                  'latitude': '19.91',
                  'longitude': '99.83',
                  'results': [
                    {
                      'vegetable_name': 'คะน้า',
                      'outcome': 'passed',
                      'inspected_at': '2026-10-11 03:30:00',
                      'certificate_id': 5,
                      'certificate_no': 'CERT-005',
                      'issued_at': '2026-10-11',
                      'expires_at': '2027-10-11',
                    },
                  ],
                },
              }),
            ),
            200,
          );
        }),
      );

      final shop = await SafeVegeRepository(api: api).getPublicShop('7');

      expect(shop.verifiedVegetables, ['คะน้า']);
      expect(shop.publicResults, hasLength(1));
      expect(shop.publicResults.single.certificateId, '5');
      expect(shop.publicResults.single.certificateNumber, 'CERT-005');
    },
  );

  test('loads a public certificate directory with shop names', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost/api/v1',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v1/certificates');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'data': [
                {
                  'id': 5,
                  'shop_id': 7,
                  'shop_name': 'สวนผักจริง',
                  'certificate_no': 'CERT-005',
                  'issued_at': '2026-10-11',
                  'expires_at': '2027-10-11',
                },
              ],
            }),
          ),
          200,
        );
      }),
    );

    final certificates = await SafeVegeRepository(api: api)
        .getPublicCertificates();

    expect(certificates, hasLength(1));
    expect(certificates.single.id, '5');
    expect(certificates.single.shopId, '7');
    expect(certificates.single.shopName, 'สวนผักจริง');
  });

  test(
    'maps admin detail including inconclusive result and appointment time',
    () async {
      final api = ApiClient(
        baseUrl: 'http://localhost/api/v1',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/admin/requests/19');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'data': {
                  'id': 19,
                  'request_no': 'SV-20261011-ABCD',
                  'shop_id': 7,
                  'shop_name': 'สวนผักจริง',
                  'status': 'inspected',
                  'submitted_at': '2026-10-10 02:00:00',
                  'address_snapshot': 'ต.รอบเวียง อ.เมืองเชียงราย',
                  'latitude_snapshot': '19.91',
                  'longitude_snapshot': '99.83',
                  'items': [
                    {'id': 81, 'vegetable_name': 'คะน้า'},
                    {'id': 82, 'vegetable_name': 'ผักบุ้ง'},
                  ],
                  'appointments': [
                    {
                      'appointment_at': '2026-10-11 03:00:00',
                      'note': 'ตรวจที่แปลง',
                    },
                  ],
                  'results': [
                    {
                      'id': 112,
                      'request_item_id': 82,
                      'revision_no': 1,
                      'outcome': 'inconclusive',
                      'inspected_at': '2026-10-11 03:30:00',
                      'note': 'ต้องตรวจซ้ำ',
                    },
                    {
                      'id': 111,
                      'request_item_id': 81,
                      'revision_no': 1,
                      'outcome': 'passed',
                      'inspected_at': '2026-10-11 03:30:00',
                      'note': 'ผ่าน',
                    },
                  ],
                  'certificates': [
                    {
                      'id': 5,
                      'certificate_no': 'CERT-005',
                      'issued_at': '2026-10-11',
                      'expires_at': '2027-10-11',
                      'is_public': false,
                    },
                  ],
                },
              }),
            ),
            200,
          );
        }),
      )..accessToken = 'admin-token';

      final request = await SafeVegeRepository(api: api)
          .getAdminRequestDetails('19');

      expect(request.id, '19');
      expect(request.requestNumber, 'SV-20261011-ABCD');
      expect(request.status, RequestStatus.completed);
      expect(request.vegetables, ['คะน้า', 'ผักบุ้ง']);
      expect(request.results[0].requestItemId, 81);
      expect(request.results[0].resultId, 111);
      expect(request.results[0].passed, isTrue);
      expect(request.results[1].outcome, 'inconclusive');
      expect(request.results[1].passed, isNull);
      expect(request.results[1].notes, 'ต้องตรวจซ้ำ');
      expect(request.appointmentNotes, 'ตรวจที่แปลง');
      expect(request.certificateId, '5');
      expect(request.certificateNumber, 'CERT-005');
      expect(request.appointmentDate!.isUtc, isFalse);
    },
  );

  test('maps request summaries with their shop and vegetable names', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost/api/v1',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v1/my/requests');
        expect(request.headers['authorization'], 'Bearer shop-token');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'data': [
                {
                  'id': 29,
                  'request_no': 'SV-20261011-ABCD',
                  'shop_id': 7,
                  'shop_name': 'สวนผักจริง',
                  'status': 'submitted',
                  'submitted_at': '2026-10-11 03:00:00',
                  'vegetables': ['คะน้า', 'ผักบุ้ง'],
                },
              ],
            }),
          ),
          200,
        );
      }),
    )..accessToken = 'shop-token';

    final requests = await SafeVegeRepository(api: api).getMyRequests();

    expect(requests, hasLength(1));
    expect(requests.single.shopId, '7');
    expect(requests.single.vegetables, ['คะน้า', 'ผักบุ้ง']);
  });

  test('posts admin-created shop accounts with the shop profile', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost/api/v1',
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/admin/shops');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['username'], 'new_shop');
        expect(body['password'], 'secure-password-123');
        expect(body['display_name'], 'เจ้าของร้าน');
        expect(body['house_number'], '12/3');
        return http.Response.bytes(utf8.encode('{"id":81}'), 201);
      }),
    )..accessToken = 'admin-token';

    await SafeVegeRepository(api: api).createAdminShop({
      'username': 'new_shop',
      'password': 'secure-password-123',
      'display_name': 'เจ้าของร้าน',
      'name': 'ร้านผักใหม่',
      'owner_first_name': 'เจ้าของ',
      'owner_last_name': 'ร้าน',
      'phone': '0800000000',
      'house_number': '12/3',
      'latitude': 19.91,
      'longitude': 99.83,
    });
  });

  test('copying an inspection preserves the API item identifiers', () {
    final inspection = VegetableInspection(
      name: 'คะน้า',
      requestItemId: 81,
      resultId: 111,
      outcome: 'passed',
      passed: true,
    );

    final revised = inspection.copyWith(outcome: 'failed', passed: false);

    expect(revised.requestItemId, 81);
    expect(revised.resultId, 111);
    expect(revised.outcome, 'failed');
    expect(revised.passed, isFalse);
  });
}
