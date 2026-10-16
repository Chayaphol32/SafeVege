import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/app_models.dart';
import '../../services/osm_map_service.dart';
import '../../services/user_location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/interactive_map.dart';

class RouteNavigationScreen extends StatefulWidget {
  const RouteNavigationScreen({super.key, required this.shop});

  final ShopModel shop;

  @override
  State<RouteNavigationScreen> createState() => _RouteNavigationScreenState();
}

class _RouteNavigationScreenState extends State<RouteNavigationScreen> {
  GeoPoint? _origin;
  GeoPoint? _originCandidate;
  bool _isSelectingOrigin = false;
  bool _isGettingLocation = false;
  String? _originLabel;

  final TravelMode _travelMode = TravelMode.driving;
  OsmRouteResult? _routeResult;
  bool _isNavigating = false;
  int _currentStepIndex = 0;
  LatLng? _focusLocation;

  late final GeoPoint _destination = GeoPoint(
    latitude: widget.shop.latitude,
    longitude: widget.shop.longitude,
  );

  @override
  void initState() {
    super.initState();
    // ค้นหาตำแหน่งปัจจุบันอัตโนมัติเมื่อเปิดหน้า
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _useCurrentLocation();
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final location = await const UserLocationService().getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _origin = location;
        _originLabel = 'ตำแหน่งปัจจุบันของคุณ';
        _originCandidate = null;
        _isSelectingOrigin = false;
      });
    } on UserLocationException catch (error) {
      if (mounted) {
        AppFeedback.showInfo(
          context,
          '${error.message} (สามารถแตะ "เลือกบนแผนที่" ได้)',
        );
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.showInfo(
          context,
          'ไม่สามารถเข้าถึง GPS ได้ในขณะนี้ ลองเลือกจุดเริ่มต้นบนแผนที่',
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _beginOriginSelection() {
    setState(() {
      _originCandidate = _origin;
      _isSelectingOrigin = true;
      _isNavigating = false;
    });
  }

  void _onOriginPicked(Offset location) {
    setState(() {
      _originCandidate = GeoPoint(
        latitude: location.dx,
        longitude: location.dy,
      );
    });
  }

  void _confirmOriginSelection() {
    final candidate = _originCandidate;
    if (candidate == null) {
      AppFeedback.showError(context, 'แตะบนแผนที่เพื่อเลือกจุดเริ่มต้นก่อน');
      return;
    }
    setState(() {
      _origin = candidate;
      _originLabel = 'จุดเริ่มต้นที่เลือก';
      _isSelectingOrigin = false;
      _originCandidate = null;
    });
  }

  void _cancelOriginSelection() {
    setState(() {
      _isSelectingOrigin = false;
      _originCandidate = null;
    });
  }

  void _clearRoute() {
    setState(() {
      _origin = null;
      _originCandidate = null;
      _originLabel = null;
      _isSelectingOrigin = false;
      _routeResult = null;
      _isNavigating = false;
      _currentStepIndex = 0;
    });
  }

  void _onRouteCalculated(OsmRouteResult result) {
    if (_routeResult?.distanceKm == result.distanceKm &&
        _routeResult?.durationMinutes == result.durationMinutes &&
        _routeResult?.points.length == result.points.length &&
        _routeResult?.travelMode == result.travelMode) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _routeResult = result;
      if (_currentStepIndex >= result.steps.length) {
        _currentStepIndex = 0;
      }
    });
  }


  void _startNavigation() {
    _openExternalGoogleMaps();
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _currentStepIndex = 0;
    });
  }

  Future<void> _openExternalGoogleMaps() async {
    final originParam = _origin != null
        ? '&origin=${_origin!.latitude},${_origin!.longitude}'
        : '';
    String travelModeParam = 'driving';
    if (_travelMode == TravelMode.motorcycle) travelModeParam = 'two-wheeler';
    if (_travelMode == TravelMode.walking) travelModeParam = 'walking';

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1$originParam&destination=${widget.shop.latitude},${widget.shop.longitude}&travelmode=$travelModeParam',
    );

    try {
      final mode = kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication;
      final launched = await launchUrl(
        uri,
        mode: mode,
        webOnlyWindowName: '_blank',
      );
      if (!launched && mounted) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(context, 'ไม่สามารถเปิดแอปแผนที่ภายนอกได้');
      }
    }
  }

  void _showStepDetailsModal() {
    final steps = _routeResult?.steps ?? [];
    if (steps.isEmpty) {
      AppFeedback.showInfo(context, 'ไม่มีขั้นตอนการเดินทางให้แสดง');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.surfaceElevated : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.turn_right_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ขั้นตอนเส้นทางทั้งหมด',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ระยะทางรวม ${_routeResult?.formattedDistance ?? ''} • ประมาณ ${_routeResult?.formattedDuration ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppDarkColors.textSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: steps.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 48),
                  itemBuilder: (context, index) {
                    final step = steps[index];
                    final isCurrent = index == _currentStepIndex;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _currentStepIndex = index;
                        });
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppColors.primary
                                    : (isDark
                                          ? AppDarkColors.background
                                          : Colors.grey.shade100),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getManeuverIcon(step.type, step.modifier),
                                size: 18,
                                color: isCurrent
                                    ? Colors.white
                                    : (isDark
                                          ? AppDarkColors.textSecondary
                                          : Colors.black87),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.instruction,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isCurrent
                                          ? AppColors.primary
                                          : null,
                                    ),
                                  ),
                                  if (step.distanceMeters > 0) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      '${step.formattedDistance} (${step.formattedDuration})',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark
                                            ? AppDarkColors.textSecondary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ขั้นตอนปัจจุบัน',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getManeuverIcon(String type, String modifier) {
    if (type == 'depart') return Icons.navigation_rounded;
    if (type == 'arrive') return Icons.flag_rounded;
    if (type == 'roundabout' || type == 'rotary') {
      return Icons.roundabout_left_rounded;
    }
    if (type == 'uturn') return Icons.u_turn_left_rounded;
    if (modifier.contains('left')) return Icons.turn_left_rounded;
    if (modifier.contains('right')) return Icons.turn_right_rounded;
    return Icons.arrow_upward_rounded;
  }

  String _getEstimatedArrivalClock() {
    final durMinutes = _routeResult?.durationMinutes ?? 0;
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: durMinutes));
    final hour = arrival.hour.toString().padLeft(2, '0');
    final minute = arrival.minute.toString().padLeft(2, '0');
    return '$hour:$minute น.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: _isNavigating ? null : _buildStandardAppBar(context),
      body: SafeArea(
        top: !_isNavigating,
        child: Stack(
          children: [
            // Map
            Positioned.fill(
              child: SafeVegeInteractiveMap(
                height: double.infinity,
                isFullScreen: true,
                shops: _isSelectingOrigin ? const [] : [widget.shop],
                selectedShop: widget.shop,
                isPicker: _isSelectingOrigin,
                pickedLocation: _isSelectingOrigin
                    ? (_originCandidate == null
                          ? null
                          : Offset(
                              _originCandidate!.latitude,
                              _originCandidate!.longitude,
                            ))
                    : null,
                onLocationPicked: _onOriginPicked,
                routeStart: _isSelectingOrigin ? null : _origin,
                routeEnd: _destination,
                travelMode: _travelMode,
                onRouteCalculated: _onRouteCalculated,
                focusLocation: _focusLocation,
              ),
            ),

            // Top Overlay (HUD or Origin Picker prompt)
            if (_isNavigating)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: _buildNavigationHUDTop(isDark),
              )
            else if (_isSelectingOrigin)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: _buildOriginPickerPrompt(context),
              )
            else
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: _buildStoreHeaderCard(context, isDark),
              ),

            // Bottom Overlay (HUD control bar or Route setup actions)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _isNavigating
                  ? _buildNavigationHUDBottom(isDark)
                  : _buildRouteSetupPanel(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildStandardAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'ระบบนำทางไปยังร้านค้า',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      ),
      leading: IconButton(
        icon: const Icon(CupertinoIcons.back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          tooltip: 'เปิดใน Google Maps',
          icon: const Icon(Icons.map_outlined),
          onPressed: _openExternalGoogleMaps,
        ),
      ],
    );
  }

  Widget _buildStoreHeaderCard(BuildContext context, bool isDark) {
    final primaryColor = isDark ? AppDarkColors.primary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark
            ? AppDarkColors.surfaceElevated.withOpacity(0.96)
            : Colors.white.withOpacity(0.96),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.shop.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppDarkColors.textPrimary
                              : AppColors.textPrimaryOf(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.shop.isVerified) ...[
                      const SizedBox(width: 5),
                      Icon(
                        Icons.verified_rounded,
                        color: primaryColor,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.shop.fullAddress,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppDarkColors.textSecondary
                        : AppColors.textSecondaryOf(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.shop.phone.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? primaryColor.withOpacity(0.18)
                    : const Color(0xFFE8F7EC),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  CupertinoIcons.phone_fill,
                  color: primaryColor,
                  size: 18,
                ),
                tooltip: 'โทรหาร้านค้า',
                onPressed: () {
                  final uri = Uri.parse('tel:${widget.shop.phone}');
                  launchUrl(uri);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOriginPickerPrompt(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.touch_app_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'แตะจุดบนแผนที่ เพื่อตั้งเป็นจุดเริ่มต้นเดินทาง',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationHUDTop(bool isDark) {
    final steps = _routeResult?.steps ?? [];
    final currentStep = steps.isNotEmpty && _currentStepIndex < steps.length
        ? steps[_currentStepIndex]
        : null;

    final maneuverIcon = currentStep != null
        ? _getManeuverIcon(currentStep.type, currentStep.modifier)
        : Icons.navigation_rounded;

    final instruction = currentStep?.instruction ?? 'มุ่งหน้าไปตามเส้นทาง';
    final distance = currentStep?.formattedDistance ?? '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(maneuverIcon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (distance.isNotEmpty)
                      Text(
                        'อีก $distance',
                        style: const TextStyle(
                          color: Color(0xFF6EE7B7),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      instruction,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                tooltip: 'สิ้นสุดการนำทาง',
                onPressed: _stopNavigation,
              ),
            ],
          ),
          if (steps.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: _currentStepIndex > 0
                      ? () => setState(() => _currentStepIndex--)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 13,
                          color: _currentStepIndex > 0
                              ? Colors.white70
                              : Colors.white24,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ก่อนหน้า',
                          style: TextStyle(
                            fontSize: 11,
                            color: _currentStepIndex > 0
                                ? Colors.white70
                                : Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  'ขั้นตอน ${_currentStepIndex + 1} จาก ${steps.length}',
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
                InkWell(
                  onTap: _currentStepIndex < steps.length - 1
                      ? () => setState(() => _currentStepIndex++)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'ถัดไป',
                          style: TextStyle(
                            fontSize: 11,
                            color: _currentStepIndex < steps.length - 1
                                ? Colors.white70
                                : Colors.white24,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: _currentStepIndex < steps.length - 1
                              ? Colors.white70
                              : Colors.white24,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationHUDBottom(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _routeResult?.formattedDuration ?? '~ นาที',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${_routeResult?.formattedDistance ?? ''})',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppDarkColors.textSecondary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'คาดว่าจะถึง ${_getEstimatedArrivalClock()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppDarkColors.textSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _showStepDetailsModal,
                    icon: const Icon(Icons.list_alt_rounded, size: 18),
                    label: const Text('ขั้นตอน'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _stopNavigation,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('หยุดนำทาง'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'โหมด: ${_travelMode.label}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? AppDarkColors.textMuted : AppColors.textMuted,
                ),
              ),
              InkWell(
                onTap: _openExternalGoogleMaps,
                child: const Row(
                  children: [
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'เปิด Google Maps เสียงจริง',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSetupPanel(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderOf(context), width: 0.8),
        boxShadow: AppShadows.cardOf(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Origin status row
          if (_isSelectingOrigin)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _originCandidate == null
                        ? 'แตะบนแผนที่เพื่อเลือกพิกัดจุดเริ่มต้น'
                        : 'พิกัดที่เลือก: ${_originCandidate!.latitude.toStringAsFixed(4)}, ${_originCandidate!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _cancelOriginSelection,
                  child: const Text('ยกเลิก'),
                ),
                FilledButton(
                  onPressed: _originCandidate != null
                      ? _confirmOriginSelection
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('ใช้จุดนี้'),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7)
                        .withOpacity(isDark ? 0.22 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.location_fill,
                    size: 15,
                    color: isDark
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _origin == null
                            ? 'ยังไม่ได้ระบุจุดเริ่มต้น'
                            : (_originLabel ?? 'จุดเริ่มต้น'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppDarkColors.textPrimary
                              : AppColors.textPrimaryOf(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _origin == null
                            ? 'กดปุ่มด้านล่างเพื่อค้นหาตำแหน่ง'
                            : 'ปลายทาง: ${widget.shop.name}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppDarkColors.textSecondary
                              : AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_origin != null)
                  TextButton(
                    onPressed: _clearRoute,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      'ล้าง',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppDarkColors.primary
                            : AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            if (_routeResult != null && _origin != null)
              const SizedBox(height: 10),

            // Stats row (if route calculated)
            if (_routeResult != null && _origin != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppDarkColors.surfaceElevated
                      : const Color(0xFFF3F7F4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (isDark ? AppDarkColors.primary : AppColors.primary)
                        .withOpacity(0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: isDark
                                ? AppDarkColors.primary
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _routeResult!.formattedDuration,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppDarkColors.primary
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '•  ${_routeResult!.formattedDistance}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppDarkColors.textSecondary
                                  : AppColors.textSecondaryOf(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _showStepDetailsModal,
                      child: Row(
                        children: [
                          Text(
                            'ดู ${_routeResult!.steps.length} ขั้นตอน',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? AppDarkColors.primary
                                  : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: isDark
                                ? AppDarkColors.primary
                                : AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            if (_origin == null)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark
                            ? AppDarkColors.primary
                            : AppColors.primary,
                        foregroundColor: isDark
                            ? const Color(0xFF04200E)
                            : Colors.white,
                      ),
                      onPressed: _isGettingLocation
                          ? null
                          : _useCurrentLocation,
                      icon: _isGettingLocation
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark
                                    ? const Color(0xFF04200E)
                                    : Colors.white,
                              ),
                            )
                          : const Icon(Icons.my_location_rounded, size: 17),
                      label: const Text('ใช้ตำแหน่งปัจจุบัน (GPS)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AppDarkColors.primary
                          : AppColors.primary,
                      side: BorderSide(
                        color:
                            (isDark ? AppDarkColors.primary : AppColors.primary)
                                .withOpacity(0.4),
                      ),
                    ),
                    onPressed: _beginOriginSelection,
                    icon: const Icon(Icons.touch_app_outlined, size: 17),
                    label: const Text('เลือกบนแผนที่'),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark
                            ? AppDarkColors.primary
                            : AppColors.primary,
                        foregroundColor: isDark
                            ? const Color(0xFF04200E)
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _startNavigation,
                      icon: const Icon(Icons.navigation_rounded, size: 19),
                      label: const Text(
                        'เริ่มการนำทาง',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? AppDarkColors.primary
                            : AppColors.primary,
                        side: BorderSide(
                          color:
                              (isDark
                                      ? AppDarkColors.primary
                                      : AppColors.primary)
                                  .withOpacity(0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _openExternalGoogleMaps,
                      icon: const Icon(Icons.open_in_new_rounded, size: 17),
                      label: const Text(
                        'Google Maps',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'เปลี่ยนจุดเริ่มต้น',
                    icon: Icon(
                      Icons.tune_rounded,
                      color: isDark
                          ? AppDarkColors.textSecondary
                          : AppColors.textSecondaryOf(context),
                    ),
                    onPressed: _beginOriginSelection,
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

}
