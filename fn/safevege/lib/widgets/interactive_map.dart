import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../models/app_models.dart';
import '../services/osm_map_service.dart';
import '../theme/app_theme.dart';

/// แผนที่ OpenStreetMap แบบ Native Flutter 100% (ฟรี ไม่ต้องใช้ API Key, ลื่นไหล และเสถียร)
class SafeVegeInteractiveMap extends StatefulWidget {
  const SafeVegeInteractiveMap({
    super.key,
    this.height = 280,
    this.compact = false,
    this.shops = const [],
    this.selectedShop,
    this.onShopTap,
    this.isPicker = false,
    this.pickedLocation,
    this.onLocationPicked,
    this.isFullScreen = false,
    this.routeStart,
    this.routeEnd,
    this.travelMode = TravelMode.driving,
    this.onRouteCalculated,
    this.focusLocation,
    this.focusZoom,
  });

  final double height;
  final bool compact;
  final List<ShopModel> shops;
  final ShopModel? selectedShop;
  final ValueChanged<ShopModel>? onShopTap;
  final bool isPicker;
  final Offset? pickedLocation;
  final ValueChanged<Offset>? onLocationPicked;

  final bool isFullScreen;
  final GeoPoint? routeStart;
  final GeoPoint? routeEnd;
  final TravelMode travelMode;
  final ValueChanged<OsmRouteResult>? onRouteCalculated;
  final LatLng? focusLocation;
  final double? focusZoom;

  @override
  State<SafeVegeInteractiveMap> createState() => _SafeVegeInteractiveMapState();
}

class _SafeVegeInteractiveMapState extends State<SafeVegeInteractiveMap> {
  static const double _fallbackLatitude = 19.9112; // เชียงราย
  static const double _fallbackLongitude = 99.8354;

  final MapController _mapController = MapController();
  ShopModel? _activeShop;
  Offset? _pickerLocation;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  GeoPoint? _lastFetchedStart;
  GeoPoint? _lastFetchedEnd;
  TravelMode? _lastFetchedMode;

