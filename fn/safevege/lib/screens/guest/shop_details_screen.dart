import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/interactive_animations.dart';
import '../../widgets/interactive_map.dart';
import 'inspection_history_screen.dart';
import 'certificate_viewer_screen.dart';

class ShopDetailsScreen extends StatefulWidget {
  const ShopDetailsScreen({
    super.key,
    required this.shop,
    required this.appState,
  });

  final ShopModel shop;
  final AppState appState;

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  late ShopModel _shop;

  ShopModel get shop => _shop;
  AppState get appState => widget.appState;

  @override
  void initState() {
    super.initState();
    _shop = widget.shop;
    _loadShopDetails();
  }

  Future<void> _loadShopDetails() async {
    try {
      final details = await appState.loadPublicShopDetails(widget.shop.id);
      if (mounted) setState(() => _shop = details);
    } catch (error) {
      if (mounted) AppFeedback.showError(context, error.toString());
    }
  }

  Future<void> _toggleFavorite() async {
    await appState.toggleFavorite(shop.id);
    if (!mounted) return;
    setState(() {});
    AppFeedback.showSuccess(
      context,
      appState.isFavorite(shop.id)
          ? 'บันทึกร้าน ${shop.name} เป็นร้านโปรดแล้ว'
          : 'ลบร้าน ${shop.name} ออกจากร้านโปรดแล้ว',
    );
  }

