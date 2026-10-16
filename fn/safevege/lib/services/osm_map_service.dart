import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';

enum TravelMode {
  driving('ขับรถยนต์', 'driving', 'car'),
  motorcycle('มอเตอร์ไซค์', 'motorcycle', 'motorcycle'),
  walking('เดินเท้า', 'walking', 'walk');

  const TravelMode(this.label, this.code, this.iconKey);
  final String label;
  final String code;
  final String iconKey;
}

class OsmRouteStep {
  const OsmRouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.type,
    required this.modifier,
    this.streetName = '',
  });

  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final String type;
  final String modifier;
  final String streetName;

  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} กม.';
    }
    return '${distanceMeters.round()} ม.';
  }

  String get formattedDuration {
    final mins = (durationSeconds / 60).round();
    if (mins <= 1) return '~1 นาที';
    return '~$mins นาที';
  }
}

class OsmRouteResult {
  const OsmRouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    this.steps = const [],
    this.travelMode = TravelMode.driving,
  });

  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final List<OsmRouteStep> steps;
  final TravelMode travelMode;

  String get formattedDistance {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()} ม.';
    }
    return '${distanceKm.toStringAsFixed(1)} กม.';
  }

  String get formattedDuration {
    if (durationMinutes <= 1) return '< 1 นาที';
    if (durationMinutes >= 60) {
      final hours = durationMinutes ~/ 60;
      final mins = durationMinutes % 60;
      if (mins == 0) return '$hours ชม.';
      return '$hours ชม. $mins นาที';
    }
    return '$durationMinutes นาที';
  }
}

/// บริการแผนที่ OpenStreetMap และ OSRM Routing (ฟรี 100% ไม่ต้องใช้ API Key)
class OsmMapService {
  OsmMapService._();

  static String get tileUrl => AppConfig.osmTileUrl;

  /// แปลง OSRM maneuver type & modifier ให้เป็นข้อความภาษาไทยเข้าใจง่าย
  static String _buildThaiInstruction(
    String type,
    String modifier,
    String street,
  ) {
    final streetInfo = street.trim().isNotEmpty ? ' เข้าสู่ $street' : '';
    switch (type) {
      case 'depart':
        return street.trim().isNotEmpty
            ? 'เริ่มต้นออกเดินทางบน $street'
            : 'เริ่มต้นออกเดินทางจากจุดเริ่มต้น';
      case 'arrive':
        return 'ถึงจุดหมายปลายทาง';
      case 'turn':
        if (modifier == 'left') return 'เลี้ยวซ้าย$streetInfo';
        if (modifier == 'right') return 'เลี้ยวขวา$streetInfo';
        if (modifier == 'slight left') return 'เบี่ยงซ้ายเล็กน้อย$streetInfo';
        if (modifier == 'slight right') return 'เบี่ยงขวาเล็กน้อย$streetInfo';
        if (modifier == 'sharp left') return 'เลี้ยวซ้ายหักศอก$streetInfo';
        if (modifier == 'sharp right') return 'เลี้ยวขวาหักศอก$streetInfo';
        if (modifier == 'uturn') return 'กลับรถ (U-turn)$streetInfo';
        return 'เลี้ยว$streetInfo';
      case 'new name':
      case 'continue':
        return 'ตรงต่อไปตามเส้นทาง$streetInfo';
      case 'roundabout':
      case 'rotary':
        return 'เข้าสู่วงเวียน$streetInfo';
      case 'fork':
        if (modifier.contains('left')) return 'ชิดซ้ายที่ทางแยก';
        return 'ชิดขวาที่ทางแยก';
      case 'end of road':
        if (modifier.contains('left')) return 'สุดทาง เลี้ยวซ้าย$streetInfo';
        return 'สุดทาง เลี้ยวขวา$streetInfo';
      default:
        if (street.trim().isNotEmpty) return 'มุ่งหน้าไปตาม $street';
        return 'ตรงไปตามเส้นทางข้างหน้า';
    }
  }

