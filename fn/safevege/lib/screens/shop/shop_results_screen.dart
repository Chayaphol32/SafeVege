import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../models/app_models.dart';
import '../../widgets/common_widgets.dart';
import '../guest/certificate_viewer_screen.dart';

class ShopResultsScreen extends StatelessWidget {
  const ShopResultsScreen({super.key, required this.request});

  final InspectionRequestModel request;

  @override
  Widget build(BuildContext context) {
    final results = request.results;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('ผลการตรวจสอบ')),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: AppContentWidth.form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            request.id,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primaryOf(context),
                            ),
                          ),
                          StatusBadge(status: request.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ร้านค้า: ${request.shopName}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (request.inspectionDate != null)
                        Text(
                          'วันที่ตรวจจริง: ${request.inspectionDate!.day}/${request.inspectionDate!.month}/${request.inspectionDate!.year + 543}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                      if (request.inspectorName != null)
                        Text(
                          'ผู้ตรวจสอบ: ${request.inspectorName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'รายการผลตรวจผักรายชนิด',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryOf(context),
                ),
              ),
              const SizedBox(height: 8),

              if (results.isEmpty)
                const EmptyStateView(
                  title: 'ยังไม่มีผลการตรวจสอบ',
                  message: 'คำขอนี้ยังอยู่ระหว่างกระบวนการตรวจสอบ กรุณารอการบันทึกผลจากเจ้าหน้าที่',
                )
              else
                ...results.map((item) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      item.passed == true
                                          ? Icons.verified_rounded
                                          : item.passed == false
                                          ? Icons.cancel_rounded
                                          : Icons.pending_outlined,
                                      color: item.passed == true
                                          ? AppColors.success
                                          : item.passed == false
                                          ? AppColors.danger
                                          : AppColors.textMutedOf(context),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(status: item.passed),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (item.details != null)
                            Text(
                              item.details!,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                          if (item.notes != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'หมายเหตุผู้ตรวจ: ${item.notes}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryOf(context),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 16),

              // Certificate Section
              if (request.hasCertificate) ...[
                Card(
                  color: AppColors.successBgOf(context).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(
                      color: AppColors.success,
                      width: 1.2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: AppColors.primaryOf(context),
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'เอกสารใบรับรองผลตรวจ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    request.certificateNumber!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondaryOf(context),
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
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CertificateViewerScreen(
                                        shopName: request.shopName,
                                        certNumber: request.certificateNumber!,
                                        certificateId: request.certificateId,
                                        certificateFileName:
                                            request.certificateFileName,
                                        vegetables: request.results
                                            .where(
                                              (result) => result.passed == true,
                                            )
                                            .map((result) => result.name)
                                            .toList(),
                                        issueDate: request.inspectionDate,
                                        expiryDate:
                                            request.certificateExpiryDate,
                                        inspectorName: request.inspectorName,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.remove_red_eye_outlined,
                                  size: 16,
                                ),
                                label: const Text('เปิดใบรับรองจริง'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (request.isCompleted && !request.hasCertificate) ...[
                const SizedBox(height: 16),
                const EmptyStateView(
                  title: 'ยังไม่มีใบรับรองสำหรับคำขอนี้',
                  message: 'ใบรับรองจะแสดงเมื่อผลตรวจผ่านทุกรายการและมีข้อมูลไฟล์กับเลขที่ครบ',
                ),
              ],

              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('กลับหน้าหลัก'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
