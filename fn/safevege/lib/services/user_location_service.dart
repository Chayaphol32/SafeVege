import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/app_models.dart';

class UserLocationException implements Exception {
  const UserLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UserLocationService {
  const UserLocationService();

  Future<GeoPoint> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const UserLocationException(
        'กรุณาเปิดบริการตำแหน่ง หรือเลือกจุดเริ่มต้นบนแผนที่',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const UserLocationException(
        'ยังไม่ได้รับอนุญาตให้ใช้ตำแหน่ง คุณเลือกจุดเริ่มต้นบนแผนที่ได้',
      );
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      throw const UserLocationException(
        'ไม่สามารถเข้าถึงตำแหน่งได้ ตรวจสอบสิทธิ์ตำแหน่งในการตั้งค่า หรือเลือกจุดบนแผนที่',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on TimeoutException {
      throw const UserLocationException(
        'ค้นหาตำแหน่งไม่ทันเวลา ลองอีกครั้งหรือเลือกจุดบนแผนที่',
      );
    } catch (error) {
      if (error is UserLocationException) rethrow;
      throw const UserLocationException(
        'อ่านตำแหน่งไม่สำเร็จ ลองอีกครั้งหรือเลือกจุดบนแผนที่',
      );
    }
  }
}