  /// ดึงข้อมูลเส้นทางขับรถจริงผ่าน OSRM (Open Source Routing Machine)
  static Future<OsmRouteResult> fetchDrivingRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    TravelMode mode = TravelMode.driving,
  }) async {
    // เลือก Routing endpoint ที่ตรงกับโหมดการเดินทางจริง (เดิน/มอเตอร์ไซค์/รถยนต์)
    final (primaryUrl, fallbackUrl) = switch (mode) {
      TravelMode.walking => (
        'https://routing.openstreetmap.de/routed-foot/route/v1/driving/'
            '$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson&steps=true',
        'https://router.project-osrm.org/route/v1/foot/'
            '$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson&steps=true',
      ),
      TravelMode.motorcycle => (
        'https://routing.openstreetmap.de/routed-bike/route/v1/driving/'
            '$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson&steps=true',
        'https://router.project-osrm.org/route/v1/bicycle/'
            '$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson&steps=true',
      ),
      TravelMode.driving => (
        'https://routing.openstreetmap.de/routed-car/route/v1/driving/'
            '$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson&steps=true',
        'https://router.project-osrm.org/route/v1/driving/'
            '$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson&steps=true',
      ),
    };

    try {
      http.Response response;
      try {
        response = await http
            .get(
              Uri.parse(primaryUrl),
              headers: {'User-Agent': 'SafeVege/1.0 (FlutterApp)'},
            )
            .timeout(const Duration(seconds: 5));
        if (response.statusCode != 200) {
          response = await http
              .get(
                Uri.parse(fallbackUrl),
                headers: {'User-Agent': 'SafeVege/1.0 (FlutterApp)'},
              )
              .timeout(const Duration(seconds: 5));
        }
      } catch (_) {
        response = await http
            .get(
              Uri.parse(fallbackUrl),
              headers: {'User-Agent': 'SafeVege/1.0 (FlutterApp)'},
            )
            .timeout(const Duration(seconds: 5));
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes.first as Map<String, dynamic>;
          final distanceMeters =
              (firstRoute['distance'] as num?)?.toDouble() ?? 0.0;
          final durationSeconds =
              (firstRoute['duration'] as num?)?.toDouble() ?? 0.0;
          final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
          final coordinates = geometry?['coordinates'] as List<dynamic>?;

          final List<LatLng> routePoints = [];
          if (coordinates != null) {
            for (final coord in coordinates) {
              final lon = (coord[0] as num).toDouble();
              final lat = (coord[1] as num).toDouble();
              routePoints.add(LatLng(lat, lon));
            }
          }

          // Parse steps
          final List<OsmRouteStep> steps = [];
          final legs = firstRoute['legs'] as List<dynamic>?;
          if (legs != null && legs.isNotEmpty) {
            final legSteps = legs.first['steps'] as List<dynamic>?;
            if (legSteps != null) {
              for (final st in legSteps) {
                final stepMap = st as Map<String, dynamic>;
                final sDist = (stepMap['distance'] as num?)?.toDouble() ?? 0.0;
                final sDur = (stepMap['duration'] as num?)?.toDouble() ?? 0.0;
                final name = (stepMap['name'] as String?) ?? '';
                final maneuver = stepMap['maneuver'] as Map<String, dynamic>?;
                final type = (maneuver?['type'] as String?) ?? 'continue';
                final modifier =
                    (maneuver?['modifier'] as String?) ?? 'straight';

                final thaiInstruction = _buildThaiInstruction(
                  type,
                  modifier,
                  name,
                );
                steps.add(
                  OsmRouteStep(
                    instruction: thaiInstruction,
                    distanceMeters: sDist,
                    durationSeconds: sDur,
                    type: type,
                    modifier: modifier,
                    streetName: name,
                  ),
                );
              }
            }
          }

          if (routePoints.isNotEmpty) {
            final distKm = distanceMeters / 1000.0;
            int finalDurationMinutes;
            switch (mode) {
              case TravelMode.driving:
                finalDurationMinutes = (durationSeconds / 60.0).round().clamp(
                  1,
                  999,
                );
                break;
              case TravelMode.motorcycle:
                // มอเตอร์ไซค์ใช้เส้นทางลัด/ซอย คล่องตัวกว่ารถยนต์
                finalDurationMinutes = (durationSeconds * 0.75 / 60.0)
                    .round()
                    .clamp(1, 999);
                break;
              case TravelMode.walking:
                // เวลาเดินจริงจาก routing engine หรือคำนวณจากระยะทาง
                finalDurationMinutes = durationSeconds > 0
                    ? (durationSeconds / 60.0).round().clamp(1, 999)
                    : (distKm / 4.8 * 60.0).round().clamp(1, 999);
                break;
            }

            return OsmRouteResult(
              points: routePoints,
              distanceKm: distKm,
              durationMinutes: finalDurationMinutes,
              steps: steps,
              travelMode: mode,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('OSRM Route fetch error, using haversine fallback: $e');
    }

    // กรณีออฟไลน์หรือ OSRM ไม่ตอบสนอง: คำนวณเส้นตรง Haversine พร้อมสร้าง Steps สำรอง
    final straightDist = calculateDistanceKm(
      lat1: startLat,
      lon1: startLon,
      lat2: endLat,
      lon2: endLon,
    );
    int fallbackMinutes;
    switch (mode) {
      case TravelMode.driving:
        fallbackMinutes = estimateTravelDurationMinutes(straightDist);
        break;
      case TravelMode.motorcycle:
        fallbackMinutes = (estimateTravelDurationMinutes(straightDist) * 0.85)
            .round()
            .clamp(1, 999);
        break;
      case TravelMode.walking:
        fallbackMinutes = (straightDist / 4.8 * 60.0).round().clamp(1, 999);
        break;
    }

    final fallbackSteps = [
      OsmRouteStep(
        instruction: 'เริ่มต้นออกเดินทางจากตำแหน่งของคุณ',
        distanceMeters: 0,
        durationSeconds: 0,
        type: 'depart',
        modifier: 'straight',
      ),
      OsmRouteStep(
        instruction:
            'มุ่งหน้าตามเส้นทางตรงไปยังร้านค้า (${straightDist.toStringAsFixed(1)} กม.)',
        distanceMeters: straightDist * 1000,
        durationSeconds: fallbackMinutes * 60.0,
        type: 'continue',
        modifier: 'straight',
      ),
      OsmRouteStep(
        instruction: 'ถึงจุดหมายปลายทางร้านค้าเป้าหมาย',
        distanceMeters: 0,
        durationSeconds: 0,
        type: 'arrive',
        modifier: 'straight',
      ),
    ];

    return OsmRouteResult(
      points: [LatLng(startLat, startLon), LatLng(endLat, endLon)],
      distanceKm: straightDist,
      durationMinutes: fallbackMinutes,
      steps: fallbackSteps,
      travelMode: mode,
    );
  }

  /// คำนวณระยะทางตรงระหว่างสองพิกัด (Haversine Formula) เป็นกิโลเมตร
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// ประมาณการระยะเวลาเดินทาง (นาที) สำหรับรถยนต์
  static int estimateTravelDurationMinutes(double distanceKm) {
    if (distanceKm <= 0) return 1;
    final hours = distanceKm / 40.0;
    return (hours * 60).round().clamp(1, 999);
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);
}
