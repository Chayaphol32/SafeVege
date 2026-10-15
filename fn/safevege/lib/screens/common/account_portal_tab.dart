import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/interactive_animations.dart';
import '../shop/shop_login_screen.dart';
import '../shop/shop_registration_screen.dart';
import '../shop/shop_dashboard_screen.dart';
import '../admin/admin_login_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/super_admin_dashboard_screen.dart';
import '../guest/certificates_hub_tab.dart';
import '../welcome_screen.dart';

class AccountPortalTab extends StatelessWidget {
  const AccountPortalTab({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isShop = appState.isShopLoggedIn;
        final isAdmin = appState.isAdminLoggedIn;

        return Scaffold(
          backgroundColor: isDark
              ? AppDarkColors.background
              : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppDarkColors.background : Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            title: Row(
              children: [
                Icon(
                  CupertinoIcons.person_crop_circle_fill,
                  color: isDark ? AppDarkColors.primary : AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'บัญชีและร้านค้า',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark
                        ? AppDarkColors.textPrimary
                        : AppColors.textPrimaryOf(context),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: isDark ? 'เปลี่ยนเป็นโหมดสว่าง' : 'เปลี่ยนเป็นโหมดมืด',
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey(isDark),
                    color: isDark ? AppDarkColors.primary : AppColors.primary,
                    size: 21,
                  ),
                ),
                onPressed: () {
                  appState.toggleThemeMode();
                },
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. User Hero Profile Section
                if (isShop)
                  _buildShopLoggedInCard(context)
                else if (isAdmin)
                  _buildAdminLoggedInCard(context)
                else
                  _buildGuestProfileCard(context),

                const SizedBox(height: 20),

                // 2. Portals & Access Management (เมื่อยังไม่ได้เข้าสู่ระบบ)
                if (!isShop && !isAdmin) ...[
                  _buildSectionLabel(context, 'เข้าสู่ระบบตามบทบาท (PORTALS)'),
                  const SizedBox(height: 8),
                  _buildRolePortalsGroup(context),
                  const SizedBox(height: 20),
                ],

                // 3. Verification & Standards Group
                _buildSectionLabel(context, 'ข้อมูลและการรับรองมาตรฐาน'),
                const SizedBox(height: 8),
                _buildStandardsGroup(context),

                const SizedBox(height: 20),

                // 4. Preferences & Settings Group
                _buildSectionLabel(context, 'การตั้งค่าระบบ (SETTINGS)'),
                const SizedBox(height: 8),
                _buildSettingsGroup(context),

                const SizedBox(height: 28),

                // Footer Branding
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.eco_rounded,
                            size: 14,
                            color: isDark
                                ? AppDarkColors.secondary
                                : AppColors.secondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'SafeVege • จังหวัดเชียงราย',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppDarkColors.textSecondary
                                  : AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'เวอร์ชัน 1.0.0 • OpenStreetMap',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppDarkColors.textMuted
                              : AppColors.textMutedOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Label for Grouped Sections
  Widget _buildSectionLabel(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark
              ? AppDarkColors.textMuted
              : AppColors.textSecondaryOf(context),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Guest Profile Hero Card
  Widget _buildGuestProfileCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppDarkColors.border : AppColors.borderOf(context),
          width: 0.8,
        ),
        boxShadow: AppShadows.cardOf(context),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF15803D), Color(0xFF22C55E)],
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'ผู้ใช้ทั่วไป (Guest)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppDarkColors.textPrimary
                                  : AppColors.textPrimaryOf(context),
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF143820)
                                : const Color(0xFFE8F7EC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'โหมดผู้บริโภค',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppDarkColors.primary
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ค้นหาร้านค้าและดูผลตรวจผักปลอดภัยได้ทันที',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppDarkColors.textSecondary
                            : AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark
                ? AppDarkColors.borderLight
                : AppColors.borderLightOf(context),
          ),
          const SizedBox(height: 10),
          PressableScale(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CertificatesHubTab(appState: appState),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isDark
                    ? AppDarkColors.surfaceElevated
                    : const Color(0xFFF7FAF7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppDarkColors.border
                      : const Color(0xFFE2EBE2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    size: 16,
                    color: isDark ? AppDarkColors.primary : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ตรวจดูผลแล็บและใบรับรองทั้งหมดในระบบ',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppDarkColors.textPrimary
                            : AppColors.textPrimaryOf(context),
                      ),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 14,
                    color: isDark
                        ? AppDarkColors.textMuted
                        : AppColors.textMutedOf(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Role Portals Group (ร้านค้า & ผู้ดูแลระบบ)
  Widget _buildRolePortalsGroup(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppDarkColors.border : AppColors.borderOf(context),
          width: 0.8,
        ),
        boxShadow: AppShadows.cardOf(context),
      ),
      child: Column(
        children: [
          // Row 1: สำหรับเกษตรกรและร้านค้า
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF143820)
                            : const Color(0xFFE8F7EC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        CupertinoIcons.building_2_fill,
                        color: isDark
                            ? AppDarkColors.primary
                            : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สำหรับเกษตรกรและร้านค้า',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppDarkColors.textPrimary
                                  : AppColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ยื่นขอตรวจแปลงผัก รับผลตรวจแล็บ และปักหมุดบนแผนที่',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppDarkColors.textSecondary
                                  : AppColors.textSecondaryOf(context),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: PressableScale(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ShopLoginScreen(appState: appState),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppDarkColors.primary
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.arrow_right_to_line,
                                size: 16,
                                color: isDark
                                    ? const Color(0xFF04200E)
                                    : Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'เข้าสู่ระบบร้านค้า',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFF04200E)
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: PressableScale(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ShopRegistrationScreen(appState: appState),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppDarkColors.surfaceElevated
                                : const Color(0xFFF1F5F1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppDarkColors.border
                                  : AppColors.borderOf(context),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'สมัครร้านค้า',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppDarkColors.textPrimary
                                    : AppColors.textPrimaryOf(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark
                ? AppDarkColors.borderLight
                : AppColors.borderLightOf(context),
          ),

          // Row 2: สำหรับเจ้าหน้าที่และผู้ตรวจสอบ
          PressableScale(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminLoginScreen(appState: appState),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF232D38)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.shield_fill,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF334155),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สำหรับเจ้าหน้าที่และผู้ตรวจสอบ',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppDarkColors.textPrimary
                                : AppColors.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'จัดการคำขอ นัดหมายตรวจแปลง และบันทึกผลแล็บ',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? AppDarkColors.textSecondary
                                : AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppDarkColors.surfaceElevated
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppDarkColors.border
                            : const Color(0xFFCBD5E1),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppDarkColors.textPrimary
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          CupertinoIcons.chevron_forward,
                          size: 11,
                          color: isDark
                              ? AppDarkColors.textMuted
                              : AppColors.textMutedOf(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Verification & Standards Group
  Widget _buildStandardsGroup(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppDarkColors.border : AppColors.borderOf(context),
          width: 0.8,
        ),
        boxShadow: AppShadows.cardOf(context),
      ),
      child: Column(
        children: [
          // Tile 1: ตรวจดูผลแล็บและใบรับรอง
          _buildMenuTile(
            context: context,
            icon: CupertinoIcons.checkmark_seal_fill,
            iconColor: isDark ? AppDarkColors.primary : AppColors.primary,
            iconBg: isDark ? const Color(0xFF143820) : const Color(0xFFE8F7EC),
            title: 'ผลตรวจแล็บและใบรับรองทั้งหมด',
            subtitle: 'ค้นหาใบรับรอง QR Code และผลตรวจปลอดภัย',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CertificatesHubTab(appState: appState),
                ),
              );
            },
          ),

          Divider(
            height: 1,
            indent: 64,
            color: isDark
                ? AppDarkColors.borderLight
                : AppColors.borderLightOf(context),
          ),

          // Tile 2: มาตรฐานการตรวจรับรอง 4 ขั้นตอน
          _buildMenuTile(
            context: context,
            icon: CupertinoIcons.doc_text_search,
            iconColor: isDark
                ? const Color(0xFF60A5FA)
                : const Color(0xFF2563EB),
            iconBg: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            title: 'มาตรฐานการตรวจรับรอง 4 ขั้นตอน',
            subtitle: 'ขั้นตอนการสุ่มตรวจแปลงและแล็บวิเคราะห์สารเคมี',
            onTap: () => _showStandardsModal(context),
          ),

          Divider(
            height: 1,
            indent: 64,
            color: isDark
                ? AppDarkColors.borderLight
                : AppColors.borderLightOf(context),
          ),

          // Tile 3: เกี่ยวกับ SafeVege และคำแนะนำเริ่มต้นใช้งาน
          _buildMenuTile(
            context: context,
            icon: CupertinoIcons.sparkles,
            iconColor: isDark
                ? const Color(0xFFFBBF24)
                : const Color(0xFFD97706),
            iconBg: isDark ? const Color(0xFF2E2415) : const Color(0xFFFEF3C7),
            title: 'เกี่ยวกับ SafeVege และคู่มือเริ่มต้นใช้งาน',
            subtitle: 'แนะนำฟีเจอร์เด่น แผนที่ ตรวจสอบสารพิษ และนำทาง',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WelcomeScreen(appState: appState),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Preferences & Settings Group
  Widget _buildSettingsGroup(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMode = appState.themeMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppDarkColors.border : AppColors.borderOf(context),
          width: 0.8,
        ),
        boxShadow: AppShadows.cardOf(context),
      ),
      child: Column(
        children: [
          // Theme row with segmented control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2D2638)
                        : const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: isDark
                        ? const Color(0xFFC084FC)
                        : const Color(0xFF9333EA),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ธีมการแสดงผล',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppDarkColors.textPrimary
                          : AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppDarkColors.surfaceElevated
                        : const Color(0xFFF1F4F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCompactThemeButton(
                        context: context,
                        icon: Icons.brightness_auto_rounded,
                        isSelected: currentMode == ThemeMode.system,
                        onTap: () => appState.setThemeMode(ThemeMode.system),
                      ),
                      _buildCompactThemeButton(
                        context: context,
                        icon: Icons.light_mode_rounded,
                        isSelected: currentMode == ThemeMode.light,
                        onTap: () => appState.setThemeMode(ThemeMode.light),
                      ),
                      _buildCompactThemeButton(
                        context: context,
                        icon: Icons.dark_mode_rounded,
                        isSelected: currentMode == ThemeMode.dark,
                        onTap: () => appState.setThemeMode(ThemeMode.dark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            indent: 64,
            color: isDark
                ? AppDarkColors.borderLight
                : AppColors.borderLightOf(context),
          ),

          // About SafeVege
          _buildMenuTile(
            context: context,
            icon: Icons.info_outline_rounded,
            iconColor: isDark
                ? AppDarkColors.textSecondary
                : AppColors.textSecondaryOf(context),
            iconBg: isDark
                ? AppDarkColors.surfaceElevated
                : const Color(0xFFF1F5F1),
            title: 'เกี่ยวกับ SafeVege',
            subtitle: 'ระบบค้นหาและตรวจสอบร้านค้าผักปลอดสารพิษ',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'SafeVege',
                applicationVersion: '1.0.0',
                applicationIcon: Image.asset(
                  'assets/safevege_logo.png',
                  width: 48,
                  height: 48,
                ),
                children: const [
                  Text(
                    'ระบบค้นหาและตรวจสอบร้านค้าผักปลอดสารพิษ จังหวัดเชียงราย '
                    'พัฒนาด้วย Flutter และ OpenStreetMap',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Clean Menu List Tile
  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppDarkColors.textPrimary
                          : AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? AppDarkColors.textSecondary
                          : AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 14,
              color: isDark
                  ? AppDarkColors.textMuted
                  : AppColors.textMutedOf(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactThemeButton({
    required BuildContext context,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppDarkColors.primary : AppColors.primary;

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppDarkColors.surface : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected
              ? primaryColor
              : (isDark
                    ? AppDarkColors.textMuted
                    : AppColors.textMutedOf(context)),
        ),
      ),
    );
  }

  /// Modern Bottom Sheet Modal for Standards
  void _showStandardsModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF143820)
                          : const Color(0xFFE8F7EC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: isDark ? AppDarkColors.primary : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'มาตรฐานผักปลอดภัย SafeVege',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppDarkColors.textPrimary
                                : AppColors.textPrimaryOf(context),
                          ),
                        ),
                        Text(
                          '4 ขั้นตอนการตรวจสอบและรับรองคุณภาพ',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppDarkColors.textSecondary
                                : AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildStepItem(
                context: ctx,
                step: '1',
                title: 'สมัครและปักหมุดแปลงปลูก',
                desc: 'ระบุพิกัดแปลงจริงผ่านระบบแผนที่ OpenStreetMap',
                icon: Icons.pin_drop_rounded,
              ),
              const SizedBox(height: 12),
              _buildStepItem(
                context: ctx,
                step: '2',
                title: 'ยื่นคำขอระบุชนิดผัก',
                desc: 'เลือกชนิดผักที่ขอตรวจและนัดหมายวันเข้าเก็บตัวอย่าง',
                icon: Icons.assignment_rounded,
              ),
              const SizedBox(height: 12),
              _buildStepItem(
                context: ctx,
                step: '3',
                title: 'สุ่มตรวจสารพิษในห้องแล็บ',
                desc: 'ตรวจหาสารเคมีกำจัดแมลง โลหะหนัก และไนเตรตตกค้าง',
                icon: Icons.science_rounded,
              ),
              const SizedBox(height: 12),
              _buildStepItem(
                context: ctx,
                step: '4',
                title: 'ออกใบรับรองและขึ้นแสดงบนแผนที่',
                desc: 'ออกตราสัญลักษณ์ QR Code และเปิดแสดงบนแผนที่สาธารณะ',
                icon: Icons.verified_rounded,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark
                        ? AppDarkColors.primary
                        : AppColors.primary,
                    foregroundColor: isDark
                        ? const Color(0xFF04200E)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'เข้าใจแล้ว',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepItem({
    required BuildContext context,
    required String step,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF143820) : const Color(0xFFE8F7EC),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? AppDarkColors.primary : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppDarkColors.textPrimary
                      : AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark
                      ? AppDarkColors.textSecondary
                      : AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Shop Logged In Hero Card
  Widget _buildShopLoggedInCard(BuildContext context) {
    final shop = appState.currentShop;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.heroCardDark : AppGradients.heroCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
        boxShadow: AppShadows.cardOf(context),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  CupertinoIcons.building_2_fill,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'เจ้าของ: ${shop.ownerFullName} • ${shop.shortArea}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PressableScale(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopDashboardScreen(appState: appState),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.square_grid_2x2_fill,
                          size: 17,
                          color: AppColors.primaryOf(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'เข้าสู่แดชบอร์ดร้านค้า',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.primaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PressableScale(
                onTap: () {
                  appState.logoutShop();
                  AppFeedback.showSuccess(context, 'ออกจากระบบร้านค้าแล้ว');
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.square_arrow_right,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Admin Logged In Hero Card
  Widget _buildAdminLoggedInCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.8),
        boxShadow: AppShadows.cardOf(context),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  CupertinoIcons.shield_fill,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appState.adminName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'ผู้ดูแลระบบและเจ้าหน้าที่ตรวจสอบคุณภาพ',
                      style: TextStyle(fontSize: 12.5, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PressableScale(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => appState.isSuperAdmin
                            ? SuperAdminDashboardScreen(appState: appState)
                            : AdminDashboardScreen(appState: appState),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          CupertinoIcons.slider_horizontal_3,
                          size: 17,
                          color: Color(0xFF1E293B),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'จัดการระบบผู้ดูแล',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PressableScale(
                onTap: () {
                  appState.logoutAdmin();
                  AppFeedback.showSuccess(context, 'ออกจากระบบผู้ดูแลแล้ว');
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.square_arrow_right,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
