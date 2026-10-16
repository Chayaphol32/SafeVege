import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/interactive_animations.dart';
import 'admin_audit_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_users_screen.dart';
import 'inspection_requests_screen.dart';
import 'shop_management_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  bool _isRefreshing = false;

  AppState get appState => widget.appState;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!appState.isSuperAdmin) return;
    try {
      await Future.wait([
        appState.loadPublicShops().catchError((_) {}),
        appState.loadAdminUsers().catchError((_) => <AdminUserModel>[]),
        appState.loadAdminSettings().catchError((_) => <String, dynamic>{}),
        appState.loadAuditEvents().catchError((_) => <AuditEventModel>[]),
      ]);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await _loadInitialData();
    if (mounted) {
      setState(() => _isRefreshing = false);
      AppFeedback.showSuccess(context, 'อัปเดตข้อมูลภาพรวมระบบล่าสุดแล้ว');
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'ออกจากระบบผู้ดูแลระดับสูงสุด?',
      message: 'คุณต้องการสิ้นสุดเซสชัน Super Administrator ใช่หรือไม่?',
      confirmLabel: 'ออกจากระบบ',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      await appState.logoutAdmin();
      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      AppFeedback.showSuccess(context, 'ออกจากระบบเรียบร้อยแล้ว');
    }
  }

  Future<void> _showQuickCreateInspector() async {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final displayNameController = TextEditingController();
    final passwordController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryOf(ctx).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_rounded,
                color: AppColors.primaryOf(ctx),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'เพิ่มผู้ตรวจการผักใหม่',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'สร้างบัญชีเจ้าหน้าที่ระดับผู้ตรวจการ (Inspector Admin) สำหรับลงพื้นที่สุ่มตรวจแปลงและบันทึกผลแล็บ',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อผู้ใช้ (Username)',
                    prefixIcon: Icon(Icons.account_circle_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'กรุณากรอกชื่อผู้ใช้'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อ-นามสกุล ที่แสดง',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'กรุณากรอกชื่อที่แสดง'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'รหัสผ่านเริ่มต้น',
                    helperText: 'อย่างน้อย 12 ตัวอักษร',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) => v == null || v.length < 12
                      ? 'รหัสผ่านต้องมีอย่างน้อย 12 ตัวอักษร'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton.icon(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              try {
                await appState.createAdminUser(
                  username: usernameController.text.trim(),
                  displayName: displayNameController.text.trim(),
                  password: passwordController.text,
                  role: UserRole.admin,
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (error) {
                if (ctx.mounted) {
                  AppFeedback.showError(ctx, error.toString());
                }
              }
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('สร้างบัญชี'),
          ),
        ],
      ),
    );

    usernameController.dispose();
    displayNameController.dispose();
    passwordController.dispose();

    if (created == true && mounted) {
      AppFeedback.showSuccess(context, 'สร้างบัญชีผู้ตรวจการเรียบร้อยแล้ว');
      setState(() {});
    }
  }

  Future<void> _toggleMaintenanceMode() async {
    final current =
        appState.adminSettings['maintenance_mode'] == true ||
        appState.adminSettings['maintenance_mode'] == 1 ||
        appState.adminSettings['maintenance_mode'] == '1';
    final target = !current;

    final confirmed = await ConfirmActionDialog.show(
      context,
      title: target ? 'เปิดโหมดซ่อมบำรุงระบบ?' : 'ปิดโหมดซ่อมบำรุงระบบ?',
      message: target
          ? 'เมื่อเปิดโหมดนี้ ผู้ใช้งานทั่วไปจะไม่สามารถยื่นคำขอตรวจหรือเข้าถึงบางฟีเจอร์ได้'
          : 'ระบบจะกลับมาเปิดให้บริการผู้ใช้งานและร้านค้าตามปกติ',
      confirmLabel: target ? 'เปิดโหมดซ่อมบำรุง' : 'เปิดให้บริการปกติ',
      isDestructive: target,
    );

    if (confirmed && mounted) {
      try {
        await appState.updateAdminSettings({'maintenance_mode': target});
        if (mounted) {
          AppFeedback.showSuccess(
            context,
            target
                ? 'เปิดโหมดซ่อมบำรุงระบบแล้ว'
                : 'ปิดโหมดซ่อมบำรุง ระบบพร้อมใช้งานปกติ',
          );
        }
      } catch (error) {
        if (mounted) AppFeedback.showError(context, error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!appState.isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('เมนูผู้ดูแลระบบขั้นสูง')),
        body: const Center(child: Text('ไม่มีสิทธิ์เข้าถึงเมนูนี้')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final verifiedShopsCount = appState.shops.where((s) => s.isVerified).length;
    final pendingShopsCount = appState.shops.length - verifiedShopsCount;
    final pendingRequestsCount = appState.requests
        .where((r) => r.isPending)
        .length;
    final maintenanceMode =
        appState.adminSettings['maintenance_mode'] == true ||
        appState.adminSettings['maintenance_mode'] == 1 ||
        appState.adminSettings['maintenance_mode'] == '1';

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text(
          'เมนูผู้ดูแลระบบขั้นสูง',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'สลับธีม',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: () => appState.toggleThemeMode(),
          ),
          IconButton(
            tooltip: 'รีเฟรชข้อมูล',
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isRefreshing ? null : _refresh,
          ),
          IconButton(
            tooltip: 'ออกจากระบบ',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // 1. Executive Super Admin Command Banner
              _buildExecutiveBanner(context, isDark, maintenanceMode),
              const SizedBox(height: 14),

              // 2. Primary System Management Cards
              const Row(
                children: [
                  Icon(
                    Icons.dashboard_customize_rounded,
                    size: 19,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'การจัดการระบบ',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildManagementModules(context, isDark),
              const SizedBox(height: 18),

              // 3. Executive KPI Cards Grid
              _buildKpiMetricsGrid(
                context,
                isDark,
                verifiedShopsCount: verifiedShopsCount,
                pendingShopsCount: pendingShopsCount,
                pendingRequestsCount: pendingRequestsCount,
              ),
              const SizedBox(height: 18),

              // 4. Quick Action Command Suite
              _buildQuickActionSuite(context, isDark, maintenanceMode),
              const SizedBox(height: 20),

              // 5. Recent System Audit Activity Feed
              _buildRecentAuditFeed(context, isDark),
              const SizedBox(height: 20),

              // 6. System Architecture & Status Card
              _buildSystemInfoCard(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExecutiveBanner(
    BuildContext context,
    bool isDark,
    bool maintenanceMode,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2B1D),
                  Color(0xFF133824),
                  Color(0xFF1E2822),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B462D),
                  Color(0xFF146340),
                  Color(0xFF1E7E52),
                ],
              ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2A5940) : const Color(0xFF34A870),
          width: 1.2,
        ),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Decorative Watermark
          Positioned(
            right: -16,
            bottom: -20,
            child: Icon(
              Icons.shield_rounded,
              size: 150,
              color: Colors.white.withOpacity(isDark ? 0.05 : 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Prestige Avatar Squircle with floating animation
                    FloatingElement(
                      distance: 3.5,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: const Color(0xFFFBBF24).withOpacity(0.6),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('👑', style: TextStyle(fontSize: 11)),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Super Administrator',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFDE68A),
                                      letterSpacing: 0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            appState.adminName.isNotEmpty
                                ? appState.adminName
                                : (appState.username.isNotEmpty
                                      ? appState.username
                                      : 'ผู้ดูแลระบบตัวจริง'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${appState.username} • ควบคุมสิทธิ์การจัดการระบบ SafeVege ทั้งหมด',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withOpacity(0.85),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PulsingStatusDot(
                            color: Color(0xFF4ADE80),
                            size: 8,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'ออนไลน์ (Active)',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFE2E8F0),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Maintenance Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: maintenanceMode
                            ? const Color(0xFFEF4444).withOpacity(0.3)
                            : Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(100),
                        border: maintenanceMode
                            ? Border.all(
                                color: const Color(0xFFFCA5A5),
                                width: 0.8,
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            maintenanceMode
                                ? Icons.construction_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 13,
                            color: maintenanceMode
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFF86EFAC),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              maintenanceMode
                                  ? 'ซ่อมบำรุง: เปิดอยู่'
                                  : 'ระบบปกติ',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: maintenanceMode
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFE2E8F0),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetricsGrid(
    BuildContext context,
    bool isDark, {
    required int verifiedShopsCount,
    required int pendingShopsCount,
    required int pendingRequestsCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.analytics_rounded, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'ตัวชี้วัดหลัก SafeVege เชียงราย (KPIs)',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'ร้านค้าทั้งหมด',
                value: '${appState.shops.length}',
                detail: 'ผ่านตรวจ $verifiedShopsCount • รอ $pendingShopsCount',
                icon: Icons.storefront_rounded,
                accentColor: const Color(0xFF10B981),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShopManagementScreen(appState: appState),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'งานตรวจแปลงผัก',
                value: '${appState.requests.length}',
                detail: 'รอดำเนินการ $pendingRequestsCount งาน',
                icon: Icons.fact_check_rounded,
                accentColor: const Color(0xFF3B82F6),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        InspectionRequestsScreen(appState: appState),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'ทีมงานผู้ดูแลระบบ',
                value: '${appState.adminUsers.length}',
                detail: 'ผู้ตรวจการ & แอดมิน',
                icon: Icons.badge_rounded,
                accentColor: const Color(0xFFF59E0B),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminUsersScreen(appState: appState),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'บันทึกความปลอดภัย',
                value: '${appState.auditEvents.length}',
                detail: 'กิจกรรม Audit ทั้งหมด',
                icon: Icons.security_rounded,
                accentColor: const Color(0xFF8B5CF6),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminAuditScreen(appState: appState),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String detail,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: accentColor),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: AppColors.textSecondaryOf(context).withOpacity(0.6),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedCount(
              count: int.tryParse(value) ?? 0,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryOf(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionSuite(
    BuildContext context,
    bool isDark,
    bool maintenanceMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceElevated : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A2B) : const Color(0xFFDCFCE7),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFF16A34A)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'คำสั่งด่วนผู้ดูแลระบบ (Executive Quick Actions)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: _showQuickCreateInspector,
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('เพิ่มผู้ตรวจการใหม่'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _toggleMaintenanceMode,
                icon: Icon(
                  maintenanceMode
                      ? Icons.check_circle_outline
                      : Icons.construction_rounded,
                  size: 16,
                ),
                label: Text(
                  maintenanceMode ? 'ปิดโหมดซ่อมบำรุง' : 'สลับโหมดซ่อมบำรุง',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: maintenanceMode
                      ? AppColors.danger
                      : AppColors.primaryOf(context),
                  side: BorderSide(
                    color: maintenanceMode
                        ? AppColors.danger
                        : AppColors.primaryOf(context).withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminDashboardScreen(appState: appState),
                  ),
                ),
                icon: const Icon(Icons.dashboard_rounded, size: 16),
                label: const Text('เปิดแดชบอร์ดงานตรวจ'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementModules(BuildContext context, bool isDark) {
    final expiryDays =
        appState.adminSettings['default_certificate_expiry_days']?.toString() ??
        '30';

    return Column(
      children: [
        _ExecutiveModuleTile(
          icon: Icons.fact_check_rounded,
          iconGradient: const [Color(0xFF059669), Color(0xFF10B981)],
          title: 'ข้อมูลงานตรวจผักและร้านค้า',
          subtitle: 'ดูร้านค้า คำขอตรวจ นัดหมาย ผลตรวจ และใบรับรองทั้งหมด',
          badgeText:
              '${appState.shops.length} ร้าน • ${appState.requests.length} งาน',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminDashboardScreen(appState: appState),
            ),
          ),
        ),
        _ExecutiveModuleTile(
          icon: Icons.manage_accounts_rounded,
          iconGradient: const [Color(0xFF2563EB), Color(0xFF60A5FA)],
          title: 'จัดการบัญชีผู้ใช้',
          subtitle: 'สร้างแอดมินตรวจผัก เปิด/ปิดบัญชี และเปลี่ยนรหัสผ่าน',
          badgeText: '${appState.adminUsers.length} บัญชีผู้ดูแล',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminUsersScreen(appState: appState),
            ),
          ),
        ),
        _ExecutiveModuleTile(
          icon: Icons.tune_rounded,
          iconGradient: const [Color(0xFFD97706), Color(0xFFFBBF24)],
          title: 'ตั้งค่าระบบ',
          subtitle: 'ปรับค่าการทำงานของระบบและใบรับรอง',
          badgeText: 'ใบรับรอง: $expiryDays วัน',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminSettingsScreen(appState: appState),
            ),
          ),
        ),
        _ExecutiveModuleTile(
          icon: Icons.history_edu_rounded,
          iconGradient: const [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          title: 'ประวัติการใช้งาน',
          subtitle: 'ตรวจสอบการเปลี่ยนแปลงของผู้ดูแลระบบ',
          badgeText: '${appState.auditEvents.length} รายการ',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminAuditScreen(appState: appState),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAuditFeed(BuildContext context, bool isDark) {
    final recentEvents = appState.auditEvents.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'ประวัติกิจกรรมความปลอดภัยล่าสุด (Audit Feed)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (appState.auditEvents.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminAuditScreen(appState: appState),
                  ),
                ),
                child: const Text('ดูทั้งหมด'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (recentEvents.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 36,
                    color: AppColors.textSecondaryOf(context).withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ยังไม่มีบันทึกกิจกรรมความปลอดภัยล่าสุด',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'กิจกรรมเช่น เข้าสู่ระบบ, อนุมัติผลตรวจ, หรือสร้างผู้ใช้จะถูกบันทึกที่นี่',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentEvents.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: isDark ? AppDarkColors.border : const Color(0xFFF1F5F9),
              ),
              itemBuilder: (ctx, idx) {
                final ev = recentEvents[idx];
                final date = ev.createdAt?.toLocal();
                final timeText = date == null
                    ? ''
                    : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: _actionColor(ev.action).withOpacity(0.14),
                    child: Icon(
                      _actionIcon(ev.action),
                      size: 18,
                      color: _actionColor(ev.action),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ev.action,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'โดย: ${ev.actorUsername} • ${ev.entityType} ${ev.entityId.isNotEmpty ? '#${ev.entityId}' : ''}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemInfoCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F1A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF263A2F) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'สถาปัตยกรรมระบบ & สภาพแวดล้อม',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'v1.0.0 Production',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('เซิร์ฟเวอร์ API:', AppConfig.apiBaseUrl),
          const SizedBox(height: 6),
          _infoRow(
            'มาตรฐานความปลอดภัย:',
            'Role-Based Access Control (RBAC) + Audit Logging',
          ),
          const SizedBox(height: 6),
          _infoRow(
            'พื้นที่ดูแล:',
            'โครงการผักปลอดภัย จังหวัดเชียงราย (SafeVege Network)',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Color _actionColor(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('login') || lower.contains('auth')) {
      return const Color(0xFF2563EB);
    }
    if (lower.contains('create') || lower.contains('add')) {
      return const Color(0xFF10B981);
    }
    if (lower.contains('delete') || lower.contains('cancel')) {
      return const Color(0xFFEF4444);
    }
    if (lower.contains('update') || lower.contains('edit')) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF8B5CF6);
  }

  IconData _actionIcon(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('login')) {
      return Icons.login_rounded;
    }
    if (lower.contains('create') || lower.contains('add')) {
      return Icons.add_circle_outline_rounded;
    }
    if (lower.contains('delete')) {
      return Icons.delete_outline_rounded;
    }
    if (lower.contains('update') || lower.contains('edit')) {
      return Icons.edit_note_rounded;
    }
    return Icons.history_rounded;
  }
}

class _ExecutiveModuleTile extends StatelessWidget {
  const _ExecutiveModuleTile({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.onTap,
  });

  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String subtitle;
  final String badgeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: iconGradient,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: iconGradient.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(child: Icon(icon, color: Colors.white, size: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: iconGradient.first.withOpacity(
                              isDark ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: iconGradient.first.withOpacity(0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? iconGradient.last
                                  : iconGradient.first,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondaryOf(context).withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
