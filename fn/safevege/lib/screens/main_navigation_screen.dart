import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../services/user_location_service.dart';
import '../widgets/common_widgets.dart';
import 'guest/explore_feed_tab.dart';
import 'guest/explore_map_tab.dart';
import 'guest/certificates_hub_tab.dart';
import 'common/account_portal_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    required this.appState,
    this.initialIndex = 1,
  });

  final AppState appState;
  final int initialIndex;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  String _selectedCategory = 'ทั้งหมด';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 0: หน้าหลัก, 1: แผนที่, 2: สแกน QR, 3: ใบรับรอง, 4: บัญชี
    switch (widget.initialIndex) {
      case 0:
        _currentIndex = 0;
        break;
      case 1:
        _currentIndex = 1;
        break;
      case 2:
        _currentIndex = 2;
        break;
      case 3:
        _currentIndex = 3;
        break;
      case 4:
        _currentIndex = 4;
        break;
      default:
        _currentIndex = 1;
        break;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setIndex(int idx) {
    if (_currentIndex == idx) return;
    setState(() => _currentIndex = idx);
  }

  void _openCertificates() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CertificatesHubTab(appState: widget.appState),
      ),
    );
  }

  Future<void> _setSelectedCategory(String category) async {
    if (category == 'ใกล้ฉัน' && widget.appState.nearbyOrigin == null) {
      try {
        final location = await const UserLocationService().getCurrentLocation();
        if (!mounted) return;
        widget.appState.setNearbyOrigin(location);
      } on UserLocationException catch (error) {
        if (mounted) AppFeedback.showError(context, error.message);
        return;
      }
    } else if (category != 'ใกล้ฉัน' &&
        _selectedCategory == 'ใกล้ฉัน' &&
        widget.appState.nearbyOrigin != null) {
      widget.appState.setNearbyOrigin(null);
    }

    try {
      await widget.appState.loadPublicShops(
        query: _searchController.text.trim(),
        near: category == 'ใกล้ฉัน' ? widget.appState.nearbyOrigin : null,
      );
    } catch (error) {
      if (mounted) AppFeedback.showError(context, error.toString());
    }

    if (mounted) setState(() => _selectedCategory = category);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppDarkColors.primary : AppColors.primary;

    return Scaffold(
      backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
      body: Row(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppContentWidth.page,
                ),
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    // Tab 0: หน้าหลัก
                    ExploreFeedTab(
                      appState: widget.appState,
                      searchController: _searchController,
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: _setSelectedCategory,
                      onOpenMap: () => _setIndex(1),
                      onOpenCertificates: _openCertificates,
                      onOpenAccount: () => _setIndex(4),
                    ),
                    // Tab 1: แผนที่
                    ExploreMapTab(
                      appState: widget.appState,
                      searchController: _searchController,
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: _setSelectedCategory,
                      onSwitchToFeed: () => _setIndex(0),
                    ),
                    // Tab 2: สแกน QR
                    _QrScannerTab(appState: widget.appState),
                    // Tab 3: ใบรับรองความปลอดภัย
                    CertificatesHubTab(appState: widget.appState),
                    // Tab 4: บัญชีและบทบาท
                    AccountPortalTab(appState: widget.appState),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppContentWidth.page),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xE6141D17)
                      : Colors.white.withOpacity(0.92),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppDarkColors.border
                          : const Color(0x18000000),
                      width: 0.7,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  height: 64,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _setIndex,
                  indicatorColor: primaryColor.withOpacity(
                    isDark ? 0.22 : 0.14,
                  ),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(CupertinoIcons.house, size: 21),
                      selectedIcon: Icon(
                        CupertinoIcons.house_fill,
                        size: 22,
                        color: primaryColor,
                      ),
                      label: 'หน้าหลัก',
                    ),
                    NavigationDestination(
                      icon: const Icon(CupertinoIcons.map, size: 21),
                      selectedIcon: Icon(
                        CupertinoIcons.map_fill,
                        size: 22,
                        color: primaryColor,
                      ),
                      label: 'แผนที่',
                    ),
                    NavigationDestination(
                      icon: const Icon(
                        CupertinoIcons.qrcode_viewfinder,
                        size: 22,
                      ),
                      selectedIcon: Icon(
                        CupertinoIcons.qrcode_viewfinder,
                        size: 23,
                        color: primaryColor,
                      ),
                      label: 'สแกน QR',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: true,
                        label: Text(
                          widget.appState.publicCertificates.isNotEmpty
                              ? '${widget.appState.publicCertificates.length}'
                              : '2',
                        ),
                        backgroundColor: primaryColor,
                        textStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        child: const Icon(
                          CupertinoIcons.doc_text,
                          size: 21,
                        ),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: true,
                        label: Text(
                          widget.appState.publicCertificates.isNotEmpty
                              ? '${widget.appState.publicCertificates.length}'
                              : '2',
                        ),
                        backgroundColor: primaryColor,
                        textStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        child: Icon(
                          CupertinoIcons.doc_text_fill,
                          size: 22,
                          color: primaryColor,
                        ),
                      ),
                      label: 'ใบรับรอง',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible:
                            widget.appState.isShopLoggedIn ||
                            widget.appState.isAdminLoggedIn,
                        smallSize: 7,
                        backgroundColor: primaryColor,
                        child: const Icon(
                          CupertinoIcons.person_crop_circle,
                          size: 21,
                        ),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible:
                            widget.appState.isShopLoggedIn ||
                            widget.appState.isAdminLoggedIn,
                        smallSize: 7,
                        backgroundColor: primaryColor,
                        child: Icon(
                          CupertinoIcons.person_crop_circle_fill,
                          size: 22,
                          color: primaryColor,
                        ),
                      ),
                      label: 'บัญชี',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QrScannerTab extends StatelessWidget {
  const _QrScannerTab({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppDarkColors.primary : AppColors.primary;

    return Scaffold(
      backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF13281C) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryColor, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.qrcode_viewfinder,
                        size: 90,
                        color: primaryColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'วาง QR Code ในกรอบเพื่อสแกน',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'สแกน QR Code ตรวจสอบผักปลอดภัย',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F5A3C),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'สแกน QR Code บนใบรับรองหน้าร้านค้า เพื่อตรวจสอบรายงานผลตรวจสารพิษตกค้างอย่างแม่นยำ',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CertificatesHubTab(appState: appState),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(CupertinoIcons.doc_text, size: 16),
                label: const Text('ค้นหาใบรับรองด้วยตนเอง'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
