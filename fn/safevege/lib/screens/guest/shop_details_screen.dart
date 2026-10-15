import 'package:flutter/material.dart';
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
import 'route_navigation_screen.dart';

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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.phone_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
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
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'เบอร์โทรศัพท์: ${shop.phone}',
              style: const TextStyle(fontSize: 16, color: AppColors.primary),
            ),
            const SizedBox(height: 10),
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
                Uri(scheme: 'tel', path: shop.phone),
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
            label: const Text('โทรออก'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('รายละเอียดร้านค้า'),
        actions: [
          AnimatedFavoriteHeart(
            isFavorite: appState.isFavorite(shop.id),
            onToggle: _toggleFavorite,
            size: 24,
            activeColor: const Color(0xFFF43F5E),
            inactiveColor: Theme.of(context).appBarTheme.iconTheme?.color ??
                (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: AppContentWidth.form,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  children: [
                    // Hero Header Card with Lush Gradient
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.borderOf(context),
                          width: 1.2,
                        ),
                        boxShadow: AppShadows.cardOf(context),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Farm Banner Cover
                          Container(
                            height: 110,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: AppGradients.heroCard,
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                FloatingElement(
                                  distance: 4.0,
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceOf(context),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.storefront_rounded,
                                      color: AppColors.primaryOf(context),
                                      size: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (shop.isVerified)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.92,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.verified_rounded,
                                                size: 12,
                                                color: AppColors.secondary,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'SafeVege Certified',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryOf(
                                                    context,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        shop.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Store Info Body
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (shop.ownerFullName.isNotEmpty) ...[
                                      Icon(
                                        Icons.person_outline_rounded,
                                        size: 16,
                                        color: AppColors.textSecondaryOf(
                                          context,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'เจ้าของร้าน: ${shop.ownerFullName}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textPrimaryOf(
                                            context,
                                          ),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1FAF3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.near_me_rounded,
                                            size: 12,
                                            color: AppColors.primaryOf(context),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'ห่าง ${appState.distanceTextFor(shop)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryOf(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: AppColors.textSecondaryOf(context),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        shop.fullAddress,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondaryOf(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 16,
                                      color: AppColors.textSecondaryOf(context),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      shop.phone,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimaryOf(context),
                                      ),
                                    ),
                                    const Spacer(),
                                    OutlinedButton.icon(
                                      onPressed: () => _callShop(context),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 32),
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                      ),
                                      icon: const Icon(Icons.call, size: 14),
                                      label: const Text(
                                        'โทรออก',
                                        style: TextStyle(fontSize: 12),
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

                    const SizedBox(height: 14),

                    // Map Preview Card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.borderOf(context),
                          width: 1.2,
                        ),
                        boxShadow: AppShadows.cardOf(context),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.map_rounded,
                                    size: 18,
                                    color: AppColors.primaryOf(context),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'ตำแหน่งร้านค้าบนแผนที่',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RouteNavigationScreen(shop: shop),
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(
                                  Icons.turn_right_rounded,
                                  size: 16,
                                ),
                                label: const Text('ดูเส้นทาง'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 150,
                              child: SafeVegeInteractiveMap(
                                height: 150,
                                compact: true,
                                shops: [shop],
                                selectedShop: shop,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Certified Vegetables Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ผักปลอดสารพิษที่รับรอง (${shop.verifiedVegetables.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOf(context),
                          ),
                        ),
                        TextButton(
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
                          child: const Text('ดูประวัติผลตรวจ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (shop.verifiedVegetables.isEmpty)
                      const EmptyStateView(
                        title: 'ยังไม่มีข้อมูลผลตรวจที่เผยแพร่',
                        message:
                            'ร้านค้านี้อยู่ระหว่างรอการตรวจรับรองผักปลอดสารพิษ',
                      )
                    else
                      ...shop.verifiedVegetables.map((veg) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceOf(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.borderOf(context),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x05000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.successBgOf(context),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.eco_rounded,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                veg,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: const Text(
                                'ผลผ่านและใบรับรองที่เผยแพร่ • แตะเพื่อดูประวัติผลตรวจ',
                                style: TextStyle(fontSize: 11.5),
                              ),
                              trailing: const StatusBadge(status: 'ผ่าน'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => InspectionHistoryScreen(
                                      shop: shop,
                                      results: shop.publicResults
                                          .where(
                                            (result) =>
                                                result.vegetableName == veg,
                                          )
                                          .toList(growable: false),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Bottom Sticky Action Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  border: Border(
                    top: BorderSide(color: AppColors.borderOf(context)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: latestCertificate == null
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CertificateViewerScreen(
                                    shopName: shop.name,
                                    certNumber:
                                        latestCertificate.certificateNumber,
                                    certificateId:
                                        latestCertificate.certificateId,
                                    vegetables: latestCertificateVegetables,
                                    issueDate: latestCertificate.issuedAt,
                                    expiryDate: latestCertificate.expiresAt,
                                  ),
                                ),
                              ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.borderOf(context)),
                          minimumSize: const Size(0, 48),
                        ),
                        icon: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 18,
                        ),
                        label: Text(
                          latestCertificate == null
                              ? 'ยังไม่มีใบรับรอง'
                              : 'เปิดใบรับรองจริง',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RouteNavigationScreen(shop: shop),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(0, 48),
                        ),
                        icon: const Icon(Icons.turn_right_rounded),
                        label: const Text(
                          'นำทางไปยังร้านค้า',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
