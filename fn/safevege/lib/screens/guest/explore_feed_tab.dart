import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/interactive_animations.dart';
import 'shop_details_screen.dart';
import 'route_navigation_screen.dart';

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
        if (origin == null ||
            origin.distanceKmTo(
                  GeoPoint(latitude: shop.latitude, longitude: shop.longitude),
                ) >
                5.0) {
          return false;
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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final filteredShops = _getFilteredShops();
    final featuredShops = widget.appState.shops
        .where((s) => s.isVerified)
        .take(3)
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
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: [
                        // SafeVege Logo & Brand (Clean, premium badge)
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                padding: const EdgeInsets.all(5.5),
                                decoration: BoxDecoration(
                                  color: surfaceElevated,
                                  borderRadius: BorderRadius.circular(14),
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
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/safevege_logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'SafeVege',
                                          style: TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w900,
                                            color: primaryColor,
                                            letterSpacing: -0.4,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          width: 7,
                                          height: 7,
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
                                        fontSize: 11.5,
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
                        const SizedBox(width: 8),

                        // Quick Theme Toggle, Location chip & Account Button
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PressableScale(
                              onTap: () => widget.appState.toggleThemeMode(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
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
                                  isDark
                                      ? Icons.light_mode_rounded
                                      : Icons.dark_mode_rounded,
                                  size: 17,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6.5,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceElevated,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: isDark
                                      ? borderColor
                                      : const Color(0xFFDCE6DF),
                                  width: 0.8,
                                ),
                                boxShadow: AppShadows.cardOf(context),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 13.5,
                                    color: isDark
                                        ? AppDarkColors.primary
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'เชียงราย',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            PressableScale(
                              onTap: widget.onOpenAccount,
                              child: Container(
                                padding: const EdgeInsets.all(8),
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
                                  CupertinoIcons.person_crop_circle_fill,
                                  size: 18,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Bar (iOS Minimal Modern style)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
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
                          hintText:
                              'ค้นหาชื่อร้านค้า ผักปลอดสาร หรือพื้นที่...',
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
                                      borderRadius: BorderRadius.circular(14),
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

                // Category Selector Carousel (iOS Segmented Pills)
                SliverToBoxAdapter(
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.only(top: 6),
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
                                horizontal: 14,
                                vertical: 8,
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
                                    label,
                                    style: TextStyle(
                                      fontSize: 12.5,
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
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Text(
                                  '🌟',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'ร้านผักปลอดภัยแนะนำ',
                                    style: TextStyle(
                                      fontSize: 18,
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
                                  'ดูบนแผนที่',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 10,
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
                      height: 232,
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
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Text('🥗', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'ร้านค้าผักปลอดภัย (${filteredShops.length})',
                                  style: TextStyle(
                                    fontSize: 18,
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
                        if (_searchQuery.isNotEmpty ||
                            _selectedCategory != 'ทั้งหมด')
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
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Store Feed List
                if (filteredShops.isEmpty)
                  SliverToBoxAdapter(
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((ctx, idx) {
                        final shop = filteredShops[idx];
                        final card = Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: MarketplaceShopCard(
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
                            onRoute: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RouteNavigationScreen(shop: shop),
                                ),
                              );
                            },
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
}
