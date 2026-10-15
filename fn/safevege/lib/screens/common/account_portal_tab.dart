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
        final primaryColor = isDark ? AppDarkColors.primary : AppColors.primary;
        final surfaceElevated = isDark
            ? AppDarkColors.surfaceElevated
            : Colors.white;
        final borderColor = isDark
            ? AppDarkColors.border
            : AppColors.borderOf(context);

        return Scaffold(
          backgroundColor: isDark
              ? AppDarkColors.background
              : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppDarkColors.background : Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(isDark ? 0.25 : 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.person_crop_circle_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
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
              PressableScale(
                onTap: () => appState.toggleThemeMode(),
                child: Container(
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? borderColor : const Color(0xFFE2EAE3),
                      width: 0.8,
                    ),
                    boxShadow: AppShadows.cardOf(context),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      key: ValueKey(isDark),
                      color: primaryColor,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  children: [
                    // 1. User Hero Profile Section
                    if (isShop)
                      _buildShopLoggedInCard(context)
                    else if (isAdmin)
                      _buildAdminLoggedInCard(context)
                    else
                      _buildGuestProfileCard(context),

                    const SizedBox(height: 22),

                    // 2. Portals & Access Management (เมื่อยังไม่ได้เข้าสู่ระบบ)
                    if (!isShop && !isAdmin) ...[
                      _buildSectionLabel(
                        context,
                        'เข้าสู่ระบบตามบทบาท (PORTALS)',
                      ),
                      const SizedBox(height: 10),
                      _buildRolePortalsGroup(context),
                      const SizedBox(height: 22),
                    ],

                    // 3. Verification & Standards Group
                    _buildSectionLabel(context, 'ข้อมูลและการรับรองมาตรฐาน'),
                    const SizedBox(height: 10),
                    _buildStandardsGroup(context),

                    const SizedBox(height: 22),

                    // 4. Preferences & Settings Group
                    _buildSectionLabel(context, 'การตั้งค่าระบบ (SETTINGS)'),
                    const SizedBox(height: 10),
                    _buildSettingsGroup(context),

                    const SizedBox(height: 32),

                    // Footer Branding
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.eco_rounded,
                                  size: 13,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'SafeVege • จังหวัดเชียงราย',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: isDark
                                      ? AppDarkColors.textSecondary
                                      : AppColors.textSecondaryOf(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'ระบบค้นหาและตรวจสอบร้านค้าผักปลอดสารพิษ • v1.0.0',
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Label for Grouped Sections with sleek botanical accent
  Widget _buildSectionLabel(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppDarkColors.primary : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 12,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppDarkColors.textMuted
                  : AppColors.textSecondaryOf(context),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Guest Profile Hero Card
  Widget _buildGuestProfileCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppDarkColors.primary : AppColors.primary;
    final surfaceColor = isDark ? AppDarkColors.surface : Colors.white;
    final borderColor = isDark
        ? AppDarkColors.border
        : AppColors.borderOf(context);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: AppShadows.cardOf(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle decorative watermark leaf in top-right corner
          Positioned(
            right: -14,
            top: -14,
            child: Icon(
              Icons.eco_rounded,
              size: 96,
              color: primaryColor.withOpacity(isDark ? 0.05 : 0.035),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar Squircle
                    Stack(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF059669), Color(0xFF10B981)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF10B981,
                                ).withOpacity(0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        // Online / verified guest green dot
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: surfaceColor,
                                width: 2.2,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                                    fontSize: 16.5,
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
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(
                                    isDark ? 0.16 : 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.25),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'โหมดผู้บริโภค',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ค้นหาร้านค้าและดูผลตรวจผักปลอดภัยได้ทันที',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? AppDarkColors.textSecondary
                                  : AppColors.textSecondaryOf(context),
                              height: 1.25,
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
                  color: isDark
                      ? AppDarkColors.borderLight
                      : AppColors.borderLightOf(context),
                ),
                const SizedBox(height: 12),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppDarkColors.surfaceElevated
                          : const Color(0xFFF6FAF6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppDarkColors.border
                            : const Color(0xFFE0ECE1),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            size: 16,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ตรวจดูผลแล็บและใบรับรองทั้งหมดในระบบ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppDarkColors.textPrimary
                                  : AppColors.textPrimaryOf(context),
                            ),
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppDarkColors.border
                                  : const Color(0xFFD6E3D8),
                              width: 0.6,
                            ),
                          ),
                          child: Icon(
                            CupertinoIcons.chevron_forward,
                            size: 13,
                            color: isDark
                                ? AppDarkColors.textMuted
                                : AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
        borderRadius: BorderRadius.circular(22),
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.24),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.building_2_fill,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สำหรับเกษตรกรและร้านค้า',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                              color: isDark
                                  ? AppDarkColors.textPrimary
                                  : AppColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'ยื่นขอตรวจแปลงผัก รับผลตรวจแล็บ และปักหมุดบนแผนที่',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppDarkColors.textSecondary
                                  : AppColors.textSecondaryOf(context),
                              height: 1.35,
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF10B981,
                                ).withOpacity(0.28),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.arrow_right_to_line,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'เข้าสู่ระบบร้านค้า',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppDarkColors.surfaceElevated
                                : const Color(0xFFF4F7F4),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: isDark
                                  ? AppDarkColors.border
                                  : const Color(0xFFDDE6DF),
                              width: 0.8,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'สมัครร้านค้า',
                              style: TextStyle(
                                fontSize: 13,
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
            indent: 16,
            endIndent: 16,
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
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF334155), Color(0xFF1E293B)],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      CupertinoIcons.shield_fill,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สำหรับเจ้าหน้าที่และผู้ตรวจสอบ',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
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
                      horizontal: 11,
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
        borderRadius: BorderRadius.circular(22),
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
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10B981)],
            ),
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
            indent: 68,
            endIndent: 16,
            color: isDark
                ? AppDarkColors.borderLight
                : AppColors.borderLightOf(context),
          ),

          // Tile 2: มาตรฐานการตรวจรับรอง 4 ขั้นตอน
          _buildMenuTile(
            context: context,
            icon: CupertinoIcons.doc_text_search,
            gradient: const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
            ),
            title: 'มาตรฐานการตรวจรับรอง 4 ขั้นตอน',
            subtitle: 'ขั้นตอนการสุ่มตรวจแปลงและแล็บวิเคราะห์สารเคมี',
            onTap: () => _showStandardsModal(context),
          ),

          Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: isDark
                ? AppDarkColors.borderLight
                : AppColors.borderLightOf(context),
          ),

          // Tile 3: เกี่ยวกับ SafeVege และคำแนะนำเริ่มต้นใช้งาน
          _buildMenuTile(
            context: context,
            icon: CupertinoIcons.sparkles,
            gradient: const LinearGradient(
              colors: [Color(0xFFD97706), Color(0xFFFBBF24)],
            ),
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
        borderRadius: BorderRadius.circular(22),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.palette_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    'ธีมการแสดงผล',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                      color: isDark
                          ? AppDarkColors.textPrimary
                          : AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppDarkColors.surfaceElevated
                        : const Color(0xFFF0F4F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppDarkColors.border
                          : const Color(0xFFDEE7E0),
                      width: 0.6,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCompactThemeButton(
                        context: context,
                        icon: Icons.brightness_auto_rounded,
                        tooltip: 'ตามระบบ',
                        isSelected: currentMode == ThemeMode.system,
                        onTap: () => appState.setThemeMode(ThemeMode.system),
                      ),
                      _buildCompactThemeButton(
                        context: context,
                        icon: Icons.light_mode_rounded,
                        tooltip: 'โหมดสว่าง',
                        isSelected: currentMode == ThemeMode.light,
                        onTap: () => appState.setThemeMode(ThemeMode.light),
                      ),
                      _buildCompactThemeButton(
                        context: context,
                        icon: Icons.dark_mode_rounded,
                        tooltip: 'โหมดมืด',
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
            indent: 68,
            endIndent: 16,
            color: isDark
                ? AppDarkColors.borderLight
                : AppColors.borderLightOf(context),
          ),

          // About SafeVege
          _buildMenuTile(
            context: context,
            icon: Icons.info_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
            ),
            title: 'เกี่ยวกับ SafeVege',
            subtitle: 'ระบบค้นหาและตรวจสอบร้านค้าผักปลอดสารพิษ',
            trailingBadge: 'v1.0.0',
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

  /// Clean Menu List Tile with gradient icon squircle
  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required Gradient gradient,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailingBadge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
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
            if (trailingBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppDarkColors.surfaceElevated
                      : const Color(0xFFF1F5F1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trailingBadge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppDarkColors.textMuted
                        : AppColors.textSecondaryOf(context),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
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
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppDarkColors.primary : AppColors.primary;

    return Tooltip(
      message: tooltip,
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppDarkColors.surface : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                      blurRadius: 5,
                      offset: const Offset(0, 1.5),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 16.5,
            color: isSelected
                ? primaryColor
                : (isDark
                      ? AppDarkColors.textMuted
                      : AppColors.textMutedOf(context)),
          ),
        ),
      ),
    );
  }

  /// Modern Bottom Sheet Modal for Standards
  void _showStandardsModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppDarkColors.primary : AppColors.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: Colors.white,
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
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                            color: isDark
                                ? AppDarkColors.textPrimary
                                : AppColors.textPrimaryOf(context),
                          ),
                        ),
                        Text(
                          '4 ขั้นตอนการตรวจสอบและรับรองคุณภาพอย่างโปร่งใส',
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
              const SizedBox(height: 14),
              _buildStepItem(
                context: ctx,
                step: '2',
                title: 'ยื่นคำขอระบุชนิดผัก',
                desc: 'เลือกชนิดผักที่ขอตรวจและนัดหมายวันเข้าเก็บตัวอย่าง',
                icon: Icons.assignment_rounded,
              ),
              const SizedBox(height: 14),
              _buildStepItem(
                context: ctx,
                step: '3',
                title: 'สุ่มตรวจสารพิษในห้องแล็บ',
                desc: 'ตรวจหาสารเคมีกำจัดแมลง โลหะหนัก และไนเตรตตกค้าง',
                icon: Icons.science_rounded,
              ),
              const SizedBox(height: 14),
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
                    backgroundColor: primaryColor,
                    foregroundColor: isDark
                        ? const Color(0xFF04200E)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text(
                    'เข้าใจแล้ว',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10B981)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.25),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 13),
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
    );
  }

  /// Shop Logged In Hero Card
  Widget _buildShopLoggedInCard(BuildContext context) {
    final shop = appState.currentShop;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.heroCardDark : AppGradients.heroCard,
        borderRadius: BorderRadius.circular(22),
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
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  CupertinoIcons.building_2_fill,
                  color: Colors.white,
                  size: 26,
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
                        fontSize: 17.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
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
                      borderRadius: BorderRadius.circular(13),
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
                            fontSize: 13.5,
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
                    borderRadius: BorderRadius.circular(13),
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
        borderRadius: BorderRadius.circular(22),
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
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  CupertinoIcons.shield_fill,
                  color: Colors.white,
                  size: 26,
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
                        fontSize: 17.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
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
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                            fontSize: 13.5,
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
                    borderRadius: BorderRadius.circular(13),
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
