import 'dart:convert';
import 'dart:typed_data';

import '../api/api_client.dart';
import '../../models/app_models.dart';

class SessionUser {
  const SessionUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String username;
  final String displayName;
  final UserRole role;
  final bool isActive;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    final role = switch (json['role']?.toString()) {
      'shop' => UserRole.shop,
      'admin' => UserRole.admin,
      'super_admin' => UserRole.superAdmin,
      _ => UserRole.guest,
    };
    return SessionUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      role: role,
      isActive:
          json['is_active'] == true || json['is_active']?.toString() == '1',
    );
  }
}

class SafeVegeRepository {
  SafeVegeRepository({required this.api});

  final ApiClient api;

  Future<SessionUser> login(String username, String password) async {
    final response = await api.postJson('/auth/login', {
      'username': username,
      'password': password,
    });
    api.accessToken = _string(response['token']);
    final user = response['user'];
    if (api.accessToken!.isEmpty || user is! Map) {
      throw const ApiException('รูปแบบข้อมูลบัญชีจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    }
    return SessionUser.fromJson(Map<String, dynamic>.from(user));
  }

  Future<void> logout() async {
    if (api.accessToken != null) await api.postJson('/auth/logout', const {});
    api.accessToken = null;
  }

  Future<SessionUser> currentUser() async {
    final response = await api.getJson('/me');
    final user = response['user'];
    if (user is! Map) {
      throw const ApiException('เซิร์ฟเวอร์ไม่พบข้อมูลบัญชี');
    }
    return SessionUser.fromJson(Map<String, dynamic>.from(user));
  }

  Future<List<AdminUserModel>> getAdminUsers() async {
    final response = await api.getJson('/admin/users');
    return _list(response['data']).map(_adminUser).toList(growable: false);
  }

  Future<AdminUserModel> createAdminUser({
    required String username,
    required String displayName,
    required String password,
    required UserRole role,
    String? currentPassword,
  }) async {
    final fields = <String, Object?>{
      'username': username,
      'display_name': displayName,
      'password': password,
      'role': _roleValue(role),
    };
    if (currentPassword != null) fields['current_password'] = currentPassword;
    final response = await api.postJson('/admin/users', fields);
    return _adminUser(_object(response));
  }

  Future<void> updateAdminUser(
    String userId, {
    String? displayName,
    UserRole? role,
    bool? isActive,
    String? currentPassword,
  }) async {
    final fields = <String, Object?>{};
    if (displayName != null) fields['display_name'] = displayName;
    if (role != null) fields['role'] = _roleValue(role);
    if (isActive != null) fields['is_active'] = isActive;
    if (currentPassword != null) fields['current_password'] = currentPassword;
    await api.patchJson('/admin/users/$userId', fields);
  }

  Future<void> resetAdminUserPassword(String userId, String newPassword) async {
    await api.postJson('/admin/users/$userId/password', {
      'new_password': newPassword,
    });
  }

  Future<List<AuditEventModel>> getAuditEvents({
    int? actorId,
    String? action,
    String? entityType,
  }) async {
    final query = <String, String>{
      if (actorId != null) 'actor_id': actorId.toString(),
      if (action != null && action.trim().isNotEmpty) 'action': action.trim(),
      if (entityType != null && entityType.trim().isNotEmpty)
        'entity_type': entityType.trim(),
    };
    final response = await api.getJson(
      '/admin/audit',
      queryParameters: query.isEmpty ? null : query,
    );
    return _list(response['data']).map(_auditEvent).toList(growable: false);
  }

  Future<Map<String, dynamic>> getAdminSettings() async {
    final response = await api.getJson('/admin/settings');
    final data = response['data'];
    if (data is List && data.isEmpty) return <String, dynamic>{};
    return _object(data);
  }

  Future<void> updateAdminSettings(Map<String, dynamic> values) async {
    await api.patchJson('/admin/settings', {'values': values});
  }

  Future<void> registerShop({
    required String username,
    required String password,
    required String displayName,
    required Map<String, Object?> shop,
  }) async {
    await api.postJson('/auth/register', {
      'username': username,
      'password': password,
      'display_name': displayName,
      'shop': shop,
    });
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await api.postJson('/auth/change-password', {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  Future<void> deleteCurrentAccount() async {
    await api.postJson('/my/account/delete', const {});
    api.accessToken = null;
  }

  Future<List<ShopModel>> searchPublicShops({
    String query = '',
    GeoPoint? near,
    double radiusKm = 25,
  }) async {
    final parameters = <String, String>{};
    if (query.trim().isNotEmpty) parameters['q'] = query.trim();
    if (near != null) {
      parameters['lat'] = near.latitude.toString();
      parameters['lng'] = near.longitude.toString();
      parameters['radius_km'] = radiusKm.toString();
    }
    final response = await api.getJson(
      '/shops',
      queryParameters: parameters.isEmpty ? null : parameters,
    );
    return _list(response['data'])
        .map((shop) => _shop(shop, publicByDefault: true))
        .toList(growable: false);
  }

  Future<ShopModel> getPublicShop(String shopId) async {
    final response = await api.getJson('/shops/$shopId');
    final data = _object(response['data']);
    return _shop(data, publicByDefault: true);
  }

  Future<List<CertificateModel>> getPublicShopCertificates(
    ShopModel shop,
  ) async {
    final response = await api.getJson('/shops/${shop.id}/certificates');
    return _list(response['data'])
        .map((json) => _certificate(json, shop))
        .toList(growable: false);
  }

  Future<List<CertificateModel>> getPublicCertificates() async {
    final response = await api.getJson('/certificates');
    return _list(response['data'])
        .map(
          (json) => CertificateModel(
            id: _string(json['id']),
            shopId: _string(json['shop_id']),
            shopName: _string(json['shop_name']),
            certificateNumber: _string(json['certificate_no']),
            issuedAt:
                _date(json['issued_at']) ??
                DateTime.fromMillisecondsSinceEpoch(0),
            expiresAt: _date(json['expires_at']),
            isPublic: true,
            vegetables: _strings(json['vegetables']),
          ),
        )
        .toList(growable: false);
  }

  Future<Uint8List> downloadCertificate(String certificateId) =>
      api.getBytes('/certificates/$certificateId/file');

  Future<List<ShopModel>> getMyShops() async {
    final response = await api.getJson('/my/shops');
    return _list(response['data'])
        .map((shop) => _shop(shop, publicByDefault: false))
        .toList(growable: false);
  }

  Future<ShopModel> updateMyShop(
    String shopId,
    Map<String, Object?> fields,
  ) async {
    final response = await api.patchJson('/my/shops/$shopId', fields);
    return _shop(_object(response['data']), publicByDefault: false);
  }

  Future<List<InspectionRequestModel>> getMyRequests() async {
    final response = await api.getJson('/my/requests');
    return _list(response['data']).map(_requestSummary).toList(growable: false);
  }

  Future<InspectionRequestModel> getMyRequestDetails(String requestId) async {
    final response = await api.getJson('/my/requests/$requestId');
    return _request(_object(response['data']));
  }

  Future<InspectionRequestModel> createInspectionRequest({
    required String shopId,
    required List<String> vegetables,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final response = await api.postJson('/my/shops/$shopId/requests', {
      'vegetables': vegetables,
      'address_snapshot': address,
      'latitude': latitude,
      'longitude': longitude,
    });
    final id = _string(response['id']);
    if (id.isEmpty) {
      throw const ApiException('เซิร์ฟเวอร์ไม่ได้ส่งเลขคำขอกลับมา');
    }
    return getMyRequestDetails(id);
  }

  Future<List<InspectionRequestModel>> getAdminRequests({
    String? status,
  }) async {
    final response = await api.getJson(
      '/admin/requests',
      queryParameters: status == null ? null : {'status': status},
    );
    return _list(response['data']).map(_requestSummary).toList(growable: false);
  }

  Future<InspectionRequestModel> getAdminRequestDetails(
    String requestId,
  ) async {
    final response = await api.getJson('/admin/requests/$requestId');
    return _request(_object(response['data']));
  }

  Future<List<ShopModel>> getAdminShops() async {
    final response = await api.getJson('/admin/shops');
    return _list(response['data'])
        .map((shop) => _shop(shop, publicByDefault: false))
        .toList(growable: false);
  }

  Future<void> createAdminShop(Map<String, Object?> fields) async {
    await api.postJson('/admin/shops', fields);
  }

  Future<void> updateAdminShop(
    String shopId,
    Map<String, Object?> fields,
  ) async {
    await api.patchJson('/admin/shops/$shopId', fields);
  }

  Future<void> deleteAdminShop(String shopId) async {
    await api.deleteJson('/admin/shops/$shopId');
  }

  Future<void> scheduleInspection(
    String requestId,
    DateTime appointmentAt,
    String note,
  ) async {
    await api.postJson('/admin/requests/$requestId/appointment', {
      'appointment_at': _utcTimestamp(appointmentAt),
      if (note.trim().isNotEmpty) 'note': note.trim(),
    });
  }

  Future<void> recordInspectionResults({
    required String requestId,
    required List<VegetableInspection> results,
    DateTime? inspectedAt,
  }) async {
    final items = results
        .map((result) {
          final itemId = result.requestItemId;
          final outcome =
              result.outcome ??
              (result.passed == true
                  ? 'passed'
                  : result.passed == false
                  ? 'failed'
                  : 'inconclusive');
          if (itemId == null) {
            throw ApiException('ไม่พบรายการผักของคำขอ: ${result.name}');
          }
          return <String, Object?>{
            'request_item_id': itemId,
            'outcome': outcome,
            if ((result.notes ?? result.details)?.trim().isNotEmpty ?? false)
              'note': (result.notes ?? result.details)!.trim(),
          };
        })
        .toList(growable: false);
    await api.postJson('/admin/requests/$requestId/results', {
      'items': items,
      'inspected_at': _utcTimestamp(inspectedAt ?? DateTime.now()),
    });
  }

  Future<void> uploadCertificate({
    required String requestId,
    required String certificateNumber,
    required DateTime issuedAt,
    DateTime? expiresAt,
    required List<int> resultIds,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    await api.postMultipart(
      '/admin/requests/$requestId/certificates',
      fields: {
        'certificate_no': certificateNumber,
        'issued_at': _dateOnly(issuedAt),
        if (expiresAt != null) 'expires_at': _dateOnly(expiresAt),
        'result_ids': _jsonList(resultIds),
      },
      fileBytes: fileBytes,
      fileName: fileName,
    );
  }

  Future<void> publishRequest(String requestId) async {
    await api.postJson('/admin/requests/$requestId/publish', const {});
  }

  static ShopModel _shop(
    Map<String, dynamic> data, {
    required bool publicByDefault,
  }) {
    final rawResults = _list(data['results']);
    final resultVegetables = rawResults
        .map((result) => _string(result['vegetable_name']))
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final latitude = _number(data['latitude']);
    final longitude = _number(data['longitude']);
    final distance = _optionalNumber(data['distance_km']);
    return ShopModel(
      id: _string(data['id']),
      name: _string(data['name']),
      ownerFirstName: _string(data['owner_first_name']),
      ownerLastName: _string(data['owner_last_name']),
      phone: _string(data['phone']),
      houseNo: _string(data['house_number']),
      moo: _string(data['moo']),
      road: _string(data['street']),
      subDistrict: _string(data['subdistrict']),
      district: _string(data['district']),
      province: _string(data['province']),
      latitude: latitude,
      longitude: longitude,
      hasCoordinates: data['latitude'] != null && data['longitude'] != null,
      isVerified: _bool(data['is_public'], defaultValue: publicByDefault),
      distanceText: distance == null
          ? '—'
          : '${distance.toStringAsFixed(1)} กม.',
      verifiedVegetables: resultVegetables,
      publicResults: rawResults
          .where((result) => _string(result['outcome']) == 'passed')
          .map(
            (result) => PublicInspectionResult(
              vegetableName: _string(result['vegetable_name']),
              certificateId: _string(result['certificate_id']),
              certificateNumber: _string(result['certificate_no']),
              inspectedAt: _date(result['inspected_at']),
              issuedAt: _date(result['issued_at']),
              expiresAt: _date(result['expires_at']),
            ),
          )
          .toList(growable: false),
      createdAt:
          _date(data['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  static AdminUserModel _adminUser(Map<String, dynamic> json) => AdminUserModel(
    id: _string(json['id']),
    username: _string(json['username']),
    displayName: _string(json['display_name']),
    role: _role(json['role']),
    isActive: _bool(json['is_active'], defaultValue: false),
    createdAt: _date(json['created_at']),
  );

  static AuditEventModel _auditEvent(Map<String, dynamic> json) {
    final rawDetails = json['details'];
    Map<String, dynamic> details = <String, dynamic>{};
    if (rawDetails is Map) {
      details = Map<String, dynamic>.from(rawDetails);
    } else if (rawDetails is String && rawDetails.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawDetails);
        if (decoded is Map) details = Map<String, dynamic>.from(decoded);
      } on FormatException {
        // Keep an empty details map when a legacy row is not valid JSON.
      }
    }
    return AuditEventModel(
      id: _string(json['id']),
      actorUserId: _string(json['actor_user_id']),
      actorUsername: _string(json['actor_username']),
      entityType: _string(json['entity_type']),
      entityId: _string(json['entity_id']),
      action: _string(json['action']),
      details: details,
      createdAt: _date(json['created_at']),
    );
  }

  static CertificateModel _certificate(
    Map<String, dynamic> json,
    ShopModel shop,
  ) => CertificateModel(
    id: _string(json['id']),
    shopId: shop.id,
    shopName: shop.name,
    certificateNumber: _string(json['certificate_no']),
    issuedAt:
        _date(json['issued_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    expiresAt: _date(json['expires_at']),
    isPublic: _bool(json['is_public'], defaultValue: true),
    vegetables: shop.verifiedVegetables,
  );

  static InspectionRequestModel _requestSummary(Map<String, dynamic> json) =>
      InspectionRequestModel(
        id: _string(json['id']),
        requestNumber: _string(json['request_no']),
        shopId: _string(json['shop_id']),
        shopName: _string(json['shop_name']),
        vegetables: _strings(json['vegetables']),
        status: _status(json['status']),
        submissionDate:
            _date(json['submitted_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        shopAddress: '',
        latitude: 0,
        longitude: 0,
      );

  static InspectionRequestModel _request(Map<String, dynamic> json) {
    final items = _list(json['items']);
    final resultRows = _list(json['results']);
    final latestByItemId = <int, Map<String, dynamic>>{};
    for (final result in resultRows) {
      final itemId = _optionalInt(result['request_item_id']);
      if (itemId != null && !latestByItemId.containsKey(itemId)) {
        latestByItemId[itemId] = result;
      }
    }
    final vegetableResults = <VegetableInspection>[];
    for (final item in items) {
      final itemId = _optionalInt(item['id']);
      final result = item['outcome'] != null
          ? item
          : (itemId == null ? null : latestByItemId[itemId]);
      final outcome = result == null ? null : _string(result['outcome']);
      vegetableResults.add(
        VegetableInspection(
          name: _string(item['vegetable_name']),
          requestItemId: itemId,
          resultId: result == null ? null : _optionalInt(result['id']),
          outcome: outcome,
          passed: outcome == 'passed'
              ? true
              : outcome == 'failed'
              ? false
              : null,
          inspectionDate: _date(result?['inspected_at']),
          notes: result == null ? null : _nullableString(result['note']),
          details: result == null ? null : _nullableString(result['note']),
        ),
      );
    }
    final appointments = _list(json['appointments']);
    final appointment = appointments.isEmpty ? null : appointments.first;
    final certificates = _list(json['certificates']);
    certificates.sort(
      (a, b) =>
          (_date(b['issued_at']) ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(
                _date(a['issued_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
              ),
    );
    final certificate = certificates.isEmpty ? null : certificates.first;
    final status = _status(json['status']);
    final requestId = _string(json['id']);
    final shopId = _string(json['shop_id']);
    return InspectionRequestModel(
      id: requestId,
      requestNumber: _string(json['request_no']),
      shopId: shopId,
      shopName: _string(json['shop_name']),
      vegetables: items.map((item) => _string(item['vegetable_name'])).toList(),
      status: status,
      submissionDate:
          _date(json['submitted_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      appointmentDate: _date(appointment?['appointment_at']),
      appointmentNotes: _nullableString(appointment?['note']),
      inspectionDate: vegetableResults
          .map((result) => result.inspectionDate)
          .whereType<DateTime>()
          .fold<DateTime?>(
            null,
            (latest, current) =>
                latest == null || current.isAfter(latest) ? current : latest,
          ),
      results: vegetableResults,
      certificateFileName: certificate == null
          ? null
          : _string(certificate['certificate_no']),
      certificateId: certificate == null ? null : _string(certificate['id']),
      certificateNumber: certificate == null
          ? null
          : _string(certificate['certificate_no']),
      certificateExpiryDate: _date(certificate?['expires_at']),
      shopAddress: _string(json['address_snapshot']),
      latitude: _number(json['latitude_snapshot']),
      longitude: _number(json['longitude_snapshot']),
    );
  }

  static RequestStatus _status(Object? value) => switch (value?.toString()) {
    'submitted' => RequestStatus.pending,
    'scheduled' => RequestStatus.scheduled,
    'inspected' || 'published' => RequestStatus.completed,
    'cancelled' => RequestStatus.cancelled,
    _ => throw ApiException(
      'ไม่รู้จักสถานะคำขอจากเซิร์ฟเวอร์: ${_string(value)}',
    ),
  };

  static UserRole _role(Object? value) => switch (value?.toString()) {
    'shop' => UserRole.shop,
    'admin' => UserRole.admin,
    'super_admin' => UserRole.superAdmin,
    _ => UserRole.guest,
  };

  static String _roleValue(UserRole role) => switch (role) {
    UserRole.admin => 'admin',
    UserRole.superAdmin => 'super_admin',
    _ => throw const ApiException('เลือก role ผู้ดูแลระบบไม่ถูกต้อง'),
  };

  static List<Map<String, dynamic>> _list(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];

  static List<String> _strings(Object? value) => value is List
      ? value
            .map(
              (item) => item is Map
                  ? _string(item['vegetable_name'] ?? item['name'])
                  : _string(item),
            )
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
      : <String>[];

  static Map<String, dynamic> _object(Object? value) => value is Map
      ? Map<String, dynamic>.from(value)
      : throw const ApiException('เซิร์ฟเวอร์ส่งข้อมูลไม่ครบถ้วน');

  static String _string(Object? value) => value?.toString() ?? '';

  static String? _nullableString(Object? value) =>
      value == null ? null : _string(value);

  static double _number(Object? value) => _optionalNumber(value) ?? 0;

  static double? _optionalNumber(Object? value) => switch (value) {
    num number => number.toDouble(),
    String text => double.tryParse(text),
    _ => null,
  };

  static int? _optionalInt(Object? value) => switch (value) {
    int number => number,
    num number => number.toInt(),
    String text => int.tryParse(text),
    _ => null,
  };

  static bool _bool(Object? value, {required bool defaultValue}) =>
      switch (value) {
        bool result => result,
        num number => number != 0,
        String text => text == '1' || text.toLowerCase() == 'true',
        _ => defaultValue,
      };

  static DateTime? _date(Object? value) {
    if (value == null || value.toString().isEmpty) return null;
    final raw = value.toString();
    final parsedText = raw.contains('T') || raw.length == 10
        ? raw
        : '${raw.replaceFirst(' ', 'T')}Z';
    return DateTime.tryParse(parsedText)?.toLocal();
  }

  static String _utcTimestamp(DateTime date) {
    final value = date.toUtc().toIso8601String();
    return '${value.substring(0, 10)} ${value.substring(11, 19)}';
  }

  static String _dateOnly(DateTime date) =>
      date.toIso8601String().substring(0, 10);

  static String _jsonList(List<int> values) =>
      '[${values.map((value) => value.toString()).join(',')}]';
}
