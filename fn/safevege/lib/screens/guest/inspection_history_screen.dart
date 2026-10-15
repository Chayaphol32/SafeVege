import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/common_widgets.dart';
import 'certificate_viewer_screen.dart';

class InspectionHistoryScreen extends StatelessWidget {
  const InspectionHistoryScreen({
    super.key,
    required this.shop,
    required this.results,
  });

  final ShopModel shop;
  final List<PublicInspectionResult> results;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('ประวัติผลตรวจที่เผยแพร่')),
      body: results.isEmpty
          ? const EmptyStateView(
              title: 'ยังไม่มีประวัติที่เผยแพร่',
              message: 'ข้อมูลผลตรวจจะแสดงเมื่อมีการเผยแพร่ใบรับรองจากระบบ',
            )
          : ResponsiveContent(
              maxWidth: AppContentWidth.form,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final result = results[index];
                  final vegetables = results
                      .where(
                        (item) => item.certificateId == result.certificateId,
                      )
                      .map((item) => item.vegetableName)
                      .toSet()
                      .toList(growable: false);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.eco_rounded,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  result.vegetableName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const StatusBadge(status: true),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('ร้านค้า: ${shop.name}'),
                          if (result.inspectedAt != null)
                            Text(
                              'ตรวจเมื่อ: ${_formatDate(result.inspectedAt!)}',
                            ),
                          Text('ใบรับรอง: ${result.certificateNumber}'),
                          if (result.expiresAt != null)
                            Text('มีผลถึง: ${_formatDate(result.expiresAt!)}'),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CertificateViewerScreen(
                                  shopName: shop.name,
                                  certNumber: result.certificateNumber,
                                  certificateId: result.certificateId,
                                  vegetables: vegetables,
                                  issueDate: result.issuedAt,
                                  expiryDate: result.expiresAt,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('เปิดใบรับรองจริง'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _formatDate(DateTime value) =>
      '${value.day}/${value.month}/${value.year + 543}';
}
