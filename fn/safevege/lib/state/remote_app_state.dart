import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../data/api/api_client.dart';
import '../data/api/session_store.dart';
import '../data/repositories/safevege_repository.dart';
import '../models/app_models.dart';

class AppState extends ChangeNotifier {
  AppState({ApiClient? apiClient, SessionStore? sessionStore})
    : _repository = SafeVegeRepository(
        api: apiClient ?? ApiClient(baseUrl: AppConfig.apiBaseUrl),
      ),
      _sessionStore = sessionStore ?? SecureSessionStore();

  final SafeVegeRepository _repository;
  final SessionStore _sessionStore;
  UserRole _currentRole = UserRole.guest;
  bool _isShopLoggedIn = false;
  bool _isAdminLoggedIn = false;
  String? _currentShopId;
  String _adminName = '';
  String _username = '';
  final Set<String> _favoriteShopIds = {};
  GeoPoint? _nearbyOrigin;
  final List<ShopModel> _shops = [];
  final List<InspectionRequestModel> _requests = [];
  final List<CertificateModel> _publicCertificates = [];
  final Map<String, InspectionResultDraft> _resultDrafts = {};
  final List<AdminUserModel> _adminUsers = [];
  final List<AuditEventModel> _auditEvents = [];
  Map<String, dynamic> _adminSettings = <String, dynamic>{};
  bool _isLoading = false;
  bool _initialized = false;
  String? _errorMessage;
  ThemeMode _themeMode = ThemeMode.system;

  UserRole get currentRole => _currentRole;
  bool get isShopLoggedIn => _isShopLoggedIn;
  bool get isAdminLoggedIn => _isAdminLoggedIn;
  bool get isSuperAdmin => _currentRole == UserRole.superAdmin;
  bool get canManageUsers => isSuperAdmin;
  bool get isLoading => _isLoading;
  bool get isInitialized => _initialized;
  String get adminName => _adminName;
  String get username => _username;
  String? get errorMessage => _errorMessage;
  List<ShopModel> get shops => List.unmodifiable(_shops);
  List<InspectionRequestModel> get requests => List.unmodifiable(_requests);
  List<CertificateModel> get publicCertificates =>
      List.unmodifiable(_publicCertificates);
  List<AdminUserModel> get adminUsers => List.unmodifiable(_adminUsers);
  List<AuditEventModel> get auditEvents => List.unmodifiable(_auditEvents);
  Map<String, dynamic> get adminSettings => Map.unmodifiable(_adminSettings);
  GeoPoint? get nearbyOrigin => _nearbyOrigin;
  ThemeMode get themeMode => _themeMode;
  Set<String> get favoriteShopIds => Set.unmodifiable(_favoriteShopIds);

  bool isFavorite(String shopId) => _favoriteShopIds.contains(shopId);

