import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/interactive_animations.dart';
import 'create_request_screen.dart';
import 'my_requests_screen.dart';
import 'request_tracking_screen.dart';
import 'shop_profile_screen.dart';
import 'shop_results_screen.dart';

class ShopDashboardScreen extends StatefulWidget {
  const ShopDashboardScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen> {
  int _navIndex = 0;
  int _requestsFilterIndex = 0;

  void _switchTab(int index, {int filterIndex = 0}) {
    setState(() {
      _navIndex = index;
      _requestsFilterIndex = filterIndex;
    });
  }

  Future<void> _logout() async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'ออกจากระบบร้านค้า?',
      message: 'คุณต้องการออกจากระบบบัญชีร้านค้านี้ใช่หรือไม่?',
      confirmLabel: 'ออกจากระบบ',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      widget.appState.logoutShop();
      Navigator.popUntil(context, (r) => r.isFirst);
      AppFeedback.showSuccess(context, 'ออกจากระบบร้านค้าเรียบร้อยแล้ว');
    }
  }

  String _getThaiMonth(int month) {
    const months = [
      '',
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    if (month >= 1 && month <= 12) return months[month];
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final shop = widget.appState.currentShop;
        final myRequests = widget.appState.currentShopRequests;

        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(CupertinoIcons.arrow_left, size: 20),
                    tooltip: 'กลับสู่หน้ารวม',
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Row(
              children: [
                Image.asset(
                  'assets/safevege_logo.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                const Text(
                  'SafeVege เกษตรกร',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(CupertinoIcons.square_arrow_right, size: 20),
                tooltip: 'ออกจากระบบ',
                onPressed: _logout,
              ),
            ],
          ),
          body: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppContentWidth.page,
                      ),
                      child: MotionSwitcher(
                        child: KeyedSubtree(
                          key: ValueKey(_navIndex),
                          child: _navIndex == 0
                              ? _buildDashboardHome(shop, myRequests)
                              : _navIndex == 1
                              ? MyRequestsScreen(
                                  appState: widget.appState,
                                  initialFilterIndex: _requestsFilterIndex,
                                )
                              : ShopProfileScreen(appState: widget.appState),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppDarkColors.surfaceGlass
                      : Colors.white.withOpacity(0.92),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppDarkColors.border
                          : const Color(0x18000000),
                      width: 0.6,
                    ),
                  ),
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  height: 64,
                  selectedIndex: _navIndex,
                  onDestinationSelected: (idx) => _switchTab(idx),
                  indicatorColor:
                      (isDark ? AppDarkColors.primaryAccent : AppColors.primary)
                          .withOpacity(0.18),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(
                        CupertinoIcons.square_grid_2x2,
                        size: 21,
                      ),
                      selectedIcon: Icon(
                        CupertinoIcons.square_grid_2x2_fill,
                        size: 22,
                        color: isDark
                            ? AppDarkColors.primaryAccent
                            : AppColors.primary,
                      ),
                      label: 'หน้าหลัก',
                    ),
                    NavigationDestination(
                      icon: const Icon(CupertinoIcons.doc_text, size: 21),
                      selectedIcon: Icon(
                        CupertinoIcons.doc_text_fill,
                        size: 22,
                        color: isDark
                            ? AppDarkColors.primaryAccent
                            : AppColors.primary,
                      ),
                      label: 'คำขอตรวจ',
                    ),
                    NavigationDestination(
                      icon: const Icon(
                        CupertinoIcons.building_2_fill,
                        size: 21,
                      ),
                      selectedIcon: Icon(
                        CupertinoIcons.building_2_fill,
                        size: 22,
                        color: isDark
                            ? AppDarkColors.primaryAccent
                            : AppColors.primary,
                      ),
                      label: 'ร้านค้าของฉัน',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardHome(
    ShopModel shop,
    List<InspectionRequestModel> myRequests,
  ) {
    final pendingCount = myRequests
        .where((r) => r.status == RequestStatus.pending)
        .length;
    final scheduledCount = myRequests
        .where((r) => r.status == RequestStatus.scheduled)
        .length;
    final inProgressCount = myRequests
        .where((r) => r.status == RequestStatus.inProgress)
        .length;
    final completedCount = myRequests
        .where((r) => r.status == RequestStatus.completed)
        .length;

    // Find any active upcoming inspection (scheduled or in-progress)
    final upcomingRequest = myRequests
        .cast<InspectionRequestModel?>()
        .firstWhere(
          (r) =>
              r != null &&
              (r.status == RequestStatus.scheduled ||
                  r.status == RequestStatus.inProgress),
          orElse: () => null,
        );

    // Find completed request with certificate (if any)
    final certRequest = myRequests.cast<InspectionRequestModel?>().firstWhere(
      (r) => r != null && r.hasCertificate,
      orElse: () => myRequests.cast<InspectionRequestModel?>().firstWhere(
        (r) => r != null && r.isCompleted,
        orElse: () => null,
      ),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 840;

        if (isWide) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Profile + Hero Banner + Quick Services
                  Expanded(
                    flex: 11,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFarmHeaderCard(shop, certRequest, isDark),
                        const SizedBox(height: 16),
                        _buildHeroCreateRequestCard(isDark),
                        const SizedBox(height: 16),
                        _buildQuickServicesSection(
                          shop,
                          myRequests,
                          certRequest,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Right Column: Upcoming Alert + Status Metrics + Recent Requests
                  Expanded(
                    flex: 9,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (upcomingRequest != null) ...[
                          _buildUpcomingAppointmentCard(
                            upcomingRequest,
                            isDark,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildStatusMetricsSection(
                          totalCount: myRequests.length,
                          pendingCount: pendingCount,
                          scheduledCount: scheduledCount,
                          inProgressCount: inProgressCount,
                          completedCount: completedCount,
                          isWide: true,
                          isDarkOverride: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildRecentRequestsSection(myRequests, isDark),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        }

        // Mobile / Compact Layout
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _buildFarmHeaderCard(shop, certRequest, isDark),
            const SizedBox(height: 14),
            _buildHeroCreateRequestCard(isDark),
            const SizedBox(height: 16),
            if (upcomingRequest != null) ...[
              _buildUpcomingAppointmentCard(upcomingRequest, isDark),
              const SizedBox(height: 16),
            ],
            _buildStatusMetricsSection(
              totalCount: myRequests.length,
              pendingCount: pendingCount,
              scheduledCount: scheduledCount,
              inProgressCount: inProgressCount,
              completedCount: completedCount,
              isWide: false,
              isDarkOverride: isDark,
            ),
            const SizedBox(height: 16),
            _buildQuickServicesSection(
              shop,
              myRequests,
              certRequest,
              isDark,
            ),
            const SizedBox(height: 16),
            _buildRecentRequestsSection(myRequests, isDark),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  /// Farm Profile & Greeting Header Card
  Widget _buildFarmHeaderCard(
    ShopModel shop,
    InspectionRequestModel? certRequest, [
    bool? isDarkOverride,
  ]) {
    final isDark =
        isDarkOverride ?? Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppDarkColors.border : const Color(0xFFE2EBE5),
          width: 0.9,
        ),
        boxShadow: isDark
            ? const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ]
            : AppShadows.cardOf(context),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildShopAvatar(shop: shop, isDark: isDark, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สวัสดีคุณ ${shop.ownerFirstName.isNotEmpty ? shop.ownerFirstName : "เกษตรกร"} 👋',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? AppDarkColors.textSecondary
                            : AppColors.textSecondaryOf(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shop.name,
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? AppDarkColors.textPrimary
                            : AppColors.textPrimaryOf(context),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: isDark
                              ? const Color(0xFF34D399)
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            'ต.${shop.subDistrict}, อ.${shop.district} จ.${shop.province}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? AppDarkColors.textSecondary
                                  : AppColors.textSecondaryOf(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Verified / Pending Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: shop.isVerified
                      ? (isDark
                          ? const Color(0xFF0F3824)
                          : const Color(0xFFE8F5E9))
                      : (isDark
                          ? const Color(0xFF3B2A10)
                          : const Color(0xFFFEF3C7)),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: shop.isVerified
                        ? const Color(0xFF10B981).withOpacity(0.4)
                        : const Color(0xFFF59E0B).withOpacity(0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      shop.isVerified
                          ? CupertinoIcons.checkmark_seal_fill
                          : CupertinoIcons.hourglass,
                      size: 12,
                      color: shop.isVerified
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      shop.isVerified ? 'รับรองแล้ว' : 'รอการตรวจ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: shop.isVerified
                            ? (isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF0F5A3C))
                            : (isDark
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFB45309)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark ? AppDarkColors.border : const Color(0xFFEAEAEA),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A3324)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF22C55E).withOpacity(0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🌿', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            'ผักรับรอง ${shop.verifiedVegetables.length} ชนิด',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFF4ADE80)
                                  : const Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A2A38)
                            : const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF0284C7).withOpacity(0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'รหัสแปลง #${shop.id}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PressableScale(
                onTap: () => _switchTab(2),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1F2922)
                        : const Color(0xFFF3F6F4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2E3E33)
                          : const Color(0xFFE2EBE5),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ข้อมูลร้านค้า',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppDarkColors.primaryAccent
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 11,
                        color: isDark
                            ? AppDarkColors.primaryAccent
                            : AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Hero CTA Card: Create New Inspection Request
  Widget _buildHeroCreateRequestCard([bool? isDarkOverride]) {
    final isDark =
        isDarkOverride ?? Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF0E3825), Color(0xFF155337)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF0A3E2A), Color(0xFF16794D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: (isDark ? const Color(0xFF22C55E) : const Color(0xFF34D399))
              .withOpacity(0.3),
          width: 1,
        ),
        boxShadow: isDark
            ? const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF0F5A3C).withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateRequestScreen(appState: widget.appState),
            ),
          ),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('🌿', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 4),
                            Text(
                              'มาตรฐานผักปลอดภัย SafeVege',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'ยื่นขอตรวจแปลงผักใหม่',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'ส่งตัวอย่างผักเพื่อตรวจสอบสารตกค้าง และรับรองมาตรฐานตรา SafeVege ประจำรอบใหม่',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 15),
                      PressableScale(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateRequestScreen(appState: widget.appState),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF22C55E) : Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.add_circled_solid,
                                size: 16,
                                color: isDark
                                    ? const Color(0xFF052514)
                                    : const Color(0xFF0F5A3C),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'เริ่มส่งคำขอตรวจ',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF052514)
                                      : const Color(0xFF0F5A3C),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.doc_checkmark_fill,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Highlight card for scheduled or in-progress inspection
  Widget _buildUpcomingAppointmentCard(
    InspectionRequestModel request, [
    bool? isDarkOverride,
  ]) {
    final isDark =
        isDarkOverride ?? Theme.of(context).brightness == Brightness.dark;
    final appDate = request.appointmentDate;
    final dateText = appDate != null
        ? '${appDate.day} ${_getThaiMonth(appDate.month)} ${appDate.year + 543} เวลา ${appDate.hour.toString().padLeft(2, '0')}:${appDate.minute.toString().padLeft(2, '0')} น.'
        : 'อยู่ระหว่างดำเนินการ';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF142E1F) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF22C55E).withOpacity(0.4)
              : const Color(0xFFB8E6C8),
          width: 1.2,
        ),
        boxShadow: isDark
            ? const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ]
            : AppShadows.cardOf(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestTrackingScreen(request: request),
            ),
          ),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? const Color(0xFF22C55E)
                                      : AppColors.primary)
                                  .withOpacity(0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.calendar_month_rounded,
                              color: isDark
                                  ? const Color(0xFF34D399)
                                  : AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'นัดหมายตรวจแปลงเร็วๆ นี้',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: request.status),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppDarkColors.surfaceElevated
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppDarkColors.border
                          : const Color(0xFFD6F0E0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 14,
                            color: isDark
                                ? const Color(0xFF34D399)
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppDarkColors.textPrimary
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🌿', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'แปลงผักที่นัดตรวจ: ${request.vegetables.join(", ")}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppDarkColors.textSecondary
                                    : AppColors.textPrimaryOf(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (request.appointmentNotes != null &&
                          request.appointmentNotes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: isDark
                                  ? AppDarkColors.textMuted
                                  : AppColors.textMutedOf(context),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                request.appointmentNotes!,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? AppDarkColors.textSecondary
                                      : AppColors.textSecondaryOf(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'รหัสคำขอ: #${request.id}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppDarkColors.textMuted
                              : AppColors.textMutedOf(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ติดตามการลงพื้นที่',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFF34D399)
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 12,
                          color: isDark
                              ? const Color(0xFF34D399)
                              : AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Interactive status summary cards that filter the list upon click
  Widget _buildStatusMetricsSection({
    required int totalCount,
    required int pendingCount,
    required int scheduledCount,
    required int inProgressCount,
    required int completedCount,
    bool isWide = false,
    bool? isDarkOverride,
  }) {
    final isDark =
        isDarkOverride ?? Theme.of(context).brightness == Brightness.dark;

    final items = [
      (
        label: 'ทั้งหมด',
        value: '$totalCount',
        color: isDark ? AppDarkColors.textPrimary : AppColors.primary,
        icon: CupertinoIcons.square_stack_3d_up,
        filterIndex: 0,
      ),
      (
        label: 'รอดำเนินการ',
        value: '$pendingCount',
        color: AppColors.warning,
        icon: CupertinoIcons.hourglass,
        filterIndex: 1,
      ),
      (
        label: 'นัดหมายแล้ว',
        value: '$scheduledCount',
        color: AppColors.info,
        icon: CupertinoIcons.calendar,
        filterIndex: 2,
      ),
      (
        label: 'กำลังตรวจ',
        value: '$inProgressCount',
        color: const Color(0xFF7C3AED),
        icon: CupertinoIcons.lab_flask,
        filterIndex: 3,
      ),
      (
        label: 'เสร็จสิ้น',
        value: '$completedCount',
        color: AppColors.success,
        icon: CupertinoIcons.checkmark_seal_fill,
        filterIndex: 4,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'สถานะคำขอตรวจสอบ',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: isDark
                      ? AppDarkColors.textPrimary
                      : AppColors.textPrimaryOf(context),
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'แตะเพื่อดูรายการ',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppDarkColors.textMuted
                    : AppColors.textMutedOf(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isWide)
          Row(
            children: items.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildInteractiveMetricCard(
                    label: item.label,
                    value: item.value,
                    color: item.color,
                    icon: item.icon,
                    filterIndex: item.filterIndex,
                    isDark: isDark,
                  ),
                ),
              );
            }).toList(),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 88,
                    child: _buildInteractiveMetricCard(
                      label: item.label,
                      value: item.value,
                      color: item.color,
                      icon: item.icon,
                      filterIndex: item.filterIndex,
                      isDark: isDark,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildInteractiveMetricCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required int filterIndex,
    required bool isDark,
  }) {
    return PressableScale(
      onPressed: () => _switchTab(1, filterIndex: filterIndex),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppDarkColors.surfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppDarkColors.border : const Color(0xFFE2EBE5),
            width: 0.9,
          ),
          boxShadow: isDark
              ? const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : AppShadows.cardOf(context),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.18 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: 6),
            AnimatedCount(
              count: int.tryParse(value) ?? 0,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: color,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppDarkColors.textSecondary
                    : AppColors.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Quick farmer services section
  Widget _buildQuickServicesSection(
    ShopModel shop,
    List<InspectionRequestModel> myRequests,
    InspectionRequestModel? certRequest, [
    bool? isDarkOverride,
  ]) {
    final isDark =
        isDarkOverride ?? Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'บริการสำหรับร้านค้า',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: isDark
                ? AppDarkColors.textPrimary
                : AppColors.textPrimaryOf(context),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // 1. Lab Results & Certificate
            Expanded(
              child: _buildServiceTile(
                icon: CupertinoIcons.doc_checkmark_fill,
                title: 'ผลตรวจแล็บ',
                subtitle: 'และใบรับรอง',
                color: const Color(0xFF0284C7),
                isDark: isDark,
                onTap: () {
                  if (certRequest != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopResultsScreen(request: certRequest),
                      ),
                    );
                  } else {
                    AppFeedback.showInfo(
                      context,
                      'ยังไม่มีคำขอที่ตรวจเสร็จสิ้น สามารถตรวจสอบความคืบหน้าได้ในแท็บคำขอ',
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // 2. Farm Map & Location
            Expanded(
              child: _buildServiceTile(
                icon: CupertinoIcons.map_pin_ellipse,
                title: 'พิกัดแปลงผัก',
                subtitle: 'จัดการแผนที่',
                color: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () => _switchTab(2),
              ),
            ),
            const SizedBox(width: 8),
            // 3. Inspection Requests List
            Expanded(
              child: _buildServiceTile(
                icon: CupertinoIcons.square_list_fill,
                title: 'รายการคำขอ',
                subtitle: 'ขั้นตอนการตรวจ',
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
                onTap: () => _switchTab(1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppDarkColors.border : const Color(0xFFE2EBE5),
          width: 0.9,
        ),
        boxShadow: isDark
            ? const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ]
            : AppShadows.cardOf(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppDarkColors.textPrimary
                        : AppColors.textPrimaryOf(context),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark
                        ? AppDarkColors.textSecondary
                        : AppColors.textSecondaryOf(context),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Recent Requests list
  Widget _buildRecentRequestsSection(
    List<InspectionRequestModel> myRequests, [
    bool? isDarkOverride,
  ]) {
    final isDark =
        isDarkOverride ?? Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'คำขอล่าสุด',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: isDark
                    ? AppDarkColors.textPrimary
                    : AppColors.textPrimaryOf(context),
                letterSpacing: -0.2,
              ),
            ),
            PressableScale(
              onTap: () => _switchTab(1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ดูทั้งหมด (${myRequests.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppDarkColors.primaryAccent
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 11,
                      color: isDark
                          ? AppDarkColors.primaryAccent
                          : AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (myRequests.isEmpty)
          EmptyStateView(
            title: 'ยังไม่มีคำขอตรวจสอบ',
            message: 'ส่งคำขอตรวจสอบแปลงผักของคุณเพื่อรับรองมาตรฐาน SafeVege',
            actionLabel: 'ส่งคำขอแรกของคุณ',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateRequestScreen(appState: widget.appState),
              ),
            ),
          )
        else
          ...myRequests.take(3).map((req) {
            final hasAppDate = req.appointmentDate != null;
            final dateLabel = hasAppDate
                ? 'นัดตรวจ: ${req.appointmentDate!.day}/${req.appointmentDate!.month}/${req.appointmentDate!.year + 543}'
                : 'ยื่นเมื่อ: ${req.submissionDate.day}/${req.submissionDate.month}/${req.submissionDate.year + 543}';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isDark ? AppDarkColors.surfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppDarkColors.border : const Color(0xFFE2EBE5),
                  width: 0.9,
                ),
                boxShadow: isDark
                    ? const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : AppShadows.cardOf(context),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    try {
                      final details =
                          await widget.appState.loadRequestDetails(req.id);
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RequestTrackingScreen(request: details),
                        ),
                      );
                    } catch (_) {
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RequestTrackingScreen(request: req),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '#${req.id}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: isDark
                                    ? AppDarkColors.primaryAccent
                                    : AppColors.primary,
                              ),
                            ),
                            StatusBadge(status: req.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: req.vegetables.map((veg) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF14281B)
                                    : const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: const Color(0xFF22C55E).withOpacity(0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    safeVegeEmoji(veg),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    veg,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? const Color(0xFF4ADE80)
                                          : const Color(0xFF166534),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    hasAppDate
                                        ? CupertinoIcons.calendar
                                        : CupertinoIcons.clock,
                                    size: 12.5,
                                    color: hasAppDate
                                        ? (isDark
                                            ? const Color(0xFF34D399)
                                            : AppColors.primary)
                                        : (isDark
                                            ? AppDarkColors.textMuted
                                            : AppColors.textMutedOf(context)),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      dateLabel,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: hasAppDate
                                            ? (isDark
                                                ? const Color(0xFF34D399)
                                                : AppColors.primary)
                                            : (isDark
                                                ? AppDarkColors.textSecondary
                                                : AppColors.textSecondaryOf(
                                                    context,
                                                  )),
                                        fontWeight: hasAppDate
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ดูรายละเอียด',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppDarkColors.primaryAccent
                                        : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 11,
                                  color: isDark
                                      ? AppDarkColors.primaryAccent
                                      : AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
