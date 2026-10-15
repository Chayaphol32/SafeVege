import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/interactive_animations.dart';
import '../guest/certificate_viewer_screen.dart';
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

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        const SizedBox(height: 12),

        // Farm Identity & Welcome Card
        _buildFarmHeaderCard(shop, certRequest),
        const SizedBox(height: 14),

        // Primary Action: Hero Create Request Banner
        _buildHeroCreateRequestCard(),
        const SizedBox(height: 16),

        // Upcoming Appointment Alert Card (if any scheduled or in-progress)
        if (upcomingRequest != null) ...[
          _buildUpcomingAppointmentCard(upcomingRequest),
          const SizedBox(height: 16),
        ],

        // Interactive Inspection Status Metric Cards (Tap to filter)
        _buildStatusMetricsSection(
          totalCount: myRequests.length,
          pendingCount: pendingCount,
          scheduledCount: scheduledCount,
          inProgressCount: inProgressCount,
          completedCount: completedCount,
        ),
        const SizedBox(height: 16),

        // Quick Services for Farmer
        _buildQuickServicesSection(shop, myRequests, certRequest),
        const SizedBox(height: 16),

        // Recent Requests Section
        _buildRecentRequestsSection(myRequests),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Farm Profile & Greeting Header Card
  Widget _buildFarmHeaderCard(
    ShopModel shop,
    InspectionRequestModel? certRequest,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context), width: 0.8),
        boxShadow: AppShadows.cardOf(context),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FloatingElement(
                distance: 3.5,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOf(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primaryOf(context),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สวัสดีคุณ ${shop.ownerFirstName} 👋',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryOf(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shop.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryOf(context),
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textMutedOf(context),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            'ต.${shop.subDistrict}, อ.${shop.district} จ.${shop.province}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryOf(context),
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
              StatusBadge(
                status: shop.isVerified ? 'ผ่านการตรวจ' : 'รอการตรวจ',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: AppColors.borderLightOf(context)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      size: 15,
                      color: AppColors.primaryOf(context),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'ผักรับรอง ${shop.verifiedVegetables.length} ชนิด',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOf(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (shop.isVerified) ...[
                InkWell(
                  onTap: () => _showShopQrSheet(shop, certRequest),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.qrcode,
                          size: 14,
                          color: AppColors.primaryOf(context),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'QR หน้าร้าน',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              InkWell(
                onTap: () => _switchTab(2),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ข้อมูลร้านค้า',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 15,
                        color: AppColors.textSecondaryOf(context),
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
  Widget _buildHeroCreateRequestCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.heroCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.floating,
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
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.verified_outlined,
                              size: 12,
                              color: Colors.white,
                            ),
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
                      const SizedBox(height: 8),
                      const Text(
                        'ยื่นขอตรวจแปลงผักใหม่',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ส่งตัวอย่างผักเพื่อตรวจสอบสารตกค้างและรับรองมาตรฐานตรา SafeVege',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceOf(context),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle,
                              size: 16,
                              color: AppColors.primaryOf(context),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'เริ่มส่งคำขอตรวจ',
                              style: TextStyle(
                                color: AppColors.primaryOf(context),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_add,
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
  Widget _buildUpcomingAppointmentCard(InspectionRequestModel request) {
    final appDate = request.appointmentDate;
    final dateText = appDate != null
        ? '${appDate.day} ${_getThaiMonth(appDate.month)} ${appDate.year + 543} เวลา ${appDate.hour.toString().padLeft(2, '0')}:${appDate.minute.toString().padLeft(2, '0')} น.'
        : 'อยู่ระหว่างดำเนินการ';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB8E6C8), width: 1.2),
        boxShadow: AppShadows.cardOf(context),
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
                              color: AppColors.primaryOf(context)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.primaryOf(context),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'นัดหมายตรวจแปลงเร็วๆ นี้',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primaryOf(context),
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
                    color: AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD6F0E0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 14,
                            color: AppColors.primaryOf(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateText,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryOf(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            size: 14,
                            color: AppColors.textSecondaryOf(context),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'แปลงผักที่นัดตรวจ: ${request.vegetables.join(", ")}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textPrimaryOf(context),
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
                              color: AppColors.textMutedOf(context),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                request.appointmentNotes!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryOf(context),
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
                        'รหัสคำขอ: ${request.id}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMutedOf(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ดูรายละเอียด & แผนที่',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOf(context),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.primaryOf(context),
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
  }) {
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
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimaryOf(context),
                  letterSpacing: 0,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'แตะเพื่อดูรายการ',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMutedOf(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _buildInteractiveMetricCard(
                label: 'ทั้งหมด',
                value: '$totalCount',
                color: AppColors.textPrimaryOf(context),
                icon: CupertinoIcons.square_stack_3d_up,
                filterIndex: 0,
              ),
              const SizedBox(width: 8),
              _buildInteractiveMetricCard(
                label: 'รอดำเนินการ',
                value: '$pendingCount',
                color: AppColors.warning,
                icon: CupertinoIcons.hourglass,
                filterIndex: 1,
              ),
              const SizedBox(width: 8),
              _buildInteractiveMetricCard(
                label: 'นัดหมายแล้ว',
                value: '$scheduledCount',
                color: AppColors.info,
                icon: CupertinoIcons.calendar,
                filterIndex: 2,
              ),
              const SizedBox(width: 8),
              _buildInteractiveMetricCard(
                label: 'กำลังตรวจ',
                value: '$inProgressCount',
                color: const Color(0xFF7C3AED),
                icon: CupertinoIcons.lab_flask,
                filterIndex: 3,
              ),
              const SizedBox(width: 8),
              _buildInteractiveMetricCard(
                label: 'เสร็จสิ้น',
                value: '$completedCount',
                color: AppColors.success,
                icon: CupertinoIcons.checkmark_seal_fill,
                filterIndex: 4,
              ),
            ],
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
  }) {
    return PressableScale(
      onPressed: () => _switchTab(1, filterIndex: filterIndex),
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderOf(context), width: 0.8),
          boxShadow: AppShadows.cardOf(context),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(height: 6),
              AnimatedCount(
                count: int.tryParse(value) ?? 0,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondaryOf(context),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Quick farmer services section
  Widget _buildQuickServicesSection(
    ShopModel shop,
    List<InspectionRequestModel> myRequests,
    InspectionRequestModel? certRequest,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'บริการสำหรับร้านค้า',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.textPrimaryOf(context),
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildServiceTile(
                icon: Icons.workspace_premium_outlined,
                title: 'ผลตรวจแล็บ',
                subtitle: 'และใบรับรอง',
                color: const Color(0xFF0284C7),
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
            Expanded(
              child: _buildServiceTile(
                icon: Icons.qr_code_2_rounded,
                title: 'QR หน้าร้าน',
                subtitle: 'ให้ลูกค้าสแกน',
                color: AppColors.primaryOf(context),
                onTap: () => _showShopQrSheet(shop, certRequest),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildServiceTile(
                icon: Icons.pin_drop_outlined,
                title: 'พิกัดแปลงผัก',
                subtitle: 'จัดการแผนที่',
                color: AppColors.secondary,
                onTap: () => _switchTab(2),
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
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context), width: 0.8),
        boxShadow: AppShadows.cardOf(context),
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
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryOf(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondaryOf(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Recent Requests list
  Widget _buildRecentRequestsSection(List<InspectionRequestModel> myRequests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'คำขอล่าสุด',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimaryOf(context),
                letterSpacing: 0,
              ),
            ),
            TextButton(
              onPressed: () => _switchTab(1),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'ดูทั้งหมด (${myRequests.length}) >',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.borderOf(context),
                  width: 0.8,
                ),
                boxShadow: AppShadows.cardOf(context),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestTrackingScreen(request: req),
                    ),
                  ),
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
                              req.id,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: AppColors.primaryOf(context),
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
                                color: AppColors.accent.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                veg,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF1B6A3E),
                                  fontWeight: FontWeight.w600,
                                ),
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
                                        ? Icons.event_outlined
                                        : Icons.schedule_outlined,
                                    size: 13,
                                    color: hasAppDate
                                        ? AppColors.primary
                                        : AppColors.textMutedOf(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      dateLabel,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: hasAppDate
                                            ? AppColors.primary
                                            : AppColors.textSecondaryOf(
                                                context,
                                              ),
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
                                    color: AppColors.primaryOf(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: AppColors.primaryOf(context),
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

  /// Show beautiful QR Code and Certificate modal sheet
  void _showShopQrSheet(ShopModel shop, InspectionRequestModel? certRequest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/safevege_logo.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'QR Code ประจำร้านค้า SafeVege',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryOf(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                shop.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              Text(
                'ให้ผู้บริโภคสแกนเพื่อตรวจสอบผลความปลอดภัยและตราสัญลักษณ์',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondaryOf(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Simulated Clean QR Code Widget
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.borderOf(context),
                    width: 1.2,
                  ),
                  boxShadow: AppShadows.cardOf(context),
                ),
                child: Column(
                  children: [
                    // QR codes need a light quiet zone to stay scannable,
                    // so this inner panel is intentionally white in both themes.
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildQrPattern(),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ID ร้าน: ${shop.id} • ${shop.shortArea}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMutedOf(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Certified Veggies Chips
              if (shop.verifiedVegetables.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ผักที่ผ่านการรับรองความปลอดภัย:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: shop.verifiedVegetables.map((v) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successBgOf(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🌿 $v',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Certificate Action Buttons
              if (certRequest != null && certRequest.hasCertificate) ...[
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CertificateViewerScreen(
                          shopName: certRequest.shopName,
                          certNumber:
                              certRequest.certificateNumber ??
                              'SV-CERT-${certRequest.id}',
                          certificateId: certRequest.certificateId,
                          vegetables: certRequest.vegetables,
                          certificateFileName: certRequest.certificateFileName,
                          issueDate: certRequest.inspectionDate,
                          expiryDate: certRequest.certificateExpiryDate,
                          inspectorName: certRequest.inspectorName,
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                  label: const Text('เปิดดูใบรับรองผลตรวจฉบับเต็ม'),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: const Text('ปิดหน้าต่าง'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Visual QR pattern simulating genuine QR Matrix
  Widget _buildQrPattern() {
    return SizedBox(
      width: 170,
      height: 170,
      child: CustomPaint(painter: _QrMatrixPainter()),
    );
  }
}

class _QrMatrixPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintDark = Paint()..color = const Color(0xFF141915);
    final paintLight = Paint()..color = Colors.white;

    final cellWidth = size.width / 21;
    final cellHeight = size.height / 21;

    void drawFinder(double x, double y) {
      // Outer 7x7 dark square
      canvas.drawRect(
        Rect.fromLTWH(
          x * cellWidth,
          y * cellHeight,
          7 * cellWidth,
          7 * cellHeight,
        ),
        paintDark,
      );
      // Inner 5x5 white square
      canvas.drawRect(
        Rect.fromLTWH(
          (x + 1) * cellWidth,
          (y + 1) * cellHeight,
          5 * cellWidth,
          5 * cellHeight,
        ),
        paintLight,
      );
      // Center 3x3 dark square
      canvas.drawRect(
        Rect.fromLTWH(
          (x + 2) * cellWidth,
          (y + 2) * cellHeight,
          3 * cellWidth,
          3 * cellHeight,
        ),
        paintDark,
      );
    }

    // Draw three corner finders
    drawFinder(0, 0);
    drawFinder(14, 0);
    drawFinder(0, 14);

    // Simulated data dots
    final matrixData = [
      0x5A5A,
      0xA5A5,
      0x3C3C,
      0xC3C3,
      0x6969,
      0x9696,
      0x5555,
      0xAAAA,
      0x3333,
      0xCCCC,
      0x0F0F,
      0xF0F0,
      0x55AA,
      0xAA55,
    ];

    for (int r = 0; r < 21; r++) {
      for (int c = 0; c < 21; c++) {
        // Skip corner finder zones
        if ((r < 8 && c < 8) || (r < 8 && c > 12) || (r > 12 && c < 8)) {
          continue;
        }
        // Center quiet zone
        if (r >= 8 && r <= 12 && c >= 8 && c <= 12) {
          continue;
        }

        final seed = ((matrixData[r % matrixData.length] >> (c % 16)) & 1) == 1;
        if (seed || (r + c) % 3 == 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * cellWidth + 0.5,
                r * cellHeight + 0.5,
                cellWidth - 1,
                cellHeight - 1,
              ),
              const Radius.circular(1.5),
            ),
            paintDark,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