  @override
  void initState() {
    super.initState();
    _activeShop = widget.selectedShop;
    _pickerLocation = widget.pickedLocation;
    _checkAndFetchRoute();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SafeVegeInteractiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedShop?.id != oldWidget.selectedShop?.id) {
      _activeShop = widget.selectedShop;
      if (widget.selectedShop != null) {
        _animateTo(
          widget.selectedShop!.latitude,
          widget.selectedShop!.longitude,
          15.0,
        );
      }
    }
    if (widget.pickedLocation != oldWidget.pickedLocation) {
      setState(() => _pickerLocation = widget.pickedLocation);
    }
    final routeStartChanged = widget.routeStart != oldWidget.routeStart;
    final routeEndChanged = widget.routeEnd != oldWidget.routeEnd;
    final travelModeChanged = widget.travelMode != oldWidget.travelMode;
    if (routeStartChanged || routeEndChanged || travelModeChanged) {
      _checkAndFetchRoute();
    }
    if (widget.focusLocation != null &&
        widget.focusLocation != oldWidget.focusLocation) {
      _animateTo(
        widget.focusLocation!.latitude,
        widget.focusLocation!.longitude,
        widget.focusZoom ?? 16.0,
      );
    }
  }

  Future<void> _checkAndFetchRoute() async {
    final start = widget.routeStart;
    final end = widget.routeEnd;
    if (start == null || end == null) {
      if (_routePoints.isNotEmpty) {
        setState(() => _routePoints = []);
      }
      _lastFetchedStart = null;
      _lastFetchedEnd = null;
      _lastFetchedMode = null;
      return;
    }

    if (start == _lastFetchedStart &&
        end == _lastFetchedEnd &&
        widget.travelMode == _lastFetchedMode &&
        _routePoints.isNotEmpty) {
      return;
    }

    _lastFetchedStart = start;
    _lastFetchedEnd = end;
    _lastFetchedMode = widget.travelMode;

    setState(() => _isLoadingRoute = true);
    final result = await OsmMapService.fetchDrivingRoute(
      startLat: start.latitude,
      startLon: start.longitude,
      endLat: end.latitude,
      endLon: end.longitude,
      mode: widget.travelMode,
    );

    if (!mounted) return;
    setState(() {
      _routePoints = result.points;
      _isLoadingRoute = false;
    });

    widget.onRouteCalculated?.call(result);

    if (_routePoints.length >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(_routePoints),
              padding: const EdgeInsets.all(52),
            ),
          );
        } catch (_) {}
      });
    }
  }

  double get _centerLatitude =>
      widget.selectedShop?.latitude ??
      _pickerLocation?.dx ??
      (widget.shops.isNotEmpty
          ? widget.shops.first.latitude
          : _fallbackLatitude);

  double get _centerLongitude =>
      widget.selectedShop?.longitude ??
      _pickerLocation?.dy ??
      (widget.shops.isNotEmpty
          ? widget.shops.first.longitude
          : _fallbackLongitude);

  double get _initialZoom => widget.shops.isEmpty && _pickerLocation == null
      ? 6.0
      : (widget.compact ? 12.5 : 13.8);

  void _animateTo(double latitude, double longitude, double zoom) {
    try {
      _mapController.move(LatLng(latitude, longitude), zoom);
    } catch (_) {}
  }

  void _onMapTap(TapPosition _, LatLng point) {
    if (!widget.isPicker) return;
    final newLoc = Offset(point.latitude, point.longitude);
    setState(() => _pickerLocation = newLoc);
    widget.onLocationPicked?.call(newLoc);
  }

  void _onShopTap(ShopModel shop) {
    setState(() => _activeShop = shop);
    _animateTo(shop.latitude, shop.longitude, 15.2);
    widget.onShopTap?.call(shop);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F2),
        borderRadius: widget.isFullScreen
            ? BorderRadius.zero
            : BorderRadius.circular(16),
        border: widget.isFullScreen
            ? null
            : Border.all(color: AppColors.borderOf(context), width: 1.2),
        boxShadow: widget.isFullScreen ? null : AppShadows.cardOf(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Native FlutterMap Widget with OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_centerLatitude, _centerLongitude),
              initialZoom: _initialZoom,
              minZoom: 4.0,
              maxZoom: 19.0,
              onTap: _onMapTap,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // OpenStreetMap Tile Layer (ฟรี 100% ไม่มีลายน้ำ ไม่ต้องใช้ API Key)
              if (Theme.of(context).brightness == Brightness.dark)
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    -0.2093,
                    -0.4109,
                    -0.0798,
                    0,
                    180,
                    -0.2093,
                    -0.4109,
                    -0.0798,
                    0,
                    195,
                    -0.2093,
                    -0.4109,
                    -0.0798,
                    0,
                    185,
                    0,
                    0,
                    0,
                    1.0,
                    0,
                  ]),
                  child: TileLayer(
                    urlTemplate: AppConfig.osmTileUrl,
                    fallbackUrl: AppConfig.osmFallbackTileUrl,
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.safevege.safevege',
                    tileProvider: NetworkTileProvider(
                      headers: <String, String>{
                        'User-Agent': 'SafeVege/1.0 (com.safevege.safevege; mail: info@safevege.app)',
                      },
                    ),
                    maxZoom: 19,
                    errorTileCallback: (tile, error, stackTrace) {
                      debugPrint(
                        'SafeVege Map Tile load failed: $tile ($error)',
                      );
                    },
                  ),
                )
              else
                TileLayer(
                  urlTemplate: AppConfig.osmTileUrl,
                  fallbackUrl: AppConfig.osmFallbackTileUrl,
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.safevege.safevege',
                  tileProvider: NetworkTileProvider(
                    headers: <String, String>{
                      'User-Agent': 'SafeVege/1.0 (com.safevege.safevege; mail: info@safevege.app)',
                    },
                  ),
                  maxZoom: 19,
                  errorTileCallback: (tile, error, stackTrace) {
                    debugPrint('SafeVege Map Tile load failed: $tile ($error)');
                  },
                ),

              // OSRM Driving Route Polyline Layer
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 7.0,
                      color: const Color(0xFF064E3B),
                    ),
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.5,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),

              // Markers Layer
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),

          // Floating Zoom & My Location Controls
          Positioned(
            left: widget.isFullScreen ? 12 : null,
            right: widget.isFullScreen ? null : 12,
            top: widget.isFullScreen ? 150 : 12,
            child: Column(
              children: [
                _buildMapButton(
                  icon: Icons.add,
                  tooltip: 'ซูมเข้า',
                  onTap: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      (zoom + 1).clamp(4.0, 19.0),
                    );
                  },
                ),
                const SizedBox(height: 6),
                _buildMapButton(
                  icon: Icons.remove,
                  tooltip: 'ซูมออก',
                  onTap: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      (zoom - 1).clamp(4.0, 19.0),
                    );
                  },
                ),
                const SizedBox(height: 6),
                _buildMapButton(
                  icon: Icons.my_location_rounded,
                  tooltip: widget.isPicker
                      ? 'กลับไปยังตำแหน่งที่เลือก'
                      : 'จัดแผนที่ให้อยู่ตรงกลาง',
                  onTap: () => _animateTo(
                    _centerLatitude,
                    _centerLongitude,
                    _initialZoom,
                  ),
                  color: AppColors.primaryOf(context),
                ),
              ],
            ),
          ),

          // OpenStreetMap Attribution badge
          Positioned(
            left: 8,
            bottom: widget.isPicker || (_activeShop != null && !widget.compact)
                ? 100
                : 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xCC18201B)
                    : Colors.white.withOpacity(0.82),
                borderRadius: BorderRadius.circular(4),
                border: Theme.of(context).brightness == Brightness.dark
                    ? Border.all(color: AppDarkColors.border, width: 0.5)
                    : null,
              ),
              child: Text(
                Theme.of(context).brightness == Brightness.dark
                    ? '© OpenStreetMap contributors, © CARTO'
                    : AppConfig.mapAttribution,
                style: TextStyle(
                  fontSize: 9.5,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppDarkColors.textSecondary
                      : AppColors.textSecondaryOf(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Route Loading Indicator
          if (_isLoadingRoute)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppDarkColors.surfaceElevated
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Theme.of(context).brightness == Brightness.dark
                      ? Border.all(color: AppDarkColors.border, width: 0.8)
                      : null,
                  boxShadow: AppShadows.cardOf(context),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppDarkColors.primary
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'กำลังคำนวณเส้นทาง...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppDarkColors.textPrimary
                            : AppColors.textPrimaryOf(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Location Picker Coordinate Status Chip
          if (widget.isPicker && _pickerLocation != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderOf(context)),
                  boxShadow: AppShadows.cardOf(context),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.pin_drop_rounded,
                      color: AppColors.primaryOf(context),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'พิกัดที่เลือก: ${_pickerLocation!.dx.toStringAsFixed(5)}, ${_pickerLocation!.dy.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                    ),
                    Text(
                      'แตะเพื่อเปลี่ยนจุด',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Selected Shop Preview Card (when not compact & not picker & not fullscreen)
          if (_activeShop != null &&
              !widget.compact &&
              !widget.isPicker &&
              !widget.isFullScreen)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _buildPreviewCard(_activeShop!),
            ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];

    // 1. Location Picker Pin
    if (widget.isPicker) {
      if (_pickerLocation != null) {
        markers.add(
          Marker(
            point: LatLng(_pickerLocation!.dx, _pickerLocation!.dy),
            width: 48,
            height: 48,
            child: _buildPickerPin(),
          ),
        );
      }
      return markers;
    }

    // 2. Shop Pins
    for (final shop in widget.shops) {
      final isSelected = _activeShop?.id == shop.id;
      markers.add(
        Marker(
          point: LatLng(shop.latitude, shop.longitude),
          width: isSelected ? 48 : 40,
          height: isSelected ? 48 : 40,
          child: GestureDetector(
            onTap: () => _onShopTap(shop),
            child: _buildShopPin(shop, isSelected),
          ),
        ),
      );
    }

    // 3. Route Start Pin
    if (widget.routeStart != null) {
      markers.add(
        Marker(
          point: LatLng(
            widget.routeStart!.latitude,
            widget.routeStart!.longitude,
          ),
          width: 38,
          height: 38,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    // 4. Route Destination Pin
    if (widget.routeEnd != null) {
      markers.add(
        Marker(
          point: LatLng(widget.routeEnd!.latitude, widget.routeEnd!.longitude),
          width: 42,
          height: 42,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.flag_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildShopPin(ShopModel shop, bool isSelected) {
    final bgColor = shop.isVerified ? AppColors.primary : AppColors.warning;

    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: isSelected ? 1.15 : 1.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: isSelected ? 44 : 36,
            height: isSelected ? 44 : 36,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: isSelected ? 3.0 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? bgColor.withOpacity(0.5)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: isSelected ? 10 : 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              shop.isVerified ? Icons.eco_rounded : Icons.storefront_rounded,
              color: Colors.white,
              size: isSelected ? 24 : 19,
            ),
          ),
          if (shop.isVerified)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.secondary,
                  size: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPickerPin() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: const Icon(Icons.location_pin, color: Colors.white, size: 30),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        color ??
        (isDark ? AppDarkColors.textPrimary : AppColors.textPrimaryOf(context));
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xE61E2822)
            : Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(10),
        border: isDark
            ? Border.all(color: AppDarkColors.border, width: 0.8)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 20),
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildPreviewCard(ShopModel shop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => widget.onShopTap?.call(shop),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppDarkColors.surfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppDarkColors.border : AppColors.borderOf(context),
            width: 0.8,
          ),
          boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardOf(context),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isDark ? AppDarkColors.primary : AppColors.primary)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.storefront_rounded,
                color: isDark ? AppDarkColors.primary : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark
                                ? AppDarkColors.textPrimary
                                : AppColors.textPrimaryOf(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (shop.isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          color: isDark
                              ? AppDarkColors.secondary
                              : AppColors.secondary,
                          size: 15,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${shop.shortArea} • ห่าง ${shop.distanceText}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? AppDarkColors.textSecondary
                          : AppColors.textSecondaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ผักรับรอง: ${shop.verifiedVegetables.join(', ')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppDarkColors.primary : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => widget.onShopTap?.call(shop),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              tooltip: 'ดูรายละเอียด',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
