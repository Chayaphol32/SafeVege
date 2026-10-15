import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/interactive_map.dart';

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String formattedAddress;

  LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
  });
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialLatitude = 19.9072,
    this.initialLongitude = 99.8325,
  });

  final double initialLatitude;
  final double initialLongitude;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late double _latitude;
  late double _longitude;
  String _address = 'ต.รอบเวียง อ.เมืองเชียงราย จ.เชียงราย';

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
  }

  void _onPinMoved(Offset point) {
    setState(() {
      _latitude = double.parse(point.dx.toStringAsFixed(6));
      _longitude = double.parse(point.dy.toStringAsFixed(6));
      _address = 'พิกัด ($latitudeStr, $longitudeStr) อ.เมืองเชียงราย';
    });
  }

  String get latitudeStr => _latitude.toStringAsFixed(6);
  String get longitudeStr => _longitude.toStringAsFixed(6);

  void _useCurrentLocation() {
    setState(() {
      _latitude = 19.9072;
      _longitude = 99.8325;
      _address =
          'ตำแหน่งปัจจุบันของคุณ (หอนาฬิกาเชียงราย ต.เวียง อ.เมืองเชียงราย)';
    });
    AppFeedback.showSuccess(context, 'ดึงพิกัดจากตำแหน่งปัจจุบันเรียบร้อยแล้ว');
  }

  void _confirmSelection() {
    Navigator.pop(
      context,
      LocationPickerResult(
        latitude: _latitude,
        longitude: _longitude,
        formattedAddress: _address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text('เลือกตำแหน่งร้านค้า'),
        actions: [
          TextButton(
            onPressed: _confirmSelection,
            child: const Text(
              'ยืนยัน',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Map section
            Expanded(
              child: Stack(
                children: [
                  SafeVegeInteractiveMap(
                    height: double.infinity,
                    isPicker: true,
                    onLocationPicked: _onPinMoved,
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    right: 60,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 18,
                            color: AppColors.primaryOf(context),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'แตะบนแผนที่ OpenStreetMap เพื่อกำหนดตำแหน่งร้าน',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Coordinates & Address Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundOf(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.pin_drop_rounded,
                          color: AppColors.primaryOf(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Latitude: $latitudeStr',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Longitude: $longitudeStr',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _useCurrentLocation,
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 36),
                        ),
                        icon: const Icon(Icons.my_location, size: 15),
                        label: const Text(
                          'ใช้ตำแหน่งปัจจุบัน',
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundOf(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderOf(context)),
                    ),
                    child: Text(
                      'ที่อยู่โดยประมาณ: $_address',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('ยกเลิก'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _confirmSelection,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('ยืนยันตำแหน่งนี้'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