  Future<void> toggleFavorite(String shopId) async {
    if (_favoriteShopIds.contains(shopId)) {
      _favoriteShopIds.remove(shopId);
    } else {
      _favoriteShopIds.add(shopId);
    }
    notifyListeners();
    try {
      await _sessionStore.writeFavorites(_favoriteShopIds);
    } catch (_) {}
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void toggleThemeMode() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  InspectionResultDraft? inspectionResultDraft(String requestId) =>
      _resultDrafts[requestId];

  String distanceTextFor(ShopModel shop) {
    final origin = _nearbyOrigin;
    if (!shop.hasCoordinates) return '—';
    if (origin == null) return shop.distanceText;
    return '${origin.distanceKmTo(GeoPoint(latitude: shop.latitude, longitude: shop.longitude)).toStringAsFixed(1)} กม.';
  }

  ShopModel get currentShop {
    if (_shops.isEmpty) {
      throw StateError('บัญชีนี้ยังไม่มีข้อมูลร้านค้า');
    }
    return _shops.firstWhere(
      (shop) => shop.id == _currentShopId,
      orElse: () => _shops.first,
    );
  }

  List<InspectionRequestModel> get currentShopRequests => _requests
      .where((request) => request.shopId == _currentShopId)
      .toList(growable: false);

  Future<void> initialize() async {
    if (_initialized || _isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final savedFavorites = await _sessionStore.readFavorites();
      _favoriteShopIds
        ..clear()
        ..addAll(savedFavorites);

      final token = await _sessionStore.readToken();
      _repository.api.accessToken = token;
      if (token != null && token.isNotEmpty) {
        try {
          _applyUser(await _repository.currentUser());
          await _loadRoleData();
          _initialized = true;
          return;
        } on ApiException catch (error) {
          if (error.statusCode != 401 && error.statusCode != 403) rethrow;
          await _sessionStore.clearToken();
          _repository.api.accessToken = null;
          _resetSession();
        }
      }
      _currentRole = UserRole.guest;
      _isShopLoggedIn = false;
      _isAdminLoggedIn = false;
      await _loadPublicShops();
    } catch (error) {
      _errorMessage = _message(error);
    } finally {
      _initialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginShop(String username, String password) =>
      login(username, password, expectedRoles: const {UserRole.shop});

  Future<void> loginAdmin(String username, String password) => login(
    username,
    password,
    expectedRoles: const {UserRole.admin, UserRole.superAdmin},
  );

  Future<void> login(
    String username,
    String password, {
    required Set<UserRole> expectedRoles,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await _repository.login(username.trim(), password);
      if (!expectedRoles.contains(user.role) || !user.isActive) {
        await _repository.logout();
        throw const ApiException(
          'บัญชีนี้ไม่มีสิทธิ์เข้าสู่ระบบส่วนนี้',
          statusCode: 403,
        );
      }
      _applyUser(user);
      await _loadRoleData();
      final token = _repository.api.accessToken;
      if (token == null || token.isEmpty) {
        throw const ApiException('เซิร์ฟเวอร์ไม่ได้ออก session token');
      }
      await _sessionStore.writeToken(token);
    } catch (error) {
      _resetSession();
      _repository.api.accessToken = null;
      await _sessionStore.clearToken();
      _errorMessage = _message(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logoutShop() => logout();
  Future<void> logoutAdmin() => logout();

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.logout();
    } catch (error) {
      _errorMessage = _message(error);
    } finally {
      await _sessionStore.clearToken();
      _resetSession();
      try {
        await _loadPublicShops();
      } catch (error) {
        _errorMessage = _message(error);
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerShop({
    required String username,
    required String password,
    required String name,
    required String ownerFirstName,
    required String ownerLastName,
    required String phone,
    required String houseNo,
    String moo = '',
    String road = '',
    required String subDistrict,
    required String district,
    required String province,
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.registerShop(
        username: username,
        password: password,
        displayName: '$ownerFirstName $ownerLastName'.trim(),
        shop: {
          'name': name,
          'owner_first_name': ownerFirstName,
          'owner_last_name': ownerLastName,
          'phone': phone,
          'house_number': houseNo,
          'moo': moo,
          'street': road,
          'subdistrict': subDistrict,
          'district': district,
          'province': province,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
    } catch (error) {
      _errorMessage = _message(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    } catch (error) {
      _errorMessage = _message(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCurrentAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteCurrentAccount();
      await _sessionStore.clearToken();
      _resetSession();
      try {
        await _loadPublicShops();
      } catch (error) {
        _errorMessage = _message(error);
      }
    } catch (error) {
      _errorMessage = _message(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPublicShops({String query = '', GeoPoint? near}) async {
    _isLoading = true;
    _errorMessage = null;
    if (near != null || query.isEmpty) _nearbyOrigin = near;
    notifyListeners();
    try {
      await _loadPublicShops(query: query, near: near);
    } catch (error) {
      _errorMessage = _message(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ShopModel> loadPublicShopDetails(String shopId) async {
    try {
      final shop = await _repository.getPublicShop(shopId);
      _replaceShop(shop);
      _errorMessage = null;
      notifyListeners();
      return shop;
    } catch (error) {
      _errorMessage = _message(error);
      notifyListeners();
      rethrow;
    }
  }

  Future<List<CertificateModel>> loadPublicCertificates() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final certificates = await _repository.getPublicCertificates();
      _publicCertificates
        ..clear()
        ..addAll(certificates);
      return List.unmodifiable(_publicCertificates);
    } catch (error) {
      _errorMessage = _message(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<AdminUserModel>> loadAdminUsers() async {
    if (!isSuperAdmin) {
      throw const ApiException('ไม่มีสิทธิ์จัดการบัญชีผู้ใช้', statusCode: 403);
    }
    final users = await _repository.getAdminUsers();
    _adminUsers
      ..clear()
      ..addAll(users);
    notifyListeners();
    return List.unmodifiable(_adminUsers);
  }

  Future<AdminUserModel> createAdminUser({
    required String username,
    required String displayName,
    required String password,
    required UserRole role,
    String? currentPassword,
  }) async {
    if (!isSuperAdmin) {
      throw const ApiException('ไม่มีสิทธิ์จัดการบัญชีผู้ใช้', statusCode: 403);
    }
    final user = await _repository.createAdminUser(
      username: username,
      displayName: displayName,
      password: password,
      role: role,
      currentPassword: currentPassword,
    );
    _adminUsers.insert(0, user);
    notifyListeners();
    return user;
  }

  Future<void> updateAdminUser(
    String userId, {
    String? displayName,
    UserRole? role,
    bool? isActive,
    String? currentPassword,
  }) async {
    if (!isSuperAdmin) {
      throw const ApiException('ไม่มีสิทธิ์จัดการบัญชีผู้ใช้', statusCode: 403);
    }
    await _repository.updateAdminUser(
      userId,
      displayName: displayName,
      role: role,
      isActive: isActive,
      currentPassword: currentPassword,
    );
    await loadAdminUsers();
  }

  Future<void> resetAdminUserPassword(String userId, String newPassword) async {
    if (!isSuperAdmin) {
      throw const ApiException('ไม่มีสิทธิ์จัดการบัญชีผู้ใช้', statusCode: 403);
    }
    await _repository.resetAdminUserPassword(userId, newPassword);
  }

  Future<Map<String, dynamic>> loadAdminSettings() async {
    if (!isSuperAdmin) {
      throw const ApiException('ไม่มีสิทธิ์ตั้งค่าระบบ', statusCode: 403);
    }
    final settings = await _repository.getAdminSettings();
    _adminSettings = {...settings};
    notifyListeners();
    return Map.unmodifiable(_adminSettings);
  }

  Future<void> updateAdminSettings(Map<String, dynamic> values) async {
    if (!isSuperAdmin) {
      throw const ApiException('ไม่มีสิทธิ์ตั้งค่าระบบ', statusCode: 403);
    }
    await _repository.updateAdminSettings(values);
    _adminSettings = {..._adminSettings, ...values};
    notifyListeners();
  }

  Future<List<AuditEventModel>> loadAuditEvents({
    int? actorId,
    String? action,
    String? entityType,
  }) async {
    if (!isSuperAdmin) {
      throw const ApiException('ไม่มีสิทธิ์ดูประวัติระบบ', statusCode: 403);
    }
    final events = await _repository.getAuditEvents(
      actorId: actorId,
      action: action,
      entityType: entityType,
    );
    _auditEvents
      ..clear()
      ..addAll(events);
    notifyListeners();
    return List.unmodifiable(_auditEvents);
  }

  Future<Uint8List> downloadCertificate(String certificateId) =>
      _repository.downloadCertificate(certificateId);

  Future<void> loadMyRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final requests = await _repository.getMyRequests();
      _requests
        ..clear()
        ..addAll(requests);
    } catch (error) {
      _errorMessage = _message(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAdminRequests({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final requests = await _repository.getAdminRequests(status: status);
      _requests
        ..clear()
        ..addAll(requests);
    } catch (error) {
      _errorMessage = _message(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAdminShops() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final shops = await _repository.getAdminShops();
      _shops
        ..clear()
        ..addAll(shops);
      _currentShopId = shops.isEmpty ? null : shops.first.id;
    } catch (error) {
      _errorMessage = _message(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<InspectionRequestModel> loadRequestDetails(String requestId) async {
    final request =
        _currentRole == UserRole.admin || _currentRole == UserRole.superAdmin
        ? await _repository.getAdminRequestDetails(requestId)
        : await _repository.getMyRequestDetails(requestId);
    _replaceRequest(request);
    _errorMessage = null;
    notifyListeners();
    return request;
  }

  void setRole(UserRole role) {
    if (role == UserRole.guest && _currentRole != UserRole.guest) {
      logout();
    }
  }

  void setNearbyOrigin(GeoPoint? location) {
    _nearbyOrigin = location;
    notifyListeners();
  }

  void saveInspectionResultDraft({
    required String requestId,
    required List<VegetableInspection> results,
    String? certificateFileName,
    String? certificateNumber,
  }) {
    _resultDrafts[requestId] = InspectionResultDraft(
      results: results,
      certificateFileName: certificateFileName,
      certificateNumber: certificateNumber,
    );
    notifyListeners();
  }

  void clearInspectionResultDraft(String requestId) {
    _resultDrafts.remove(requestId);
    notifyListeners();
  }

  Future<ShopModel> updateCurrentShop({
    required String name,
    required String ownerFirstName,
    required String ownerLastName,
    required String phone,
    required String houseNo,
    required String moo,
    required String road,
    required String subDistrict,
    required String district,
    required String province,
    required double latitude,
    required double longitude,
  }) async {
    final shop = await _repository.updateMyShop(currentShop.id, {
      'name': name,
      'owner_first_name': ownerFirstName,
      'owner_last_name': ownerLastName,
      'phone': phone,
      'house_number': houseNo,
      'moo': moo,
      'street': road,
      'subdistrict': subDistrict,
      'district': district,
      'province': province,
      'latitude': latitude,
      'longitude': longitude,
    });
    _replaceShop(shop);
    _errorMessage = null;
    notifyListeners();
    return shop;
  }

  Future<InspectionRequestModel> addInspectionRequest({
    required List<String> vegetables,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final request = await _repository.createInspectionRequest(
      shopId: currentShop.id,
      vegetables: vegetables,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
    _replaceRequest(request);
    _errorMessage = null;
    notifyListeners();
    return request;
  }

  Future<InspectionRequestModel> scheduleInspection(
    String requestId,
    DateTime date,
    String notes,
  ) async {
    await _repository.scheduleInspection(requestId, date, notes);
    return loadRequestDetails(requestId);
  }

  Future<InspectionRequestModel> recordInspectionResults({
    required String requestId,
    required List<VegetableInspection> results,
    String? certFileName,
    String? certNumber,
    Uint8List? certificateBytes,
    DateTime? certificateIssuedAt,
    DateTime? certificateExpiresAt,
  }) async {
    await _repository.recordInspectionResults(
      requestId: requestId,
      results: results,
    );
    if (certFileName != null && certFileName.trim().isNotEmpty) {
      if (certificateBytes == null ||
          certNumber == null ||
          certNumber.trim().isEmpty) {
        throw const ApiException(
          'เลือกไฟล์และกรอกเลขใบรับรองให้ครบก่อนเผยแพร่',
        );
      }
      final inspected = await _repository.getAdminRequestDetails(requestId);
      final passingResultIds = inspected.results
          .where((result) => result.passed == true && result.resultId != null)
          .map((result) => result.resultId!)
          .toList(growable: false);
      if (passingResultIds.isEmpty) {
        throw const ApiException(
          'ใบรับรองใช้ได้เมื่อมีผักอย่างน้อยหนึ่งรายการผ่านผลตรวจ',
        );
      }
      await _repository.uploadCertificate(
        requestId: requestId,
        certificateNumber: certNumber.trim(),
        issuedAt: certificateIssuedAt ?? DateTime.now(),
        expiresAt: certificateExpiresAt,
        resultIds: passingResultIds,
        fileBytes: certificateBytes,
        fileName: certFileName,
      );
      await _repository.publishRequest(requestId);
    }
    final request = await _repository.getAdminRequestDetails(requestId);
    _replaceRequest(request);
    _resultDrafts.remove(requestId);
    _errorMessage = null;
    notifyListeners();
    return request;
  }

  Future<void> updateAdminShop(ShopModel shop) async {
    await _repository.updateAdminShop(shop.id, {
      'name': shop.name,
      'owner_first_name': shop.ownerFirstName,
      'owner_last_name': shop.ownerLastName,
      'phone': shop.phone,
      'house_number': shop.houseNo,
      'moo': shop.moo,
      'street': shop.road,
      'subdistrict': shop.subDistrict,
      'district': shop.district,
      'province': shop.province,
      'latitude': shop.latitude,
      'longitude': shop.longitude,
    });
    _replaceShop(shop);
    notifyListeners();
  }

  Future<void> addShopByAdmin({
    required ShopModel shop,
    required String username,
    required String password,
  }) async {
    await _repository.createAdminShop({
      'username': username.trim(),
      'password': password,
      'display_name': shop.ownerFullName,
      'name': shop.name,
      'owner_first_name': shop.ownerFirstName,
      'owner_last_name': shop.ownerLastName,
      'phone': shop.phone,
      'house_number': shop.houseNo,
      'moo': shop.moo,
      'street': shop.road,
      'subdistrict': shop.subDistrict,
      'district': shop.district,
      'province': shop.province,
      'latitude': shop.latitude,
      'longitude': shop.longitude,
    });
    await loadAdminShops();
  }

  Future<void> deleteShop(String shopId) async {
    await _repository.deleteAdminShop(shopId);
    _shops.removeWhere((shop) => shop.id == shopId);
    _requests.removeWhere((request) => request.shopId == shopId);
    if (_currentShopId == shopId) {
      _currentShopId = _shops.isEmpty ? null : _shops.first.id;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    switch (_currentRole) {
      case UserRole.guest:
        await loadPublicShops(near: _nearbyOrigin);
        return;
      case UserRole.shop:
      case UserRole.admin:
      case UserRole.superAdmin:
        await _loadRoleData();
        return;
    }
  }

  Future<void> _loadPublicShops({String query = '', GeoPoint? near}) async {
    final shops = await _repository.searchPublicShops(query: query, near: near);
    _shops
      ..clear()
      ..addAll(shops);
    _currentShopId = shops.isEmpty ? null : shops.first.id;
  }

  Future<void> _loadRoleData() async {
    if (_currentRole == UserRole.shop) {
      final shops = await _repository.getMyShops();
      if (shops.isEmpty) {
        throw const ApiException('บัญชีนี้ยังไม่มีร้านค้าที่เชื่อมอยู่');
      }
      _shops
        ..clear()
        ..addAll(shops);
      _currentShopId = shops.first.id;
      final requests = await _repository.getMyRequests();
      _requests
        ..clear()
        ..addAll(requests);
    } else if (_currentRole == UserRole.admin ||
        _currentRole == UserRole.superAdmin) {
      final values = await Future.wait<Object>([
        _repository.getAdminShops(),
        _repository.getAdminRequests(),
      ]);
      _shops
        ..clear()
        ..addAll(values[0] as List<ShopModel>);
      _requests
        ..clear()
        ..addAll(values[1] as List<InspectionRequestModel>);
      _currentShopId = _shops.isEmpty ? null : _shops.first.id;
    } else {
      await _loadPublicShops();
      _requests.clear();
      _currentShopId = null;
    }
  }

  void _applyUser(SessionUser user) {
    _currentRole = user.role;
    _isShopLoggedIn = user.role == UserRole.shop;
    _isAdminLoggedIn =
        user.role == UserRole.admin || user.role == UserRole.superAdmin;
    _username = user.username;
    if (user.role == UserRole.admin || user.role == UserRole.superAdmin) {
      _adminName = user.displayName;
    }
  }

  void _resetSession() {
    _currentRole = UserRole.guest;
    _isShopLoggedIn = false;
    _isAdminLoggedIn = false;
    _currentShopId = null;
    _username = '';
    _shops.clear();
    _requests.clear();
    _adminUsers.clear();
    _auditEvents.clear();
    _adminSettings = <String, dynamic>{};
  }

  void _replaceShop(ShopModel shop) {
    final index = _shops.indexWhere((item) => item.id == shop.id);
    if (index < 0) {
      _shops.add(shop);
    } else {
      _shops[index] = shop;
    }
  }

  void _replaceRequest(InspectionRequestModel request) {
    final index = _requests.indexWhere((item) => item.id == request.id);
    if (index < 0) {
      _requests.insert(0, request);
    } else {
      _requests[index] = request;
    }
  }

  String _message(Object error) => error is ApiException
      ? error.message
      : 'เกิดข้อผิดพลาดในการเชื่อมต่อ กรุณาลองอีกครั้ง';
}