  void _callShop(BuildContext context) {
    if (shop.phone.trim().isEmpty) {
      AppFeedback.showInfo(context, 'ทางร้านยังไม่ได้ระบุหมายเลขโทรศัพท์');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successBgOf(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_in_talk_rounded,
                color: AppColors.primaryOf(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'โทรหาร้านค้า',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ร้าน: ${shop.name}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.isDark(context)
                    ? AppDarkColors.surfaceElevated
                    : const Color(0xFFF1F8F4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.call_rounded,
                    size: 16,
                    color: AppColors.primaryOf(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    shop.phone,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ต้องการเปิดแอปพลิเคชันโทรศัพท์เพื่อโทรออกทันทีหรือไม่?',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final opened = await launchUrl(
                Uri(scheme: 'tel', path: shop.phone.trim()),
                mode: LaunchMode.externalApplication,
              );
              if (!context.mounted) return;
              if (!opened) {
                AppFeedback.showError(
                  context,
                  'อุปกรณ์นี้ไม่สามารถเปิดการโทรได้',
                );
              }
            },
            icon: const Icon(Icons.call, size: 16),
            label: const Text('โทรออกทันที'),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps() async {
    final origin = appState.nearbyOrigin;
    final originParam = origin != null
        ? '&origin=${origin.latitude},${origin.longitude}'
        : '';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1$originParam&destination=${shop.latitude},${shop.longitude}&travelmode=driving',
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
        AppFeedback.showError(context, 'ไม่สามารถเปิด Google Maps ได้');
      }
    }
  }



  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final thaiYear = date.year + 543;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/$thaiYear';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isFav = appState.isFavorite(shop.id);

    final latestCertificate = shop.publicResults.isEmpty
        ? null
        : shop.publicResults.first;
    final latestCertificateVegetables = latestCertificate == null
        ? const <String>[]
        : shop.publicResults
              .where(
                (result) =>
                    result.certificateId == latestCertificate.certificateId,
              )
              .map((result) => result.vegetableName)
              .toSet()
              .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text(
          'รายละเอียดร้านค้า',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          AnimatedFavoriteHeart(
            isFavorite: isFav,
            onToggle: _toggleFavorite,
            size: 24,
            activeColor: const Color(0xFFF43F5E),
            inactiveColor: Theme.of(context).appBarTheme.iconTheme?.color ??
                (isDark ? Colors.white70 : Colors.black87),
          ),
          IconButton(
            tooltip: 'โทรหาร้าน',
            icon: const Icon(Icons.phone_outlined, size: 22),
            onPressed: () => _callShop(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: AppContentWidth.form,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    // 1. Hero Store Profile Card
                    _buildHeroStoreCard(context, isDark),

                    const SizedBox(height: 14),

                    // 2. Quick Action Bar (4 Pill Buttons)
                    _buildQuickActionBar(
                      context: context,
                      isDark: isDark,
                      isFav: isFav,
                      latestCertificate: latestCertificate,
                      latestCertificateVegetables: latestCertificateVegetables,
                    ),

                    const SizedBox(height: 16),

                    // 3. Trust & Certification Highlight Card
                    _buildTrustSummaryCard(
                      context: context,
                      isDark: isDark,
                      latestCertificate: latestCertificate,
                      latestCertificateVegetables: latestCertificateVegetables,
                    ),

                    const SizedBox(height: 16),

                    // 4. Certified Vegetables Section
                    _buildCertifiedVegetablesSection(
                      context: context,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // 5. Location & Interactive Map Card
                    _buildLocationAndMapCard(context, isDark),

                    const SizedBox(height: 16),

                    // 6. Shop Information Card
                    _buildShopInfoCard(context, isDark),

                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Bottom Sticky Action Bar
              _buildBottomStickyBar(
                context: context,
                isDark: isDark,
                latestCertificate: latestCertificate,
                latestCertificateVegetables: latestCertificateVegetables,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. HERO STORE PROFILE CARD
  // ==========================================
  Widget _buildHeroStoreCard(BuildContext context, bool isDark) {
    final distance = appState.distanceTextFor(shop);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppDarkColors.border : const Color(0xFFE2EBE4),
          width: 1,
        ),
        boxShadow: AppShadows.cardOf(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Lush Botanical Header Banner
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0C2919),
                        Color(0xFF133F27),
                        Color(0xFF1B5536),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0A4428),
                        Color(0xFF125C37),
                        Color(0xFF1B7A4C),
                      ],
                    ),
            ),
            child: Stack(
              children: [
                // Organic background ambient rings
                Positioned(
                  right: -25,
                  top: -30,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
                Positioned(
                  left: -35,
                  bottom: -35,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),

                // Banner Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Category Pill & Certified Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Category Chip
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    shop.name.contains('ดอย') || shop.name.contains('ฟาร์ม')
                                        ? Icons.agriculture_rounded
                                        : (shop.name.contains('สวน')
                                            ? Icons.park_rounded
                                            : Icons.storefront_rounded),
                                    size: 13,
                                    color: const Color(0xFFA7F3D0),
                                  ),
                                  const SizedBox(width: 4.5),
                                  Flexible(
                                    child: Text(
                                      shop.name.contains('ดอย') || shop.name.contains('ฟาร์ม')
                                          ? 'ฟาร์มเกษตรปลอดภัย'
                                          : (shop.name.contains('สวน')
                                              ? 'สวนเกษตรปลอดภัย'
                                              : 'ร้านค้าผักปลอดภัย'),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // SafeVege Certified Badge
                          if (shop.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.checkmark_seal_fill,
                                    size: 13,
                                    color: Color(0xFF10B981),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'SafeVege Certified',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F5A3C),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Store Identity Row: Avatar + Name + Farmer
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Shop Avatar
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                shop.name.contains('ดอย') || shop.name.contains('ฟาร์ม')
                                    ? Icons.agriculture_rounded
                                    : (shop.name.contains('สวน')
                                        ? Icons.park_rounded
                                        : Icons.storefront_rounded),
                                size: 28,
                                color: const Color(0xFF0F5A3C),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Name & Farmer Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  shop.name,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.25,
                                    letterSpacing: -0.3,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black38,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person_rounded,
                                      size: 13,
                                      color: Color(0xFFA7F3D0),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        shop.ownerFullName.isNotEmpty
                                            ? 'เจ้าของ: ${shop.ownerFullName}'
                                            : 'เกษตรกรผู้ผลิต SafeVege',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFFD1FAE5),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Card Body: Chips & Quality Guarantee Strip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Badges Wrap
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Distance Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F3221)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF22543D)
                              : const Color(0xFFC8E6C9),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.near_me_rounded,
                            size: 12,
                            color: isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 3.5),
                          Text(
                            distance.isNotEmpty && distance != '—'
                                ? 'ห่าง $distance'
                                : 'ใกล้คุณ',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Area Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1C2720)
                            : const Color(0xFFF3F6F4),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2F3E33)
                              : const Color(0xFFE2EBE4),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12.5,
                            color: isDark
                                ? AppDarkColors.textSecondary
                                : AppColors.textSecondaryOf(context),
                          ),
                          const SizedBox(width: 3.5),
                          Text(
                            shop.shortArea,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppDarkColors.textPrimary
                                  : AppColors.textPrimaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Verified Vegetables Count Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF113020)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: const Color(0xFF22C55E).withOpacity(0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🥬', style: TextStyle(fontSize: 11.5)),
                          const SizedBox(width: 3.5),
                          Text(
                            'ผักรับรอง ${shop.verifiedVegetables.length} ชนิด',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFF4ADE80)
                                  : const Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Quality Assurance Guarantee Strip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? const [Color(0xFF0F2B1D), Color(0xFF143B27)]
                          : const [Color(0xFFEBF7EF), Color(0xFFDEF2E4)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF22543D)
                          : const Color(0xFFBAE6C7),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4.5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1B4E32)
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark_shield_fill,
                          size: 14,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'รับรองความปลอดภัยตามเกณฑ์มาตรฐาน SafeVege',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFF0D5434),
                              ),
                            ),
                            Text(
                              'ผ่านการตรวจสอบสารตกค้าง ปลอดภัย มั่นใจได้ทุกมื้อ',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFF2D6A4F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. QUICK ACTION BAR (4 Interactive Action Buttons)
  // ==========================================
  Widget _buildQuickActionBar({
    required BuildContext context,
    required bool isDark,
    required bool isFav,
    required PublicInspectionResult? latestCertificate,
    required List<String> latestCertificateVegetables,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderOf(context),
          width: 1.1,
        ),
        boxShadow: AppShadows.cardOf(context),
      ),
      child: Row(
        children: [
          // 1. Call
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.phone_rounded,
              label: 'โทรออก',
              color: const Color(0xFF10B981),
              bgColor: isDark ? const Color(0xFF0F3523) : const Color(0xFFE8F5E9),
              onTap: () => _callShop(context),
            ),
          ),

          // 2. Google Maps Navigation
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.near_me_rounded,
              label: 'นำทาง Maps',
              color: const Color(0xFF0284C7),
              bgColor: isDark ? const Color(0xFF0C2C3D) : const Color(0xFFE0F2FE),
              onTap: _openGoogleMaps,
            ),
          ),

          // 3. View Certificate
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.workspace_premium_rounded,
              label: 'ใบรับรอง',
              color: const Color(0xFFD97706),
              bgColor: isDark ? const Color(0xFF38230A) : const Color(0xFFFEF3C7),
              onTap: latestCertificate == null
                  ? () => AppFeedback.showInfo(
                        context,
                        'ร้านนี้อยู่ระหว่างการเตรียมเผยแพร่ใบรับรอง',
                      )
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CertificateViewerScreen(
                            shopName: shop.name,
                            certNumber: latestCertificate.certificateNumber,
                            certificateId: latestCertificate.certificateId,
                            vegetables: latestCertificateVegetables,
                            issueDate: latestCertificate.issuedAt,
                            expiryDate: latestCertificate.expiresAt,
                          ),
                        ),
                      ),
            ),
          ),

          // 4. Favorite
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              label: isFav ? 'ร้านโปรด' : 'บันทึก',
              color: const Color(0xFFE11D48),
              bgColor: isDark ? const Color(0xFF3B121B) : const Color(0xFFFFE4E6),
              onTap: _toggleFavorite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, size: 21, color: color),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 3. TRUST & CERTIFICATION SUMMARY CARD
  // ==========================================
  Widget _buildTrustSummaryCard({
    required BuildContext context,
    required bool isDark,
    required PublicInspectionResult? latestCertificate,
    required List<String> latestCertificateVegetables,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF234D35)
              : const Color(0xFFCBE5D5),
          width: 1.2,
        ),
        boxShadow: AppShadows.cardOf(context),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with SafeVege Trust Shield
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF13361E)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.shield_lefthalf_fill,
                  size: 18,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'การรับรองมาตรฐาน SafeVege',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    Text(
                      'ผ่านการสุ่มตรวจวิเคราะห์สารพิษตกค้างทางการเกษตร',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3-Metric Trust Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppDarkColors.surfaceElevated
                  : const Color(0xFFF8FAF7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.borderOf(context),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                // Metric 1: Residue Test Status
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'ความปลอดภัย',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'ผ่าน 100%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'สารเคมีตกค้าง',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: AppColors.borderOf(context),
                ),
                // Metric 2: Verified Crops
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'ผักที่รับรอง',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${shop.verifiedVegetables.length} ชนิด',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'รายการสุ่มตรวจ',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: AppColors.borderOf(context),
                ),
                // Metric 3: Certificate status
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'ใบรับรอง',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        latestCertificate != null ? 'ทางการ' : 'อยู่ระหว่างตรวจ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: latestCertificate != null
                              ? const Color(0xFFD97706)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        latestCertificate != null ? 'สสจ. เชียงราย' : 'รอผลตรวจ',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (latestCertificate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2620)
                    : const Color(0xFFF2F7F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 15,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'เลขที่ ${latestCertificate.certificateNumber} • ใช้ได้ถึง ${_formatDate(latestCertificate.expiresAt)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CertificateViewerScreen(
                          shopName: shop.name,
                          certNumber: latestCertificate.certificateNumber,
                          certificateId: latestCertificate.certificateId,
                          vegetables: latestCertificateVegetables,
                          issueDate: latestCertificate.issuedAt,
                          expiryDate: latestCertificate.expiresAt,
                        ),
                      ),
                    ),
                    child: Text(
                      'ดูเอกสาร',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 4. CERTIFIED VEGETABLES SECTION
  // ==========================================
  Widget _buildCertifiedVegetablesSection({
    required BuildContext context,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'ผักปลอดสารพิษที่รับรอง',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOf(context).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${shop.verifiedVegetables.length}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOf(context),
                    ),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: shop.publicResults.isEmpty
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InspectionHistoryScreen(
                            shop: shop,
                            results: shop.publicResults,
                          ),
                        ),
                      ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.history_rounded, size: 16),
              label: const Text(
                'ดูประวัติผลตรวจ',
                style: TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (shop.verifiedVegetables.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(
                    'ยังไม่มีข้อมูลผลตรวจที่เผยแพร่',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ร้านค้านี้อยู่ระหว่างรอการตรวจรับรองผักปลอดสารพิษรอบถัดไป',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...shop.verifiedVegetables.map((veg) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.borderOf(context),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InspectionHistoryScreen(
                          shop: shop,
                          results: shop.publicResults
                              .where(
                                (result) => result.vegetableName == veg,
                              )
                              .toList(growable: false),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Vegetable Emoji Container
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1B3122)
                                : const Color(0xFFEAF5EE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF285437)
                                  : const Color(0xFFC7E6D0),
                              width: 0.8,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              safeVegeEmoji(veg),
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Vegetable Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                veg,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ผ่านเกณฑ์ความปลอดภัย • แตะเพื่อดูประวัติ',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondaryOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status Badge
                        const StatusBadge(status: 'ผ่าน'),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.textMutedOf(context),
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

  // ==========================================
  // 5. LOCATION & INTEGRATED MAP CARD
  // ==========================================
  Widget _buildLocationAndMapCard(BuildContext context, bool isDark) {
    final primaryColor = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final surfaceElevated = isDark
        ? AppDarkColors.surfaceElevated
        : const Color(0xFFF3F7F4);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderOf(context),
          width: 1.1,
        ),
        boxShadow: AppShadows.cardOf(context),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with location title & distance badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ตำแหน่งที่ตั้งร้าน',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              if (shop.distanceText != '—' && shop.distanceText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.near_me_rounded, size: 12, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'ห่าง ${shop.distanceText}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Address detail box with copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppDarkColors.border.withOpacity(0.5)
                    : const Color(0xFFE5EDE7),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.storefront_rounded,
                  size: 18,
                  color: primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    shop.fullAddress,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'คัดลอกที่อยู่',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: shop.fullAddress));
                    AppFeedback.showSuccess(context, 'คัดลอกที่อยู่เรียบร้อยแล้ว');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Embedded Interactive Map Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 170,
              child: SafeVegeInteractiveMap(
                height: 170,
                compact: true,
                shops: [shop],
                selectedShop: shop,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Full-width prominent Google Maps navigation button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: _openGoogleMaps,
              style: FilledButton.styleFrom(
                backgroundColor:
                    isDark ? AppDarkColors.primary : AppColors.primary,
                foregroundColor:
                    isDark ? const Color(0xFF04200E) : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.turn_right_rounded, size: 18),
              label: const Text(
                'เปิดนำทางด้วย Google Maps',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. SHOP INFO CARD (Contact & Registration)
  // ==========================================
  Widget _buildShopInfoCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderOf(context),
          width: 1.1,
        ),
        boxShadow: AppShadows.cardOf(context),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.primaryOf(context),
              ),
              const SizedBox(width: 8),
              Text(
                'ข้อมูลการติดต่อร้านค้า',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Phone
          InkWell(
            onTap: () => _callShop(context),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: AppColors.textSecondaryOf(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'เบอร์โทรศัพท์',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          shop.phone.isNotEmpty ? shop.phone : 'ไม่ระบุ',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _callShop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      side: BorderSide(
                        color: AppColors.primaryOf(context).withOpacity(0.4),
                      ),
                    ),
                    icon: const Icon(Icons.call, size: 13),
                    label: const Text(
                      'โทรออก',
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16),
          // Registered Date
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textSecondaryOf(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'วันที่ลงทะเบียนในระบบ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        _formatDate(shop.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. BOTTOM STICKY ACTION BAR
  // ==========================================
  Widget _buildBottomStickyBar({
    required BuildContext context,
    required bool isDark,
    required PublicInspectionResult? latestCertificate,
    required List<String> latestCertificateVegetables,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        border: Border(
          top: BorderSide(color: AppColors.borderOf(context)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // View Certificate Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: latestCertificate == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CertificateViewerScreen(
                            shopName: shop.name,
                            certNumber: latestCertificate.certificateNumber,
                            certificateId: latestCertificate.certificateId,
                            vegetables: latestCertificateVegetables,
                            issueDate: latestCertificate.issuedAt,
                            expiryDate: latestCertificate.expiresAt,
                          ),
                        ),
                      ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.borderOf(context)),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.workspace_premium_rounded,
                size: 18,
                color: Color(0xFFD97706),
              ),
              label: Text(
                latestCertificate == null ? 'ไม่มีใบรับรอง' : 'ใบรับรองจริง',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Google Maps Primary Navigate Button
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _openGoogleMaps,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.turn_right_rounded, size: 20),
              label: const Text(
                'นำทาง (Google Maps)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
