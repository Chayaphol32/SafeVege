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
                      border: Border.all(color: AppColors.borderOf(context)),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.search_rounded,
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
                              fontSize: 13,
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
                              Icons.cancel_rounded,
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
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppDarkColors.surfaceSubtle
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: PressableScale(
                            onPressed: widget.onSwitchToFeed,
                            child: IconButton(
                              icon: Icon(
                                Icons.format_list_bulleted_rounded,
                                color: isDark
                                    ? AppDarkColors.primaryAccent
                                    : AppColors.primary,
                                size: 20,
                              ),
                              tooltip: 'กลับไปหน้ารายการ',
                              onPressed: widget.onSwitchToFeed,
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
                          onPressed: () => widget.onCategoryChanged(cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? (isDark
                                        ? AppDarkColors.primaryAccent
                                        : AppColors.primary)
                                  : (isDark
                                        ? AppDarkColors.surfaceElevated
                                              .withOpacity(0.92)
                                        : Colors.white.withOpacity(0.95)),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isSel
                                    ? (isDark
                                          ? AppDarkColors.primaryAccent
                                          : AppColors.primary)
                                    : AppColors.borderOf(context),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
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
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Floating Switch-to-Feed Button & Badge
            Positioned(
              right: 14,
              bottom: 205,
              child: Column(
                children: [
                  PressableScale(
                    onPressed: widget.onSwitchToFeed,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppDarkColors.surfaceElevated
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderOf(context)),
                        boxShadow: isDark
                            ? const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ]
                            : AppShadows.cardOf(context),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.format_list_bulleted_rounded,
                          color: isDark
                              ? AppDarkColors.primaryAccent
                              : AppColors.primary,
                        ),
                        tooltip: 'ดูรายการร้านค้า',
                        onPressed: widget.onSwitchToFeed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppDarkColors.primaryAccent
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isDark
                          ? const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : AppShadows.cardOf(context),
                    ),
                    child: Text(
                      '${filteredShops.length} ร้าน',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Sliding Shop Cards Carousel
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              height: 175,
              child: filteredShops.isEmpty
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppDarkColors.surfaceElevated
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.borderOf(context),
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
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: isDark
                                  ? AppDarkColors.textMuted
                                  : AppColors.textMutedOf(context),
                            ),
                            Text(
                              'ไม่พบร้านค้าในบริเวณนี้ ลองเปลี่ยนตัวกรอง',
                              style: TextStyle(
                                color: isDark
                                    ? AppDarkColors.textSecondary
                                    : AppColors.textSecondaryOf(context),
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
                            horizontal: 6,
                            vertical: isCurrent ? 0 : 6,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppDarkColors.surfaceElevated
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isCurrent
                                    ? (isDark
                                          ? AppDarkColors.primaryAccent
                                          : AppColors.primary)
                                    : AppColors.borderOf(context),
                                width: isCurrent ? 1.5 : 0.8,
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
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppDarkColors.primaryGlow
                                            : const Color(0xFFF1F7F3),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Icon(
                                        CupertinoIcons.leaf_arrow_circlepath,
                                        color: isDark
                                            ? AppDarkColors.primaryAccent
                                            : AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            shop.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isDark
                                                  ? AppDarkColors.textPrimary
                                                  : AppColors.textPrimaryOf(
                                                      context,
                                                    ),
                                              letterSpacing: 0,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(
                                                CupertinoIcons.location_fill,
                                                size: 11,
                                                color: isDark
                                                    ? AppDarkColors
                                                          .primaryAccent
                                                    : AppColors.primary,
                                              ),
                                              const SizedBox(width: 3),
                                              Expanded(
                                                child: Text(
                                                  '${widget.appState.distanceTextFor(shop)} • ${shop.shortArea}',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: isDark
                                                        ? AppDarkColors
                                                              .textSecondary
                                                        : AppColors.textSecondaryOf(
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

                                // Veg pills
                                SizedBox(
                                  height: 24,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: shop.verifiedVegetables.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(width: 4),
                                    itemBuilder: (ctx, vIdx) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppDarkColors.surfaceSubtle
                                              : const Color(0xFFF1F8F3),
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child: Text(
                                          shop.verifiedVegetables[vIdx],
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppDarkColors.primaryAccent
                                                : const Color(0xFF145D33),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: PressableScale(
                                        onPressed: () => _openGoogleMaps(shop),
                                        child: Container(
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppDarkColors.surfaceSubtle
                                                : const Color(0xFFF2F5F2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                CupertinoIcons
                                                    .arrow_turn_up_right,
                                                size: 13,
                                                color: isDark
                                                    ? AppDarkColors.textPrimary
                                                    : AppColors.textPrimaryOf(
                                                        context,
                                                      ),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'นำทาง',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? AppDarkColors
                                                            .textPrimary
                                                      : AppColors.textPrimaryOf(
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
                                    Expanded(
                                      child: PressableScale(
                                        onPressed: () {
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
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppDarkColors.primaryAccent
                                                : AppColors.primary,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'ดูร้านค้า',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? Colors.black
                                                      : Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              Icon(
                                                CupertinoIcons.chevron_right,
                                                size: 10,
                                                color: isDark
                                                    ? Colors.black
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
}
