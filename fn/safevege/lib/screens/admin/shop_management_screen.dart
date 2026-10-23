import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import 'admin_shop_details_screen.dart';

class ShopManagementScreen extends StatefulWidget {
  const ShopManagementScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await widget.appState.loadAdminShops();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ShopModel> _getFilteredShops() {
    return widget.appState.shops.where((s) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = s.name.toLowerCase().contains(q);
        final matchOwner = s.ownerFullName.toLowerCase().contains(q);
        final matchArea = s.shortArea.toLowerCase().contains(q);
        if (!matchName && !matchOwner && !matchArea) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final shops = _getFilteredShops();

        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: AppBar(
            title: const Text('จัดการร้านค้าทั้งหมด'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'รีเฟรช',
                onPressed: _loading ? null : _load,
              ),
              IconButton(
                icon: const Icon(Icons.add_business_outlined),
                tooltip: 'เพิ่มร้านค้าใหม่',
                onPressed: () async {
                  final created = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminShopDetailsScreen(
                        appState: widget.appState,
                        isAddMode: true,
                      ),
                    ),
                  );
                  if (created == true || mounted) _load();
                },
              ),
            ],
          ),
          body: ResponsiveContent(
            maxWidth: 1120,
            padding: EdgeInsets.zero,
            child: SafeArea(
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'ค้นหาชื่อร้านค้า หรือเจ้าของร้าน...',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.primaryOf(context),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),

                  // Shop list
                  Expanded(
                    child: _loading && shops.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: shops.isEmpty
                                ? LayoutBuilder(
                                    builder: (context, constraints) =>
                                        SingleChildScrollView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight,
                                        ),
                                        child: EmptyStateView(
                                          title: 'ยังไม่มีข้อมูลร้านค้าในระบบ',
                                          message:
                                              'ไม่พบร้านค้าที่ตรงกับเงื่อนไขค้นหา หรือยังไม่มีร้านค้าลงทะเบียน',
                                          actionLabel: 'เพิ่มร้านค้าใหม่',
                                          onAction: () async {
                                            final created =
                                                await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AdminShopDetailsScreen(
                                                  appState: widget.appState,
                                                  isAddMode: true,
                                                ),
                                              ),
                                            );
                                            if (created == true || mounted) {
                                              _load();
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    itemCount: shops.length,
                                    itemBuilder: (ctx, idx) {
                                      final shop = shops[idx];
                                      final reqCount = widget.appState.requests
                                          .where((r) => r.shopId == shop.id)
                                          .length;

                                      return Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      shop.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  StatusBadge(
                                                    status: shop.isVerified
                                                        ? 'ผ่านการตรวจ'
                                                        : 'รอรับรอง',
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'เจ้าของ: ${shop.ownerFullName} • โทร: ${shop.phone}',
                                              ),
                                              Text(
                                                '${shop.shortArea} • คำขอตรวจทั้งหมด: $reqCount รายการ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondaryOf(
                                                    context,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: OutlinedButton.icon(
                                                      onPressed: () async {
                                                        final res =
                                                            await Navigator
                                                                .push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                AdminShopDetailsScreen(
                                                              shop: shop,
                                                              appState: widget
                                                                  .appState,
                                                            ),
                                                          ),
                                                        );
                                                        if (res == true ||
                                                            mounted) {
                                                          _load();
                                                        }
                                                      },
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                        minimumSize:
                                                            const Size(0, 36),
                                                      ),
                                                      icon: const Icon(
                                                        Icons
                                                            .visibility_outlined,
                                                        size: 16,
                                                      ),
                                                      label: const Text(
                                                        'ดูรายละเอียด',
                                                        style: TextStyle(
                                                            fontSize: 12),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: FilledButton.icon(
                                                      onPressed: () async {
                                                        final res =
                                                            await Navigator
                                                                .push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                AdminShopDetailsScreen(
                                                              shop: shop,
                                                              appState: widget
                                                                  .appState,
                                                            ),
                                                          ),
                                                        );
                                                        if (res == true ||
                                                            mounted) {
                                                          _load();
                                                        }
                                                      },
                                                      style: FilledButton
                                                          .styleFrom(
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                        minimumSize:
                                                            const Size(0, 36),
                                                      ),
                                                      icon: const Icon(
                                                        Icons.edit_outlined,
                                                        size: 16,
                                                      ),
                                                      label: const Text(
                                                        'แก้ไขร้านค้า',
                                                        style: TextStyle(
                                                            fontSize: 12),
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
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminShopDetailsScreen(
                  appState: widget.appState,
                  isAddMode: true,
                ),
              ),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มร้านค้าใหม่'),
          ),
        );
      },
    );
  }
}
