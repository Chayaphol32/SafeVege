import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/user_location_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/interactive_animations.dart';
import 'shop_details_screen.dart';

class ExploreFeedTab extends StatefulWidget {
  const ExploreFeedTab({
    super.key,
    required this.appState,
    required this.searchController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onOpenMap,
    required this.onOpenCertificates,
    required this.onOpenAccount,
  });

  final AppState appState;
  final TextEditingController searchController;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenCertificates;
  final VoidCallback onOpenAccount;

  @override
  State<ExploreFeedTab> createState() => _ExploreFeedTabState();
}

class _ExploreFeedTabState extends State<ExploreFeedTab> {
  String get _searchQuery => widget.searchController.text;
  String get _selectedCategory => widget.selectedCategory;
  Timer? _searchDebounce;
  bool _isLocating = false;

  void _searchChanged(String query) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      widget.appState
          .loadPublicShops(
            query: query.trim(),
            near: widget.appState.nearbyOrigin,
          )
          .catchError((Object _) {});
    });
  }

  final List<Map<String, String>> _categories = const [
    {'label': 'ทั้งหมด', 'icon': '🌿'},
    {'label': 'ร้านโปรด', 'icon': '❤️'},
    {'label': 'ผักสลัด', 'icon': '🥬'},
    {'label': 'คะน้า', 'icon': '🥦'},
    {'label': 'มะเขือเทศ', 'icon': '🍅'},
    {'label': 'กะหล่ำปลี', 'icon': '🥗'},
    {'label': 'แตงกวา', 'icon': '🥒'},
    {'label': 'แครอท', 'icon': '🥕'},
    {'label': 'ใกล้ฉัน', 'icon': '⚡'},
  ];

  List<ShopModel> _getFilteredShops() {
    return widget.appState.shops.where((shop) {
      if (!shop.isVerified) return false;

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = shop.name.toLowerCase().contains(query);
        final matchArea =
            shop.shortArea.toLowerCase().contains(query) ||
            shop.district.toLowerCase().contains(query);
        final matchVeg = shop.verifiedVegetables.any(
          (v) => v.toLowerCase().contains(query),
        );
        if (!matchName && !matchArea && !matchVeg) return false;
      }

      // Quick category pill filter
      if (_selectedCategory == 'ร้านโปรด') {
        if (!widget.appState.isFavorite(shop.id)) return false;
      } else if (_selectedCategory == 'ใกล้ฉัน') {
        final origin = widget.appState.nearbyOrigin;
        if (origin != null) {
          final dist = origin.distanceKmTo(
            GeoPoint(latitude: shop.latitude, longitude: shop.longitude),
          );
          if (dist > 10.0) return false;
        }
      } else if (_selectedCategory != 'ทั้งหมด') {
        final match = shop.verifiedVegetables.any(
          (v) => v.contains(_selectedCategory),
        );
        if (!match) return false;
      }

      return true;
    }).toList();
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    widget.searchController.clear();
    widget.onCategoryChanged('ทั้งหมด');
    setState(() {});
    AppFeedback.showSuccess(context, 'ล้างตัวกรองทั้งหมดแล้ว');
  }

  Future<void> _filterNearby() async {
    widget.onCategoryChanged('ใกล้ฉัน');
    if (widget.appState.nearbyOrigin == null && !_isLocating) {
      setState(() => _isLocating = true);
      try {
        final location = await const UserLocationService().getCurrentLocation();
        await widget.appState.loadPublicShops(near: location);
        if (mounted) {
          AppFeedback.showSuccess(context, 'อัปเดตตำแหน่งเพื่อแสดงร้านใกล้คุณแล้ว');
        }
      } catch (error) {
        if (mounted) {
          AppFeedback.showInfo(
            context,
            'กำลังแสดงร้านค้าตามพิกัดศูนย์กลางเชียงราย',
          );
        }
      } finally {
        if (mounted) setState(() => _isLocating = false);
      }
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _openGoogleMaps(ShopModel shop) async {
    final origin = widget.appState.nearbyOrigin;
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

  void _callShop(ShopModel shop) {
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
              shop.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'เบอร์โทรศัพท์: ${shop.phone}',
              style: const TextStyle(fontSize: 15, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'เจ้าของร้าน: ${shop.ownerFullName}',
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
            child: const Text('ปิด'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final opened = await launchUrl(
                Uri(scheme: 'tel', path: shop.phone),
                mode: LaunchMode.externalApplication,
              );
              if (!opened && mounted) {
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

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ตัวกรองการค้นหาผักปลอดภัย',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.clear),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((c) {
                    final label = c['label']!;
                    final isSel = _selectedCategory == label;
                    return FilterChip(
                      selected: isSel,
                      label: Text('${c['icon']} $label'),
                      onSelected: (_) {
                        widget.onCategoryChanged(label);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationsSheet(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.bell_fill,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ข่าวสารและประกาศ SafeVege',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildNotificationItem(
                isDark: isDark,
                icon: Icons.verified_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'เผยแพร่ผลตรวจรอบล่าสุดเรียบร้อยแล้ว',
                desc: 'ผลตรวจสารเคมีตกค้างของแปลงผักในเครือข่ายจังหวัดเชียงรายพร้อมให้ตรวจสอบ',
                time: 'วันนี้',
              ),
              const SizedBox(height: 10),
              _buildNotificationItem(
                isDark: isDark,
                icon: Icons.map_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'เปิดนำทางด้วย Google Maps โดยตรง',
                desc: 'แตะที่ปุ่มนำทางบนการ์ดร้านค้า เพื่อเปิด Google Maps พาไปยังแปลงผักได้ทันที',
                time: 'เมื่อวานนี้',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceElevated : const Color(0xFFF8FAF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppDarkColors.border : const Color(0xFFE2EBE4),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final filteredShops = _getFilteredShops();
    final featuredShops = widget.appState.shops
        .where((s) => s.isVerified)
        .take(4)
        .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppDarkColors.primary : AppColors.primary;
    final surfaceElevated = isDark
        ? AppDarkColors.surfaceElevated
        : Colors.white;
    final borderColor = isDark
        ? AppDarkColors.border
        : AppColors.borderOf(context);
    final textPrimary = isDark
        ? AppDarkColors.textPrimary
        : AppColors.textPrimaryOf(context);
    final textSecondary = isDark
        ? AppDarkColors.textSecondary
        : AppColors.textSecondaryOf(context);

    final favCount = widget.appState.favoriteShopIds.length;

    return Scaffold(
      backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: CustomScrollView(
              slivers: [
                // Top Custom App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Row(
                      children: [
                        // SafeVege Logo & Brand (Clean, premium badge)
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                padding: const EdgeInsets.all(4.5),
                                decoration: BoxDecoration(
                                  color: surfaceElevated,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(
                                      isDark ? 0.3 : 0.18,
                                    ),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(
                                        isDark ? 0.2 : 0.08,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/safevege_logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'SafeVege',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: primaryColor,
                                              letterSpacing: -0.4,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isDark
                                                ? const Color(0xFF34D399)
                                                : const Color(0xFF16A34A),
                                            boxShadow: [
                                              BoxShadow(
                                                color: primaryColor.withOpacity(
                                                  0.5,
                                                ),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'ผักปลอดภัย มั่นใจทุกมื้อ',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w600,
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
                        const SizedBox(width: 6),

                        // Top Bar Right Controls (Notifications, User avatar)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Bell button with active notifications
                            PressableScale(
                              onTap: () => _showNotificationsSheet(context),
                              child: Container(
                                padding: const EdgeInsets.all(6.5),
                                decoration: BoxDecoration(
                                  color: surfaceElevated,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? borderColor
                                        : const Color(0xFFE2EAE3),
                                    width: 0.8,
                                  ),
                                  boxShadow: AppShadows.cardOf(context),
                                ),
                                child: Icon(
                                  CupertinoIcons.bell_fill,
                                  size: 15,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            // Avatar Icon
                            PressableScale(
                              onTap: widget.onOpenAccount,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF10B981),
                                    width: 1.5,
                                  ),
                                  color: isDark
                                      ? const Color(0xFF13281C)
                                      : const Color(0xFFE8F5E9),
                                ),
                                child: Center(
                                  child: Icon(
                                    CupertinoIcons.person_fill,
                                    size: 16,
                                    color: isDark
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFF0F5A3C),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Bar with Filter Button and Map Pill
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceElevated,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: isDark
                            ? AppShadows.cardDark
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                        border: Border.all(
                          color: isDark ? borderColor : const Color(0xFFE3EDE5),
                          width: 0.8,
                        ),
                      ),
                      child: TextField(
                        controller: widget.searchController,
                        onChanged: _searchChanged,
                        style: TextStyle(fontSize: 14, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'ค้นหาร้าน ผัก หรือพื้นที่...',
                          hintStyle: TextStyle(
                            fontSize: 13.5,
                            color: isDark
                                ? AppDarkColors.textMuted
                                : AppColors.textMutedOf(context),
                          ),
                          prefixIcon: Icon(
                            CupertinoIcons.search,
                            size: 18,
                            color: primaryColor,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: Icon(
                                    CupertinoIcons.clear_circled_solid,
                                    size: 17,
                                    color: isDark
                                        ? AppDarkColors.textMuted
                                        : AppColors.textMutedOf(context),
                                  ),
                                  onPressed: () {
                                    widget.searchController.clear();
                                    setState(() {});
                                  },
                                ),
                              // Filter Button
                              PressableScale(
                                onTap: () => _showFilterSheet(context),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F5A3C),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.slider_horizontal_3,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Map Pill Button
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: PressableScale(
                                  onTap: widget.onOpenMap,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isDark
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF22C55E),
                                                Color(0xFF16A34A),
                                              ],
                                            )
                                          : const LinearGradient(
                                              colors: [
                                                Color(0xFF0F5A3C),
                                                Color(0xFF176E48),
                                              ],
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons.map_fill,
                                          size: 13,
                                          color: isDark
                                              ? const Color(0xFF04200E)
                                              : Colors.white,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'แผนที่',
                                          style: TextStyle(
                                            fontSize: 12,
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
                            ],
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Quick Services Bar (4 Interactive Feature Shortcuts)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: surfaceElevated,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? borderColor : const Color(0xFFE2ECE4),
                          width: 0.8,
                        ),
                        boxShadow: AppShadows.cardOf(context),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildQuickServiceItem(
                              context: context,
                              icon: CupertinoIcons.map_fill,
                              label: 'แผนที่ร้าน',
                              color: const Color(0xFF0284C7),
                              bgColor: isDark ? const Color(0xFF0C2C3D) : const Color(0xFFE0F2FE),
                              onTap: widget.onOpenMap,
                            ),
                          ),
                          Expanded(
                            child: _buildQuickServiceItem(
                              context: context,
                              icon: CupertinoIcons.checkmark_seal_fill,
                              label: 'ตรวจใบรับรอง',
                              color: const Color(0xFF10B981),
                              bgColor: isDark ? const Color(0xFF0F3523) : const Color(0xFFE8F5E9),
                              onTap: widget.onOpenCertificates,
                            ),
                          ),
                          Expanded(
                            child: _buildQuickServiceItem(
                              context: context,
                              icon: Icons.near_me_rounded,
                              label: 'ร้านใกล้ฉัน',
                              color: const Color(0xFFF59E0B),
                              bgColor: isDark ? const Color(0xFF38230A) : const Color(0xFFFEF3C7),
                              onTap: _filterNearby,
                            ),
                          ),
                          Expanded(
                            child: _buildQuickServiceItem(
                              context: context,
                              icon: Icons.favorite_rounded,
                              label: 'ร้านโปรด',
                              badgeText: favCount > 0 ? '$favCount' : null,
                              color: const Color(0xFFE11D48),
                              bgColor: isDark ? const Color(0xFF3B121B) : const Color(0xFFFFE4E6),
                              onTap: () => widget.onCategoryChanged('ร้านโปรด'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Promo Hero Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF153322),
                                  Color(0xFF0F2619),
                                ],
                              )
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFEBF7EF),
                                  Color(0xFFDCF4E3),
                                  Color(0xFFCEECD7),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF285037) : const Color(0xFFC0E5CC),
                          width: 0.9,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(isDark ? 0.2 : 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          // Left text column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ค้นหาร้านผักปลอดภัยใกล้คุณ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : const Color(0xFF0D4D31),
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ผักสด คุณภาพดี ตรวจสอบได้ เพื่อสุขภาพที่ดีกว่า',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF236544),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                PressableScale(
                                  onTap: _filterNearby,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F5A3C),
                                      borderRadius: BorderRadius.circular(100),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _isLocating ? 'กำลังค้นหา...' : 'ดูร้านใกล้ฉัน',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          CupertinoIcons.chevron_right,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Right Shield Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF142E1F)
                                  : Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF285037) : const Color(0xFFC0E5CC),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(isDark ? 0.2 : 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.checkmark_shield_fill,
                                  size: 26,
                                  color: isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF16A34A),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ผักปลอดภัย',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F5A3C),
                                  ),
                                ),
                                Text(
                                  'ตรวจสอบได้',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Category Selector Carousel (Segmented Pills)
                SliverToBoxAdapter(
                  child: Container(
                    height: 48,
                    margin: const EdgeInsets.only(top: 4),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (ctx, idx) {
                        final cat = _categories[idx];
                        final label = cat['label']!;
                        final icon = cat['icon']!;
                        final isSelected = _selectedCategory == label;

                        return Center(
                          child: PressableScale(
                            onTap: () {
                              widget.onCategoryChanged(label);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 7.5,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? (isDark
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF22C55E),
                                                Color(0xFF16A34A),
                                              ],
                                            )
                                          : const LinearGradient(
                                              colors: [
                                                Color(0xFF0F5A3C),
                                                Color(0xFF18784C),
                                              ],
                                            ))
                                    : null,
                                color: isSelected ? null : surfaceElevated,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark
                                            ? const Color(0xFF4ADE80)
                                            : const Color(0xFF0F5A3C))
                                      : (isDark
                                            ? borderColor
                                            : const Color(0xFFE2E9E2)),
                                  width: 0.8,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color:
                                              (isDark
                                                      ? const Color(0xFF22C55E)
                                                      : const Color(0xFF0F5A3C))
                                                  .withOpacity(0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : AppShadows.cardOf(context),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    icon,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    label == 'ร้านโปรด' && favCount > 0
                                        ? '$label ($favCount)'
                                        : label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : textPrimary,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Trust Highlight Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: TrustHighlightBanner(
                      onTap: widget.onOpenCertificates,
                    ),
                  ),
                ),

                // Featured Farms Section (ร้านแนะนำ)
                if (_searchQuery.isEmpty && _selectedCategory == 'ทั้งหมด') ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Text(
                                  '⭐',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'ร้านผักปลอดภัยแนะนำ',
                                    style: TextStyle(
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: widget.onOpenMap,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ดูทั้งหมด',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 11,
                                  color: primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 268,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: featuredShops.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (ctx, idx) {
                          final shop = featuredShops[idx];
                          return FeaturedFarmCard(
                            shop: shop,
                            distanceText: widget.appState.distanceTextFor(shop),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ShopDetailsScreen(
                                    shop: shop,
                                    appState: widget.appState,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // All Stores Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Text('🥬', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'ร้านค้าผักปลอดภัย (${filteredShops.length})',
                                  style: TextStyle(
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_searchQuery.isNotEmpty ||
                            _selectedCategory != 'ทั้งหมด') ...[
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: _clearFilters,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              'ล้างตัวกรอง',
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Store Feed List
                if (filteredShops.isEmpty)
                  SliverToBoxAdapter(
                    key: const ValueKey('empty_shops_view'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: EmptyStateView(
                        title: _selectedCategory == 'ร้านโปรด'
                            ? 'ยังไม่มีร้านโปรดที่บันทึกไว้'
                            : 'ไม่พบร้านค้าที่ตรงกับการค้นหา',
                        message: _selectedCategory == 'ร้านโปรด'
                            ? 'แตะที่ไอคอนหัวใจ ❤️ บนการ์ดร้านค้าเพื่อบันทึกเป็นร้านโปรด'
                            : 'ลองเปลี่ยนคำค้นหา หรือกดล้างตัวกรองเพื่อดูร้านค้าทั้งหมด',
                        actionLabel: 'ล้างตัวกรอง',
                        onAction: _clearFilters,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    key: const ValueKey('shops_sliver_list'),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((ctx, idx) {
                        final shop = filteredShops[idx];
                        final card = Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: MarketplaceShopCard(
                            key: ValueKey('shop_card_${shop.id}'),
                            shop: shop,
                            distanceText: widget.appState.distanceTextFor(shop),
                            isFavorite: widget.appState.isFavorite(shop.id),
                            onFavorite: () async {
                              await widget.appState.toggleFavorite(shop.id);
                              if (mounted) setState(() {});
                            },
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ShopDetailsScreen(
                                    shop: shop,
                                    appState: widget.appState,
                                  ),
                                ),
                              );
                              if (mounted) setState(() {});
                            },
                            onCall: () => _callShop(shop),
                            onRoute: () => _openGoogleMaps(shop),
                          ),
                        );
                        if (idx < 5) {
                          return AnimatedEntrance(
                            delay: Duration(milliseconds: 30 * idx),
                            child: card,
                          );
                        }
                        return card;
                      }, childCount: filteredShops.length),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickServiceItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
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
                      child: Icon(icon, size: 20, color: color),
                    ),
                  ),
                  if (badgeText != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppDarkColors.textPrimary
                      : AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
