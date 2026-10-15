import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/interactive_animations.dart';
import 'certificate_viewer_screen.dart';

class CertificatesHubTab extends StatefulWidget {
  const CertificatesHubTab({super.key, required this.appState});

  final AppState appState;

  @override
  State<CertificatesHubTab> createState() => _CertificatesHubTabState();
}

class _CertificatesHubTabState extends State<CertificatesHubTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadPublicCertificates();
    });
  }

  Future<void> _loadPublicCertificates() async {
    try {
      await widget.appState.loadPublicCertificates();
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CertificateModel> _filteredCertificates() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return widget.appState.publicCertificates;
    return widget.appState.publicCertificates
        .where((certificate) {
          final vegetables = _resolveVegetables(certificate);
          final matchShop = certificate.shopName.toLowerCase().contains(query);
          final matchNumber = certificate.certificateNumber
              .toLowerCase()
              .contains(query);
          final matchVeg = vegetables.any(
            (v) => v.toLowerCase().contains(query),
          );
          return matchShop || matchNumber || matchVeg;
        })
        .toList(growable: false);
  }

  List<String> _resolveVegetables(CertificateModel certificate) {
    try {
      final dynamic dynCert = certificate;
      final dynamic certVegs = dynCert.vegetables;
      if (certVegs is List && certVegs.isNotEmpty) {
        return certVegs
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      }
    } catch (_) {}

    try {
      final shop = widget.appState.shops
          .where((s) => s.id == certificate.shopId)
          .firstOrNull;
      if (shop != null) {
        final dynamic dynShop = shop;
        final dynamic shopVegs = dynShop.verifiedVegetables;
        if (shopVegs is List && shopVegs.isNotEmpty) {
          return shopVegs
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList(growable: false);
        }
      }
    } catch (_) {}

    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final certificates = _filteredCertificates();
        final isLoading = widget.appState.isLoading;
        final error = widget.appState.errorMessage;

        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: AppBar(title: const Text('ผลตรวจและใบรับรอง')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'ค้นหาชื่อร้าน เลขใบรับรอง หรือชนิดผัก...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.primaryOf(context),
                        ),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'ล้างการค้นหา',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'ใบรับรองที่เผยแพร่ (${certificates.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isLoading && widget.appState.publicCertificates.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (error != null &&
                        widget.appState.publicCertificates.isEmpty)
                      EmptyStateView(
                        title: 'โหลดใบรับรองไม่สำเร็จ',
                        message: error,
                        actionLabel: 'ลองอีกครั้ง',
                        onAction: _loadPublicCertificates,
                      )
                    else if (certificates.isEmpty)
                      EmptyStateView(
                        title: _searchQuery.isEmpty
                            ? 'ยังไม่มีใบรับรองที่เผยแพร่'
                            : 'ไม่พบใบรับรองที่ค้นหา',
                        message: _searchQuery.isEmpty
                            ? 'เมื่อร้านค้ามีผลตรวจและเผยแพร่ใบรับรองแล้ว รายการจะแสดงที่นี่'
                            : 'ลองค้นหาด้วยชื่อร้านหรือเลขที่ใบรับรอง',
                      )
                    else
                      ...AnimatedEntrance.stagger(
                        certificates.map(_certificateCard).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _certificateCard(CertificateModel certificate) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PulseBadge(
                minScale: 0.92,
                maxScale: 1.15,
                duration: const Duration(milliseconds: 2000),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppColors.success,
                  size: 26,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      certificate.shopName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'เลขที่ ${certificate.certificateNumber}',
                      style: TextStyle(
                        color: AppColors.primaryOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusBadge(status: true),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'วันที่ออก ${_formatDate(certificate.issuedAt)}',
            style: TextStyle(color: AppColors.textSecondaryOf(context)),
          ),
          if (certificate.expiresAt != null)
            Text(
              'หมดอายุ ${_formatDate(certificate.expiresAt!)}',
              style: TextStyle(color: AppColors.textSecondaryOf(context)),
            ),
          Builder(
            builder: (context) {
              final vegetables = _resolveVegetables(certificate);
              if (vegetables.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: vegetables
                      .take(5)
                      .map(
                        (name) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PressableScale(
              onPressed: () {
                final vegetables = _resolveVegetables(certificate);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CertificateViewerScreen(
                      shopName: certificate.shopName,
                      certNumber: certificate.certificateNumber,
                      certificateId: certificate.id,
                      vegetables: vegetables,
                      issueDate: certificate.issuedAt,
                      expiryDate: certificate.expiresAt,
                    ),
                  ),
                );
              },
              child: FilledButton.icon(
                onPressed: () {
                  final vegetables = _resolveVegetables(certificate);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CertificateViewerScreen(
                        shopName: certificate.shopName,
                        certNumber: certificate.certificateNumber,
                        certificateId: certificate.id,
                        vegetables: vegetables,
                        issueDate: certificate.issuedAt,
                        expiryDate: certificate.expiresAt,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('เปิดใบรับรองจริง'),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year + 543}';
}
