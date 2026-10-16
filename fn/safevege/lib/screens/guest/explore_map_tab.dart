import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/interactive_map.dart';
import '../../widgets/interactive_animations.dart';
import 'shop_details_screen.dart';

class ExploreMapTab extends StatefulWidget {
  const ExploreMapTab({
    super.key,
    required this.appState,
    required this.searchController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onSwitchToFeed,
  });

  final AppState appState;
  final TextEditingController searchController;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onSwitchToFeed;

  @override
  State<ExploreMapTab> createState() => _ExploreMapTabState();
}

class _ExploreMapTabState extends State<ExploreMapTab> {
  String get _searchQuery => widget.searchController.text;
  String get _selectedCategory => widget.selectedCategory;
  ShopModel? _selectedShop;
  late final PageController _pageController;
  int _currentPageIndex = 0;
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

  final List<String> _quickCategories = const [
    'ทั้งหมด',
    'ผักสลัด',
    'คะน้า',
    'มะเขือเทศ',
    'กะหล่ำปลี',
    'แตงกวา',
    'ใกล้ฉัน',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    final verified = widget.appState.shops.where((s) => s.isVerified).toList();
    if (verified.isNotEmpty) {
      _selectedShop = verified.first;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<ShopModel> _getFilteredShops() {
    return widget.appState.shops.where((shop) {
      if (!shop.isVerified) return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchName = shop.name.toLowerCase().contains(query);
        final matchArea =
            shop.shortArea.toLowerCase().contains(query) ||
            shop.district.toLowerCase().contains(query);
        final matchVeg = shop.verifiedVegetables.any(
          (v) => v.toLowerCase().contains(query),
        );
        if (!matchName && !matchArea && !matchVeg) return false;
      }

      if (_selectedCategory == 'ใกล้ฉัน') {
        final origin = widget.appState.nearbyOrigin;
        if (origin == null ||
            origin.distanceKmTo(
                  GeoPoint(latitude: shop.latitude, longitude: shop.longitude),
                ) >
                5.0) {
          return false;
        }
      } else if (_selectedCategory != 'ทั้งหมด') {
        if (!shop.verifiedVegetables.any(
          (v) => v.contains(_selectedCategory),
        )) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _onShopMarkerTapped(ShopModel shop, List<ShopModel> shops) {
    setState(() => _selectedShop = shop);
    final idx = shops.indexWhere((s) => s.id == shop.id);
    if (idx != -1 && _pageController.hasClients) {
      _pageController.animateToPage(
        idx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
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
      final launched = await launchUrl(uri, mode: mode);
      if (!launched && mounted) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(context, 'ไม่สามารถเปิด Google Maps ได้');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredShops = _getFilteredShops();

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: SafeArea(
        child: Stack(
          children: [
            // Full Screen Map
            Positioned.fill(
              child: SafeVegeInteractiveMap(
                height: double.infinity,
                isFullScreen: true,
                shops: filteredShops,
                selectedShop: _selectedShop,
                onShopTap: (shop) => _onShopMarkerTapped(shop, filteredShops),
              ),
            ),

            // Top Floating Search Bar & Filter Chips
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Box
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppDarkColors.surfaceElevated
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark
                          ? const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : AppShadows.floating,
                      border: Border.all(
                        color: isDark ? AppDarkColors.border : const Color(0xFFE2EBE5),
                        width: 0.9,
                      ),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            CupertinoIcons.search,
                            size: 19,
                            color: isDark
                                ? AppDarkColors.primaryAccent
                                : AppColors.primary,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: widget.searchController,
                            onChanged: _searchChanged,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark
                                  ? AppDarkColors.textPrimary
                                  : AppColors.textPrimaryOf(context),
                            ),
                            decoration: InputDecoration(
                              hintText: 'ค้นหาร้าน ผัก หรือพื้นที่...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppDarkColors.textMuted
                                    : AppColors.textMutedOf(context),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              CupertinoIcons.clear_circled_solid,
                              size: 18,
                              color: isDark
                                  ? AppDarkColors.textMuted
                                  : AppColors.textMutedOf(context),
                            ),
                            onPressed: () {
                              widget.searchController.clear();
                              setState(() {});
                            },
                          ),
                        // List View Switch Button
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E3A2B)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: PressableScale(
                            onTap: widget.onSwitchToFeed,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.format_list_bulleted_rounded,
                                    color: isDark
                                        ? AppDarkColors.primaryAccent
                                        : AppColors.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'รายการ',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppDarkColors.primaryAccent
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Horizontal Category Pills
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickCategories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (ctx, idx) {
                        final cat = _quickCategories[idx];
                        final isSel = _selectedCategory == cat;
                        return PressableScale(
                          onTap: () => widget.onCategoryChanged(cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSel
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
                                            Color(0xFF16794D),
                                          ],
                                        ))
                                  : null,
                              color: isSel
                                  ? null
                                  : (isDark
                                      ? AppDarkColors.surfaceElevated
                                          .withOpacity(0.95)
                                      : Colors.white.withOpacity(0.96)),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isSel
                                    ? Colors.transparent
                                    : (isDark
                                        ? AppDarkColors.border
                                        : const Color(0xFFDDE6DF)),
                                width: 0.9,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _categoryEmoji(cat),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSel
                                        ? (isDark ? Colors.black : Colors.white)
                                        : (isDark
                                            ? AppDarkColors.textPrimary
                                            : AppColors.textPrimaryOf(context)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Floating Shop Count Indicator (Above bottom carousel)
            Positioned(
              right: 14,
              bottom: 220,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppDarkColors.surfaceElevated.withOpacity(0.95)
                      : Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isDark
                        ? AppDarkColors.border
                        : const Color(0xFFDDE6DF),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'พบ ${filteredShops.length} ร้านปลอดภัย',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppDarkColors.textPrimary
                            : AppColors.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Sliding Shop Cards Carousel
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              height: 198,
              child: filteredShops.isEmpty
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppDarkColors.surfaceElevated
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? AppDarkColors.border
                                : const Color(0xFFDDE6DF),
                          ),
                          boxShadow: isDark
                              ? const [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : AppShadows.floating,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E3527)
                                    : const Color(0xFFEBF7EF),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_off_rounded,
                                size: 20,
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ไม่พบร้านค้าในบริเวณนี้ ลองเปลี่ยนตัวกรอง',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppDarkColors.textPrimary
                                          : AppColors.textPrimaryOf(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ลองค้นหาด้วยชื่อผักอื่น หรือแตะ "ทั้งหมด"',
                                    style: TextStyle(
                                      fontSize: 11,
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
                      ),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: filteredShops.length,
                      onPageChanged: (idx) {
                        setState(() {
                          _currentPageIndex = idx;
                          _selectedShop = filteredShops[idx];
                        });
                      },
                      itemBuilder: (ctx, idx) {
                        final shop = filteredShops[idx];
                        final isCurrent = _currentPageIndex == idx;

                        return AnimatedPadding(
                          duration: const Duration(milliseconds: 250),
                          padding: EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: isCurrent ? 0 : 5,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppDarkColors.surfaceElevated
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCurrent
                                    ? (isDark
                                        ? const Color(0xFF22C55E)
                                        : AppColors.primary)
                                    : (isDark
                                        ? AppDarkColors.border
                                        : const Color(0xFFE3EDE5)),
                                width: isCurrent ? 1.6 : 0.8,
                              ),
                              boxShadow: isDark
                                  ? const [
                                      BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ]
                                  : AppShadows.floating,
                            ),
                            padding: const EdgeInsets.all(13),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Top Row: Avatar + Shop Identity + Verified Badge
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    buildShopAvatar(
                                      shop: shop,
                                      isDark: isDark,
                                      size: 46,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  shop.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 15,
                                                    color: isDark
                                                        ? AppDarkColors
                                                            .textPrimary
                                                        : AppColors
                                                            .textPrimaryOf(
                                                              context,
                                                            ),
                                                    letterSpacing: -0.3,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              // Verified Badge
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 2.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? const Color(0xFF0F3221)
                                                      : const Color(0xFFE8F5E9),
                                                  borderRadius:
                                                      BorderRadius.circular(100),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF10B981,
                                                    ).withOpacity(0.3),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      CupertinoIcons
                                                          .checkmark_seal_fill,
                                                      size: 10,
                                                      color: Color(0xFF10B981),
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      'รับรองแล้ว',
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isDark
                                                            ? const Color(
                                                              0xFF34D399,
                                                            )
                                                            : const Color(
                                                              0xFF0F5A3C,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                size: 11.5,
                                                color: isDark
                                                    ? AppDarkColors
                                                        .textSecondary
                                                    : AppColors.textSecondaryOf(
                                                        context,
                                                      ),
                                              ),
                                              const SizedBox(width: 3),
                                              Expanded(
                                                child: Text(
                                                  '${shop.shortArea}${shop.ownerFullName.isNotEmpty ? " • โดย ${shop.ownerFullName}" : ""}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark
                                                        ? AppDarkColors
                                                            .textSecondary
                                                        : AppColors
                                                            .textSecondaryOf(
                                                              context,
                                                            ),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Middle Row: Distance & Vegetables Tags
                                Row(
                                  children: [
                                    // Distance Pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF0C2C3D)
                                            : const Color(0xFFE0F2FE),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF0284C7)
                                              .withOpacity(0.25),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.near_me_rounded,
                                            size: 11,
                                            color: Color(0xFF0284C7),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            widget.appState
                                                        .distanceTextFor(shop)
                                                        .isNotEmpty &&
                                                    widget.appState
                                                            .distanceTextFor(
                                                              shop,
                                                            ) !=
                                                        '—'
                                                ? 'ห่าง ${widget.appState.distanceTextFor(shop)}'
                                                : 'ใกล้คุณ',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? const Color(0xFF38BDF8)
                                                  : const Color(0xFF0284C7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Vegetables horizontal list
                                    Expanded(
                                      child: SizedBox(
                                        height: 24,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount:
                                              shop.verifiedVegetables.length,
                                          separatorBuilder: (_, _) =>
                                              const SizedBox(width: 4),
                                          itemBuilder: (ctx, vIdx) {
                                            final vegName =
                                                shop.verifiedVegetables[vIdx];
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 7,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF13281C)
                                                    : const Color(0xFFF0FDF4),
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF22C55E,
                                                  ).withOpacity(0.3),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    safeVegeEmoji(vegName),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    vegName,
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isDark
                                                          ? const Color(
                                                            0xFF4ADE80,
                                                          )
                                                          : const Color(
                                                            0xFF15803D,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Bottom Action Buttons
                                Row(
                                  children: [
                                    // Navigate Maps Button
                                    Expanded(
                                      child: PressableScale(
                                        onTap: () => _openGoogleMaps(shop),
                                        child: Container(
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1F2922)
                                                : const Color(0xFFF3F6F4),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFF2F3E33)
                                                  : const Color(0xFFE2EBE4),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                CupertinoIcons.location_fill,
                                                size: 13,
                                                color: isDark
                                                    ? const Color(0xFF34D399)
                                                    : const Color(0xFF0F5A3C),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'นำทาง Maps',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? AppDarkColors.textPrimary
                                                      : AppColors
                                                          .textPrimaryOf(
                                                            context,
                                                          ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Shop Details Button
                                    Expanded(
                                      child: PressableScale(
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
                                        child: Container(
                                          height: 38,
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
                                                      Color(0xFF186E49),
                                                    ],
                                                  ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF0F5A3C,
                                                ).withOpacity(0.25),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'ดูร้านค้า',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? const Color(0xFF052312)
                                                      : Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                CupertinoIcons.chevron_right,
                                                size: 11,
                                                color: isDark
                                                    ? const Color(0xFF052312)
                                                    : Colors.white,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryEmoji(String cat) {
    switch (cat) {
      case 'ทั้งหมด':
        return '🌿';
      case 'ใกล้ฉัน':
        return '📍';
      case 'ผักสลัด':
        return '🥬';
      case 'คะน้า':
        return '🥦';
      case 'มะเขือเทศ':
        return '🍅';
      case 'กะหล่ำปลี':
        return '🥗';
      case 'แตงกวา':
        return '🥒';
      default:
        return '🌱';
    }
  }
}
