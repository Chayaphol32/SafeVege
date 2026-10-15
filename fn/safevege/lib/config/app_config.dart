import 'package:flutter/foundation.dart';

import 'api_endpoint.dart';

/// การตั้งค่าระบบ SafeVege และบริการภายนอก
class AppConfig {
  AppConfig._();

  static const String appName = 'SafeVege';
  static const String appVersion = '1.0.0';
  static const String appSubtitle = 'ระบบค้นหาและตรวจสอบร้านค้าผักปลอดสารพิษ';

  // -------------------------------------------------------------
  // OpenStreetMap & Map Configuration (ฟรี 100% ไม่ต้องใช้ API Key)
  // -------------------------------------------------------------
  /// Standard OpenStreetMap Tile URL (ฟรี 100% ไม่มีลายน้ำ ไม่ต้องใช้ API Key)
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// OpenStreetMap Humanitarian (HOT) Tile URL (สำรอง ฟรี 100% ไม่มีลายน้ำ)
  static const String osmFallbackTileUrl =
      'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';

  static const String mapAttribution = '© OpenStreetMap contributors';

  // -------------------------------------------------------------
  // Backend REST API Configuration (PHP / MySQL)
  // -------------------------------------------------------------
  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get apiBaseUrl => resolveApiBaseUrl(
    configuredUrl: _configuredApiBaseUrl,
    isWeb: kIsWeb,
    isAndroid: defaultTargetPlatform == TargetPlatform.android,
    isRelease: kReleaseMode,
  );
}
